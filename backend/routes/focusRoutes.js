const express = require('express');
const router = express.Router();
const focusController = require('../controllers/focusController');
const authMiddleware = require('../middleware/authMiddleware');

router.post('/', authMiddleware, focusController.addFocusSession);
router.get('/stats', authMiddleware, focusController.getFocusStats);

module.exports = router;
