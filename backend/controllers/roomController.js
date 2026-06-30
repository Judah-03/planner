const db = require('../db');
const { v4: uuidv4 } = require('uuid');

exports.getRooms = async (req, res) => {
  try {
    const result = await db.query(`
      SELECT r.*, 
      (SELECT e.subject FROM exams e WHERE e.room = r.name AND e.exam_date >= CURRENT_DATE ORDER BY e.exam_date ASC, e.exam_time ASC LIMIT 1) as next_exam,
      (SELECT e.exam_time FROM exams e WHERE e.room = r.name AND e.exam_date >= CURRENT_DATE ORDER BY e.exam_date ASC, e.exam_time ASC LIMIT 1) as next_time
      FROM rooms r 
      ORDER BY r.name ASC
    `);
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des salles' });
  }
};

exports.createRoom = async (req, res) => {
  try {
    const { name, building, is_occupied, capacity } = req.body;
    const newRoom = await db.query(
      'INSERT INTO rooms (id, name, building, is_occupied, capacity) VALUES ($1, $2, $3, $4, $5) RETURNING *',
      [uuidv4(), name, building, is_occupied || false, capacity]
    );
    res.status(201).json(newRoom.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la création de la salle' });
  }
};

exports.updateRoomStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { is_occupied } = req.body;
    const result = await db.query(
      'UPDATE rooms SET is_occupied = $1 WHERE id = $2 RETURNING *',
      [is_occupied, id]
    );
    if (result.rows.length === 0) return res.status(404).json({ error: 'Salle non trouvée' });
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la mise à jour du statut' });
  }
};
