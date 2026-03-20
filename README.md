# TepiLog

A place-centric photo archive where every location tells its own story across time.
Document, explore, and compare how places change — shot by shot.

## Motivation

This project started from a personal frustration. As a photographer, I'd often research a location before heading out — scrolling through Google Maps reviews, Instagram geotags, whatever I could find. But the photos were always the best-case version of a place: perfect lighting, ideal conditions, carefully edited. I'd arrive and find something completely different. There was no way to know what a place actually looked like *recently*, from a photographer's perspective.

Most platforms are built around people — your feed is shaped by who you follow, not where you want to go. TepiLog flips that. Location is the primary entity. Every post belongs to a place, and every place accumulates a visual timeline contributed by anyone who's been there. The goal isn't to build an audience — it's to build an honest archive.

EXIF timestamps are central to this. When you upload a photo, TepiLog reads the `DateTimeOriginal` from the image metadata — the moment the shutter fired, not the moment you uploaded. That distinction matters. A photo taken two years ago tells a different story than one taken last week, and viewers deserve to know which one they're looking at.

## Features

### Authentication
- Register & login with email + password
- JWT-based session with automatic refresh via Dio interceptor

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
| Auth | JWT + bcrypt |

## API Reference

### Auth
```
POST   /api/auth/register
POST   /api/auth/login
POST   /api/auth/refresh
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
│   │   ├── index.js
│   │   ├── config/db.js          # Prisma client
│   │   ├── middleware/
│   │   │   ├── auth.js           # JWT verification
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
│   │   └── services/
│   │       ├── cloudinary.service.js
│   │       └── geo.service.js    # PostGIS query helpers + findOrCreateLocation
│   └── prisma/
│       ├── schema.prisma
│       └── seed.js               # 169 Indonesian seed locations
│
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
flutter run
```

## Key Technical Decisions

### EXIF timestamp over upload time
Every post displays the timestamp from the image's EXIF metadata (`DateTimeOriginal`), not the time of upload. This is intentional — a photo taken two years ago and uploaded today should be read as a historical record, not a current one. If EXIF data is unavailable, the post is labeled accordingly rather than silently falling back to upload time.

### Geospatial deduplication via PostGIS
When a user uploads a post and tags a location, the backend checks whether any existing location in the database falls within a 50-meter radius of the submitted coordinates. If a match is found, the post is attached to that location instead of creating a new one. This keeps the map clean and prevents the same physical place from accumulating multiple fragmented pins. The logic lives in `geo.service.js` as `findOrCreateLocation`.

### Place-centric data model
`Location` is the central entity — not `User`. Posts belong to locations. Trending is ranked by location activity. The map is the primary navigation surface. This is a deliberate architectural choice that constrains the feature set but keeps the core use case coherent: understanding a place over time, not building a following.

### Cursor-based pagination for post feeds
Location feeds use cursor pagination (`cursor` + `limit`) rather than offset pagination. For feeds sorted by `taken_at` where new posts can be inserted at any position in the timeline, offset pagination produces inconsistent results. Cursor pagination ensures stable, consistent traversal regardless of new inserts.

## Design

- **Theme:** Dark monochromatic — `#1C1C1E` base, Plus Jakarta Sans
- **Navigation:** Bottom nav bar (map · trending · upload · profile)
- **Upload:** 3-step wizard with step progress indicator
- **Location Detail:** Vertical card feed with EXIF overlays and timeline slider
- **Post Detail:** Scrollable layout with sticky comment input

