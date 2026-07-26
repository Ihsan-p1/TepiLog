const prisma = require('../config/db');

// GET /api/comments/:postId
const getComments = async (req, res, next) => {
  try {
    const { postId } = req.params;
    const comments = await prisma.comment.findMany({
      where: { post_id: postId },
      orderBy: { created_at: 'desc' },
      include: {
        user: { select: { id: true, username: true, avatar_url: true } },
      },
    });

    res.json(comments);
  } catch (error) {
    next(error);
  }
};

// POST /api/comments/:postId
const createComment = async (req, res, next) => {
  try {
    const { postId } = req.params;
    const { body } = req.body;

    if (!body || body.trim().length === 0) {
      return res.status(400).json({ error: 'Komentar tidak boleh kosong' });
    }

    const comment = await prisma.comment.create({
      data: {
        post_id: postId,
        user_id: req.user.id,
        body: body.trim(),
      },
      include: {
        user: { select: { id: true, username: true, avatar_url: true } },
      },
    });

    res.status(201).json(comment);
  } catch (error) {
    next(error);
  }
};

// DELETE /api/comments/:id
const deleteComment = async (req, res, next) => {
  try {
    const comment = await prisma.comment.findUnique({
      where: { id: req.params.id },
    });

    if (!comment) {
      return res.status(404).json({ error: 'Komentar tidak ditemukan' });
    }

    if (comment.user_id !== req.user.id) {
      return res.status(403).json({ error: 'Tidak diizinkan menghapus komentar ini' });
    }

    await prisma.comment.delete({ where: { id: req.params.id } });
    res.json({ message: 'Komentar berhasil dihapus' });
  } catch (error) {
    next(error);
  }
};

module.exports = { getComments, createComment, deleteComment };
