const prisma = require('../config/db');
const { uploadToCloudinary, deleteFromCloudinary } = require('../services/cloudinary.service');
const { findOrCreateLocation } = require('../services/geo.service');

/**
 * POST /api/posts
 * Upload foto + auto-detect/create lokasi
 */
const createPost = async (req, res, next) => {
  try {
    console.log('--- Post Creation Started ---');
    console.log('Body:', req.body);
    console.log('File:', req.file ? { mimetype: req.file.mimetype, size: req.file.size } : 'No file');

    if (!req.file) {
      return res.status(400).json({ error: 'File foto wajib diupload' });
    }

    const { latitude, longitude, caption, taken_at, location_name } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json({ error: 'Koordinat (latitude, longitude) wajib diisi' });
    }

    // 1. Upload ke Cloudinary
    console.log('Uploading to Cloudinary...');
    let uploadResult;
    try {
      uploadResult = await uploadToCloudinary(req.file.buffer);
      console.log('Cloudinary Success:', uploadResult.url);
    } catch (cloudinaryErr) {
      console.error('Cloudinary Error:', cloudinaryErr);
      return res.status(500).json({ error: 'Gagal mengupload ke Cloudinary: ' + cloudinaryErr.message });
    }

    const { url, public_id } = uploadResult;

    // 2. Find or create lokasi
    console.log('Finding/Creating Location for:', latitude, longitude);
    const location = await findOrCreateLocation(
      parseFloat(latitude),
      parseFloat(longitude),
      location_name || 'Lokasi Baru'
    );
    console.log('Location ID:', location.id);

    // 3. Simpan post
    console.log('Creating Post record in DB...');
    const post = await prisma.post.create({
      data: {
        user_id: req.user.id,
        location_id: location.id,
        media_url: url,
        media_type: req.file.mimetype.startsWith('image/') ? 'photo' : 'video',
        caption: caption || null,
        taken_at: taken_at ? new Date(taken_at) : new Date(),
      },
      include: {
        user: { select: { id: true, username: true, avatar_url: true } },
        location: { select: { id: true, name: true, latitude: true, longitude: true } },
      },
    });

    // 4. Increment post_count di lokasi
    await prisma.location.update({
      where: { id: location.id },
      data: { post_count: { increment: 1 } },
    });

    console.log('Post Created Successfully:', post.id);
    res.status(201).json(post);
  } catch (err) {
    console.error('Final CreatePost Error:', err);
    next(err);
  }
};

/**
 * GET /api/posts?location_id=&cursor=&limit=
 * Feed per lokasi, cursor pagination (terbaru dulu)
 */
const getPostsByLocation = async (req, res, next) => {
  try {
    const { location_id, cursor, limit = '20' } = req.query;

    if (!location_id) {
      return res.status(400).json({ error: 'location_id wajib diisi' });
    }

    const take = parseInt(limit);
    const where = { location_id };

    const posts = await prisma.post.findMany({
      where,
      take: take + 1, // ambil 1 lebih untuk cek hasMore
      ...(cursor && {
        cursor: { id: cursor },
        skip: 1,
      }),
      orderBy: { taken_at: 'desc' },
      include: {
        user: { select: { id: true, username: true, avatar_url: true } },
        _count: { select: { comments: true } },
      },
    });

    const hasMore = posts.length > take;
    const data = hasMore ? posts.slice(0, take) : posts;
    const nextCursor = hasMore ? data[data.length - 1].id : null;

    res.json({
      data,
      nextCursor,
      hasMore,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * GET /api/posts/:id
 */
const getPostDetail = async (req, res, next) => {
  try {
    const post = await prisma.post.findUnique({
      where: { id: req.params.id },
      include: {
        user: { select: { id: true, username: true, avatar_url: true } },
        location: { select: { id: true, name: true, latitude: true, longitude: true } },
        comments: {
          orderBy: { created_at: 'desc' },
          take: 10,
          include: {
            user: { select: { id: true, username: true, avatar_url: true } },
          },
        },
        _count: { select: { comments: true } },
      },
    });

    if (!post) {
      return res.status(404).json({ error: 'Post tidak ditemukan' });
    }

    res.json(post);
  } catch (err) {
    next(err);
  }
};

/**
 * DELETE /api/posts/:id
 */
const deletePost = async (req, res, next) => {
  try {
    const post = await prisma.post.findUnique({
      where: { id: req.params.id },
    });

    if (!post) {
      return res.status(404).json({ error: 'Post tidak ditemukan' });
    }

    if (post.user_id !== req.user.id) {
      return res.status(403).json({ error: 'Tidak diizinkan menghapus post ini' });
    }

    // Hapus dari Cloudinary (extract public_id dari URL)
    const urlParts = post.media_url.split('/');
    const publicId = urlParts.slice(-2).join('/').replace(/\.[^.]+$/, '');
    await deleteFromCloudinary(publicId);

    // Hapus post & decrement counter
    await prisma.$transaction([
      prisma.post.delete({ where: { id: req.params.id } }),
      prisma.location.update({
        where: { id: post.location_id },
        data: { post_count: { decrement: 1 } },
      }),
    ]);

    res.json({ message: 'Post berhasil dihapus' });
  } catch (err) {
    next(err);
  }
};

module.exports = { createPost, getPostsByLocation, getPostDetail, deletePost };
