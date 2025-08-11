const express = require('express');
const multer = require('multer');
const { body, validationResult } = require('express-validator');
const { firestore, bucket } = require('../config/firebase');
const encryption = require('../utils/encryption');
const path = require('path');

const router = express.Router();

// Multer Konfiguration für Datei-Uploads
const storage = multer.memoryStorage();
const upload = multer({
  storage: storage,
  limits: {
    fileSize: parseInt(process.env.MAX_FILE_SIZE) || 100 * 1024 * 1024, // 100MB
  },
  fileFilter: (req, file, cb) => {
    // Erlaubte Dateitypen prüfen
    const allowedTypes = (process.env.ALLOWED_FILE_TYPES || 'image/*,video/*,audio/*,text/*').split(',');
    const isAllowed = allowedTypes.some(type => {
      if (type.includes('*')) {
        const baseType = type.split('/')[0];
        return file.mimetype.startsWith(baseType);
      }
      return file.mimetype === type;
    });

    if (isAllowed) {
      cb(null, true);
    } else {
      cb(new Error('Dateityp nicht erlaubt'), false);
    }
  }
});

// Datei-Upload
router.post('/upload', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        error: 'Keine Datei bereitgestellt',
        code: 'NO_FILE'
      });
    }

    const { originalname, mimetype, size, buffer } = req.file;
    const { category, description, tags } = req.body;
    const userId = req.user.uid;

    // Datei verschlüsseln
    const encryptedData = encryption.encrypt(buffer.toString('base64'));
    const encryptedFileName = encryption.encryptFileName(originalname);
    const fileHash = encryption.generateFileHash(buffer);

    // Datei in Firebase Storage hochladen
    const fileName = `${userId}/${Date.now()}_${encryptedFileName.encryptedName}`;
    const file = bucket.file(fileName);
    
    await file.save(Buffer.from(encryptedData.encrypted, 'hex'), {
      metadata: {
        contentType: mimetype,
        metadata: {
          originalName: encryptedFileName.encryptedName,
          encryption: JSON.stringify({
            iv: encryptedData.iv,
            salt: encryptedData.salt,
            tag: encryptedData.tag
          }),
          fileNameMetadata: JSON.stringify(encryptedFileName.metadata),
          hash: fileHash
        }
      }
    });

    // Datei-Metadaten in Firestore speichern
    const fileDoc = {
      userId: userId,
      originalName: originalname,
      encryptedName: encryptedFileName.encryptedName,
      fileNameMetadata: encryptedFileName.metadata,
      mimeType: mimetype,
      size: size,
      category: category || 'other',
      description: description || '',
      tags: tags ? tags.split(',').map(tag => tag.trim()) : [],
      hash: fileHash,
      encryption: {
        iv: encryptedData.iv,
        salt: encryptedData.salt,
        tag: encryptedData.tag
      },
      storagePath: fileName,
      uploadedAt: new Date(),
      lastModified: new Date(),
      isSynced: true,
      localPath: null
    };

    const docRef = await firestore.collection('files').add(fileDoc);

    // Benutzer-Speicher aktualisieren
    const userRef = firestore.collection('users').doc(userId);
    await userRef.update({
      'storage.used': firestore.FieldValue.increment(size)
    });

    res.status(201).json({
      message: 'Datei erfolgreich hochgeladen',
      file: {
        id: docRef.id,
        originalName: originalname,
        size: size,
        category: category,
        uploadedAt: fileDoc.uploadedAt
      }
    });

  } catch (error) {
    console.error('Datei-Upload-Fehler:', error);
    
    if (error.message.includes('Dateityp nicht erlaubt')) {
      return res.status(400).json({
        error: 'Dateityp nicht erlaubt',
        code: 'INVALID_FILE_TYPE'
      });
    }

    res.status(500).json({
      error: 'Datei-Upload fehlgeschlagen',
      code: 'UPLOAD_FAILED'
    });
  }
});

// Dateien auflisten
router.get('/', async (req, res) => {
  try {
    const userId = req.user.uid;
    const { category, search, page = 1, limit = 20 } = req.query;

    let query = firestore.collection('files').where('userId', '==', userId);

    // Kategorie-Filter
    if (category && category !== 'all') {
      query = query.where('category', '==', category);
    }

    // Suche
    if (search) {
      // Einfache Suche nach Dateinamen (könnte erweitert werden)
      query = query.orderBy('originalName').startAt(search).endAt(search + '\uf8ff');
    }

    // Paginierung
    const offset = (page - 1) * limit;
    query = query.orderBy('uploadedAt', 'desc').limit(parseInt(limit)).offset(offset);

    const snapshot = await query.get();
    const files = [];

    snapshot.forEach(doc => {
      const data = doc.data();
      files.push({
        id: doc.id,
        originalName: data.originalName,
        mimeType: data.mimeType,
        size: data.size,
        category: data.category,
        description: data.description,
        tags: data.tags,
        uploadedAt: data.uploadedAt,
        lastModified: data.lastModified,
        isSynced: data.isSynced
      });
    });

    // Gesamtanzahl für Paginierung
    const totalSnapshot = await firestore.collection('files')
      .where('userId', '==', userId)
      .count()
      .get();
    const total = totalSnapshot.data().count;

    res.json({
      files: files,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: total,
        pages: Math.ceil(total / limit)
      }
    });

  } catch (error) {
    console.error('Datei-Liste-Fehler:', error);
    res.status(500).json({
      error: 'Dateien konnten nicht abgerufen werden',
      code: 'FETCH_FAILED'
    });
  }
});

// Datei herunterladen
router.get('/:fileId/download', async (req, res) => {
  try {
    const { fileId } = req.params;
    const userId = req.user.uid;

    // Datei-Metadaten abrufen
    const fileDoc = await firestore.collection('files').doc(fileId).get();
    
    if (!fileDoc.exists) {
      return res.status(404).json({
        error: 'Datei nicht gefunden',
        code: 'FILE_NOT_FOUND'
      });
    }

    const fileData = fileDoc.data();
    
    if (fileData.userId !== userId) {
      return res.status(403).json({
        error: 'Zugriff verweigert',
        code: 'ACCESS_DENIED'
      });
    }

    // Datei aus Firebase Storage herunterladen
    const file = bucket.file(fileData.storagePath);
    const [fileBuffer] = await file.download();

    // Datei entschlüsseln
    const decryptedData = encryption.decrypt({
      encrypted: fileBuffer.toString('hex'),
      iv: fileData.encryption.iv,
      salt: fileData.encryption.salt,
      tag: fileData.encryption.tag
    });

    const decryptedBuffer = Buffer.from(decryptedData, 'base64');

    // Datei-Header setzen
    res.setHeader('Content-Type', fileData.mimeType);
    res.setHeader('Content-Disposition', `attachment; filename="${fileData.originalName}"`);
    res.setHeader('Content-Length', decryptedBuffer.length);

    res.send(decryptedBuffer);

  } catch (error) {
    console.error('Datei-Download-Fehler:', error);
    res.status(500).json({
      error: 'Datei-Download fehlgeschlagen',
      code: 'DOWNLOAD_FAILED'
    });
  }
});

// Datei löschen
router.delete('/:fileId', async (req, res) => {
  try {
    const { fileId } = req.params;
    const userId = req.user.uid;

    // Datei-Metadaten abrufen
    const fileDoc = await firestore.collection('files').doc(fileId).get();
    
    if (!fileDoc.exists) {
      return res.status(404).json({
        error: 'Datei nicht gefunden',
        code: 'FILE_NOT_FOUND'
      });
    }

    const fileData = fileDoc.data();
    
    if (fileData.userId !== userId) {
      return res.status(403).json({
        error: 'Zugriff verweigert',
        code: 'ACCESS_DENIED'
      });
    }

    // Datei aus Firebase Storage löschen
    const file = bucket.file(fileData.storagePath);
    await file.delete();

    // Metadaten aus Firestore löschen
    await firestore.collection('files').doc(fileId).delete();

    // Benutzer-Speicher aktualisieren
    const userRef = firestore.collection('users').doc(userId);
    await userRef.update({
      'storage.used': firestore.FieldValue.increment(-fileData.size)
    });

    res.json({
      message: 'Datei erfolgreich gelöscht'
    });

  } catch (error) {
    console.error('Datei-Lösch-Fehler:', error);
    res.status(500).json({
      error: 'Datei konnte nicht gelöscht werden',
      code: 'DELETE_FAILED'
    });
  }
});

// Datei aktualisieren
router.put('/:fileId', [
  body('description').optional().isString().trim(),
  body('category').optional().isString().trim(),
  body('tags').optional().isArray()
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

    const { fileId } = req.params;
    const userId = req.user.uid;
    const { description, category, tags } = req.body;

    // Datei-Metadaten abrufen
    const fileDoc = await firestore.collection('files').doc(fileId).get();
    
    if (!fileDoc.exists) {
      return res.status(404).json({
        error: 'Datei nicht gefunden',
        code: 'FILE_NOT_FOUND'
      });
    }

    const fileData = fileDoc.data();
    
    if (fileData.userId !== userId) {
      return res.status(403).json({
        error: 'Zugriff verweigert',
        code: 'ACCESS_DENIED'
      });
    }

    // Metadaten aktualisieren
    const updateData = {
      lastModified: new Date()
    };

    if (description !== undefined) updateData.description = description;
    if (category !== undefined) updateData.category = category;
    if (tags !== undefined) updateData.tags = tags;

    await firestore.collection('files').doc(fileId).update(updateData);

    res.json({
      message: 'Datei erfolgreich aktualisiert'
    });

  } catch (error) {
    console.error('Datei-Update-Fehler:', error);
    res.status(500).json({
      error: 'Datei konnte nicht aktualisiert werden',
      code: 'UPDATE_FAILED'
    });
  }
});

// Datei-Statistiken
router.get('/stats', async (req, res) => {
  try {
    const userId = req.user.uid;

    // Dateien nach Kategorie zählen
    const categories = ['photos', 'documents', 'videos', 'audio', 'other'];
    const stats = {};

    for (const category of categories) {
      const snapshot = await firestore.collection('files')
        .where('userId', '==', userId)
        .where('category', '==', category)
        .count()
        .get();
      
      stats[category] = snapshot.data().count;
    }

    // Gesamtgröße
    const totalSnapshot = await firestore.collection('files')
      .where('userId', '==', userId)
      .get();
    
    let totalSize = 0;
    totalSnapshot.forEach(doc => {
      totalSize += doc.data().size;
    });

    // Benutzer-Speicherlimits
    const userDoc = await firestore.collection('users').doc(userId).get();
    const userData = userDoc.data();
    const storageLimit = userData.storage.limit;

    res.json({
      stats: stats,
      storage: {
        used: totalSize,
        limit: storageLimit,
        percentage: Math.round((totalSize / storageLimit) * 100)
      }
    });

  } catch (error) {
    console.error('Statistik-Fehler:', error);
    res.status(500).json({
      error: 'Statistiken konnten nicht abgerufen werden',
      code: 'STATS_FAILED'
    });
  }
});

module.exports = router;