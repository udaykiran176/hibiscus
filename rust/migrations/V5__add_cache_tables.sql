-- Web 接口缓存表 (10分钟过期)
CREATE TABLE IF NOT EXISTS web_cache (
    cache_key TEXT PRIMARY KEY,
    cache_content TEXT NOT NULL,
    cache_time INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_web_cache_time ON web_cache(cache_time);

-- 图片缓存表 (3天过期)
CREATE TABLE IF NOT EXISTS image_cache (
    url TEXT PRIMARY KEY,
    local_path TEXT NOT NULL,
    cache_time INTEGER NOT NULL,
    image_width INTEGER,
    image_height INTEGER
);
CREATE INDEX IF NOT EXISTS idx_image_cache_time ON image_cache(cache_time);
