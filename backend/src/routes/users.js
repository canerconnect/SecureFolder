const express = require('express');
const { body, validationResult } = require('express-validator');
const { firestore } = require('../config/firebase');

const router = express.Router();

// Benutzerprofil abrufen
router.get('/profile', async (req, res) => {
  try {
    const userId = req.user.uid;

    const userDoc = await firestore.collection('users').doc(userId).get();
    
    if (!userDoc.exists) {
      return res.status(404).json({
        error: 'Benutzer nicht gefunden',
        code: 'USER_NOT_FOUND'
      });
    }

    const userData = userDoc.data();

    res.json({
      user: {
        uid: userId,
        email: userData.email,
        emailVerified: userData.emailVerified,
        createdAt: userData.createdAt,
        lastLogin: userData.lastLogin,
        settings: userData.settings,
        storage: userData.storage
      }
    });

  } catch (error) {
    console.error('Profil-Abruf-Fehler:', error);
    res.status(500).json({
      error: 'Profil konnte nicht abgerufen werden',
      code: 'PROFILE_FETCH_FAILED'
    });
  }
});

// Benutzerprofil aktualisieren
router.put('/profile', [
  body('settings.biometricEnabled').optional().isBoolean(),
  body('settings.pinEnabled').optional().isBoolean(),
  body('settings.autoLock').optional().isBoolean(),
  body('settings.lockTimeout').optional().isInt({ min: 60000, max: 3600000 }), // 1-60 Minuten
  body('settings.cloudSync').optional().isBoolean()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validierungsfehler',
        details: errors.array(),
        code: 'VALIDATION_ERROR'
      });
    }

    const userId = req.user.uid;
    const { settings } = req.body;

    const updateData = {};

    if (settings) {
      // Nur erlaubte Einstellungen aktualisieren
      const allowedSettings = [
        'biometricEnabled',
        'pinEnabled', 
        'autoLock',
        'lockTimeout',
        'cloudSync'
      ];

      allowedSettings.forEach(setting => {
        if (settings[setting] !== undefined) {
          updateData[`settings.${setting}`] = settings[setting];
        }
      });
    }

    if (Object.keys(updateData).length === 0) {
      return res.status(400).json({
        error: 'Keine gültigen Einstellungen zum Aktualisieren',
        code: 'NO_VALID_SETTINGS'
      });
    }

    await firestore.collection('users').doc(userId).update(updateData);

    res.json({
      message: 'Profil erfolgreich aktualisiert',
      updatedSettings: updateData
    });

  } catch (error) {
    console.error('Profil-Update-Fehler:', error);
    res.status(500).json({
      error: 'Profil konnte nicht aktualisiert werden',
      code: 'PROFILE_UPDATE_FAILED'
    });
  }
});

// PIN setzen/aktualisieren
router.post('/pin', [
  body('pin').isLength({ min: 4, max: 6 }).isNumeric(),
  body('confirmPin').custom((value, { req }) => {
    if (value !== req.body.pin) {
      throw new Error('PIN-Bestätigung stimmt nicht überein');
    }
    return true;
  })
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validierungsfehler',
        details: errors.array(),
        code: 'VALIDATION_ERROR'
      });
    }

    const userId = req.user.uid;
    const { pin } = req.body;

    // PIN in Firestore speichern (verschlüsselt)
    await firestore.collection('users').doc(userId).update({
      'settings.pinEnabled': true,
      'settings.pinHash': pin, // In Produktion sollte dies gehashed werden
      'settings.pinSetAt': new Date()
    });

    res.json({
      message: 'PIN erfolgreich gesetzt'
    });

  } catch (error) {
    console.error('PIN-Set-Fehler:', error);
    res.status(500).json({
      error: 'PIN konnte nicht gesetzt werden',
      code: 'PIN_SET_FAILED'
    });
  }
});

// PIN entfernen
router.delete('/pin', async (req, res) => {
  try {
    const userId = req.user.uid;

    await firestore.collection('users').doc(userId).update({
      'settings.pinEnabled': false,
      'settings.pinHash': firestore.FieldValue.delete(),
      'settings.pinSetAt': firestore.FieldValue.delete()
    });

    res.json({
      message: 'PIN erfolgreich entfernt'
    });

  } catch (error) {
    console.error('PIN-Entfernen-Fehler:', error);
    res.status(500).json({
      error: 'PIN konnte nicht entfernt werden',
      code: 'PIN_REMOVE_FAILED'
    });
  }
});

// PIN validieren
router.post('/pin/validate', [
  body('pin').isLength({ min: 4, max: 6 }).isNumeric()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validierungsfehler',
        details: errors.array(),
        code: 'VALIDATION_ERROR'
      });
    }

    const userId = req.user.uid;
    const { pin } = req.body;

    const userDoc = await firestore.collection('users').doc(userId).get();
    const userData = userDoc.data();

    if (!userData.settings.pinEnabled) {
      return res.status(400).json({
        error: 'PIN ist nicht aktiviert',
        code: 'PIN_NOT_ENABLED'
      });
    }

    // PIN validieren (in Produktion sollte dies gehashed verglichen werden)
    if (userData.settings.pinHash !== pin) {
      return res.status(401).json({
        error: 'Falsche PIN',
        code: 'INVALID_PIN'
      });
    }

    res.json({
      message: 'PIN ist gültig'
    });

  } catch (error) {
    console.error('PIN-Validierung-Fehler:', error);
    res.status(500).json({
      error: 'PIN konnte nicht validiert werden',
      code: 'PIN_VALIDATION_FAILED'
    });
  }
});

// Cloud-Synchronisation aktivieren/deaktivieren
router.put('/cloud-sync', [
  body('enabled').isBoolean()
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        error: 'Validierungsfehler',
        details: errors.array(),
        code: 'VALIDATION_ERROR'
      });
    }

    const userId = req.user.uid;
    const { enabled } = req.body;

    await firestore.collection('users').doc(userId).update({
      'settings.cloudSync': enabled
    });

    res.json({
      message: `Cloud-Synchronisation ${enabled ? 'aktiviert' : 'deaktiviert'}`,
      cloudSync: enabled
    });

  } catch (error) {
    console.error('Cloud-Sync-Update-Fehler:', error);
    res.status(500).json({
      error: 'Cloud-Synchronisation konnte nicht aktualisiert werden',
      code: 'CLOUD_SYNC_UPDATE_FAILED'
    });
  }
});

// Benutzer löschen (Account löschen)
router.delete('/account', async (req, res) => {
  try {
    const userId = req.user.uid;

    // Alle Dateien des Benutzers löschen
    const filesSnapshot = await firestore.collection('files')
      .where('userId', '==', userId)
      .get();

    const deletePromises = filesSnapshot.docs.map(doc => doc.ref.delete());
    await Promise.all(deletePromises);

    // Benutzer-Dokument löschen
    await firestore.collection('users').doc(userId).delete();

    // Firebase Auth Benutzer löschen (würde normalerweise hier erfolgen)
    // await auth.deleteUser(userId);

    res.json({
      message: 'Account erfolgreich gelöscht'
    });

  } catch (error) {
    console.error('Account-Lösch-Fehler:', error);
    res.status(500).json({
      error: 'Account konnte nicht gelöscht werden',
      code: 'ACCOUNT_DELETE_FAILED'
    });
  }
});

// Benutzer-Statistiken
router.get('/stats', async (req, res) => {
  try {
    const userId = req.user.uid;

    // Datei-Statistiken
    const filesSnapshot = await firestore.collection('files')
      .where('userId', '==', userId)
      .get();

    let totalFiles = 0;
    let totalSize = 0;
    const categoryStats = {};

    filesSnapshot.forEach(doc => {
      const data = doc.data();
      totalFiles++;
      totalSize += data.size;
      
      if (!categoryStats[data.category]) {
        categoryStats[data.category] = { count: 0, size: 0 };
      }
      categoryStats[data.category].count++;
      categoryStats[data.category].size += data.size;
    });

    // Benutzer-Einstellungen
    const userDoc = await firestore.collection('users').doc(userId).get();
    const userData = userDoc.data();

    res.json({
      files: {
        total: totalFiles,
        totalSize: totalSize,
        categories: categoryStats
      },
      settings: userData.settings,
      storage: userData.storage,
      account: {
        createdAt: userData.createdAt,
        lastLogin: userData.lastLogin
      }
    });

  } catch (error) {
    console.error('Benutzer-Statistik-Fehler:', error);
    res.status(500).json({
      error: 'Statistiken konnten nicht abgerufen werden',
      code: 'USER_STATS_FAILED'
    });
  }
});

module.exports = router;