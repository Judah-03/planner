const db = require('./db');

async function patch() {
  try {
    await db.query(`
      CREATE TABLE IF NOT EXISTS results (
        id UUID PRIMARY KEY,
        user_id UUID REFERENCES users(id),
        subject TEXT NOT NULL,
        grade DECIMAL(4,2) NOT NULL,
        credits INTEGER,
        semester TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    console.log('Success: results table created.');
    process.exit(0);
  } catch (err) {
    console.error('Error creating results table:', err);
    process.exit(1);
  }
}

patch();
