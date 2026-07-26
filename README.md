# TepiLog

[![CI](https://github.com/Ihsan-p1/TepiLog/actions/workflows/ci.yml/badge.svg)](https://github.com/Ihsan-p1/TepiLog/actions/workflows/ci.yml)

A place-centric photo archive where every location tells its own story across time.
Document, explore, and compare how places change — shot by shot.

## Demo

> _Screenshots / GIF coming soon._ Drop images under `docs/` and reference them here, e.g.:
>
> | Map | Location timeline | Upload wizard |
> |---|---|---|
> | ![Map](docs/map.png) | ![Timeline](docs/timeline.png) | ![Upload](docs/upload.png) |

## Motivation

This project started from a personal frustration. As a photographer, I'd often research a location before heading out — scrolling through Google Maps reviews, Instagram geotags, whatever I could find. But the photos were always the best-case version of a place: perfect lighting, ideal conditions, carefully edited. I'd arrive and find something completely different. There was no way to know what a place actually looked like *recently*, from a photographer's perspective.

Most platforms are built around people — your feed is shaped by who you follow, not where you want to go. TepiLog flips that. Location is the primary entity. Every post belongs to a place, and every place accumulates a visual timeline contributed by anyone who's been there. The goal isn't to build an audience — it's to build an honest archive.

EXIF timestamps are central to this. When you upload a photo, TepiLog reads the `DateTimeOriginal` from the image metadata — the moment the shutter fired, not the moment you uploaded. That distinction matters. A photo taken two years ago tells a different story than one taken last week, and viewers deserve to know which one they're looking at.

## Features

### Authentication
- Register & login with email + password (bcrypt cost 12)
- Password policy: min 8 chars, must contain a letter and a number
- JWT access token + **revocable, rotating** refresh token (stored hashed in DB)
- Refresh-token reuse detection — a replayed token revokes the whole session
- `POST /api/auth/logout` (single device or all devices) actually invalidates tokens server-side
- Automatic silent refresh via Dio interceptor
- Brute-force protection: `helmet` security headers + per-IP rate limiting on auth endpoints

### Interactive Map (Home)
- Google Maps with custom dark styling
- Location markers with post count badges
- Bottom sheet preview on marker tap — location name, post count, recent thumbnails
- Tap to navigate to Location Detail

### Location Detail
- Chronological photo feed with EXIF timestamp overlays
- Sort toggle: recent / oldest
- Timeline slider to filter posts by year range
- Save/bookmark toggle

### Upload — 3-Step Wizard
1. **Photo** — Pick from gallery or camera, EXIF auto-detected
2. **Location** — Autocomplete search from 169 Indonesian seed locations + manual map pin
3. **Caption** — Optional caption, EXIF preview, publish

### Post Detail
- Full photo display with EXIF badge (`taken · 17 Mar 2025, 06:42 WIB`)
- Caption and location context
- Live comment section with real-time posting

### Trending Nearby
- Ranked locations within 50 km radius
- Sorted by upload activity in the last 7 days
- Shows distance and post count per location

### Profile
- Stats: posts · locations visited · saved
- Full photo grid of user's posts
- Logout

## Tech Stack

### Mobile (Flutter)
| Layer | Technology |
|---|---|
| Framework | Flutter |
| State Management | Riverpod |
| Maps | Google Maps Flutter Plugin |
| Image Handling | image_picker + flutter_image_compress |
| EXIF Extraction | exif |
| HTTP Client | Dio |
| Navigation | GoRouter |
| Local Cache | Hive |

### Backend (Node.js)
| Layer | Technology |
|---|---|
| Runtime | Node.js + Express |
| Database | PostgreSQL + PostGIS |
| ORM | Prisma |
| File Storage | Cloudinary |
| Auth | JWT (access + rotating refresh) + bcrypt |
| Security | helmet, express-rate-limit, CORS allowlist |
| Testing / CI | Jest + Supertest, GitHub Actions |

## API Reference

### Auth
```
POST   /api/auth/register                      # rate-limited
POST   /api/auth/login                         # rate-limited
POST   /api/auth/refresh                       # rotates refresh token, revokes old
POST   /api/auth/logout                        # revoke token(s) — body: { refreshToken } or { all: true }
```

### Locations
```
GET    /api/locations?lat=&lng=&radius=        # Nearby (PostGIS radius query)
GET    /api/locations/:id                      # Location detail
GET    /api/locations/search?q=                # Search by name
GET    /api/locations/trending?lat=&lng=       # Trending nearby
```

### Posts
```
GET    /api/posts?location_id=&cursor=&limit=  # Feed per location (cursor pagination)
POST   /api/posts                              # Upload post (multipart/form-data)
GET    /api/posts/:id                          # Post detail
DELETE /api/posts/:id                          # Delete own post
```

### Comments
```
GET    /api/comments/:postId                   # List comments
POST   /api/comments/:postId                   # Create comment
DELETE /api/comments/:id                       # Delete own comment
```

### Saved Locations
```
GET    /api/saved                              # User's saved locations
POST   /api/saved/:locationId                  # Toggle save/unsave
GET    /api/saved/:locationId/check            # Check saved status
```

### Profile
```
GET    /api/users/me                           # Profile + stats
GET    /api/users/me/posts                     # User's posts
```

## Project Structure

```
TepiLog/
├── mobile/
│   └── lib/
│       ├── main.dart
│       ├── app/
│       │   ├── router.dart       # GoRouter + StatefulShellRoute
│       │   ├── theme.dart        # Dark monochromatic theme
│       │   └── main_shell.dart   # Bottom nav (4 tabs)
│       ├── features/
│       │   ├── auth/
│       │   ├── map/              # HomeScreen, LocationDetail
│       │   ├── post/             # Upload wizard, PostDetail, TagOnMap
│       │   ├── trending/
│       │   └── profile/
│       └── shared/
│           ├── constants/        # API base URLs
│           └── providers/        # Dio, Auth providers
│
├── backend/
│   ├── src/
│   │   ├── index.js              # Server bootstrap (listen)
│   │   ├── app.js                # Express app wiring (testable, no listen)
│   │   ├── config/db.js          # Prisma client
│   │   ├── middleware/
│   │   │   ├── auth.js           # JWT verification
│   │   │   ├── rateLimiters.js   # Global + auth-specific rate limits
│   │   │   └── errorHandler.js
│   │   ├── controllers/
│   │   │   ├── auth.controller.js
│   │   │   ├── location.controller.js
│   │   │   ├── post.controller.js
│   │   │   ├── comment.controller.js
│   │   │   ├── saved.controller.js
│   │   │   └── profile.controller.js
│   │   ├── routes/
│   │   │   ├── auth.routes.js
│   │   │   ├── location.routes.js
│   │   │   ├── post.routes.js
│   │   │   ├── comment.routes.js
│   │   │   ├── saved.routes.js
│   │   │   └── profile.routes.js
│   │   ├── services/
│   │   │   ├── cloudinary.service.js
│   │   │   └── geo.service.js    # PostGIS query helpers + findOrCreateLocation
│   │   └── utils/
│   │       └── validators.js     # Email + password-strength validation
│   ├── prisma/
│   │   ├── schema.prisma
│   │   ├── migrations/          # incl. refresh_tokens table
│   │   └── seed.js               # 169 Indonesian seed locations
│   └── tests/                    # Jest + Supertest (auth flow, rate limiter)
│
├── .github/workflows/ci.yml      # CI: Postgres+PostGIS tests, flutter analyze
└── .env
```

## Setup

### Prerequisites
- Node.js 18+
- PostgreSQL 14+ with PostGIS extension enabled
- Flutter SDK 3.x
- Google Maps API Key
- Cloudinary account (free tier is sufficient)

### 1. Enable PostGIS

Connect to your PostgreSQL instance and run:
```sql
CREATE EXTENSION IF NOT EXISTS postgis;
```

### 2. Environment Variables

Create `.env` in the project root:
```env
DATABASE_URL=postgresql://user:password@localhost:5432/tepilog
JWT_SECRET=your_jwt_secret
JWT_REFRESH_SECRET=your_refresh_secret
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret
MAPS_API_KEY=your_google_maps_key

# Optional — comma-separated frontend origins allowed by CORS.
# Leave empty to allow all origins (development only).
CORS_ORIGIN=
```

### 3. Backend
```bash
cd backend
npm install
npx prisma migrate dev
node prisma/seed.js    # Seeds 169 Indonesian locations
npm run dev
```

### 4. Mobile
```bash
cd mobile
flutter pub get

# Android emulator (default host alias 10.0.2.2 — no flag needed)
flutter run

# Physical device / staging / production — point at a reachable HTTPS API
flutter run --dart-define=API_BASE_URL=https://api.tepilog.app/api
```

The API base URL is injected at build time via `--dart-define=API_BASE_URL=...`,
so no source edit is needed to switch between emulator, device, and production.

## Testing

The backend has an integration test suite (Jest + Supertest) covering the auth
flow end-to-end against a real Postgres + PostGIS database: password/email
validation, login, refresh-token **rotation**, **reuse detection**, and logout
(single + all devices), plus the rate limiter.

Tests run against a **separate** database — `TEST_DATABASE_URL` is required so the
dev database is never touched. The DB-backed suite is skipped if it isn't set.

```bash
cd backend

# One-time: create a dedicated test database and apply migrations
createdb tepilog_test    # or: CREATE DATABASE tepilog_test;
DATABASE_URL="postgresql://user:pass@localhost:5432/tepilog_test" npx prisma migrate deploy

# Run the suite
TEST_DATABASE_URL="postgresql://user:pass@localhost:5432/tepilog_test" npm test
```

CI (GitHub Actions, `.github/workflows/ci.yml`) spins up a `postgis/postgis`
service, applies migrations, and runs the suite on every push and PR — and also
runs `flutter analyze` on the mobile app.

## Key Technical Decisions

### EXIF timestamp over upload time
Every post displays the timestamp from the image's EXIF metadata (`DateTimeOriginal`), not the time of upload. This is intentional — a photo taken two years ago and uploaded today should be read as a historical record, not a current one. If EXIF data is unavailable, the post is labeled accordingly rather than silently falling back to upload time.

### Geospatial deduplication via PostGIS
When a user uploads a post and tags a location, the backend checks whether any existing location in the database falls within a 50-meter radius of the submitted coordinates. If a match is found, the post is attached to that location instead of creating a new one. This keeps the map clean and prevents the same physical place from accumulating multiple fragmented pins. The logic lives in `geo.service.js` as `findOrCreateLocation`.

### Place-centric data model
`Location` is the central entity — not `User`. Posts belong to locations. Trending is ranked by location activity. The map is the primary navigation surface. This is a deliberate architectural choice that constrains the feature set but keeps the core use case coherent: understanding a place over time, not building a following.

### Cursor-based pagination for post feeds
Location feeds use cursor pagination (`cursor` + `limit`) rather than offset pagination. For feeds sorted by `taken_at` where new posts can be inserted at any position in the timeline, offset pagination produces inconsistent results. Cursor pagination ensures stable, consistent traversal regardless of new inserts.

### Revocable refresh tokens with rotation
JWTs are stateless, which makes plain refresh tokens impossible to revoke before expiry — a real problem if one is stolen. TepiLog stores a **SHA-256 hash** of each refresh token in a `refresh_tokens` table keyed by the token's `jti`. On every `/refresh`, the presented token is rotated: the old row is marked revoked and a new pair is issued. If a token that has already been rotated is replayed (reuse), the backend treats it as a theft signal and revokes *all* of that user's sessions. `logout` invalidates tokens server-side — single device or every device. Only the hash is persisted, so a database leak alone can't reconstruct a usable token.

### Defense in depth on the API surface
`helmet` sets secure HTTP headers; `express-rate-limit` caps requests globally and applies a stricter per-IP budget to `/api/auth` to blunt brute-force attempts (successful logins aren't counted, so legitimate users aren't locked out). CORS origins are an env-driven allowlist, JSON bodies are size-capped, and `trust proxy` is set so limits work correctly behind a reverse proxy. Login compares a bcrypt hash even when the email doesn't exist, avoiding user-enumeration via timing.

### Build-time API configuration
The mobile `baseUrl` is read from `String.fromEnvironment('API_BASE_URL')` with the Android-emulator alias as a dev default. Switching between emulator, a physical device, staging, and production is a `--dart-define` flag at build time — no source edits, and production builds can be pinned to an HTTPS endpoint.

## Design

- **Theme:** Dark monochromatic — `#1C1C1E` base, Plus Jakarta Sans
- **Navigation:** Bottom nav bar (map · trending · upload · profile)
- **Upload:** 3-step wizard with step progress indicator
- **Location Detail:** Vertical card feed with EXIF overlays and timeline slider
- **Post Detail:** Scrollable layout with sticky comment input

