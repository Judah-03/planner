const db = require('../db');
const { v4: uuidv4 } = require('uuid');

exports.addFocusSession = async (req, res) => {
  try {
    const userId = req.user.id;
    const { duration_minutes, session_type } = req.body;

    if (!duration_minutes || !session_type) {
      return res.status(400).json({ error: 'La durée et le type de session sont requis' });
    }

    const newSession = await db.query(
      'INSERT INTO focus_sessions (id, user_id, duration_minutes, session_type) VALUES ($1, $2, $3, $4) RETURNING *',
      [uuidv4(), userId, duration_minutes, session_type]
    );

    res.status(201).json(newSession.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de l\'enregistrement de la session' });
  }
};

exports.getFocusStats = async (req, res) => {
  try {
    const userId = req.user.id;
    
    // Total study minutes today
    const statsToday = await db.query(
      "SELECT SUM(duration_minutes) as total_minutes FROM focus_sessions WHERE user_id = $1 AND session_type = 'work' AND created_at >= CURRENT_DATE",
      [userId]
    );

    // Total study minutes all time
    const statsAllTime = await db.query(
      "SELECT SUM(duration_minutes) as total_minutes FROM focus_sessions WHERE user_id = $1 AND session_type = 'work'",
      [userId]
    );

    res.json({
      today_minutes: parseInt(statsToday.rows[0].total_minutes || 0),
      total_minutes: parseInt(statsAllTime.rows[0].total_minutes || 0)
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la récupération des statistiques' });
  }
};
