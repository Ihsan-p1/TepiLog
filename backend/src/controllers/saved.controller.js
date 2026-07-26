const prisma = require('../config/db');

// GET /api/saved — user's saved locations
const getSavedLocations = async (req, res, next) => {
  try {
    const saved = await prisma.savedLocation.findMany({
      where: { user_id: req.user.id },
      orderBy: { saved_at: 'desc' },
      include: {
        location: true,
      },
    });

    res.json(saved.map(s => ({
      ...s.location,
      saved_at: s.saved_at,
    })));
  } catch (error) {
    next(error);
  }
};

// POST /api/saved/:locationId — toggle save/unsave
const toggleSave = async (req, res, next) => {
  try {
    const { locationId } = req.params;

    const existing = await prisma.savedLocation.findUnique({
      where: {
        user_id_location_id: {
          user_id: req.user.id,
          location_id: locationId,
        },
      },
    });

    if (existing) {
      // unsave
      await prisma.savedLocation.delete({
        where: {
          user_id_location_id: {
            user_id: req.user.id,
            location_id: locationId,
          },
        },
      });
      res.json({ saved: false });
    } else {
      // save
      await prisma.savedLocation.create({
        data: {
          user_id: req.user.id,
          location_id: locationId,
        },
      });
      res.json({ saved: true });
    }
  } catch (error) {
    next(error);
  }
};

// GET /api/saved/:locationId/check — check if saved
const checkSaved = async (req, res, next) => {
  try {
    const existing = await prisma.savedLocation.findUnique({
      where: {
        user_id_location_id: {
          user_id: req.user.id,
          location_id: req.params.locationId,
        },
      },
    });
    res.json({ saved: !!existing });
  } catch (error) {
    next(error);
  }
};

module.exports = { getSavedLocations, toggleSave, checkSaved };
