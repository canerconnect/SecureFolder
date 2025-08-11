const jwt = require('jsonwebtoken');
const { auth } = require('../config/firebase');

// JWT Token validieren
const authenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1]; // Bearer TOKEN

    if (!token) {
      return res.status(401).json({ 
        error: 'Zugriff verweigert. Kein Token bereitgestellt.',
        code: 'NO_TOKEN'
      });
    }

    // Firebase Token validieren
    try {
      const decodedToken = await auth.verifyIdToken(token);
      req.user = {
        uid: decodedToken.uid,
        email: decodedToken.email,
        emailVerified: decodedToken.email_verified,
        providerData: decodedToken.provider_data || []
      };
      next();
    } catch (firebaseError) {
      // Fallback: JWT Token validieren
      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        req.user = {
          uid: decoded.uid,
          email: decoded.email,
          emailVerified: decoded.emailVerified,
          providerData: decoded.providerData || []
        };
        next();
      } catch (jwtError) {
        return res.status(403).json({ 
          error: 'Ungültiger oder abgelaufener Token.',
          code: 'INVALID_TOKEN'
        });
      }
    }
  } catch (error) {
    return res.status(500).json({ 
      error: 'Authentifizierungsfehler.',
      code: 'AUTH_ERROR'
    });
  }
};

// Optional Authentication (für öffentliche Routen)
const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers['authorization'];
    const token = authHeader && authHeader.split(' ')[1];

    if (token) {
      try {
        const decodedToken = await auth.verifyIdToken(token);
        req.user = {
          uid: decodedToken.uid,
          email: decodedToken.email,
          emailVerified: decodedToken.email_verified,
          providerData: decodedToken.provider_data || []
        };
      } catch (firebaseError) {
        try {
          const decoded = jwt.verify(token, process.env.JWT_SECRET);
          req.user = {
            uid: decoded.uid,
            email: decoded.email,
            emailVerified: decoded.emailVerified,
            providerData: decoded.providerData || []
          };
        } catch (jwtError) {
          // Token ungültig, aber Route ist optional
          req.user = null;
        }
      }
    } else {
      req.user = null;
    }
    next();
  } catch (error) {
    req.user = null;
    next();
  }
};

// Admin-Berechtigung prüfen
const requireAdmin = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ 
      error: 'Zugriff verweigert. Authentifizierung erforderlich.',
      code: 'AUTH_REQUIRED'
    });
  }

  // Hier können Sie Ihre Admin-Logik implementieren
  // Beispiel: Prüfung auf spezielle Rolle oder E-Mail-Domain
  if (req.user.email && req.user.email.endsWith('@securefolder.com')) {
    next();
  } else {
    return res.status(403).json({ 
      error: 'Zugriff verweigert. Admin-Berechtigung erforderlich.',
      code: 'ADMIN_REQUIRED'
    });
  }
};

// E-Mail-Verifizierung prüfen
const requireEmailVerification = (req, res, next) => {
  if (!req.user) {
    return res.status(401).json({ 
      error: 'Zugriff verweigert. Authentifizierung erforderlich.',
      code: 'AUTH_REQUIRED'
    });
  }

  if (!req.user.emailVerified) {
    return res.status(403).json({ 
      error: 'E-Mail-Adresse muss verifiziert werden.',
      code: 'EMAIL_NOT_VERIFIED'
    });
  }

  next();
};

module.exports = {
  authenticateToken,
  optionalAuth,
  requireAdmin,
  requireEmailVerification
};