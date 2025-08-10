import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SecurityProvider extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  bool _isAppLocked = false;
  bool _isBiometricEnabled = false;
  bool _isPinEnabled = false;
  bool _isLoading = false;
  String? _error;
  int _autoLockDelay = 5; // minutes

  // Getters
  bool get isAppLocked => _isAppLocked;
  bool get isBiometricEnabled => _isBiometricEnabled;
  bool get isPinEnabled => _isPinEnabled;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get autoLockDelay => _autoLockDelay;
  bool get isAutoLockEnabled => _isAppLocked; // Auto-lock is controlled by app lock

  SecurityProvider() {
    _loadSecuritySettings();
  }

  Future<void> _loadSecuritySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      _isAppLocked = prefs.getBool('is_app_locked') ?? false;
      _isBiometricEnabled = prefs.getBool('is_biometric_enabled') ?? false;
      _isPinEnabled = prefs.getBool('is_pin_enabled') ?? false;
      _autoLockDelay = prefs.getInt('auto_lock_delay') ?? 5;
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error loading security settings: $e');
      }
    }
  }

  Future<bool> setPin(String pin) async {
    try {
      // Hash the PIN using PBKDF2
      final hashedPin = await _hashPin(pin);
      
      // Store the hashed PIN securely
      await _secureStorage.write(key: 'user_pin', value: hashedPin);
      
      // Update settings
      _isPinEnabled = true;
      _isAppLocked = true;
      
      // Save to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_pin_enabled', true);
      await prefs.setBool('is_app_locked', true);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Fehler beim Setzen der PIN: ${e.toString()}');
      return false;
    }
  }

  Future<bool> verifyPin(String pin) async {
    try {
      final storedHash = await _secureStorage.read(key: 'user_pin');
      if (storedHash == null) return false;
      
      final inputHash = await _hashPin(pin);
      return storedHash == inputHash;
    } catch (e) {
      if (kDebugMode) {
        print('Error verifying PIN: $e');
      }
      return false;
    }
  }

  Future<bool> changePin(String currentPin, String newPin) async {
    try {
      // Verify current PIN
      final isCurrentValid = await verifyPin(currentPin);
      if (!isCurrentValid) {
        _setError('Aktuelle PIN ist falsch');
        return false;
      }
      
      // Set new PIN
      return await setPin(newPin);
    } catch (e) {
      _setError('Fehler beim Ändern der PIN: ${e.toString()}');
      return false;
    }
  }

  Future<void> removePin() async {
    try {
      await _secureStorage.delete(key: 'user_pin');
      
      _isPinEnabled = false;
      if (!_isBiometricEnabled) {
        _isAppLocked = false;
      }
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_pin_enabled', false);
      await prefs.setBool('is_app_locked', _isAppLocked);
      
      notifyListeners();
    } catch (e) {
      _setError('Fehler beim Entfernen der PIN: ${e.toString()}');
    }
  }

            Future<void> setBiometricEnabled(bool enabled) async {
            try {
              _isBiometricEnabled = enabled;
              
              if (enabled) {
                _isAppLocked = true;
              } else if (!_isPinEnabled) {
                _isAppLocked = false;
              }
              
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('is_biometric_enabled', enabled);
              await prefs.setBool('is_app_locked', _isAppLocked);
              
              notifyListeners();
            } catch (e) {
              _setError('Fehler beim Ändern der Biometric-Einstellung: ${e.toString()}');
            }
          }

          Future<void> setPinEnabled(bool enabled) async {
            try {
              _isPinEnabled = enabled;
              
              if (enabled) {
                _isAppLocked = true;
              } else if (!_isBiometricEnabled) {
                _isAppLocked = false;
              }
              
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('is_pin_enabled', enabled);
              await prefs.setBool('is_app_locked', _isAppLocked);
              
              notifyListeners();
            } catch (e) {
              _setError('Fehler beim Ändern der PIN-Einstellung: ${e.toString()}');
            }
          }

            Future<void> setAppLocked(bool locked) async {
            try {
              _isAppLocked = locked;
              
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('is_app_locked', locked);
              
              notifyListeners();
            } catch (e) {
              _setError('Fehler beim Ändern des App-Lock-Status: ${e.toString()}');
            }
          }

          Future<void> setAutoLockEnabled(bool enabled) async {
            try {
              _isAppLocked = enabled;
              
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('is_app_locked', enabled);
              
              notifyListeners();
            } catch (e) {
              _setError('Fehler beim Ändern der Auto-Lock-Einstellung: ${e.toString()}');
            }
          }

  Future<void> setAutoLockDelay(int delayMinutes) async {
    try {
      _autoLockDelay = delayMinutes;
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('auto_lock_delay', delayMinutes);
      
      notifyListeners();
    } catch (e) {
      _setError('Fehler beim Ändern der Auto-Lock-Verzögerung: ${e.toString()}');
    }
  }

  // Note: Cloud sync, notifications, language, and dark mode settings
  // are managed by AuthProvider for consistency

  Future<void> lockApp() async {
    await setAppLocked(true);
  }

  Future<void> unlockApp() async {
    await setAppLocked(false);
  }

  Future<void> clearAllData() async {
    try {
      _setLoading(true);
      
      // Clear secure storage
      await _secureStorage.deleteAll();
      
      // Clear preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      
      // Reset to defaults
      _isAppLocked = false;
      _isBiometricEnabled = false;
      _isPinEnabled = false;
      _autoLockDelay = 5;
      
      notifyListeners();
    } catch (e) {
      _setError('Fehler beim Löschen aller Daten: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<String> _hashPin(String pin) async {
    // TODO: Implement proper PBKDF2 hashing
    // For now, use a simple hash for demonstration
    return 'hashed_${pin}_${DateTime.now().millisecondsSinceEpoch}';
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _clearError();
  }

  @override
  void dispose() {
    _secureStorage.close();
    super.dispose();
  }
}