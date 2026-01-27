// 缓存工具函数

use anyhow::Result;
use once_cell::sync::Lazy;
use parking_lot::Mutex;
use std::collections::HashMap;
use std::sync::Arc;

/// 哈希锁，用于防止同一资源的并发请求
static HASH_LOCKS: Lazy<Mutex<HashMap<String, Arc<tokio::sync::Mutex<()>>>>> =
    Lazy::new(|| Mutex::new(HashMap::new()));

/// 获取指定 key 的锁
pub async fn hash_lock(key: &str) -> tokio::sync::OwnedMutexGuard<()> {
    let lock = {
        let mut locks = HASH_LOCKS.lock();
        locks
            .entry(key.to_string())
            .or_insert_with(|| Arc::new(tokio::sync::Mutex::new(())))
            .clone()
    };
    lock.lock_owned().await
}

/// 计算字符串的 MD5 哈希（返回十六进制字符串）
pub fn md5_hex(input: &str) -> String {
    use std::fmt::Write;
    let digest = md5::compute(input.as_bytes());
    let mut hex = String::with_capacity(32);
    for byte in digest.iter() {
        write!(hex, "{:02x}", byte).unwrap();
    }
    hex
}

/// VACUUM 数据库（压缩回收空间）
pub fn vacuum_database() -> Result<()> {
    crate::core::storage::vacuum()
}
