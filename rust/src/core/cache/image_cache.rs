// 图片缓存
// 用于缓存网络图片到本地，默认 3 天过期

use super::utils::{hash_lock, md5_hex};
use super::{get_image_cache_dir, IMAGE_CACHE_EXPIRE_MS};
use anyhow::Result;
use rusqlite::params;

/// 图片缓存记录
#[derive(Debug, Clone)]
pub struct ImageCacheRecord {
    pub url: String,
    pub local_path: String,
    pub cache_time: i64,
    pub image_width: Option<u32>,
    pub image_height: Option<u32>,
}

/// 获取缓存图片记录
pub fn get_cached_image(url: &str) -> Result<Option<ImageCacheRecord>> {
    let db = crate::core::storage::get_db()?;
    let mut stmt = db.prepare_cached(
        "SELECT url, local_path, cache_time, image_width, image_height FROM image_cache WHERE url = ?1",
    )?;
    let mut rows = stmt.query(params![url])?;

    if let Some(row) = rows.next()? {
        Ok(Some(ImageCacheRecord {
            url: row.get(0)?,
            local_path: row.get(1)?,
            cache_time: row.get(2)?,
            image_width: row.get::<_, Option<i32>>(3)?.map(|v| v as u32),
            image_height: row.get::<_, Option<i32>>(4)?.map(|v| v as u32),
        }))
    } else {
        Ok(None)
    }
}

/// 保存图片缓存记录
pub fn save_cached_image(
    url: &str,
    local_path: &str,
    width: Option<u32>,
    height: Option<u32>,
) -> Result<()> {
    let db = crate::core::storage::get_db()?;
    let now = chrono::Local::now().timestamp_millis();
    db.execute(
        "INSERT OR REPLACE INTO image_cache (url, local_path, cache_time, image_width, image_height) VALUES (?1, ?2, ?3, ?4, ?5)",
        params![url, local_path, now, width.map(|v| v as i32), height.map(|v| v as i32)],
    )?;
    Ok(())
}

/// 更新缓存时间（刷新 LRU）
pub fn update_cache_time(url: &str) -> Result<()> {
    let db = crate::core::storage::get_db()?;
    let now = chrono::Local::now().timestamp_millis();
    db.execute(
        "UPDATE image_cache SET cache_time = ?1 WHERE url = ?2",
        params![now, url],
    )?;
    Ok(())
}

/// 删除缓存记录
pub fn delete_by_url(url: &str) -> Result<()> {
    let db = crate::core::storage::get_db()?;
    db.execute("DELETE FROM image_cache WHERE url = ?1", params![url])?;
    Ok(())
}

/// 获取一批过期的缓存记录
pub fn take_expired_batch(before_time: i64, limit: u32) -> Result<Vec<ImageCacheRecord>> {
    let db = crate::core::storage::get_db()?;
    let mut stmt = db.prepare_cached(
        "SELECT url, local_path, cache_time, image_width, image_height FROM image_cache WHERE cache_time < ?1 ORDER BY cache_time ASC LIMIT ?2",
    )?;
    let rows = stmt.query_map(params![before_time, limit], |row| {
        Ok(ImageCacheRecord {
            url: row.get(0)?,
            local_path: row.get(1)?,
            cache_time: row.get(2)?,
            image_width: row.get::<_, Option<i32>>(3)?.map(|v| v as u32),
            image_height: row.get::<_, Option<i32>>(4)?.map(|v| v as u32),
        })
    })?;

    let mut records = Vec::new();
    for row in rows {
        records.push(row?);
    }
    Ok(records)
}

/// 清理过期图片缓存（包括文件）
pub fn clean_expired(before_time: i64) -> Result<(u64, u64)> {
    let cache_dir = get_image_cache_dir()?;
    let mut deleted_records = 0u64;
    let mut deleted_files = 0u64;

    loop {
        let batch = take_expired_batch(before_time, 100)?;
        if batch.is_empty() {
            break;
        }

        for record in batch {
            // 删除本地文件
            let file_path = cache_dir.join(&record.local_path);
            if file_path.exists() {
                if std::fs::remove_file(&file_path).is_ok() {
                    deleted_files += 1;
                }
            }
            // 删除数据库记录
            delete_by_url(&record.url)?;
            deleted_records += 1;
        }
    }

    tracing::info!(
        "Cleaned {} image cache records, {} files",
        deleted_records,
        deleted_files
    );
    Ok((deleted_records, deleted_files))
}

/// 清理所有图片缓存
pub fn clean_all() -> Result<(u64, u64)> {
    let cache_dir = get_image_cache_dir()?;
    let mut deleted_files = 0u64;

    // 删除所有文件
    if cache_dir.exists() {
        for entry in std::fs::read_dir(&cache_dir)? {
            let entry = entry?;
            let path = entry.path();
            if path.is_file() {
                if std::fs::remove_file(&path).is_ok() {
                    deleted_files += 1;
                }
            }
        }
    }

    // 清空数据库表
    let db = crate::core::storage::get_db()?;
    let count = db.execute("DELETE FROM image_cache", [])?;

    tracing::info!(
        "Cleaned all {} image cache records, {} files",
        count,
        deleted_files
    );
    Ok((count as u64, deleted_files))
}

/// 获取缓存大小（字节）
pub fn get_cache_size() -> Result<u64> {
    let cache_dir = get_image_cache_dir()?;
    let mut total_size = 0u64;

    if cache_dir.exists() {
        for entry in std::fs::read_dir(&cache_dir)? {
            let entry = entry?;
            let metadata = entry.metadata()?;
            if metadata.is_file() {
                total_size += metadata.len();
            }
        }
    }

    Ok(total_size)
}

/// 获取缓存图片数量
pub fn get_cache_count() -> Result<u64> {
    let db = crate::core::storage::get_db()?;
    let mut stmt = db.prepare_cached("SELECT COUNT(1) FROM image_cache")?;
    let count: i64 = stmt.query_row([], |row| row.get(0))?;
    Ok(count as u64)
}

/// 加载缓存图片（如果不存在则下载）
pub async fn load_cached_image(url: &str) -> Result<String> {
    let _lock = hash_lock(url).await;

    // 检查缓存
    if let Some(record) = get_cached_image(url)? {
        let cache_dir = get_image_cache_dir()?;
        let file_path = cache_dir.join(&record.local_path);

        // 检查文件是否存在
        if file_path.exists() {
            // 检查是否过期
            let now = chrono::Local::now().timestamp_millis();
            if now < record.cache_time + IMAGE_CACHE_EXPIRE_MS {
                // 更新访问时间（LRU）
                let _ = update_cache_time(url);
                return Ok(file_path.to_string_lossy().to_string());
            }
        }
        // 文件不存在或过期，删除记录
        delete_by_url(url)?;
    }

    // 下载图片
    tracing::debug!("Downloading image: {}", url);
    let response = crate::core::network::get_bytes(url).await?;

    // 确定文件扩展名
    let ext = guess_image_extension(&response).unwrap_or("jpg");
    let filename = format!("{}.{}", md5_hex(url), ext);

    // 保存到本地
    let cache_dir = get_image_cache_dir()?;
    let file_path = cache_dir.join(&filename);
    tokio::fs::write(&file_path, &response).await?;

    // 尝试获取图片尺寸
    let (width, height) = get_image_dimensions(&response);

    // 保存到数据库
    save_cached_image(url, &filename, width, height)?;

    Ok(file_path.to_string_lossy().to_string())
}

/// 猜测图片扩展名
fn guess_image_extension(data: &[u8]) -> Option<&'static str> {
    if data.len() < 4 {
        return None;
    }

    // JPEG: FF D8 FF
    if data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF {
        return Some("jpg");
    }
    // PNG: 89 50 4E 47
    if data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E && data[3] == 0x47 {
        return Some("png");
    }
    // GIF: 47 49 46 38
    if data[0] == 0x47 && data[1] == 0x49 && data[2] == 0x46 && data[3] == 0x38 {
        return Some("gif");
    }
    // WebP: 52 49 46 46 ... 57 45 42 50
    if data.len() >= 12
        && data[0] == 0x52
        && data[1] == 0x49
        && data[2] == 0x46
        && data[3] == 0x46
        && data[8] == 0x57
        && data[9] == 0x45
        && data[10] == 0x42
        && data[11] == 0x50
    {
        return Some("webp");
    }

    None
}

/// 获取图片尺寸（简单实现，仅支持部分格式）
fn get_image_dimensions(_data: &[u8]) -> (Option<u32>, Option<u32>) {
    // 这里简化处理，不解析图片尺寸
    // 如果需要可以使用 image crate
    (None, None)
}
