import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:image/image.dart' as img;
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/secure_file.dart';

class StorageService {
  static const String _filesDirName = 'secure_files';
  static const String _thumbnailsDirName = 'thumbnails';
  static const String _tempDirName = 'temp';
  static const String _filesListKey = 'files_list';
  
  late final Directory _appDir;
  late final Directory _filesDir;
  late final Directory _thumbnailsDir;
  late final Directory _tempDir;

  StorageService() {
    _initializeDirectories();
  }

  Future<void> _initializeDirectories() async {
    try {
      // Get app documents directory
      _appDir = await getApplicationDocumentsDirectory();
      
      // Create secure files directory
      _filesDir = Directory(path.join(_appDir.path, _filesDirName));
      if (!await _filesDir.exists()) {
        await _filesDir.create(recursive: true);
      }
      
      // Create thumbnails directory
      _thumbnailsDir = Directory(path.join(_appDir.path, _thumbnailsDirName));
      if (!await _thumbnailsDir.exists()) {
        await _thumbnailsDir.create(recursive: true);
      }
      
      // Create temp directory
      _tempDir = Directory(path.join(_appDir.path, _tempDirName));
      if (!await _tempDir.exists()) {
        await _tempDir.create(recursive: true);
      }
      
      // Set directory permissions (iOS/Android specific)
      await _setDirectoryPermissions();
      
    } catch (e) {
      debugPrint('Error initializing storage directories: $e');
    }
  }

  Future<void> _setDirectoryPermissions() async {
    try {
      // On Android, ensure directories are private
      if (Platform.isAndroid) {
        await _filesDir.setMode(0o700);
        await _thumbnailsDir.setMode(0o700);
        await _tempDir.setMode(0o700);
      }
    } catch (e) {
      debugPrint('Error setting directory permissions: $e');
    }
  }

  // Save encrypted file
  Future<String> saveEncryptedFile({
    required String fileId,
    required Uint8List encryptedContent,
    required FileType fileType,
  }) async {
    try {
      final extension = _getFileExtension(fileType);
      final fileName = '$fileId$extension';
      final filePath = path.join(_filesDir.path, fileName);
      
      final file = File(filePath);
      await file.writeAsBytes(encryptedContent);
      
      return filePath;
    } catch (e) {
      throw Exception('Fehler beim Speichern der verschlüsselten Datei: $e');
    }
  }

  // Save encrypted note
  Future<String> saveEncryptedNote({
    required String fileId,
    required String encryptedContent,
    required String title,
  }) async {
    try {
      final fileName = '$fileId.txt';
      final filePath = path.join(_filesDir.path, fileName);
      
      final file = File(filePath);
      await file.writeAsString(encryptedContent);
      
      return filePath;
    } catch (e) {
      throw Exception('Fehler beim Speichern der verschlüsselten Notiz: $e');
    }
  }

  // Generate thumbnail for photos and videos
  Future<String?> generateThumbnail({
    required String fileId,
    required String originalPath,
    required FileType fileType,
  }) async {
    try {
      if (fileType == FileType.photo) {
        return await _generatePhotoThumbnail(fileId, originalPath);
      } else if (fileType == FileType.video) {
        return await _generateVideoThumbnail(fileId, originalPath);
      }
      return null;
    } catch (e) {
      debugPrint('Error generating thumbnail: $e');
      return null;
    }
  }

  Future<String?> _generatePhotoThumbnail(String fileId, String imagePath) async {
    try {
      // Read image file
      final imageBytes = await File(imagePath).readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) return null;
      
      // Resize image to thumbnail size
      const thumbnailSize = 200;
      final thumbnail = img.copyResize(
        image,
        width: thumbnailSize,
        height: thumbnailSize,
        interpolation: img.Interpolation.linear,
      );
      
      // Save thumbnail
      final thumbnailPath = path.join(_thumbnailsDir.path, '${fileId}_thumb.jpg');
      final thumbnailFile = File(thumbnailPath);
      await thumbnailFile.writeAsBytes(img.encodeJpg(thumbnail, quality: 80));
      
      return thumbnailPath;
    } catch (e) {
      debugPrint('Error generating photo thumbnail: $e');
      return null;
    }
  }

  Future<String?> _generateVideoThumbnail(String fileId, String videoPath) async {
    try {
      final thumbnailPath = path.join(_thumbnailsDir.path, '${fileId}_thumb.jpg');
      
      final thumbnail = await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: thumbnailPath,
        imageFormat: ImageFormat.JPEG,
        maxHeight: 200,
        quality: 80,
      );
      
      return thumbnail;
    } catch (e) {
      debugPrint('Error generating video thumbnail: $e');
      return null;
    }
  }

  // Load files list from local storage
  Future<List<SecureFile>> loadLocalFiles() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filesJson = prefs.getStringList(_filesListKey) ?? [];
      
      final files = <SecureFile>[];
      for (final fileJson in filesJson) {
        try {
          final file = SecureFile.fromJson(fileJson);
          
          // Verify file still exists
          if (await File(file.localPath).exists()) {
            files.add(file);
          }
        } catch (e) {
          debugPrint('Error parsing file: $e');
        }
      }
      
      return files;
    } catch (e) {
      debugPrint('Error loading local files: $e');
      return [];
    }
  }

  // Save files list to local storage
  Future<void> saveFiles(List<SecureFile> files) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final filesJson = files.map((f) => f.toJson()).toList();
      await prefs.setStringList(_filesListKey, filesJson);
    } catch (e) {
      debugPrint('Error saving files list: $e');
    }
  }

  // Delete file from storage
  Future<void> deleteFile(String fileId) async {
    try {
      // Find and delete the encrypted file
      final files = await loadLocalFiles();
      final file = files.firstWhere((f) => f.id == fileId);
      
      if (file.localPath.isNotEmpty) {
        final encryptedFile = File(file.localPath);
        if (await encryptedFile.exists()) {
          await encryptedFile.delete();
        }
      }
      
      // Delete thumbnail if exists
      if (file.thumbnailPath != null) {
        final thumbnailFile = File(file.thumbnailPath!);
        if (await thumbnailFile.exists()) {
          await thumbnailFile.delete();
        }
      }
      
      // Remove from files list
      files.removeWhere((f) => f.id == fileId);
      await saveFiles(files);
      
    } catch (e) {
      debugPrint('Error deleting file: $e');
    }
  }

  // Get file size
  Future<int> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // Get available storage space
  Future<Map<String, int>> getStorageInfo() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final appDirStat = await appDir.stat();
      
      // Get total available space (approximate)
      final tempDir = await getTemporaryDirectory();
      final tempDirStat = await tempDir.stat();
      
      return {
        'appUsed': appDirStat.size,
        'tempUsed': tempDirStat.size,
        'totalAvailable': 0, // Would need platform-specific implementation
      };
    } catch (e) {
      return {
        'appUsed': 0,
        'tempUsed': 0,
        'totalAvailable': 0,
      };
    }
  }

  // Clean up temporary files
  Future<void> cleanupTempFiles() async {
    try {
      if (await _tempDir.exists()) {
        final files = await _tempDir.list().toList();
        for (final file in files) {
          if (file is File) {
            await file.delete();
          }
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up temp files: $e');
    }
  }

  // Export file to external storage
  Future<String?> exportFile({
    required String fileId,
    required String originalFileName,
    required Uint8List decryptedContent,
  }) async {
    try {
      // Get external storage directory
      Directory? externalDir;
      if (Platform.isAndroid) {
        externalDir = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        externalDir = await getApplicationDocumentsDirectory();
      }
      
      if (externalDir == null) return null;
      
      // Create export directory
      final exportDir = Directory(path.join(externalDir.path, 'SecureFolder_Exports'));
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }
      
      // Save file with original name
      final exportPath = path.join(exportDir.path, originalFileName);
      final exportFile = File(exportPath);
      await exportFile.writeAsBytes(decryptedContent);
      
      return exportPath;
    } catch (e) {
      debugPrint('Error exporting file: $e');
      return null;
    }
  }

  // Import file from external storage
  Future<File?> importFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        // Copy to temp directory for processing
        final fileName = path.basename(filePath);
        final tempPath = path.join(_tempDir.path, fileName);
        final tempFile = File(tempPath);
        
        await file.copy(tempPath);
        return tempFile;
      }
      return null;
    } catch (e) {
      debugPrint('Error importing file: $e');
      return null;
    }
  }

  // Backup files to external storage
  Future<String?> backupFiles(List<SecureFile> files) async {
    try {
      // Get external storage directory
      Directory? externalDir;
      if (Platform.isAndroid) {
        externalDir = await getExternalStorageDirectory();
      } else if (Platform.isIOS) {
        externalDir = await getApplicationDocumentsDirectory();
      }
      
      if (externalDir == null) return null;
      
      // Create backup directory
      final backupDir = Directory(path.join(externalDir.path, 'SecureFolder_Backup'));
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      
      // Create backup timestamp
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
      final backupPath = path.join(backupDir.path, 'backup_$timestamp');
      final backupFileDir = Directory(backupPath);
      await backupFileDir.create();
      
      // Save files list
      final filesListPath = path.join(backupPath, 'files_list.json');
      final filesListFile = File(filesListPath);
      final filesJson = files.map((f) => f.toJson()).toList();
      await filesListFile.writeAsString(filesJson.toString());
      
      // Copy encrypted files
      for (final file in files) {
        if (file.localPath.isNotEmpty) {
          final sourceFile = File(file.localPath);
          if (await sourceFile.exists()) {
            final fileName = path.basename(file.localPath);
            final destPath = path.join(backupPath, fileName);
            await sourceFile.copy(destPath);
          }
        }
      }
      
      return backupPath;
    } catch (e) {
      debugPrint('Error backing up files: $e');
      return null;
    }
  }

  // Restore files from backup
  Future<List<SecureFile>> restoreFiles(String backupPath) async {
    try {
      final backupDir = Directory(backupPath);
      if (!await backupDir.exists()) {
        throw Exception('Backup-Verzeichnis nicht gefunden');
      }
      
      // Read files list
      final filesListPath = path.join(backupPath, 'files_list.json');
      final filesListFile = File(filesListPath);
      if (!await filesListFile.exists()) {
        throw Exception('Backup-Dateiliste nicht gefunden');
      }
      
      final filesJson = await filesListFile.readAsString();
      final files = <SecureFile>[];
      
      // Parse files list and restore files
      // This is a simplified implementation
      // In production, you'd want more robust parsing and validation
      
      return files;
    } catch (e) {
      debugPrint('Error restoring files: $e');
      return [];
    }
  }

  // Get file extension based on file type
  String _getFileExtension(FileType fileType) {
    switch (fileType) {
      case FileType.photo:
        return '.jpg';
      case FileType.video:
        return '.mp4';
      case FileType.audio:
        return '.m4a';
      case FileType.note:
        return '.txt';
      case FileType.document:
        return '.pdf';
      case FileType.other:
      default:
        return '.bin';
    }
  }

  // Check if file is supported
  bool isFileSupported(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    const supportedExtensions = [
      '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', // Images
      '.mp4', '.avi', '.mov', '.mkv', '.wmv', '.flv', // Videos
      '.mp3', '.m4a', '.wav', '.aac', '.ogg', '.flac', // Audio
      '.txt', '.md', '.rtf', // Text
      '.pdf', '.doc', '.docx', '.xls', '.xlsx', // Documents
    ];
    
    return supportedExtensions.contains(extension);
  }

  // Get file type from path
  FileType getFileTypeFromPath(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    
    if (['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp'].contains(extension)) {
      return FileType.photo;
    } else if (['.mp4', '.avi', '.mov', '.mkv', '.wmv', '.flv'].contains(extension)) {
      return FileType.video;
    } else if (['.mp3', '.m4a', '.wav', '.aac', '.ogg', '.flac'].contains(extension)) {
      return FileType.audio;
    } else if (['.txt', '.md', '.rtf'].contains(extension)) {
      return FileType.note;
    } else if (['.pdf', '.doc', '.docx', '.xls', '.xlsx'].contains(extension)) {
      return FileType.document;
    } else {
      return FileType.other;
    }
  }

  // Clear all stored data (for logout)
  Future<void> clearAllData() async {
    try {
      // Clear files list
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_filesListKey);
      
      // Clear all directories
      if (await _filesDir.exists()) {
        await _filesDir.delete(recursive: true);
      }
      if (await _thumbnailsDir.exists()) {
        await _thumbnailsDir.delete(recursive: true);
      }
      if (await _tempDir.exists()) {
        await _tempDir.delete(recursive: true);
      }
      
      // Recreate directories
      await _initializeDirectories();
      
    } catch (e) {
      debugPrint('Error clearing all data: $e');
    }
  }
}