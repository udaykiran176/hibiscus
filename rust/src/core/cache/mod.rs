// 缓存模块
// 包含 Web 接口缓存和图片缓存

pub mod image_cache;
pub mod utils;
pub mod web_cache;

use anyhow::Result;

// 缓存过期时间常量
pub const WEB_CACHE_EXPIRE_MS: i64 = 10 * 60 * 1000; // 10分钟
pub const IMAGE_CACHE_EXPIRE_MS: i64 = 3 * 24 * 60 * 60 * 1000; // 3天
pub const IMAGE_CACHE_DIR: &str = "image_cache";

/// 获取图片缓存目录路径
pub fn get_image_cache_dir() -> Result<std::path::PathBuf> {
    let data_dir = crate::core::storage::get_data_dir()?;
    let cache_dir = data_dir.join(IMAGE_CACHE_DIR);
    if !cache_dir.exists() {
        std::fs::create_dir_all(&cache_dir)?;
    }
    Ok(cache_dir)
}
