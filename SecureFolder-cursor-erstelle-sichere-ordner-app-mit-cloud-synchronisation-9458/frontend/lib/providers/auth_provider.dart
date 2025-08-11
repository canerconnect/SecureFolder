import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _userId;
  String? _userEmail;
  String? _userName;
  String? _error;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get userId => _userId;
  String? get userEmail => _userEmail;
  String? get userName => _userName;
  String? get error => _error;

  AuthProvider() {
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      final email = await _secureStorage.read(key: 'user_email');
      final name = await _secureStorage.read(key: 'user_name');
      
      if (token != null && email != null) {
        _isAuthenticated = true;
        _userEmail = email;
        _userName = name;
        // TODO: Validate token with backend
        notifyListeners();
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading auth state: $e');
      }
    }
  }

  Future<bool> login(String email, String password, {bool rememberMe = false}) async {
    _setLoading(true);
    _clearError();
    
    try {
      // TODO: Implement actual login with backend
      // For now, simulate a successful login
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate successful authentication
      _isAuthenticated = true;
      _userEmail = email;
      _userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      _userName = email.split('@').first;
      
      // Store credentials securely
      await _secureStorage.write(key: 'auth_token', value: 'dummy_token_${DateTime.now().millisecondsSinceEpoch}');
      await _secureStorage.write(key: 'user_email', value: email);
      await _secureStorage.write(key: 'user_name', value: _userName);
      
      if (rememberMe) {
        await _secureStorage.write(key: 'remember_me', value: 'true');
      }
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Login fehlgeschlagen: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> register(String fullName, String email, String password) async {
    _setLoading(true);
    _clearError();
    
    try {
      // TODO: Implement actual registration with backend
      // For now, simulate a successful registration
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate successful registration
      _isAuthenticated = true;
      _userEmail = email;
      _userId = 'user_${DateTime.now().millisecondsSinceEpoch}';
      _userName = fullName;
      
      // Store credentials securely
      await _secureStorage.write(key: 'auth_token', value: 'dummy_token_${DateTime.now().millisecondsSinceEpoch}');
      await _secureStorage.write(key: 'user_email', value: email);
      await _secureStorage.write(key: 'user_name', value: fullName);
      
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Registrierung fehlgeschlagen: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    try {
      // Clear stored credentials
      await _secureStorage.delete(key: 'auth_token');
      await _secureStorage.delete(key: 'user_email');
      await _secureStorage.delete(key: 'user_name');
      await _secureStorage.delete(key: 'remember_me');
      
      // Reset state
      _isAuthenticated = false;
      _userId = null;
      _userEmail = null;
      _userName = null;
      
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('Error during logout: $e');
      }
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    _setLoading(true);
    _clearError();
    
    try {
      // TODO: Implement actual password change with backend
      await Future.delayed(const Duration(seconds: 1));
      
      // Simulate successful password change
      notifyListeners();
    } catch (e) {
      _setError('Passwort-Änderung fehlgeschlagen: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    
    try {
      // TODO: Implement actual password reset with backend
      await Future.delayed(const Duration(seconds: 2));
      
      // Simulate successful password reset email sent
      notifyListeners();
    } catch (e) {
      _setError('Passwort-Reset fehlgeschlagen: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateProfile({String? fullName, String? email}) async {
    _setLoading(true);
    _clearError();
    
    try {
      // TODO: Implement actual profile update with backend
      await Future.delayed(const Duration(seconds: 1));
      
      if (fullName != null) {
        _userName = fullName;
        await _secureStorage.write(key: 'user_name', value: fullName);
      }
      
      if (email != null) {
        _userEmail = email;
        await _secureStorage.write(key: 'user_email', value: email);
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Profil-Update fehlgeschlagen: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
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

  // Settings methods
  Future<void> setCloudSyncEnabled(bool enabled) async {
    // TODO: Implement cloud sync setting
    // For now, just store locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('cloud_sync_enabled', enabled);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    // TODO: Implement notifications setting
    // For now, just store locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
  }

  Future<void> setLanguage(String languageCode) async {
    // TODO: Implement language setting
    // For now, just store locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language', languageCode);
  }

  Future<void> setDarkMode(bool enabled) async {
    // TODO: Implement dark mode setting
    // For now, just store locally
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', enabled);
  }

  // Getters for settings
  bool get isCloudSyncEnabled {
    // TODO: Get from SharedPreferences
    return false;
  }

  bool get isNotificationsEnabled {
    // TODO: Get from SharedPreferences
    return true;
  }

  String get selectedLanguage {
    // TODO: Get from SharedPreferences
    return 'de';
  }

  bool get isDarkModeEnabled {
    // TODO: Get from SharedPreferences
    return false;
  }

  @override
  void dispose() {
    _secureStorage.close();
    super.dispose();
  }
}