const express = require('express');
const router = express.Router();
const { getNearbyLocations, getLocationDetail, getTrendingLocations, searchLocations } = require('../controllers/location.controller');

router.get('/', getNearbyLocations);
router.get('/trending', getTrendingLocations);
router.get('/search', searchLocations);
router.get('/:id', getLocationDetail);

module.exports = router;
