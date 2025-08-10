import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:secure_folder/models/secure_file.dart';
import 'package:secure_folder/services/encryption_service.dart';

class FileProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final EncryptionService _encryptionService = EncryptionService();
  final ImagePicker _imagePicker = ImagePicker();
  final Uuid _uuid = const Uuid();

  List<SecureFile> _files = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _currentUserId;
  bool _cloudSyncEnabled = true;

  // Getters
  List<SecureFile> get files => _files;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get cloudSyncEnabled => _cloudSyncEnabled;

  // Filter files by type
  List<SecureFile> get photos => _files.where((f) => f.type == FileType.photo).toList();
  List<SecureFile> get videos => _files.where((f) => f.type == FileType.video).toList();
  List<SecureFile> get documents => _files.where((f) => f.type == FileType.document).toList();
  List<SecureFile> get notes => _files.where((f) => f.type == FileType.note).toList();
  List<SecureFile> get audioFiles => _files.where((f) => f.type == FileType.audio).toList();

  // Statistics
  int get totalFiles => _files.length;
  int get totalSize => _files.fold(0, (sum, file) => sum + file.size);
  String get formattedTotalSize => _formatBytes(totalSize);

  // Initialize for user
  Future<void> initialize(String userId) async {
    _currentUserId = userId;
    await _encryptionService.loadUserKey(userId);
    await loadFiles();
  }

  // Load files from local storage and cloud
  Future<void> loadFiles() async {
    if (_currentUserId == null) return;

    try {
      _setLoading(true);
      _clearError();

      // Load from Firestore
      final querySnapshot = await _firestore
          .collection('files')
          .where('userId', isEqualTo: _currentUserId)
          .orderBy('createdAt', descending: true)
          .get();

      _files = querySnapshot.docs
          .map((doc) => SecureFile.fromMap(doc.data()))
          .toList();

      notifyListeners();
    } catch (e) {
      _setError('Fehler beim Laden der Dateien: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Upload file from gallery
  Future<bool> uploadFromGallery({bool isVideo = false}) async {
    try {
      final XFile? file = isVideo
          ? await _imagePicker.pickVideo(source: ImageSource.gallery)
          : await _imagePicker.pickImage(source: ImageSource.gallery);

      if (file != null) {
        return await _processFile(
          File(file.path),
          isVideo ? FileType.video : FileType.photo,
        );
      }
      return false;
    } catch (e) {
      _setError('Fehler beim Auswählen der Datei: $e');
      return false;
    }
  }

  // Upload file from camera
  Future<bool> uploadFromCamera({bool isVideo = false}) async {
    try {
      final XFile? file = isVideo
          ? await _imagePicker.pickVideo(source: ImageSource.camera)
          : await _imagePicker.pickImage(source: ImageSource.camera);

      if (file != null) {
        return await _processFile(
          File(file.path),
          isVideo ? FileType.video : FileType.photo,
        );
      }
      return false;
    } catch (e) {
      _setError('Fehler beim Aufnehmen: $e');
      return false;
    }
  }

  // Upload document
  Future<bool> uploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return await _processFile(
          File(result.files.single.path!),
          FileType.document,
        );
      }
      return false;
    } catch (e) {
      _setError('Fehler beim Auswählen des Dokuments: $e');
      return false;
    }
  }

  // Create note
  Future<bool> createNote(String title, String content) async {
    if (_currentUserId == null) return false;

    try {
      _setLoading(true);
      _clearError();

      final fileId = _uuid.v4();
      final now = DateTime.now();

      // Encrypt content
      final encryptedContent = _encryptionService.encryptText(content);
      final encryptedTitle = _encryptionService.encryptText(title);

      final note = SecureNote(
        id: fileId,
        name: title,
        encryptedName: encryptedTitle,
        content: content,
        encryptedContent: encryptedContent,
        size: content.length,
        createdAt: now,
        modifiedAt: now,
        userId: _currentUserId!,
      );

      // Save to local storage
      await _saveNoteLocally(note);

      // Save to Firestore
      await _firestore.collection('files').doc(fileId).set(note.toMap());

      _files.insert(0, note);
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Fehler beim Erstellen der Notiz: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update note
  Future<bool> updateNote(SecureNote note, String newContent) async {
    try {
      _setLoading(true);
      _clearError();

      // Encrypt new content
      final encryptedContent = _encryptionService.encryptText(newContent);

      final updatedNote = SecureNote(
        id: note.id,
        name: note.name,
        encryptedName: note.encryptedName,
        content: newContent,
        encryptedContent: encryptedContent,
        localPath: note.localPath,
        cloudPath: note.cloudPath,
        size: newContent.length,
        createdAt: note.createdAt,
        modifiedAt: DateTime.now(),
        userId: note.userId,
        metadata: note.metadata,
      );

      // Update in Firestore
      await _firestore.collection('files').doc(note.id).update(updatedNote.toMap());

      // Update local list
      final index = _files.indexWhere((f) => f.id == note.id);
      if (index != -1) {
        _files[index] = updatedNote;
        notifyListeners();
      }

      return true;
    } catch (e) {
      _setError('Fehler beim Aktualisieren der Notiz: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Process and encrypt file
  Future<bool> _processFile(File file, FileType type) async {
    if (_currentUserId == null) return false;

    try {
      _setLoading(true);
      _clearError();

      final fileId = _uuid.v4();
      final originalFileName = file.path.split('/').last;
      final secureFileName = _encryptionService.generateSecureFilename(originalFileName);
      
      // Get app directory
      final appDir = await getApplicationDocumentsDirectory();
      final secureDir = Directory('${appDir.path}/secure_files');
      if (!await secureDir.exists()) {
        await secureDir.create(recursive: true);
      }

      // Encrypt and save file locally
      final encryptedFilePath = '${secureDir.path}/$secureFileName';
      final encryptedFile = await _encryptionService.encryptFile(file, encryptedFilePath);

      // Generate checksum
      final checksum = await _encryptionService.generateFileChecksum(encryptedFile);

      // Encrypt filename
      final encryptedFileName = _encryptionService.encryptText(originalFileName);

      final secureFile = SecureFile(
        id: fileId,
        name: originalFileName,
        encryptedName: encryptedFileName,
        type: type,
        localPath: encryptedFilePath,
        size: await file.length(),
        createdAt: DateTime.now(),
        modifiedAt: DateTime.now(),
        userId: _currentUserId!,
        metadata: {
          'checksum': checksum,
          'originalSize': await file.length(),
        },
      );

      // Save to Firestore
      await _firestore.collection('files').doc(fileId).set(secureFile.toMap());

      // Upload to cloud storage if enabled
      if (_cloudSyncEnabled) {
        await _uploadToCloud(secureFile, encryptedFile);
      }

      _files.insert(0, secureFile);
      notifyListeners();

      // Delete original file
      try {
        await file.delete();
      } catch (e) {
        // Ignore if can't delete original
      }

      return true;
    } catch (e) {
      _setError('Fehler beim Verarbeiten der Datei: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Upload file to cloud storage
  Future<void> _uploadToCloud(SecureFile file, File encryptedFile) async {
    try {
      final ref = _storage.ref().child('files/${_currentUserId}/${file.id}');
      final uploadTask = ref.putFile(encryptedFile);
      
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Update file with cloud path
      final updatedFile = file.copyWith(
        cloudPath: downloadUrl,
        isSynced: true,
      );

      await _firestore.collection('files').doc(file.id).update(updatedFile.toMap());

      // Update local list
      final index = _files.indexWhere((f) => f.id == file.id);
      if (index != -1) {
        _files[index] = updatedFile;
        notifyListeners();
      }
    } catch (e) {
      // Cloud upload failed, but file is still saved locally
      debugPrint('Cloud upload failed: $e');
    }
  }

  // Delete file
  Future<bool> deleteFile(SecureFile file) async {
    try {
      _setLoading(true);
      _clearError();

      // Delete from Firestore
      await _firestore.collection('files').doc(file.id).delete();

      // Delete from cloud storage
      if (file.cloudPath != null) {
        try {
          final ref = _storage.ref().child('files/${_currentUserId}/${file.id}');
          await ref.delete();
        } catch (e) {
          // Ignore if cloud file doesn't exist
        }
      }

      // Delete local file
      if (file.localPath != null) {
        try {
          final localFile = File(file.localPath!);
          if (await localFile.exists()) {
            await localFile.delete();
          }
        } catch (e) {
          // Ignore if local file doesn't exist
        }
      }

      _files.removeWhere((f) => f.id == file.id);
      notifyListeners();

      return true;
    } catch (e) {
      _setError('Fehler beim Löschen der Datei: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Get decrypted file for viewing
  Future<File?> getDecryptedFile(SecureFile file) async {
    try {
      if (file.localPath == null) return null;

      final encryptedFile = File(file.localPath!);
      if (!await encryptedFile.exists()) return null;

      // Create temporary file for decryption
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${file.name}');

      return await _encryptionService.decryptFile(encryptedFile, tempFile.path);
    } catch (e) {
      _setError('Fehler beim Entschlüsseln der Datei: $e');
      return null;
    }
  }

  // Save note content locally
  Future<void> _saveNoteLocally(SecureNote note) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final notesDir = Directory('${appDir.path}/notes');
      if (!await notesDir.exists()) {
        await notesDir.create(recursive: true);
      }

      final noteFile = File('${notesDir.path}/${note.id}.txt');
      await noteFile.writeAsString(note.encryptedContent);
    } catch (e) {
      // Ignore local save errors
    }
  }

  // Sync with cloud
  Future<void> syncWithCloud() async {
    if (!_cloudSyncEnabled || _currentUserId == null) return;

    try {
      _setLoading(true);
      await loadFiles(); // Reload from cloud
    } catch (e) {
      _setError('Fehler bei der Synchronisierung: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Toggle cloud sync
  Future<void> toggleCloudSync(bool enabled) async {
    _cloudSyncEnabled = enabled;
    notifyListeners();

    // Save preference
    try {
      await _firestore.collection('users').doc(_currentUserId).update({
        'settings.cloudSyncEnabled': enabled,
      });
    } catch (e) {
      // Ignore settings save error
    }
  }

  // Search files
  List<SecureFile> searchFiles(String query) {
    if (query.isEmpty) return _files;

    return _files.where((file) {
      return file.name.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // Get files by date range
  List<SecureFile> getFilesByDateRange(DateTime start, DateTime end) {
    return _files.where((file) {
      return file.createdAt.isAfter(start) && file.createdAt.isBefore(end);
    }).toList();
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}