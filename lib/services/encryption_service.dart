import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static final EncryptionService _instance = EncryptionService._internal();
  factory EncryptionService() => _instance;
  EncryptionService._internal();

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late Encrypter _encrypter;
  late IV _iv;
  
  bool _isInitialized = false;

  // Initialize encryption for a user
  Future<void> initializeUserKey(String userId) async {
    try {
      // Check if user already has a key
      String? existingKey = await _secureStorage.read(key: 'encryption_key_$userId');
      
      if (existingKey == null) {
        // Generate new AES key
        final key = Key.fromSecureRandom(32); // 256-bit key
        existingKey = key.base64;
        
        // Store the key securely
        await _secureStorage.write(key: 'encryption_key_$userId', value: existingKey);
      }
      
      // Initialize encrypter
      final key = Key.fromBase64(existingKey);
      _encrypter = Encrypter(AES(key));
      _iv = IV.fromSecureRandom(16); // 128-bit IV
      
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize encryption: $e');
    }
  }

  // Load encryption key for existing user
  Future<void> loadUserKey(String userId) async {
    try {
      final existingKey = await _secureStorage.read(key: 'encryption_key_$userId');
      
      if (existingKey == null) {
        throw Exception('No encryption key found for user');
      }
      
      final key = Key.fromBase64(existingKey);
      _encrypter = Encrypter(AES(key));
      _iv = IV.fromSecureRandom(16);
      
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to load encryption key: $e');
    }
  }

  // Encrypt text data
  String encryptText(String plainText) {
    if (!_isInitialized) {
      throw Exception('Encryption service not initialized');
    }
    
    try {
      final encrypted = _encrypter.encrypt(plainText, iv: _iv);
      // Combine IV and encrypted data
      final combined = '${_iv.base64}:${encrypted.base64}';
      return base64.encode(utf8.encode(combined));
    } catch (e) {
      throw Exception('Failed to encrypt text: $e');
    }
  }

  // Decrypt text data
  String decryptText(String encryptedText) {
    if (!_isInitialized) {
      throw Exception('Encryption service not initialized');
    }
    
    try {
      final decodedData = utf8.decode(base64.decode(encryptedText));
      final parts = decodedData.split(':');
      
      if (parts.length != 2) {
        throw Exception('Invalid encrypted data format');
      }
      
      final iv = IV.fromBase64(parts[0]);
      final encrypted = Encrypted.fromBase64(parts[1]);
      
      return _encrypter.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw Exception('Failed to decrypt text: $e');
    }
  }

  // Encrypt file
  Future<File> encryptFile(File inputFile, String outputPath) async {
    if (!_isInitialized) {
      throw Exception('Encryption service not initialized');
    }
    
    try {
      final inputBytes = await inputFile.readAsBytes();
      final encryptedBytes = await _encryptBytes(inputBytes);
      
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(encryptedBytes);
      
      return outputFile;
    } catch (e) {
      throw Exception('Failed to encrypt file: $e');
    }
  }

  // Decrypt file
  Future<File> decryptFile(File inputFile, String outputPath) async {
    if (!_isInitialized) {
      throw Exception('Encryption service not initialized');
    }
    
    try {
      final inputBytes = await inputFile.readAsBytes();
      final decryptedBytes = await _decryptBytes(inputBytes);
      
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(decryptedBytes);
      
      return outputFile;
    } catch (e) {
      throw Exception('Failed to decrypt file: $e');
    }
  }

  // Encrypt bytes
  Future<Uint8List> _encryptBytes(Uint8List data) async {
    try {
      const chunkSize = 1024 * 1024; // 1MB chunks
      final encryptedChunks = <Uint8List>[];
      final iv = IV.fromSecureRandom(16);
      
      // Add IV at the beginning
      encryptedChunks.add(iv.bytes);
      
      for (int i = 0; i < data.length; i += chunkSize) {
        final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
        final chunk = data.sublist(i, end);
        
        final encrypted = _encrypter.encryptBytes(chunk, iv: iv);
        encryptedChunks.add(encrypted.bytes);
      }
      
      // Combine all chunks
      final totalLength = encryptedChunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
      final result = Uint8List(totalLength);
      
      int offset = 0;
      for (final chunk in encryptedChunks) {
        result.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }
      
      return result;
    } catch (e) {
      throw Exception('Failed to encrypt bytes: $e');
    }
  }

  // Decrypt bytes
  Future<Uint8List> _decryptBytes(Uint8List encryptedData) async {
    try {
      if (encryptedData.length < 16) {
        throw Exception('Invalid encrypted data - too short');
      }
      
      // Extract IV from the beginning
      final iv = IV(encryptedData.sublist(0, 16));
      final data = encryptedData.sublist(16);
      
      const chunkSize = 1024 * 1024 + 16; // Account for padding
      final decryptedChunks = <Uint8List>[];
      
      for (int i = 0; i < data.length; i += chunkSize) {
        final end = (i + chunkSize < data.length) ? i + chunkSize : data.length;
        final chunk = data.sublist(i, end);
        
        final encrypted = Encrypted(chunk);
        final decrypted = _encrypter.decryptBytes(encrypted, iv: iv);
        decryptedChunks.add(Uint8List.fromList(decrypted));
      }
      
      // Combine all chunks
      final totalLength = decryptedChunks.fold<int>(0, (sum, chunk) => sum + chunk.length);
      final result = Uint8List(totalLength);
      
      int offset = 0;
      for (final chunk in decryptedChunks) {
        result.setRange(offset, offset + chunk.length, chunk);
        offset += chunk.length;
      }
      
      return result;
    } catch (e) {
      throw Exception('Failed to decrypt bytes: $e');
    }
  }

  // Generate secure filename
  String generateSecureFilename(String originalFilename) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = Random.secure();
    final randomString = List.generate(16, (index) => random.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    
    final extension = originalFilename.split('.').last;
    return '${timestamp}_$randomString.$extension';
  }

  // Hash filename for storage
  String hashFilename(String filename) {
    final bytes = utf8.encode(filename);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Generate file checksum
  Future<String> generateFileChecksum(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      throw Exception('Failed to generate checksum: $e');
    }
  }

  // Verify file integrity
  Future<bool> verifyFileIntegrity(File file, String expectedChecksum) async {
    try {
      final actualChecksum = await generateFileChecksum(file);
      return actualChecksum == expectedChecksum;
    } catch (e) {
      return false;
    }
  }

  // Clear encryption data for user
  Future<void> clearUserData(String userId) async {
    try {
      await _secureStorage.delete(key: 'encryption_key_$userId');
      _isInitialized = false;
    } catch (e) {
      throw Exception('Failed to clear user data: $e');
    }
  }

  // Export encryption key (for backup purposes)
  Future<String?> exportKey(String userId) async {
    try {
      return await _secureStorage.read(key: 'encryption_key_$userId');
    } catch (e) {
      return null;
    }
  }

  // Import encryption key (for restore purposes)
  Future<bool> importKey(String userId, String keyData) async {
    try {
      await _secureStorage.write(key: 'encryption_key_$userId', value: keyData);
      await loadUserKey(userId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Generate key derivation from password (for additional security)
  String deriveKeyFromPassword(String password, String salt) {
    final passwordBytes = utf8.encode(password);
    final saltBytes = utf8.encode(salt);
    
    // Simple PBKDF2 implementation
    var key = passwordBytes + saltBytes;
    for (int i = 0; i < 10000; i++) {
      key = sha256.convert(key).bytes;
    }
    
    return base64.encode(key);
  }

  // Check if encryption is initialized
  bool get isInitialized => _isInitialized;
}