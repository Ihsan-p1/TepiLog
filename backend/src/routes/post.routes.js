const router = require('express').Router();
const multer = require('multer');
const auth = require('../middleware/auth');
const {
  createPost,
  getPostsByLocation,
  getPostDetail,
  deletePost,
} = require('../controllers/post.controller');

// Multer: simpan di memory buffer (untuk stream ke Cloudinary)
const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 }, // max 10MB
  fileFilter: (req, file, cb) => {
    if (file.mimetype.startsWith('image/')) {
      cb(null, true);
    } else {
      cb(new Error('Hanya file gambar yang diizinkan'), false);
    }
  },
});

router.post('/', auth, upload.single('photo'), createPost);
router.get('/', auth, getPostsByLocation);
router.get('/:id', auth, getPostDetail);
router.delete('/:id', auth, deletePost);

module.exports = router;
