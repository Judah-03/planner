const db = require('./db');

async function patch() {
  try {
    await db.query(`
      CREATE TABLE IF NOT EXISTS focus_sessions (
        id UUID PRIMARY KEY,
        user_id UUID REFERENCES users(id),
        duration_minutes INTEGER NOT NULL,
        session_type TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('Success: focus_sessions table created.');
    process.exit(0);
  } catch (err) {
    console.error('Error creating focus_sessions table:', err);
    process.exit(1);
  }
}

patch();
