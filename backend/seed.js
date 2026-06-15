const db = require('./db');
const { v4: uuidv4 } = require('uuid');
const bcrypt = require('bcryptjs');

const seedDatabase = async () => {
  try {
    console.log('Début du Seeding...');

    // 0. Ajout d'un utilisateur de test
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash('admin123', salt);
    
    await db.query('DELETE FROM users WHERE email = $1', ['test@emit.mg']);
    await db.query(
      'INSERT INTO users (id, student_id, email, full_name, password_hash, branch, level) VALUES ($1, $2, $3, $4, $5, $6, $7)',
      [uuidv4(), '123456', 'test@emit.mg', 'Judah User', passwordHash, 'IT', 'L3']
    );
    console.log('Utilisateur de test créé (test@emit.mg / admin123) !');

    // 1. Nettoyage des tables (Optionnel, attention supprime tout)
    // await db.query('DELETE FROM rooms');
    // await db.query('DELETE FROM exams');

    // 2. Ajout des Salles
    const rooms = [
      { name: 'Room 101', building: 'Main Building', is_occupied: true, capacity: 50 },
      { name: 'Room 102', building: 'Main Building', is_occupied: false, capacity: 60 },
      { name: 'Lab 1', building: 'IT Block', is_occupied: true, capacity: 30 },
      { name: 'Grand Hall', building: 'Annex', is_occupied: false, capacity: 200 }
    ];

    for (const room of rooms) {
      await db.query(
        'INSERT INTO rooms (id, name, building, is_occupied, capacity) VALUES ($1, $2, $3, $4, $5)',
        [uuidv4(), room.name, room.building, room.is_occupied, room.capacity]
      );
    }
    console.log('Salles insérées !');

    // 3. Ajout des Examens
    const exams = [
      {
        subject: 'Software Engineering',
        date: '2024-06-15',
        time: '09:00 AM',
        room: 'Room 102',
        teacher: 'Prof. Rakoto',
        duration: '3 hours',
        level: 'L3'
      },
      {
        subject: 'Database Systems',
        date: '2024-06-18',
        time: '02:00 PM',
        room: 'Lab 1',
        teacher: 'Dr. Lala',
        duration: '2 hours',
        level: 'L3'
      },
      {
        subject: 'Cloud Computing',
        date: '2024-06-20',
        time: '10:00 AM',
        room: 'Grand Hall',
        teacher: 'Mme. Soa',
        duration: '4 hours',
        level: 'M1'
      }
    ];

    for (const exam of exams) {
      await db.query(
        'INSERT INTO exams (id, subject, exam_date, exam_time, room, teacher, duration, level) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)',
        [uuidv4(), exam.subject, exam.date, exam.time, exam.room, exam.teacher, exam.duration, exam.level]
      );
    }
    console.log('Examens insérés !');

    console.log('Seeding terminé avec succès !');
    process.exit();
  } catch (err) {
    console.error('Erreur lors du seeding :', err);
    process.exit(1);
  }
};

seedDatabase();
