const prisma = require('../config/db');

/**
 * Mencari lokasi terdekat dalam radius tertentu
 * @param {number} lat - Latitude user
 * @param {number} lng - Longitude user
 * @param {number} radiusMeter - Radius pencarian dalam meter
 * @param {Object} db - Prisma client or transaction client to query with
 * @returns {Promise<Object>}
 */
const findNearbyLocation = async (lat, lng, radiusMeter = 50, db = prisma) => {
  // Catatan: Menggunakan queryRaw karena Prisma tidak handle Geography secara native.
  // Query ini membutuhkan ekstensi PostGIS terinstal.
  // Errors propagate on purpose: returning null here would make
  // findOrCreateLocation insert a duplicate pin whenever the query fails.
  const locations = await db.$queryRaw`
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
const findOrCreateLocation = async (lat, lng, name = 'Lokasi Baru') =>
  prisma.$transaction(async (tx) => {
    // Serialize find-or-create across connections. Without the lock, two
    // uploads near the same spot can both miss the SELECT below and each
    // insert a pin. The lock is released when the transaction ends.
    await tx.$executeRaw`SELECT pg_advisory_xact_lock(hashtext('tepilog.location_dedup'))`;

    // 1. Cek apakah ada lokasi dalam radius 50m
    const existing = await findNearbyLocation(lat, lng, 50, tx);

    if (existing) {
      return existing;
    }

    // 2. Jika tidak ada, buat lokasi baru melalui Prisma.
    // DB Trigger trg_update_location_coordinates akan otomatis mengisi field 'coordinates'.
    return tx.location.create({
      data: {
        name,
        latitude: lat,
        longitude: lng
      }
    });
  });

module.exports = {
  findNearbyLocation,
  getLocationById,
  findOrCreateLocation
};
