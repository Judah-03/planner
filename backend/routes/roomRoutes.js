const express = require('express');
const router = express.Router();
const roomController = require('../controllers/roomController');
const auth = require('../middleware/authMiddleware');

// Routes protégées par auth
router.get('/', auth, roomController.getRooms);
router.post('/', auth, roomController.createRoom);
router.patch('/:id/status', auth, roomController.updateRoomStatus);

module.exports = router;
