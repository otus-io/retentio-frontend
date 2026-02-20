# Media Upload

A per-user media storage system for WordUpX that allows users to attach audio and images to vocabulary facts. Media is a standalone resource with its own identity -- facts reference media by ID using inline markers. This decouples the media lifecycle from the fact lifecycle, enabling reuse across facts/decks and efficient sync between the phone and server.

## Table of Contents

- [Current Architecture: How Facts Reference Content](#current-architecture-how-facts-reference-content)
- [Design Principles](#design-principles)
- [Data Model](#data-model)
- [Storage Layer: Interface Pattern](#storage-layer-interface-pattern)
- [API Endpoints](#api-endpoints)
- [Sync Strategy](#sync-strategy)
- [Shared Media Pool](#shared-media-pool)
- [Validation and Limits](#validation-and-limits)
- [File Organization](#file-organization)
- [End-to-End Example](#end-to-end-example)
- [Tests](#tests)
- [Storage Cost Summary](#storage-cost-summary)
- [Implementation Phases](#implementation-phases)
- [What This Design Does NOT Include](#what-this-design-does-not-include)

---

## Current Architecture: How Facts Reference Content

Before designing media, this section documents how facts work today and where media fits in.

### Facts today

A Fact is a vocabulary entry stored as a struct with an ID and string fields:

```go
type Fact struct {
    ID     string   `json:"id"`     // nanoid
    Fields []string `json:"fields"` // e.g. ["Apple", "苹果"]
}
```

Fields are plain strings rendered as text on flashcards. There is no mechanism to attach rich content (audio pronunciation, word images) to a fact.

### The Anki precedent

The Anki-to-WordUpX converter (`utils/anki-convert/`) already handles media references. It converts HTML `<img>` tags to inline markers:

```
<img src="apple.jpg"> → [image:apple.jpg]
```

This marker pattern is the foundation for how WordUpX will reference media in fact fields.

---

## Design Principles

1. **Media as a first-class resource** -- each media item has a unique ID, belongs to a user, and exists independently of any fact or deck.
2. **Reference by ID, not URL** -- facts contain markers like `[audio:a1b2c3d4e5]`, not URLs. URLs change (server migration, CDN switch); IDs don't.
3. **Storage-agnostic** -- binary storage is behind an interface. Start with local filesystem, swap to S3 later without changing any handler or API.
4. **Sync-friendly** -- metadata syncs fast (small JSON), binaries sync lazily (large files downloaded on demand). Checksums prevent redundant transfers.

---

## Data Model

### Media struct

```go
// media/media.go
type Media struct {
    ID        string `json:"id"`         // nanoid, 10 chars
    Owner     string `json:"owner"`      // username
    Filename  string `json:"filename"`   // original filename, e.g. "apple.mp3"
    Mime      string `json:"mime"`       // MIME type, e.g. "audio/mpeg"
    Size      int64  `json:"size"`       // file size in bytes
    Checksum  string `json:"checksum"`   // "sha256:{hex}", for sync dedup
    CreatedAt int64  `json:"created_at"` // unix timestamp
}
```

### Redis storage

| Key | Type | Content |
|-----|------|---------|
| `media:{id}` | String (JSON) | Media metadata (id, owner, filename, mime, size, checksum, created_at) |
| `user:{username}:media` | Sorted Set | Media IDs scored by `created_at` (enables efficient `?since=` filtering via `ZRANGEBYSCORE`) |

### Binary file storage

Files are stored on the filesystem at:

```
{DATA_DIR}/media/{owner}/{id}{ext}
```

Where `DATA_DIR` defaults to `/data/wordupx` (configurable via `MEDIA_DATA_DIR` env var), and `ext` is derived from the MIME type (e.g. `.mp3`, `.jpg`).

Example: `/data/wordupx/media/alice/a1b2c3d4e5.mp3`

### Media references in facts

Fact fields use inline markers to reference media by ID:

```json
{
  "id": "x9y8z7w6v5",
  "fields": ["Apple", "苹果", "[audio:a1b2c3d4e5]", "[image:f6g7h8i9j0]"]
}
```

The frontend parses these markers and resolves them:

- **Online**: fetch from `GET /api/media/{id}`
- **Offline (local-first)**: load from the phone's local media cache

Multiple media markers can appear in a single field, and text can surround them:

```
"The word is: Apple [audio:a1b2c3d4e5] [image:f6g7h8i9j0]"
```

### Marker format

```
[type:mediaId]
```

Where `type` is one of: `audio`, `image`. The frontend uses the type hint to choose the appropriate renderer (audio player, image view) without needing to fetch metadata first. Video is intentionally excluded -- it adds significant complexity (large files, streaming) for minimal value on a flashcard.

---

## Storage Layer: Interface Pattern

Binary storage is abstracted behind a Go interface so the implementation can change without affecting handlers or API contracts.

```go
// media/storage.go
type Storage interface {
    Put(ctx context.Context, key string, r io.Reader) error
    Get(ctx context.Context, key string) (io.ReadCloser, error)
    Delete(ctx context.Context, key string) error
    Exists(ctx context.Context, key string) (bool, error)
}
```

The `key` is the full relative path: `{owner}/{id}{ext}`.

### Phase 1: Local filesystem

```go
// media/local_storage.go
type LocalStorage struct {
    BaseDir string // e.g. "/data/wordupx/media"
}
```

- `Put`: creates parent directories, writes file atomically (write to temp file, then rename)
- `Get`: opens file, returns `io.ReadCloser`
- `Delete`: removes the file
- `Exists`: checks file existence via `os.Stat`

This matches the current single-server deployment. The Go server serves files directly through the download handler.

### Phase 2 (future): S3-compatible storage

- Swap `LocalStorage` for `S3Storage` by changing the initialization in `main.go`
- No handler or API changes needed
- Can use presigned URLs for direct client uploads/downloads to reduce server load

---

## API Endpoints

All under `/api/media`, JWT-protected via `JwtAuthMiddleware`:

| Method | Path | Description |
|--------|------|-------------|
| `POST` | `/api/media` | Upload a file |
| `GET` | `/api/media` | List user's media metadata (sync manifest) |
| `GET` | `/api/media/{id}` | Download the binary file |
| `GET` | `/api/media/{id}/meta` | Get metadata only |
| `DELETE` | `/api/media/{id}` | Delete media and binary file |

### Upload: `POST /api/media`

**Request**: `multipart/form-data`

| Field | Required | Description |
|-------|----------|-------------|
| `file` | Yes | The binary file |
| `client_id` | No | Client-generated nanoid; if provided, used as the media ID (for idempotent sync uploads) |

**Handler logic**:

1. Parse multipart form with size limit (`http.MaxBytesReader`)
2. Validate MIME type by reading the file header (`http.DetectContentType`), not trusting the `Content-Type` header
3. If `client_id` is provided, use `SETNX` on a short-lived lock key `media:lock:{client_id}` to guard against concurrent duplicate uploads. If `media:{client_id}` already exists in Redis, return the existing metadata (idempotent)
4. Generate nanoid (or use `client_id`)
5. Stream the file to storage via `Storage.Put`, using `io.TeeReader` to compute the SHA-256 checksum during the write -- the file is never fully buffered in memory
6. Save metadata to Redis: `SET media:{id}` and `ZADD user:{username}:media {created_at} {id}`
7. If the Redis write in step 6 fails after the file was written in step 5, the orphaned file will be cleaned up by a periodic sweep job (see "Orphan cleanup" below)
8. Respond with `201 Created` and media metadata

**Orphan cleanup**: a background goroutine (or cron job) periodically scans the media directory for files whose IDs have no corresponding `media:{id}` key in Redis, and deletes them. This handles crash recovery between steps 5 and 6.

**Rate limiting**: uploads are rate-limited per user (e.g. 30 uploads/minute) to prevent abuse. Enforced via a Redis sliding-window counter keyed by `ratelimit:upload:{username}`.

**Response**:

```json
{
  "data": {
    "id": "a1b2c3d4e5",
    "owner": "alice",
    "filename": "apple.mp3",
    "mime": "audio/mpeg",
    "size": 48210,
    "checksum": "sha256:9f86d081...",
    "created_at": 1708100000
  },
  "meta": {"msg": "media uploaded"}
}
```

### List (sync manifest): `GET /api/media`

**Query parameters**:

| Param | Required | Description |
|-------|----------|-------------|
| `since` | No | Unix timestamp; only return media created after this time (exclusive) |
| `limit` | No | Max items to return (default 200, max 1000) |
| `offset` | No | Number of items to skip (default 0) |

**Handler logic**:

1. Use `ZRANGEBYSCORE user:{username}:media {since} +inf LIMIT {offset} {limit}` to retrieve matching media IDs directly from Redis. If `since` is not provided, use `-inf` as the lower bound to return all. This avoids loading all IDs and filtering in Go -- Redis does the filtering using its skip-list index in O(log n + k) where k is the result count.
2. Build a key slice from the returned IDs and `MGET media:{id1} media:{id2} ...` to load all metadata in a single Redis round-trip (same pattern as `LoadFacts`).
3. Return metadata array (no binary data)

**Response**:

```json
{
  "data": [
    {"id": "a1b2c3d4e5", "mime": "audio/mpeg", "size": 48210, "checksum": "sha256:9f86d...", "created_at": 1708100000},
    {"id": "f6g7h8i9j0", "mime": "image/jpeg", "size": 102400, "checksum": "sha256:3c7a1...", "created_at": 1708100500}
  ],
  "meta": {"count": 2, "has_more": false}
}
```

### Download: `GET /api/media/{id}`

**Handler logic**:

1. Load metadata from `media:{id}`
2. Verify the requesting user is the owner. For Phase 1, only the owner can download their own media. When deck sharing is implemented, access will be extended to users who have access to a deck that references the media -- this will require a reverse index from media ID to deck IDs (deferred).
3. Set response headers: `Content-Type`, `Content-Length`, `Content-Disposition: inline`, `ETag` (checksum), `Cache-Control: public, max-age=31536000, immutable` (media is immutable -- aggressive caching is safe)
4. Check `If-None-Match` header; if it matches the checksum, respond `304 Not Modified`
5. Stream the file from `Storage.Get` to the response writer

### Metadata: `GET /api/media/{id}/meta`

Same as download but returns only the JSON metadata, no binary. Useful for the frontend to check if media exists before downloading. Sets the same `Cache-Control: public, max-age=31536000, immutable` header since metadata is also immutable.

### Delete: `DELETE /api/media/{id}`

**Handler logic**:

1. Load metadata from `media:{id}`
2. Verify the requesting user is the owner
3. Delete binary file via `Storage.Delete`
4. `DEL media:{id}`
5. `ZREM user:{username}:media {id}`
6. Respond with `200 OK`

Note: deletion does not scan facts for dangling `[audio:id]` markers. The frontend handles missing media gracefully (shows a "media not found" placeholder). A future cleanup job could scan for orphaned markers.

---

## Sync Strategy

This is designed to work with the upcoming local-first architecture where decks live on the phone and sync with the server on demand.

### Sync flow

```
1. Phone → Server:  GET /api/media?since={lastSyncTimestamp}
   Server → Phone:  Media manifest (array of {id, checksum, size, mime, created_at})

2. Phone compares manifest with local media database:
   - Media on server but not on phone → download list
   - Media on phone but not on server → upload list

3. For each item in the download list:
   Phone → Server:  GET /api/media/{id}
   Server → Phone:  Binary file (with ETag)

4. For each item in the upload list:
   Phone → Server:  POST /api/media (with client_id = local media ID)
   Server → Phone:  Media metadata (confirms upload)

5. Phone updates lastSyncTimestamp
```

### Key properties

- **Metadata-first**: the manifest is small (a few KB even for hundreds of items); binary downloads happen lazily
- **Idempotent uploads**: the `client_id` field means retrying a failed upload doesn't create duplicates. If two devices upload the same file with different `client_id`s, both uploads succeed and create separate media entries -- the checksum is stored for sync comparison, not for server-side dedup
- **Incremental**: `?since=` is backed by a Redis sorted set, so only IDs created after the given timestamp are fetched -- O(log n + k) where k is the number of new items, not O(n) over all items
- **ETag/304**: phone skips re-downloading files it already has

### Conflict resolution

Media is immutable once uploaded -- there is no "update" endpoint. If a user wants a different audio clip for a word, they upload a new file and update the fact's marker to point to the new ID. This means there are no edit conflicts for media, only for the fact fields that reference them.

---

## Shared Media Pool

Pronunciation audio and common word images are highly duplicated across users -- every learner studying "apple" needs the same audio clip. A shared media pool stores these files once, centrally, so users reference them instead of each uploading their own copy.

### Two tiers of media

| Tier | Owner | Referenced by | Example marker |
|------|-------|---------------|----------------|
| User media (existing) | Individual user | nanoid | `[audio:a1b2c3d4e5]` |
| Shared media (new) | Admin-curated | nanoid + word lookup | `[audio:shared:b2c3d4e5f6]` |

User media is unchanged -- private, per-user, referenced by nanoid. Shared media is read-only for regular users, uploaded by admins, and stored once regardless of how many users reference it.

### Why nanoid, not the word itself

Using the word as the primary key (e.g., `apple/en/us`) causes problems:

- **Homographs**: "read" (present, /riːd/) vs "read" (past, /rɛd/) have the same spelling but different pronunciations -- the key can't distinguish them without increasingly ad-hoc suffixes
- **Unicode in URLs and file paths**: words like `苹果`, `café`, `naïve` need URL encoding and create filesystem complications
- **Normalization**: is `Apple` the same as `apple`? Is `café` the same as `cafe`? Every client must apply identical normalization rules
- **Multi-word phrases**: "good morning", "kick the bucket" -- slashes and spaces in keys are messy for URLs and file paths

Instead, shared media uses nanoid as the primary key (same as user media) with a **word-based lookup index** on top. The word is how humans *find* shared media; the nanoid is how the system *stores and references* it.

### Marker format

The existing marker syntax is extended with a `shared:` prefix, but the reference is still a nanoid:

```
[type:shared:nanoid]
```

Examples in a fact field:

```json
{"fields": ["Apple [audio:shared:b2c3d4e5f6]", "苹果 [image:shared:c3d4e5f6g7]"]}
```

The frontend parses the `shared:` prefix and resolves via the shared media endpoint. User markers (`[audio:a1b2c3d4e5]`) continue to work as before. Both marker types use nanoid references, keeping parsing uniform.

### Data model

```go
type SharedMedia struct {
    ID        string `json:"id"`         // nanoid, 10 chars
    Word      string `json:"word"`       // e.g. "apple"
    Lang      string `json:"lang"`       // e.g. "en"
    Variant   string `json:"variant"`    // e.g. "us", "uk", "default"
    Mime      string `json:"mime"`       // "audio/mpeg"
    Size      int64  `json:"size"`       // file size in bytes
    Checksum  string `json:"checksum"`   // "sha256:{hex}"
    CreatedAt int64  `json:"created_at"` // unix timestamp
}
```

### Redis storage

| Key | Type | Content |
|-----|------|---------|
| `shared_media:{id}` | String (JSON) | SharedMedia metadata |
| `shared_media:index` | Set | Set of all shared media nanoids |
| `shared_media:lookup:{word}:{lang}:{variant}` | String | nanoid (lookup index) |

The lookup key enables finding shared media by word: given "apple", "en", "us", Redis returns the nanoid. The nanoid is then used for all storage and API operations. The `word` component is lowercased and must not contain colons (validated on upload) to avoid breaking the key structure.

### Binary file storage

Shared media files are stored alongside user media but in a dedicated `shared/` directory, keyed by nanoid:

```
{DATA_DIR}/media/shared/{id}{ext}
```

Example: `/data/wordupx/media/shared/b2c3d4e5f6.mp3`

### API endpoints

Upload and deletion are admin-only. Download and lookup are available to any authenticated user.

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| `POST` | `/api/admin/media/shared` | Admin JWT | Upload shared media (with word, lang, variant metadata) |
| `GET` | `/api/media/shared/{id}` | Any JWT | Download shared media file by nanoid |
| `GET` | `/api/media/shared?word=apple&lang=en&variant=us` | Any JWT | Look up shared media by word (returns metadata with nanoid) |
| `DELETE` | `/api/admin/media/shared/{id}` | Admin JWT | Delete shared media |

The lookup endpoint lets the frontend (or an admin tool) discover shared media by word. Once the nanoid is known, it goes into the fact marker and all subsequent access is by nanoid -- no word-based lookups on the hot path.

### What this does NOT include (deferred)

- **Crowdsourced contributions** -- users cannot promote their own uploads to the shared pool (future consideration)
- **Automatic TTS generation** -- no pipeline to auto-generate pronunciations; admins upload manually or via a script
- **Shared media versioning** -- immutable once uploaded, same as user media; upload a new file and update the lookup index for a new version

---

## Validation and Limits

### Allowed MIME types

| Category | MIME Types |
|----------|-----------|
| Image | `image/jpeg`, `image/png`, `image/gif`, `image/webp` |
| Audio | `audio/mpeg`, `audio/wav`, `audio/ogg`, `audio/mp4` |

MIME type is validated by reading the first 512 bytes of the file with `http.DetectContentType`, not by trusting the client-provided `Content-Type` header or file extension.

### Size limits

- **Max file size**: 5 MB (configurable via `MEDIA_MAX_SIZE` env var)
- **Enforced at the HTTP layer** using `http.MaxBytesReader` to avoid buffering oversized files

### Per-user quota (future)

- Consider a total storage quota per user (e.g. 500 MB) enforced on upload
- Track total usage by summing `size` across all `user:{username}:media` items

---

## File Organization

```
backend-api/media/
├── media.go           # Handlers: Upload, List, Download, GetMeta, Delete
├── storage.go         # Storage interface definition
├── local_storage.go   # LocalStorage implementation
└── validation.go      # MIME validation, size checks, checksum computation

backend-api/tests/
├── unit/
│   └── media_test.go        # Validation, checksum, marker parsing
└── integration/
    └── media_test.go        # Upload/download/list/delete handler tests
```

### Routes

```go
// Media endpoints
apiRouter.HandleFunc("/media", media.Upload).Methods("POST", "OPTIONS")
apiRouter.HandleFunc("/media", media.List).Methods("GET", "OPTIONS")
apiRouter.HandleFunc("/media/{id}", media.Download).Methods("GET", "OPTIONS")
apiRouter.HandleFunc("/media/{id}/meta", media.GetMeta).Methods("GET", "OPTIONS")
apiRouter.HandleFunc("/media/{id}", media.Delete).Methods("DELETE", "OPTIONS")
```

---

## End-to-End Example

This walkthrough shows how a user attaches an audio pronunciation to a vocabulary fact, and how the frontend resolves it -- both online and in local-first mode.

### Step 1: Upload media

The user records or selects an audio file and the frontend uploads it:

```
POST /api/media
Content-Type: multipart/form-data
Authorization: Bearer <token>

file: apple-pronunciation.mp3
```

Server stores the binary, computes the checksum, and responds with metadata:

```json
{
  "data": {
    "id": "a1b2c3d4e5",
    "owner": "alice",
    "filename": "apple-pronunciation.mp3",
    "mime": "audio/mpeg",
    "size": 48210,
    "checksum": "sha256:9f86d081...",
    "created_at": 1708100000
  },
  "meta": {"msg": "media uploaded"}
}
```

At this point the media exists independently -- it is not yet linked to any fact.

### Step 2: Update the fact to reference the media

The user edits a fact to attach the audio. The frontend sends an update using the existing `UpdateFact` endpoint:

```
PATCH /api/decks/deck123/facts/abc12345
Authorization: Bearer <token>

["Apple", "苹果", "[audio:a1b2c3d4e5]"]
```

The backend treats `[audio:a1b2c3d4e5]` as an opaque string -- no parsing, no validation of the marker. The fact is now stored in Redis as:

```json
{"id": "abc12345", "fields": ["Apple", "苹果", "[audio:a1b2c3d4e5]"]}
```

Markers can also be mixed into existing fields alongside text:

```json
{"id": "abc12345", "fields": ["Apple [audio:a1b2c3d4e5]", "苹果 [image:f6g7h8i9j0]"]}
```

### Step 3: Frontend retrieves the fact and resolves markers

When the frontend fetches the urgent card or fact list, the response includes the raw fact fields:

```json
{
  "data": {
    "card": {"fact_id": "abc12345", "template_index": 0, ...},
    "card_index": 3,
    "urgency": 1.2
  },
  "meta": {"msg": "Next urgent card retrieved successfully"}
}
```

The fact fields come back as `["Apple", "苹果", "[audio:a1b2c3d4e5]"]`. The frontend then:

1. Parses each field with a regex: `\[(audio|image):(shared:)?([a-z0-9]+)\]` (handles both user markers like `[audio:abc123]` and shared markers like `[audio:shared:abc123]`)
2. For each match, checks if the file is in local cache
3. If not cached, fetches the binary: `GET /api/media/a1b2c3d4e5`
4. Renders the appropriate widget -- audio player or image view

### Step 4: Local-first flow (future)

When decks are stored on the phone, the flow changes:

1. Facts live in the local database (SQLite/Hive), markers included
2. Media binaries are in a local `media/` folder, keyed by ID (e.g. `media/a1b2c3d4e5.mp3`)
3. The frontend resolves `[audio:a1b2c3d4e5]` to a local file path -- no network request, instant playback
4. During sync, any media IDs found in facts that are not cached locally get queued for download from the server

### Why the backend does not parse markers

The media API and the fact API are fully decoupled:

- **Media API** handles upload, download, list, and delete of binary files
- **Fact API** handles CRUD of text fields (which happen to contain marker strings)
- **Frontend** is the glue -- it writes markers into fact fields and resolves them to media URLs or local files

This means no existing backend handler (`AddFact`, `UpdateFact`, `GetFacts`, `GetUrgentCard`) needs to change. They already pass fact fields through as opaque strings. The only new backend code is the `media/` package for storing and serving binaries.

---

## Tests

### Unit tests

- MIME type validation: accept allowed types, reject disallowed types (e.g. `application/pdf`, `text/html`)
- Size validation: accept files under limit, reject files over limit
- Checksum computation: verify SHA-256 output matches expected value for known input
- Marker parsing: extract `[audio:id]`, `[image:id]` from fact field strings
- Marker with surrounding text: `"word [audio:abc] definition"` parses correctly
- Multiple markers in one field: `"[image:abc] [audio:def]"` extracts both
- Idempotent upload: when `client_id` matches existing media, return existing metadata without writing a new file

### Integration tests

- `TestUploadMedia`: upload a file, verify metadata in Redis and file on disk
- `TestUploadMediaIdempotent`: upload with same `client_id` twice, verify single file stored
- `TestUploadMediaTooLarge`: upload a file exceeding the size limit, expect `413 Request Entity Too Large`
- `TestUploadMediaBadMimeType`: upload a disallowed file type, expect `415 Unsupported Media Type`
- `TestListMedia`: upload multiple files, list all, verify count and metadata
- `TestListMediaSince`: upload files at different times, filter with `since`, verify only newer items returned
- `TestDownloadMedia`: upload a file, download it, verify binary content matches
- `TestDownloadMediaETag`: download with matching `If-None-Match`, expect `304 Not Modified`
- `TestDownloadMediaNotOwner`: user A uploads, user B attempts download, expect `403 Forbidden`
- `TestGetMeta`: upload a file, get metadata only, verify JSON response with no binary
- `TestDeleteMedia`: upload and delete, verify Redis keys and file removed
- `TestDeleteMediaNotOwner`: user A uploads, user B attempts delete, expect `403 Forbidden`

---

## Storage Cost Summary

Projected ceiling: **100 TB** (200K users at the 500 MB cap, or 2M users at ~50 MB avg with shared pool). Per-user cost: ~2 cents/month on S3, ~0.5 cents on Hetzner. Storage provider decisions are deferred -- the `Storage` interface (see "Storage Layer" above) makes this swappable without changing any handler or API.

| Scale | Storage | Est. cost/month |
|-------|---------|----------------|
| 0-10K users | Local filesystem on server disk | ~$0 (included with server) |
| 10K-100K users | Hetzner Storage Box / Volumes (~$3.50-$4.40/TB) | ~$35-$175 |
| 100K+ users | S3 + CloudFront (if ops burden justifies it, ~$23/TB) | ~$500-$2,280 |

---

## Implementation Phases

### Phase 1: Core user media (current)

The foundation everything else builds on:

- `Storage` interface + `LocalStorage` implementation
- User media handlers: Upload, Download, List, GetMeta, Delete
- MIME validation, size limits, SHA-256 checksums
- Routes under `/api/media`

### Phase 2: Shared media pool

Admin-curated centralized media for common pronunciations and images:

- `SharedMedia` struct with nanoid + word-based lookup index
- Admin upload/delete endpoints (separate admin route with its own auth)
- User download and word lookup endpoints
- `[audio:shared:nanoid]` marker format

### Phase 3: Export/import

Data portability and backup without third-party cloud sync complexity:

- `GET /api/media/export` -- ZIP archive of all user media with manifest JSON
- `POST /api/media/import` -- accepts ZIP, uploads media, returns old-to-new ID mapping

---

## What This Design Does NOT Include

These are explicitly deferred:

- **Video support** -- large files, streaming, range requests add significant complexity for minimal flashcard value
- **Media transcoding** -- store as-is; no format conversion or image compression
- **CDN or reverse proxy** -- serve files through Go directly; add nginx or CDN when scale demands it
- **Thumbnail generation** -- can be added as a background job later
- **Media search** -- users find media through the facts that reference it
- **Third-party cloud sync** (Google Drive, Dropbox) -- OAuth, token management, and conflict resolution is months of work per provider; export/import (Phase 3) covers the real user need
