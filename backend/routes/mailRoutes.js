const express = require('express');
const router = express.Router();
const mailController = require('../controllers/mailController');
const authMiddleware = require('../middleware/authMiddleware');

// Route for sending email
router.post('/send', authMiddleware, mailController.sendMail);

module.exports = router;
