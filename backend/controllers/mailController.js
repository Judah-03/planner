const nodemailer = require('nodemailer');
require('dotenv').config();

let transporter;

async function getTransporter() {
  if (transporter) return transporter;

  const user = process.env.EMAIL_USER;
  const pass = process.env.EMAIL_PASS;

  if (user && pass && pass !== 'ton_app_password' && pass.trim() !== '') {
    transporter = nodemailer.createTransport({
      service: process.env.EMAIL_SERVICE || 'gmail',
      auth: { user, pass }
    });
    console.log("Transporter SMTP Gmail configuré avec succès.");
  } else {
    console.log("Aucun mot de passe email valide configuré. Utilisation d'un compte de test Ethereal...");
    const testAccount = await nodemailer.createTestAccount();
    transporter = nodemailer.createTransport({
      host: 'smtp.ethereal.email',
      port: 587,
      secure: false,
      auth: {
        user: testAccount.user,
        pass: testAccount.pass
      }
    });
    console.log("Compte Ethereal temporaire créé:", testAccount.user);
  }
  return transporter;
}

exports.sendMail = async (req, res) => {
  try {
    const { to, subject, message } = req.body;
    
    if (!to || !subject || !message) {
      return res.status(400).json({ error: 'Tous les champs sont requis.' });
    }

    const currentTransporter = await getTransporter();

    const mailOptions = {
      from: process.env.EMAIL_USER || 'plannerj@emit.mg',
      to: to,
      subject: `[PlannerJ] - ${subject}`,
      text: message,
      html: `
        <div style="font-family: Arial, sans-serif; padding: 20px; color: #333;">
          <h2 style="color: #4F46E5;">Message de l'application PlannerJ</h2>
          <p><strong>Sujet :</strong> ${subject}</p>
          <hr />
          <p style="white-space: pre-wrap;">${message}</p>
          <br />
          <p style="font-size: 12px; color: #888;">Cet email a été envoyé automatiquement depuis l'application ExamPlannerJ.</p>
        </div>
      `
    };

    const info = await currentTransporter.sendMail(mailOptions);
    
    const previewUrl = nodemailer.getTestMessageUrl(info);
    if (previewUrl) {
      console.log("-----------------------------------------");
      console.log("Email de test envoyé avec Ethereal !");
      console.log("Prévisualiser l'email ici : " + previewUrl);
      console.log("-----------------------------------------");
    }
    
    res.status(200).json({ message: 'Email envoyé avec succès.', previewUrl });
  } catch (error) {
    console.error('Erreur lors de l\'envoi de l\'email:', error);
    res.status(500).json({ error: 'Erreur lors de l\'envoi de l\'email.' });
  }
};
