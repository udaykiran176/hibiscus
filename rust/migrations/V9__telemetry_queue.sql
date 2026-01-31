-- Telemetry queue for OTLP protobuf payloads (base64-encoded)

CREATE TABLE IF NOT EXISTS telemetry_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  payload_base64 TEXT NOT NULL,
  retry_count INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_telemetry_queue_created_at
  ON telemetry_queue(created_at);

CREATE INDEX IF NOT EXISTS idx_telemetry_queue_retry_count
  ON telemetry_queue(retry_count);

