-- Baseline schema (idempotent)

CREATE TABLE IF NOT EXISTS history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  video_id TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL,
  cover_url TEXT,
  duration TEXT,
  watch_progress INTEGER DEFAULT 0,
  total_duration INTEGER DEFAULT 0,
  watched_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_history_watched_at ON history(watched_at DESC);
CREATE INDEX IF NOT EXISTS idx_history_video_id ON history(video_id);

CREATE TABLE IF NOT EXISTS downloads (
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

CREATE INDEX IF NOT EXISTS idx_downloads_status ON downloads(status);

CREATE TABLE IF NOT EXISTS settings (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS cookies (
  domain TEXT NOT NULL,
  name TEXT NOT NULL,
  value TEXT NOT NULL,
  path TEXT DEFAULT '/',
  expires INTEGER,
  PRIMARY KEY (domain, name, path)
);

