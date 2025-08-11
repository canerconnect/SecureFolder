const express = require('express');
const { body, validationResult } = require('express-validator');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { auth, firestore } = require('../config/firebase');
const { generateSecureToken } = require('../utils/encryption');

const router = express.Router();

// Validierung für Registrierung
const registerValidation = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Gültige E-Mail-Adresse erforderlich'),
  body('password')
    .isLength({ min: 8 })
    .withMessage('Passwort muss mindestens 8 Zeichen lang sein')
    .matches(/^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]/)
    .withMessage('Passwort muss Groß- und Kleinbuchstaben, Zahlen und Sonderzeichen enthalten'),
  body('confirmPassword')
    .custom((value, { req }) => {
      if (value !== req.body.password) {
        throw new Error('Passwort-Bestätigung stimmt nicht überein');
      }
      return true;
    })
];

// Validierung für Login
const loginValidation = [
  body('email')
    .isEmail()
    .normalizeEmail()
    .withMessage('Gültige E-Mail-Adresse erforderlich'),
  body('password')
    .notEmpty()
    .withMessage('Passwort erforderlich')
];

// Registrierung
router.post('/register', registerValidation, async (req, res) => {
  try {
    // Validierungsfehler prüfen
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validierungsfehler',
        details: errors.array(),
        code: 'VALIDATION_ERROR'
      });
    }

    const { email, password, confirmPassword } = req.body;

    // Passwort-Bestätigung prüfen
    if (password !== confirmPassword) {
      return res.status(400).json({
        error: 'Passwort-Bestätigung stimmt nicht überein',
        code: 'PASSWORD_MISMATCH'
      });
    }

    // Firebase Auth: Benutzer erstellen
    const userRecord = await auth.createUser({
      email: email,
      password: password,
      emailVerified: false
    });

    // Benutzer in Firestore speichern
    await firestore.collection('users').doc(userRecord.uid).set({
      email: email,
      createdAt: new Date(),
      lastLogin: new Date(),
      settings: {
        cloudSync: true,
        biometricEnabled: false,
        pinEnabled: false,
        autoLock: true,
        lockTimeout: 300000 // 5 Minuten
      },
      storage: {
        used: 0,
        limit: 1073741824 // 1GB
      }
    });

    // E-Mail-Verifikation senden
    await auth.generateEmailVerificationLink(email);

    // JWT Token generieren
    const token = jwt.sign(
      { 
        uid: userRecord.uid, 
        email: email,
        emailVerified: false 
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    res.status(201).json({
      message: 'Benutzer erfolgreich erstellt',
      user: {
        uid: userRecord.uid,
        email: email,
        emailVerified: false
      },
      token: token
    });

  } catch (error) {
    if (error.code === 'auth/email-already-in-use') {
      return res.status(400).json({
        error: 'E-Mail-Adresse wird bereits verwendet',
        code: 'EMAIL_IN_USE'
      });
    }

    if (error.code === 'auth/weak-password') {
      return res.status(400).json({
        error: 'Passwort ist zu schwach',
        code: 'WEAK_PASSWORD'
      });
    }

    console.error('Registrierungsfehler:', error);
    res.status(500).json({
      error: 'Registrierung fehlgeschlagen',
      code: 'REGISTRATION_FAILED'
    });
  }
});

// Login
router.post('/login', loginValidation, async (req, res) => {
  try {
    // Validierungsfehler prüfen
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validierungsfehler',
        details: errors.array(),
        code: 'VALIDATION_ERROR'
      });
    }

    const { email, password } = req.body;

    // Firebase Auth: Benutzer anmelden
    const signInResult = await auth.signInWithEmailAndPassword(email, password);
    const userRecord = signInResult.user;

    // JWT Token generieren
    const token = jwt.sign(
      { 
        uid: userRecord.uid, 
        email: userRecord.email,
        emailVerified: userRecord.emailVerified 
      },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    // Last login aktualisieren
    await firestore.collection('users').doc(userRecord.uid).update({
      lastLogin: new Date()
    });

    res.json({
      message: 'Anmeldung erfolgreich',
      user: {
        uid: userRecord.uid,
        email: userRecord.email,
        emailVerified: userRecord.emailVerified
      },
      token: token
    });

  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      return res.status(401).json({
        error: 'E-Mail oder Passwort falsch',
        code: 'INVALID_CREDENTIALS'
      });
    }

    if (error.code === 'auth/wrong-password') {
      return res.status(401).json({
        error: 'E-Mail oder Passwort falsch',
        code: 'INVALID_CREDENTIALS'
      });
    }

    if (error.code === 'auth/user-disabled') {
      return res.status(401).json({
        error: 'Benutzerkonto ist deaktiviert',
        code: 'USER_DISABLED'
      });
    }

    console.error('Anmeldungsfehler:', error);
    res.status(500).json({
      error: 'Anmeldung fehlgeschlagen',
      code: 'LOGIN_FAILED'
    });
  }
});

// Passwort zurücksetzen
router.post('/reset-password', [
  body('email').isEmail().normalizeEmail()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Gültige E-Mail-Adresse erforderlich',
        code: 'VALIDATION_ERROR'
      });
    }

    const { email } = req.body;

    // Passwort-Reset-Link generieren
    const resetLink = await auth.generatePasswordResetLink(email);

    // Hier würde normalerweise eine E-Mail gesendet werden
    // Für Demo-Zwecke geben wir den Link zurück
    res.json({
      message: 'Passwort-Reset-Link wurde generiert',
      resetLink: resetLink
    });

  } catch (error) {
    if (error.code === 'auth/user-not-found') {
      return res.status(404).json({
        error: 'Benutzer nicht gefunden',
        code: 'USER_NOT_FOUND'
      });
    }

    console.error('Passwort-Reset-Fehler:', error);
    res.status(500).json({
      error: 'Passwort-Reset fehlgeschlagen',
      code: 'PASSWORD_RESET_FAILED'
    });
  }
});

// E-Mail-Verifikation bestätigen
router.post('/verify-email', async (req, res) => {
  try {
    const { oobCode } = req.body;

    if (!oobCode) {
      return res.status(400).json({
        error: 'Verifikationscode erforderlich',
        code: 'VERIFICATION_CODE_REQUIRED'
      });
    }

    // E-Mail-Verifikation bestätigen
    await auth.confirmPasswordReset(oobCode, 'newPassword');

    res.json({
      message: 'E-Mail erfolgreich verifiziert'
    });

  } catch (error) {
    console.error('E-Mail-Verifikationsfehler:', error);
    res.status(500).json({
      error: 'E-Mail-Verifikation fehlgeschlagen',
      code: 'EMAIL_VERIFICATION_FAILED'
    });
  }
});

// Logout (Client-seitig, aber hier für Logging)
router.post('/logout', async (req, res) => {
  try {
    // Hier könnte Logging oder Session-Cleanup erfolgen
    res.json({
      message: 'Abmeldung erfolgreich'
    });
  } catch (error) {
    console.error('Abmeldungsfehler:', error);
    res.status(500).json({
      error: 'Abmeldung fehlgeschlagen',
      code: 'LOGOUT_FAILED'
    });
  }
});

module.exports = router;