const db = require('../db');
const { v4: uuidv4 } = require('uuid');

exports.getExams = async (req, res) => {
  try {
    const result = await db.query('SELECT * FROM exams ORDER BY exam_date ASC');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des examens' });
  }
};

exports.createExam = async (req, res) => {
  try {
    const { subject, exam_date, exam_time, room, teacher, duration, level } = req.body;
    const newExam = await db.query(
      'INSERT INTO exams (id, subject, exam_date, exam_time, room, teacher, duration, level) VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *',
      [uuidv4(), subject, exam_date, exam_time, room, teacher, duration, level]
    );
    res.status(201).json(newExam.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la création de l\'examen' });
  }
};

exports.updateExam = async (req, res) => {
  try {
    const { id } = req.params;
    const { subject, exam_date, exam_time, room, teacher, duration, level } = req.body;
    const result = await db.query(
      'UPDATE exams SET subject = $1, exam_date = $2, exam_time = $3, room = $4, teacher = $5, duration = $6, level = $7 WHERE id = $8 RETURNING *',
      [subject, exam_date, exam_time, room, teacher, duration, level, id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Examen non trouvé' });
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la mise à jour' });
  }
};

exports.deleteExam = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await db.query('DELETE FROM exams WHERE id = $1 RETURNING *', [id]);
    if (result.rows.length === 0) return res.status(404).json({ error: 'Examen non trouvé' });
    res.json({ message: 'Examen supprimé avec succès' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la suppression' });
  }
};
