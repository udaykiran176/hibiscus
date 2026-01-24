-- Ensure downloads table contains the latest columns by rebuilding it.
-- This avoids relying on conditional ALTER TABLE (not supported in SQLite).

CREATE TABLE IF NOT EXISTS downloads_new (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  video_id TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  cover_url TEXT,
  video_url TEXT NOT NULL,
  quality TEXT,
  description TEXT,
  tags TEXT,
  cover_path TEXT,
  save_path TEXT,
  total_bytes INTEGER DEFAULT 0,
  downloaded_bytes INTEGER DEFAULT 0,
  status INTEGER DEFAULT 0,
  error_message TEXT,
  created_at INTEGER NOT NULL,
  completed_at INTEGER
);

INSERT OR IGNORE INTO downloads_new (
  id, video_id, title, cover_url, video_url, quality, save_path,
  total_bytes, downloaded_bytes, status, error_message, created_at, completed_at
)
SELECT
  id, video_id, title, cover_url, video_url, quality, save_path,
  total_bytes, downloaded_bytes, status, error_message, created_at, completed_at
FROM downloads;

DROP TABLE downloads;
ALTER TABLE downloads_new RENAME TO downloads;

CREATE INDEX IF NOT EXISTS idx_downloads_status ON downloads(status);

