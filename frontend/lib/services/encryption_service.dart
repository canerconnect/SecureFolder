import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class EncryptionService {
  static const String _keyStorageKey = 'encryption_key';
  static const String _saltStorageKey = 'encryption_salt';
  static const int _keyLength = 32; // 256 bits
  static const int _saltLength = 16;
  static const int _iterations = 100000;
  
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  late final Uint8List _encryptionKey;
  late final Uint8List _salt;

  EncryptionService() {
    _initializeEncryption();
  }

  Future<void> _initializeEncryption() async {
    try {
      // Try to load existing key and salt
      final storedKey = await _secureStorage.read(key: _keyStorageKey);
      final storedSalt = await _secureStorage.read(key: _saltStorageKey);
      
      if (storedKey != null && storedSalt != null) {
        _encryptionKey = base64Decode(storedKey);
        _salt = base64Decode(storedSalt);
      } else {
        // Generate new key and salt
        await _generateNewKey();
      }
    } catch (e) {
      // If anything goes wrong, generate new key
      await _generateNewKey();
    }
  }

  Future<void> _generateNewKey() async {
    try {
      // Generate random salt
      _salt = _generateRandomBytes(_saltLength);
      
      // Generate encryption key from device-specific data
      final deviceKey = await _getDeviceKey();
      _encryptionKey = await _deriveKey(deviceKey, _salt);
      
      // Store key and salt securely
      await _secureStorage.write(
        key: _keyStorageKey,
        value: base64Encode(_encryptionKey),
      );
      await _secureStorage.write(
        key: _saltStorageKey,
        value: base64Encode(_salt),
      );
    } catch (e) {
      // Fallback: use a simple key derivation
      final fallbackKey = 'SecureFolder_${DateTime.now().millisecondsSinceEpoch}';
      _salt = _generateRandomBytes(_saltLength);
      _encryptionKey = await _deriveKey(fallbackKey, _salt);
    }
  }

  Future<String> _getDeviceKey() async {
    // This would ideally use device-specific identifiers
    // For now, we'll use a combination of available data
    try {
      final deviceInfo = await _getDeviceInfo();
      return '${deviceInfo['platform']}_${deviceInfo['id']}_${deviceInfo['version']}';
    } catch (e) {
      return 'SecureFolder_Device_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<Map<String, String>> _getDeviceInfo() async {
    // Simplified device info - in production, use device_info_plus package
    return {
      'platform': Platform.isIOS ? 'iOS' : 'Android',
      'id': 'device_${DateTime.now().millisecondsSinceEpoch}',
      'version': '1.0.0',
    };
  }

  Future<Uint8List> _deriveKey(String password, Uint8List salt) async {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac(sha256),
      iterations: _iterations,
      bits: _keyLength * 8,
    );
    
    final key = pbkdf2.deriveKey(
      secretKey: Uint8List.fromUtf8(password),
      nonce: salt,
    );
    
    return key;
  }

  Uint8List _generateRandomBytes(int length) {
    final random = Random.secure();
    final bytes = Uint8List(length);
    for (int i = 0; i < length; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  }

  // File encryption
  Future<Uint8List> encryptFile(File file) async {
    try {
      final fileBytes = await file.readAsBytes();
      return await encryptData(fileBytes);
    } catch (e) {
      throw Exception('Fehler beim Verschlüsseln der Datei: $e');
    }
  }

  Future<Uint8List> encryptData(Uint8List data) async {
    try {
      // Generate random IV for this encryption
      final iv = _generateRandomBytes(16);
      
      // Create encryptor
      final encrypter = Encrypter(AES(_encryptionKey));
      final encrypted = encrypter.encrypt(data, iv: IV(iv));
      
      // Combine IV and encrypted data
      final result = Uint8List(iv.length + encrypted.bytes.length);
      result.setRange(0, iv.length, iv);
      result.setRange(iv.length, result.length, encrypted.bytes);
      
      return result;
    } catch (e) {
      throw Exception('Fehler beim Verschlüsseln der Daten: $e');
    }
  }

  Future<Uint8List> decryptFile(File encryptedFile) async {
    try {
      final encryptedBytes = await encryptedFile.readAsBytes();
      return await decryptData(encryptedBytes);
    } catch (e) {
      throw Exception('Fehler beim Entschlüsseln der Datei: $e');
    }
  }

  Future<Uint8List> decryptData(Uint8List encryptedData) async {
    try {
      if (encryptedData.length < 16) {
        throw Exception('Ungültige verschlüsselte Daten');
      }
      
      // Extract IV and encrypted data
      final iv = encryptedData.sublist(0, 16);
      final data = encryptedData.sublist(16);
      
      // Create decryptor
      final encrypter = Encrypter(AES(_encryptionKey));
      final decrypted = encrypter.decrypt(Encrypted(data), iv: IV(iv));
      
      return Uint8List.fromList(decrypted.codeUnits);
    } catch (e) {
      throw Exception('Fehler beim Entschlüsseln der Daten: $e');
    }
  }

  // Text encryption
  Future<String> encryptText(String text) async {
    try {
      final textBytes = Uint8List.fromUtf8(text);
      final encryptedBytes = await encryptData(textBytes);
      return base64Encode(encryptedBytes);
    } catch (e) {
      throw Exception('Fehler beim Verschlüsseln des Textes: $e');
    }
  }

  Future<String> decryptText(String encryptedText) async {
    try {
      final encryptedBytes = base64Decode(encryptedText);
      final decryptedBytes = await decryptData(encryptedBytes);
      return String.fromCharCodes(decryptedBytes);
    } catch (e) {
      throw Exception('Fehler beim Entschlüsseln des Textes: $e');
    }
  }

  // File name encryption
  Future<String> encryptFileName(String fileName) async {
    try {
      final fileNameBytes = Uint8List.fromUtf8(fileName);
      final encryptedBytes = await encryptData(fileNameBytes);
      return base64Encode(encryptedBytes);
    } catch (e) {
      throw Exception('Fehler beim Verschlüsseln des Dateinamens: $e');
    }
  }

  Future<String> decryptFileName(String encryptedFileName) async {
    try {
      final encryptedBytes = base64Decode(encryptedFileName);
      final decryptedBytes = await decryptData(encryptedBytes);
      return String.fromCharCodes(decryptedBytes);
    } catch (e) {
      throw Exception('Fehler beim Entschlüsseln des Dateinamens: $e');
    }
  }

  // PIN hashing
  Future<String> hashPin(String pin) async {
    try {
      // Use PBKDF2 for PIN hashing
      final pbkdf2 = Pbkdf2(
        macAlgorithm: Hmac(sha256),
        iterations: _iterations,
        bits: 256,
      );
      
      final key = pbkdf2.deriveKey(
        secretKey: Uint8List.fromUtf8(pin),
        nonce: _salt,
      );
      
      return base64Encode(key);
    } catch (e) {
      throw Exception('Fehler beim Hashen der PIN: $e');
    }
  }

  // Generate secure random tokens
  String generateSecureToken(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(length, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  // Generate file checksum
  String generateChecksum(Uint8List data) {
    final digest = sha256.convert(data);
    return digest.toString();
  }

  // Verify file integrity
  Future<bool> verifyFileIntegrity(File file, String expectedChecksum) async {
    try {
      final fileBytes = await file.readAsBytes();
      final actualChecksum = generateChecksum(fileBytes);
      return actualChecksum == expectedChecksum;
    } catch (e) {
      return false;
    }
  }

  // Change encryption key
  Future<bool> changeEncryptionKey(String newPassword) async {
    try {
      // Generate new key and salt
      final newSalt = _generateRandomBytes(_saltLength);
      final newKey = await _deriveKey(newPassword, newSalt);
      
      // Store new key and salt
      await _secureStorage.write(
        key: _keyStorageKey,
        value: base64Encode(newKey),
      );
      await _secureStorage.write(
        key: _saltStorageKey,
        value: base64Encode(newSalt),
      );
      
      // Update current key and salt
      _encryptionKey = newKey;
      _salt = newSalt;
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Backup encryption key
  Future<String> backupEncryptionKey() async {
    try {
      final keyData = {
        'key': base64Encode(_encryptionKey),
        'salt': base64Encode(_salt),
        'timestamp': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
      
      final jsonData = jsonEncode(keyData);
      return base64Encode(utf8.encode(jsonData));
    } catch (e) {
      throw Exception('Fehler beim Sichern des Verschlüsselungsschlüssels: $e');
    }
  }

  // Restore encryption key
  Future<bool> restoreEncryptionKey(String backupData) async {
    try {
      final jsonData = utf8.decode(base64Decode(backupData));
      final keyData = jsonDecode(jsonData) as Map<String, dynamic>;
      
      final key = base64Decode(keyData['key'] as String);
      final salt = base64Decode(keyData['salt'] as String);
      
      // Store restored key and salt
      await _secureStorage.write(
        key: _keyStorageKey,
        value: base64Encode(key),
      );
      await _secureStorage.write(
        key: _saltStorageKey,
        value: base64Encode(salt),
      );
      
      // Update current key and salt
      _encryptionKey = key;
      _salt = salt;
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Clear encryption data (for logout)
  Future<void> clearEncryptionData() async {
    try {
      await _secureStorage.delete(key: _keyStorageKey);
      await _secureStorage.delete(key: _saltStorageKey);
    } catch (e) {
      // Ignore errors during cleanup
    }
  }
}