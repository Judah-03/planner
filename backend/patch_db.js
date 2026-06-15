const db = require('./db');

async function patch() {
  try {
    await db.query('ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_image TEXT;');
    console.log('Success: profile_image column added or exists.');
    process.exit(0);
  } catch (err) {
    console.error('Error adding column:', err);
    process.exit(1);
  }
}

patch();
