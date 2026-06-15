const express = require('express');
const cors = require('cors');
require('dotenv').config();
const db = require('./db');

const path = require('path');

const app = express();
const PORT = process.env.PORT || 5000;

// Middlewares
app.use(cors());
app.use(express.json());
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));

// Routes
app.use('/api/auth', require('./routes/authRoutes'));
app.use('/api/exams', require('./routes/examRoutes'));
app.use('/api/rooms', require('./routes/roomRoutes'));
app.use('/api/results', require('./routes/resultRoutes'));
app.use('/api/focus', require('./routes/focusRoutes'));

// Routes de test
app.get('/', (req, res) => {
  res.json({ message: 'Bienvenue sur l\'API Planner !' });
});

// Test de connexion DB
app.get('/test-db', async (req, res) => {
  try {
    const result = await db.query('SELECT NOW()');
    res.json({
      message: 'Connexion à la base de données réussie !',
      time: result.rows[0].now
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur de connexion à la base de données' });
  }
});

app.listen(PORT, () => {
  console.log(`Le serveur tourne sur le port ${PORT}`);
});
