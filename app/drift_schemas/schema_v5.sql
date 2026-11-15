-- Historical schema fixture before the provisional library status (v6).
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

CREATE TABLE anime_identity_entries (
  anime_id TEXT NOT NULL,
  created_at_utc INTEGER NOT NULL,
  PRIMARY KEY (anime_id),
  CHECK (length(trim(anime_id)) > 0)
);

CREATE TABLE anime_identity_relationships (
  source_anime_id TEXT NOT NULL REFERENCES anime_identity_entries (anime_id) ON DELETE CASCADE,
  target_anime_id TEXT NOT NULL REFERENCES anime_identity_entries (anime_id) ON DELETE CASCADE,
  relationship_kind TEXT NOT NULL,
  evidence TEXT NOT NULL,
  linked_at_utc INTEGER NOT NULL,
  PRIMARY KEY (source_anime_id, target_anime_id, relationship_kind),
  CHECK (source_anime_id <> target_anime_id),
  CHECK (relationship_kind IN ('season', 'sequel', 'prequel', 'movie', 'special', 'ova', 'alternateVersion')),
  CHECK (evidence IN ('trustedProviderCrossReference', 'verifiedOfficialReference', 'userConfirmed'))
);

CREATE TABLE external_anime_identifiers (
  provider_id TEXT NOT NULL,
  external_id TEXT NOT NULL,
  anime_id TEXT NOT NULL REFERENCES anime_identity_entries (anime_id) ON DELETE CASCADE,
  evidence TEXT NOT NULL,
  linked_at_utc INTEGER NOT NULL,
  PRIMARY KEY (provider_id, external_id),
  CHECK (length(trim(provider_id)) > 0),
  CHECK (length(trim(external_id)) > 0),
  CHECK (evidence IN ('trustedProviderCrossReference', 'verifiedOfficialReference', 'userConfirmed'))
);

CREATE TABLE library_entries (
  anime_id TEXT NOT NULL REFERENCES anime_identity_entries (anime_id) ON DELETE CASCADE,
  added_at_utc INTEGER NOT NULL,
  PRIMARY KEY (anime_id),
  CHECK (length(trim(anime_id)) > 0)
);

CREATE INDEX external_anime_identifiers_by_anime ON external_anime_identifiers (anime_id);
CREATE INDEX library_entries_by_added_at ON library_entries (added_at_utc);
