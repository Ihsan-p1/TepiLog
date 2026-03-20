const express = require('express');
const router = express.Router();
const { register, login, refresh } = require('../controllers/auth.controller');

router.post('/register', register);
router.post('/login', login);
router.post('/refresh', refresh);

module.exports = router;
