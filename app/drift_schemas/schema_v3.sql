-- Historical schema fixture before typed playback checkpoints (v4).
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
