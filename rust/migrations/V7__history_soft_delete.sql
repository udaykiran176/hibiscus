-- History soft delete support
-- deleted_at: NULL or deleted_at < watched_at means not deleted

ALTER TABLE history ADD COLUMN deleted_at INTEGER DEFAULT NULL;

CREATE INDEX IF NOT EXISTS idx_history_deleted_at ON history(deleted_at);
