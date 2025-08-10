import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secure_folder/services/encryption_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final EncryptionService _encryptionService = EncryptionService();
  
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _user != null;

  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  // Register with email and password
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      // Create user account
      final UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        // Update display name
        await userCredential.user!.updateDisplayName(displayName);
        
        // Create user document in Firestore
        await _createUserDocument(userCredential.user!, displayName);
        
        // Initialize encryption key for user
        await _encryptionService.initializeUserKey(userCredential.user!.uid);
        
        _user = userCredential.user;
        notifyListeners();
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('Ein unerwarteter Fehler ist aufgetreten.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in with email and password
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    try {
      _setLoading(true);
      _clearError();

      final UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        _user = userCredential.user;
        notifyListeners();
        return true;
      }
      return false;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('Ein unerwarteter Fehler ist aufgetreten.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _user = null;
      notifyListeners();
    } catch (e) {
      _setError('Fehler beim Abmelden.');
    }
  }

  // Reset password
  Future<bool> resetPassword(String email) async {
    try {
      _setLoading(true);
      _clearError();

      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('Ein unerwarteter Fehler ist aufgetreten.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update password
  Future<bool> updatePassword(String newPassword) async {
    try {
      if (_user == null) return false;
      
      _setLoading(true);
      _clearError();

      await _user!.updatePassword(newPassword);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('Ein unerwarteter Fehler ist aufgetreten.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Update email
  Future<bool> updateEmail(String newEmail) async {
    try {
      if (_user == null) return false;
      
      _setLoading(true);
      _clearError();

      await _user!.updateEmail(newEmail);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('Ein unerwarteter Fehler ist aufgetreten.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Delete account
  Future<bool> deleteAccount() async {
    try {
      if (_user == null) return false;
      
      _setLoading(true);
      _clearError();

      // Delete user data from Firestore
      await _deleteUserData(_user!.uid);
      
      // Delete Firebase Auth account
      await _user!.delete();
      _user = null;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('Ein unerwarteter Fehler ist aufgetreten.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Reauthenticate user
  Future<bool> reauthenticate(String password) async {
    try {
      if (_user == null || _user!.email == null) return false;
      
      _setLoading(true);
      _clearError();

      final credential = EmailAuthProvider.credential(
        email: _user!.email!,
        password: password,
      );

      await _user!.reauthenticateWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      _setError(_getAuthErrorMessage(e.code));
      return false;
    } catch (e) {
      _setError('Ein unerwarteter Fehler ist aufgetreten.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Create user document in Firestore
  Future<void> _createUserDocument(User user, String displayName) async {
    final userDoc = _firestore.collection('users').doc(user.uid);
    
    await userDoc.set({
      'uid': user.uid,
      'email': user.email,
      'displayName': displayName,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
      'settings': {
        'cloudSyncEnabled': true,
        'biometricEnabled': false,
        'autoLockEnabled': true,
        'autoLockDuration': 300, // 5 minutes
      },
      'storageUsed': 0,
      'fileCount': 0,
    });
  }

  // Delete user data from Firestore
  Future<void> _deleteUserData(String userId) async {
    final batch = _firestore.batch();
    
    // Delete user document
    batch.delete(_firestore.collection('users').doc(userId));
    
    // Delete user's files
    final filesQuery = await _firestore
        .collection('files')
        .where('userId', isEqualTo: userId)
        .get();
    
    for (final doc in filesQuery.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
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

  // Get localized error messages
  String _getAuthErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Kein Benutzer mit dieser E-Mail-Adresse gefunden.';
      case 'wrong-password':
        return 'Falsches Passwort.';
      case 'email-already-in-use':
        return 'Diese E-Mail-Adresse wird bereits verwendet.';
      case 'weak-password':
        return 'Das Passwort ist zu schwach.';
      case 'invalid-email':
        return 'Ungültige E-Mail-Adresse.';
      case 'user-disabled':
        return 'Dieses Benutzerkonto wurde deaktiviert.';
      case 'too-many-requests':
        return 'Zu viele Anmeldeversuche. Versuchen Sie es später erneut.';
      case 'network-request-failed':
        return 'Netzwerkfehler. Überprüfen Sie Ihre Internetverbindung.';
      case 'requires-recent-login':
        return 'Diese Aktion erfordert eine erneute Anmeldung.';
      default:
        return 'Ein unerwarteter Fehler ist aufgetreten.';
    }
  }

  void clearError() {
    _clearError();
  }
}