const express = require('express');
const router = express.Router();
const examController = require('../controllers/examController');
const auth = require('../middleware/authMiddleware');

// Toutes les routes d'examens sont protégées par le middleware d'auth
router.get('/', auth, examController.getExams);
router.post('/', auth, examController.createExam);
router.put('/:id', auth, examController.updateExam);
router.delete('/:id', auth, examController.deleteExam);

module.exports = router;
