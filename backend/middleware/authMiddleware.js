const jwt = require('jsonwebtoken');

module.exports = (req, res, next) => {
  // 1. Récupérer le token du header
  const token = req.header('x-auth-token') || req.header('Authorization')?.split(' ')[1];

  if (!token) {
    return res.status(401).json({ error: 'Pas de token, accès refusé' });
  }

  try {
    // 2. Vérifier le token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    req.user = decoded;
    next();
  } catch (err) {
    res.status(401).json({ error: 'Token invalide' });
  }
};
