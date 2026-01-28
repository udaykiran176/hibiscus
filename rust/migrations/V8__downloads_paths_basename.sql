-- Normalize downloads local path fields to basenames only.
-- Reason: iOS simulator container path changes across runs, so storing absolute paths breaks reopening.
--
-- This migration trims directory prefixes and keeps only the final file name segment.
-- It also normalizes Windows '\' separators into '/' before processing.

-- save_path -> basename
WITH RECURSIVE scan(video_id, p, pos) AS (
  SELECT
    video_id,
    rtrim(replace(save_path, '\\', '/'), '/') AS p,
    instr(rtrim(replace(save_path, '\\', '/'), '/'), '/') AS pos
  FROM downloads
  WHERE save_path IS NOT NULL
    AND instr(rtrim(replace(save_path, '\\', '/'), '/'), '/') > 0
  UNION ALL
  SELECT
    video_id,
    p,
    pos + instr(substr(p, pos + 1), '/')
  FROM scan
  WHERE instr(substr(p, pos + 1), '/') > 0
),
last_pos AS (
  SELECT video_id, max(pos) AS last_pos FROM scan GROUP BY video_id
)
UPDATE downloads
SET save_path = substr(
  rtrim(replace(save_path, '\\', '/'), '/'),
  (SELECT last_pos + 1 FROM last_pos WHERE last_pos.video_id = downloads.video_id)
)
WHERE save_path IS NOT NULL
  AND instr(rtrim(replace(save_path, '\\', '/'), '/'), '/') > 0;

-- cover_path -> basename
WITH RECURSIVE scan(video_id, p, pos) AS (
  SELECT
    video_id,
    rtrim(replace(cover_path, '\\', '/'), '/') AS p,
    instr(rtrim(replace(cover_path, '\\', '/'), '/'), '/') AS pos
  FROM downloads
  WHERE cover_path IS NOT NULL
    AND instr(rtrim(replace(cover_path, '\\', '/'), '/'), '/') > 0
  UNION ALL
  SELECT
    video_id,
    p,
    pos + instr(substr(p, pos + 1), '/')
  FROM scan
  WHERE instr(substr(p, pos + 1), '/') > 0
),
last_pos AS (
  SELECT video_id, max(pos) AS last_pos FROM scan GROUP BY video_id
)
UPDATE downloads
SET cover_path = substr(
  rtrim(replace(cover_path, '\\', '/'), '/'),
  (SELECT last_pos + 1 FROM last_pos WHERE last_pos.video_id = downloads.video_id)
)
WHERE cover_path IS NOT NULL
  AND instr(rtrim(replace(cover_path, '\\', '/'), '/'), '/') > 0;

-- author_avatar_path -> basename
WITH RECURSIVE scan(video_id, p, pos) AS (
  SELECT
    video_id,
    rtrim(replace(author_avatar_path, '\\', '/'), '/') AS p,
    instr(rtrim(replace(author_avatar_path, '\\', '/'), '/'), '/') AS pos
  FROM downloads
  WHERE author_avatar_path IS NOT NULL
    AND instr(rtrim(replace(author_avatar_path, '\\', '/'), '/'), '/') > 0
  UNION ALL
  SELECT
    video_id,
    p,
    pos + instr(substr(p, pos + 1), '/')
  FROM scan
  WHERE instr(substr(p, pos + 1), '/') > 0
),
last_pos AS (
  SELECT video_id, max(pos) AS last_pos FROM scan GROUP BY video_id
)
UPDATE downloads
SET author_avatar_path = substr(
  rtrim(replace(author_avatar_path, '\\', '/'), '/'),
  (SELECT last_pos + 1 FROM last_pos WHERE last_pos.video_id = downloads.video_id)
)
WHERE author_avatar_path IS NOT NULL
  AND instr(rtrim(replace(author_avatar_path, '\\', '/'), '/'), '/') > 0;

