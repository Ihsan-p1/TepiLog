const prisma = require('../config/db');

/**
 * Mencari lokasi terdekat dalam radius tertentu
 * @param {number} lat - Latitude user
 * @param {number} lng - Longitude user
 * @param {number} radiusMeter - Radius pencarian dalam meter
 * @returns {Promise<Object>}
 */
const findNearbyLocation = async (lat, lng, radiusMeter = 50) => {
  // Catatan: Menggunakan queryRaw karena Prisma tidak handle Geography secara native.
  // Query ini membutuhkan ekstensi PostGIS terinstal.
  try {
    const locations = await prisma.$queryRaw`
      SELECT id, name, latitude, longitude, post_count
      FROM locations
      WHERE ST_DWithin(
        coordinates,
        ST_MakePoint(${lng}, ${lat})::geography,
        ${radiusMeter}
      )
      ORDER BY ST_Distance(
        coordinates,
        ST_MakePoint(${lng}, ${lat})::geography
      )
      LIMIT 1;
    `;
    
    return locations[0] || null;
  } catch (error) {
    console.error('Error in findNearbyLocation:', error.message);
    // Fallback sederhana jika PostGIS bermasalah (hanya untuk testing, tidak akurat)
    return null;
  }
};

/**
 * Mendapatkan lokasi berdasarkan ID dengan statistik tambahan
 */
const getLocationById = async (id) => {
  return prisma.location.findUnique({
    where: { id },
    include: {
      _count: {
        select: { posts: true }
      }
    }
  });
};

/**
 * Mencari atau membuat lokasi baru berdasarkan koordinat
 * Digunakan saat upload post (deduplication 50m)
 */
const findOrCreateLocation = async (lat, lng, name = 'Lokasi Baru') => {
  // 1. Cek apakah ada lokasi dalam radius 50m
  const existing = await findNearbyLocation(lat, lng, 50);
  
  if (existing) {
    return existing;
  }
  
  // 2. Jika tidak ada, buat lokasi baru melalui Prisma.
  // DB Trigger trg_update_location_coordinates akan otomatis mengisi field 'coordinates'.
  return prisma.location.create({
    data: {
      name,
      latitude: lat,
      longitude: lng
    }
  });
};

module.exports = {
  findNearbyLocation,
  getLocationById,
  findOrCreateLocation
};
