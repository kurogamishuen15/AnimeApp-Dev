-- Historical schema fixture before catalog identities/library (v5).
CREATE TABLE settings_entries (
  setting_key TEXT NOT NULL PRIMARY KEY,
  value_json TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE progress_documents (
  document_key TEXT NOT NULL PRIMARY KEY,
  payload_json TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);

CREATE TABLE latest_anime_search (
  slot TEXT NOT NULL PRIMARY KEY,
  search_query TEXT NOT NULL,
  page INTEGER NOT NULL,
  per_page INTEGER NOT NULL,
  result_json TEXT NOT NULL,
  cached_at INTEGER NOT NULL
);

CREATE TABLE playback_progress_entries (
  content_id TEXT NOT NULL,
  episode_id TEXT NOT NULL,
  position_ms INTEGER NOT NULL,
  duration_ms INTEGER,
  updated_at_utc INTEGER NOT NULL,
  completion TEXT NOT NULL,
  revision INTEGER NOT NULL DEFAULT 0,
  PRIMARY KEY (content_id, episode_id)
);
