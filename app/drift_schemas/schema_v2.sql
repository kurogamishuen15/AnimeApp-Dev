-- Historical schema fixture before the bounded AniList search cache (v3).
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
