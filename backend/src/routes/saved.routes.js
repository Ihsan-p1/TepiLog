const express = require('express');
const router = express.Router();
const { getSavedLocations, toggleSave, checkSaved } = require('../controllers/saved.controller');
const verifyToken = require('../middleware/auth');

router.get('/', verifyToken, getSavedLocations);
router.post('/:locationId', verifyToken, toggleSave);
router.get('/:locationId/check', verifyToken, checkSaved);

module.exports = router;
