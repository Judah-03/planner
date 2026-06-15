const express = require('express');
const router = express.Router();
const resultController = require('../controllers/resultController');
const auth = require('../middleware/authMiddleware');

router.get('/', auth, resultController.getResults);
router.post('/', auth, resultController.addResult);
router.delete('/:id', auth, resultController.deleteResult);

module.exports = router;
