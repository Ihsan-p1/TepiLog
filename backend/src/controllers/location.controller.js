const geoService = require('../services/geo.service');
const prisma = require('../config/db');

// GET /api/locations?lat=&lng=&radius=
const getNearbyLocations = async (req, res, next) => {
  try {
    const { lat, lng, radius } = req.query;

    if (!lat || !lng) {
      return res.status(400).json({ error: 'Latitude dan Longitude wajib diisi' });
    }

    const radiusMeter = parseFloat(radius) || 5000; // default 5km

    // Menggunakan raw SQL via service untuk pencarian radius PostGIS.
    // cover_url = foto terbaru (taken_at) untuk pin peta; first/last_taken_at = rentang tahun.
    const locations = await prisma.$queryRaw`
      SELECT l.id, l.name, l.latitude, l.longitude, l.post_count,
             ST_Distance(l.coordinates, ST_MakePoint(${parseFloat(lng)}, ${parseFloat(lat)})::geography) as distance,
             cover.media_url AS cover_url,
             span.first_taken_at, span.last_taken_at
      FROM locations l
      LEFT JOIN LATERAL (
        SELECT p.media_url FROM posts p
        WHERE p.location_id = l.id
        ORDER BY p.taken_at DESC
        LIMIT 1
      ) cover ON true
      LEFT JOIN LATERAL (
        SELECT MIN(p.taken_at) AS first_taken_at, MAX(p.taken_at) AS last_taken_at
        FROM posts p
        WHERE p.location_id = l.id
      ) span ON true
      WHERE ST_DWithin(
        l.coordinates,
        ST_MakePoint(${parseFloat(lng)}, ${parseFloat(lat)})::geography,
        ${radiusMeter}
      )
      ORDER BY distance ASC
      LIMIT 50;
    `;

    res.json(locations);
  } catch (error) {
    next(error);
  }
};

// GET /api/locations/:id
const getLocationDetail = async (req, res, next) => {
  try {
    const { id } = req.params;
    const location = await geoService.getLocationById(id);

    if (!location) {
      return res.status(404).json({ error: 'Lokasi tidak ditemukan' });
    }

    res.json(location);
  } catch (error) {
    next(error);
  }
};

// GET /api/locations/trending?lat=&lng=
const getTrendingLocations = async (req, res, next) => {
  try {
    const { lat, lng } = req.query;
    const radiusMeter = 50000; // 50km radius as per TDD

    // Query trending: upload terbanyak dalam 7 hari terakhir, radius 50km
    const locations = await prisma.$queryRaw`
      SELECT l.*, COUNT(p.id) as recent_posts
      FROM locations l
      JOIN posts p ON p.location_id = l.id
      WHERE ST_DWithin(l.coordinates, ST_MakePoint(${parseFloat(lng)}, ${parseFloat(lat)})::geography, ${radiusMeter})
      AND p.uploaded_at > NOW() - INTERVAL '7 days'
      GROUP BY l.id
      ORDER BY recent_posts DESC
      LIMIT 20;
    `;

    res.json(locations);
  } catch (error) {
    next(error);
  }
};

// GET /api/locations/search?q=
const searchLocations = async (req, res, next) => {
  try {
    const { q } = req.query;
    if (!q || q.length < 2) return res.json([]);

    const locations = await prisma.location.findMany({
      where: {
        name: {
          contains: q,
          mode: 'insensitive',
        },
      },
      orderBy: { post_count: 'desc' },
      take: 5,
    });

    res.json(locations);
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getNearbyLocations,
  getLocationDetail,
  getTrendingLocations,
  searchLocations
};
