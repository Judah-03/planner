const db = require('../db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { v4: uuidv4 } = require('uuid');
const nodemailer = require('nodemailer');

const dns = require('dns').promises;

// Fonction pour vérifier si le domaine de l'email peut recevoir des messages (Records MX)
async function isEmailDomainValid(email) {
  const domain = email.split('@')[1];
  try {
    const mxRecords = await dns.resolveMx(domain);
    return mxRecords && mxRecords.length > 0;
  } catch (error) {
    // Si l'erreur est liée au réseau (ex: ECONNREFUSED), on laisse passer car c'est un souci de connexion local
    console.log(`[DNS INFO] Impossible de vérifier les records MX pour ${domain}: ${error.code}`);
    if (error.code === 'ECONNREFUSED' || error.code === 'ETIMEOUT') {
      return true; // On assume que c'est valide si on n'arrive pas à interroger le DNS
    }
    return false;
  }
}

// 1. Envoyer le code de vérification
exports.sendCode = async (req, res) => {
  try {
    const { email } = req.body;
    
    // Validation du format basique
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({ error: "Format d'email invalide." });
    }

    const code = Math.floor(100000 + Math.random() * 900000).toString();

    // Vérifier si l'utilisateur existe déjà
    const result = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    
    // Si l'utilisateur existe déjà et a un mot de passe, il ne peut pas s'inscrire à nouveau
    if (result.rows.length > 0 && result.rows[0].password_hash) {
      return res.status(400).json({ 
        error: "Cet email est déjà associé à un compte. Veuillez vous connecter." 
      });
    }

    // Vérification de l'existence réelle du domaine (Vérification Internet)
    const isValidDomain = await isEmailDomainValid(email);
    if (!isValidDomain) {
      return res.status(400).json({ 
        error: "Cet email ne semble pas exister sur internet (domaine invalide)." 
      });
    }

    // Inscription ou Mise à jour
    if (result.rows.length === 0) {
      // Nouvel utilisateur
      await db.query(
        'INSERT INTO users (id, email, verification_code, is_verified) VALUES ($1, $2, $3, $4)',
        [uuidv4(), email, code, false]
      );
    } else {
      // Utilisateur existant mais non finalisé
      await db.query(
        'UPDATE users SET verification_code = $1, is_verified = $2 WHERE email = $3', 
        [code, false, email]
      );
    }

    // Configuration automatique pour le test (si aucun compte n'est configuré)
    let transportConfig;
    if (!process.env.EMAIL_USER || process.env.EMAIL_USER === 'ton_email@gmail.com') {
      // GÉNÉRATION AUTOMATIQUE D'UN COMPTE DE TEST
      let testAccount = await nodemailer.createTestAccount();
      transportConfig = {
        host: "smtp.ethereal.email",
        port: 587,
        secure: false,
        auth: {
          user: testAccount.user,
          pass: testAccount.pass,
        },
      };
    } else {
      transportConfig = {
        service: process.env.EMAIL_SERVICE,
        auth: {
          user: process.env.EMAIL_USER,
          pass: process.env.EMAIL_PASS,
        },
      };
    }

    const transporter = nodemailer.createTransport(transportConfig);

    try {
      const info = await transporter.sendMail({
        from: '"Planner Support" <support@planner.app>',
        to: email,
        subject: "Vérification de votre compte Planner",
        text: `Votre code de vérification est : ${code}`,
        html: `
          <div style="font-family: sans-serif; padding: 20px; border: 1px solid #eee; border-radius: 10px;">
            <h2 style="color: #6366f1;">Vérification de compte</h2>
            <p>Bonjour, voici votre code de vérification pour l'application Planner :</p>
            <div style="background: #f3f4f6; padding: 20px; text-align: center; font-size: 32px; font-weight: bold; letter-spacing: 5px; color: #1f2937;">
              ${code}
            </div>
            <p style="margin-top: 20px; color: #6b7280; font-size: 12px;">Si vous n'avez pas demandé ce code, ignorez cet email.</p>
          </div>
        `,
      });

      // SI C'EST UN COMPTE DE TEST, ON AFFICHE LE LIEN DE PRÉVISUALISATION
      if (!process.env.EMAIL_USER || process.env.EMAIL_USER === 'ton_email@gmail.com') {
        console.log(`\x1b[36m%s\x1b[0m`, `[TEST EMAIL] L'email a été envoyé !`);
        console.log(`\x1b[36m%s\x1b[0m`, `👉 Voir l'email reçu ici : ${nodemailer.getTestMessageUrl(info)}`);
      } else {
        console.log(`\x1b[32m%s\x1b[0m`, `[SUCCESS] Email envoyé réellement à ${email}`);
      }
      
    } catch (mailError) {
      console.error("Erreur d'envoi d'email:", mailError);
    }

    // Le code s'affiche toujours ici aussi par sécurité
    console.log(`\x1b[32m%s\x1b[0m`, `[APP] Code de vérification pour ${email} : ${code}`);
    
    res.json({ message: 'Code de vérification envoyé.' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de l\'envoi du code' });
  }
};

// 2. Vérifier le code
exports.verifyCode = async (req, res) => {
  try {
    const { email, code } = req.body;
    const result = await db.query('SELECT * FROM users WHERE email = $1 AND verification_code = $2', [email, code]);

    if (result.rows.length === 0) {
      return res.status(400).json({ error: 'Code invalide' });
    }

    await db.query('UPDATE users SET is_verified = $1 WHERE email = $2', [true, email]);
    res.json({ message: 'Email vérifié' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur verification' });
  }
};

// 1. Inscription Directe (Plus besoin de code)
exports.register = async (req, res) => {
  try {
    const { email, password, full_name, student_id, branch, level } = req.body;

    // Vérifier si l'utilisateur existe déjà
    const userExists = await db.query('SELECT * FROM users WHERE email = $1', [email]);
    if (userExists.rows.length > 0) {
      // Si l'utilisateur est déjà inscrit avec un MDP
      if (userExists.rows[0].password_hash) {
        return res.status(400).json({ error: 'Cet email est déjà utilisé.' });
      }
      // Sinon on va le mettre à jour plus bas
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    if (userExists.rows.length === 0) {
      // Nouvel insertion
      await db.query(
        'INSERT INTO users (id, email, full_name, student_id, password_hash, branch, level, is_verified) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)',
        [uuidv4(), email, full_name, student_id, passwordHash, branch, level, true]
      );
    } else {
      // Mise à jour de l'existant
      await db.query(
        'UPDATE users SET full_name = $1, student_id = $2, password_hash = $3, branch = $4, level = $5, is_verified = $6 WHERE email = $7',
        [full_name, student_id, passwordHash, branch, level, true, email]
      );
    }

    res.json({ message: 'Inscription réussie !' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de l\'inscription' });
  }
};

// 2. Connexion Directe
exports.login = async (req, res) => {
  try {
    const { student_id_or_email, password } = req.body;

    const result = await db.query(
      'SELECT * FROM users WHERE email = $1 OR student_id = $1', 
      [student_id_or_email]
    );

    if (result.rows.length === 0) {
      return res.status(400).json({ error: 'Identifiants invalides' });
    }

    const user = result.rows[0];

    // Vérification du mot de passe
    if (!user.password_hash) {
      return res.status(400).json({ error: 'Compte non finalisé. Veuillez vous inscrire.' });
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(400).json({ error: 'Identifiants invalides' });
    }

    const token = jwt.sign(
      { id: user.id },
      process.env.JWT_SECRET,
      { expiresIn: '24h' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        full_name: user.full_name,
        email: user.email,
        student_id: user.student_id,
        level: user.level,
        profile_image: user.profile_image
      }
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur connexion' });
  }
};

// 3. Mettre à jour le profil (Nom, ID, Niveau, etc.)
exports.updateProfile = async (req, res) => {
  try {
    const { full_name, student_id, branch, level } = req.body;
    await db.query(
      'UPDATE users SET full_name = $1, student_id = $2, branch = $3, level = $4 WHERE id = $5',
      [full_name, student_id, branch, level, req.user.id]
    );

    const updated = await db.query('SELECT * FROM users WHERE id = $1', [req.user.id]);
    res.json({ message: 'Profil mis à jour', user: updated.rows[0] });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de la mise à jour' });
  }
};

// 4. Charger l'image de profil
exports.uploadImage = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({ error: 'Aucun fichier reçu' });
    }

    const imageUrl = `/uploads/${req.file.filename}`;
    await db.query('UPDATE users SET profile_image = $1 WHERE id = $2', [imageUrl, req.user.id]);

    res.json({ message: 'Image mise à jour', imageUrl });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'Erreur lors de l\'upload' });
  }
};

// Gardé pour la compatibilité (mais non utilisé dans le nouveau flux simple)
exports.sendCode = async (req, res) => res.status(410).json({ error: 'Cette méthode est obsolète.' });
exports.verifyCode = async (req, res) => res.status(410).json({ error: 'Cette méthode est obsolète.' });
