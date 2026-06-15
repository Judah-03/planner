const db = require('../db');
const { v4: uuidv4 } = require('uuid');

exports.getResults = async (req, res) => {
  try {
    const userId = req.user.id;
    const result = await db.query('SELECT * FROM results WHERE user_id = $1 ORDER BY created_at DESC', [userId]);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des notes' });
  }
};

exports.addResult = async (req, res) => {
  try {
    const userId = req.user.id;
    const { subject, grade, credits, semester } = req.body;
    
    if (!subject || grade === undefined) {
      return res.status(400).json({ error: 'La matière et la note sont requises' });
    }

    const newResult = await db.query(
      'INSERT INTO results (id, user_id, subject, grade, credits, semester) VALUES ($1, $2, $3, $4, $5, $6) RETURNING *',
      [uuidv4(), userId, subject, grade, credits, semester]
    );
    
    res.status(201).json(newResult.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de l\'ajout de la note' });
  }
};

exports.deleteResult = async (req, res) => {
  try {
    const { id } = req.params;
    const userId = req.user.id;
    await db.query('DELETE FROM results WHERE id = $1 AND user_id = $2', [id, userId]);
    res.json({ message: 'Note supprimée' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la suppression' });
  }
};
