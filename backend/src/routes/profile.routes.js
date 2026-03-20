const express = require('express');
const router = express.Router();
const { getMyProfile, getMyPosts } = require('../controllers/profile.controller');
const verifyToken = require('../middleware/auth');

router.get('/me', verifyToken, getMyProfile);
router.get('/me/posts', verifyToken, getMyPosts);

module.exports = router;
