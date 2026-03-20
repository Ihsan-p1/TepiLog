const prisma = require('../config/db');

// GET /api/users/me
const getMyProfile = async (req, res, next) => {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: {
        id: true,
        email: true,
        username: true,
        avatar_url: true,
        created_at: true,
        _count: {
          select: {
            posts: true,
            saved_locations: true,
          },
        },
      },
    });

    if (!user) {
      return res.status(404).json({ error: 'User tidak ditemukan' });
    }

    // Count unique locations user has posted to
    const locationCount = await prisma.post.groupBy({
      by: ['location_id'],
      where: { user_id: req.user.id },
    });

    res.json({
      ...user,
      stats: {
        posts: user._count.posts,
        locations: locationCount.length,
        saved: user._count.saved_locations,
      },
    });
  } catch (error) {
    next(error);
  }
};

// GET /api/users/me/posts
const getMyPosts = async (req, res, next) => {
  try {
    const posts = await prisma.post.findMany({
      where: { user_id: req.user.id },
      orderBy: { uploaded_at: 'desc' },
      include: {
        user: { select: { id: true, username: true, avatar_url: true } },
        location: { select: { id: true, name: true, latitude: true, longitude: true } },
        _count: { select: { comments: true } },
      },
    });

    res.json(posts);
  } catch (error) {
    next(error);
  }
};

module.exports = { getMyProfile, getMyPosts };
