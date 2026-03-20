const express = require('express');
const router = express.Router();
const { getNearbyLocations, getLocationDetail, getTrendingLocations } = require('../controllers/location.controller');

router.get('/', getNearbyLocations);
router.get('/trending', getTrendingLocations);
router.get('/:id', getLocationDetail);

module.exports = router;
