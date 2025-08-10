import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

enum BiometricType {
  none,
  fingerprint,
  face,
  iris,
}

enum AuthMethod {
  none,
  pin,
  biometric,
}

class BiometricProvider extends ChangeNotifier {
  final LocalAuthentication _localAuth = LocalAuthentication();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  bool _isAvailable = false;
  bool _isEnabled = false;
  bool _isAuthenticated = false;
  AuthMethod _authMethod = AuthMethod.none;
  List<BiometricType> _availableBiometrics = [];
  String? _errorMessage;
  
  // Getters
  bool get isAvailable => _isAvailable;
  bool get isEnabled => _isEnabled;
  bool get isAuthenticated => _isAuthenticated;
  AuthMethod get authMethod => _authMethod;
  List<BiometricType> get availableBiometrics => _availableBiometrics;
  String? get errorMessage => _errorMessage;

  BiometricProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _checkBiometricAvailability();
    await _loadSettings();
  }

  // Check if biometric authentication is available
  Future<void> _checkBiometricAvailability() async {
    try {
      _isAvailable = await _localAuth.canCheckBiometrics;
      
      if (_isAvailable) {
        final availableBiometrics = await _localAuth.getAvailableBiometrics();
        _availableBiometrics = availableBiometrics.map((biometric) {
          switch (biometric) {
            case BiometricType.fingerprint:
              return BiometricType.fingerprint;
            case BiometricType.face:
              return BiometricType.face;
            case BiometricType.iris:
              return BiometricType.iris;
            default:
              return BiometricType.none;
          }
        }).toList();
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Fehler beim Überprüfen der biometrischen Authentifizierung.');
    }
  }

  // Load settings from storage
  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isEnabled = prefs.getBool('biometric_enabled') ?? false;
      
      final authMethodString = prefs.getString('auth_method') ?? 'none';
      _authMethod = AuthMethod.values.firstWhere(
        (method) => method.toString().split('.').last == authMethodString,
        orElse: () => AuthMethod.none,
      );
      
      notifyListeners();
    } catch (e) {
      _setError('Fehler beim Laden der Einstellungen.');
    }
  }

  // Enable biometric authentication
  Future<bool> enableBiometric() async {
    try {
      if (!_isAvailable) {
        _setError('Biometrische Authentifizierung ist nicht verfügbar.');
        return false;
      }

      // Test biometric authentication
      final isAuthenticated = await _authenticate(
        reason: 'Biometrische Authentifizierung aktivieren',
      );

      if (isAuthenticated) {
        _isEnabled = true;
        _authMethod = AuthMethod.biometric;
        await _saveSettings();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _setError('Fehler beim Aktivieren der biometrischen Authentifizierung.');
      return false;
    }
  }

  // Disable biometric authentication
  Future<void> disableBiometric() async {
    try {
      _isEnabled = false;
      _authMethod = AuthMethod.none;
      await _saveSettings();
      await _secureStorage.delete(key: 'user_pin');
      notifyListeners();
    } catch (e) {
      _setError('Fehler beim Deaktivieren der biometrischen Authentifizierung.');
    }
  }

  // Set PIN authentication
  Future<bool> setPinAuth(String pin) async {
    try {
      if (pin.length < 4) {
        _setError('PIN muss mindestens 4 Zeichen lang sein.');
        return false;
      }

      // Hash the PIN
      final hashedPin = _hashPin(pin);
      
      // Store hashed PIN securely
      await _secureStorage.write(key: 'user_pin', value: hashedPin);
      
      _isEnabled = true;
      _authMethod = AuthMethod.pin;
      await _saveSettings();
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Fehler beim Einrichten der PIN.');
      return false;
    }
  }

  // Authenticate with PIN
  Future<bool> authenticateWithPin(String pin) async {
    try {
      final storedHashedPin = await _secureStorage.read(key: 'user_pin');
      if (storedHashedPin == null) {
        _setError('Keine PIN eingerichtet.');
        return false;
      }

      final hashedPin = _hashPin(pin);
      if (hashedPin == storedHashedPin) {
        _isAuthenticated = true;
        notifyListeners();
        return true;
      } else {
        _setError('Falsche PIN.');
        return false;
      }
    } catch (e) {
      _setError('Fehler bei der PIN-Authentifizierung.');
      return false;
    }
  }

  // Authenticate with biometrics
  Future<bool> authenticateWithBiometric() async {
    try {
      if (!_isEnabled || _authMethod != AuthMethod.biometric) {
        _setError('Biometrische Authentifizierung ist nicht aktiviert.');
        return false;
      }

      final isAuthenticated = await _authenticate(
        reason: 'Sicheren Ordner entsperren',
      );

      if (isAuthenticated) {
        _isAuthenticated = true;
        notifyListeners();
      }
      
      return isAuthenticated;
    } catch (e) {
      _setError('Fehler bei der biometrischen Authentifizierung.');
      return false;
    }
  }

  // Generic authenticate method
  Future<bool> authenticate() async {
    switch (_authMethod) {
      case AuthMethod.biometric:
        return await authenticateWithBiometric();
      case AuthMethod.pin:
        // For PIN, we need the PIN from UI
        return false; // UI should handle PIN input
      case AuthMethod.none:
        return true; // No authentication required
    }
  }

  // Change PIN
  Future<bool> changePin(String oldPin, String newPin) async {
    try {
      // Verify old PIN
      final isOldPinValid = await authenticateWithPin(oldPin);
      if (!isOldPinValid) {
        return false;
      }

      // Set new PIN
      return await setPinAuth(newPin);
    } catch (e) {
      _setError('Fehler beim Ändern der PIN.');
      return false;
    }
  }

  // Lock the app
  void lock() {
    _isAuthenticated = false;
    notifyListeners();
  }

  // Internal authentication method
  Future<bool> _authenticate({required String reason}) async {
    try {
      _clearError();
      
      final isAuthenticated = await _localAuth.authenticate(
        localizedFallbackTitle: 'PIN verwenden',
        authMessages: const [
          AndroidAuthMessages(
            biometricHint: 'Biometrische Authentifizierung',
            biometricNotRecognized: 'Nicht erkannt. Versuchen Sie es erneut.',
            biometricRequiredTitle: 'Biometrische Authentifizierung erforderlich',
            biometricSuccess: 'Biometrische Authentifizierung erfolgreich',
            cancelButton: 'Abbrechen',
            deviceCredentialsRequiredTitle: 'Geräteschutz erforderlich',
            deviceCredentialsSetupDescription: 'Richten Sie einen Bildschirmschutz ein',
            goToSettingsButton: 'Zu Einstellungen',
            goToSettingsDescription: 'Sicherheitseinstellungen sind nicht eingerichtet',
            signInTitle: 'Authentifizierung erforderlich',
          ),
          IOSAuthMessages(
            cancelButton: 'Abbrechen',
            goToSettingsButton: 'Zu Einstellungen',
            goToSettingsDescription: 'Biometrische Authentifizierung ist nicht eingerichtet',
            lockOut: 'Biometrische Authentifizierung ist deaktiviert',
          ),
        ],
      );

      return isAuthenticated;
    } catch (e) {
      _setError('Authentifizierung fehlgeschlagen.');
      return false;
    }
  }

  // Save settings to SharedPreferences
  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', _isEnabled);
      await prefs.setString('auth_method', _authMethod.toString().split('.').last);
    } catch (e) {
      _setError('Fehler beim Speichern der Einstellungen.');
    }
  }

  // Hash PIN using SHA-256
  String _hashPin(String pin) {
    final bytes = utf8.encode(pin);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Error handling
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

  // Get biometric type name
  String getBiometricTypeName(BiometricType type) {
    switch (type) {
      case BiometricType.fingerprint:
        return 'Fingerabdruck';
      case BiometricType.face:
        return 'Face ID';
      case BiometricType.iris:
        return 'Iris-Scan';
      case BiometricType.none:
        return 'Keine';
    }
  }

  // Get primary biometric type
  BiometricType get primaryBiometricType {
    if (_availableBiometrics.contains(BiometricType.face)) {
      return BiometricType.face;
    } else if (_availableBiometrics.contains(BiometricType.fingerprint)) {
      return BiometricType.fingerprint;
    } else if (_availableBiometrics.contains(BiometricType.iris)) {
      return BiometricType.iris;
    }
    return BiometricType.none;
  }

  // Check if specific biometric type is available
  bool isBiometricTypeAvailable(BiometricType type) {
    return _availableBiometrics.contains(type);
  }
}