const express = require('express');
const router = express.Router();
const { getComments, createComment, deleteComment } = require('../controllers/comment.controller');
const verifyToken = require('../middleware/auth');

router.get('/:postId', verifyToken, getComments);
router.post('/:postId', verifyToken, createComment);
router.delete('/:id', verifyToken, deleteComment);

module.exports = router;
