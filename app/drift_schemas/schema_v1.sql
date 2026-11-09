-- Historical schema fixture. This is the exact v1 layout before progress
-- documents were introduced in schema v2.
CREATE TABLE settings_entries (
  setting_key TEXT NOT NULL PRIMARY KEY,
  value_json TEXT NOT NULL,
  updated_at INTEGER NOT NULL
);
