import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/secure_file.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000/api'; // TODO: Configure for production
  static const String authTokenKey = 'auth_token';
  
  late final Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token to requests
        final token = await _secureStorage.read(key: authTokenKey);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        // Handle common errors
        if (error.response?.statusCode == 401) {
          // Token expired or invalid
          _handleAuthError();
        }
        handler.next(error);
      },
    ));
  }

  // Authentication endpoints
  Future<Map<String, dynamic>?> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        if (displayName != null) 'displayName': displayName,
      });
      
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
      return null;
    }
  }

  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
      return null;
    }
  }

  Future<bool> resetPassword(String email) async {
    try {
      await _dio.post('/auth/reset-password', data: {
        'email': email,
      });
      return true;
    } on DioException catch (e) {
      _handleDioError(e);
      return false;
    }
  }

  Future<bool> verifyEmail(String token) async {
    try {
      await _dio.post('/auth/verify-email', data: {
        'token': token,
      });
      return true;
    } on DioException catch (e) {
      _handleDioError(e);
      return false;
    }
  }

  Future<bool> logout() async {
    try {
      await _dio.post('/auth/logout');
      await _secureStorage.delete(key: authTokenKey);
      return true;
    } on DioException catch (e) {
      _handleDioError(e);
      return false;
    }
  }

  Future<bool> validateToken(String token) async {
    try {
      final response = await _dio.get('/auth/validate', options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ));
      return response.statusCode == 200;
    } on DioException catch (e) {
      return false;
    }
  }

  // File endpoints
  Future<List<Map<String, dynamic>>?> getFiles() async {
    try {
      final response = await _dio.get('/files');
      return List<Map<String, dynamic>>.from(response.data['files'] ?? []);
    } on DioException catch (e) {
      _handleDioError(e);
      return null;
    }
  }

  Future<Map<String, dynamic>?> uploadFile({
    required File file,
    required String fileName,
    required String mimeType,
    Map<String, dynamic>? metadata,
    List<String>? tags,
    ProgressCallback? onProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: fileName,
          contentType: DioMediaType.parse(mimeType),
        ),
        if (metadata != null) 'metadata': jsonEncode(metadata),
        if (tags != null) 'tags': jsonEncode(tags),
      });

      final response = await _dio.post(
        '/files/upload',
        data: formData,
        onSendProgress: onProgress,
      );
      
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
      return null;
    }
  }

  Future<File?> downloadFile(String fileId) async {
    try {
      final response = await _dio.get(
        '/files/$fileId/download',
        options: Options(responseType: ResponseType.bytes),
      );
      
      // Save to temporary file
      final tempDir = Directory.systemTemp;
      final tempFile = File('${tempDir.path}/$fileId');
      await tempFile.writeAsBytes(response.data);
      
      return tempFile;
    } on DioException catch (e) {
      _handleDioError(e);
      return null;
    }
  }

  Future<bool> deleteFile(String fileId) async {
    try {
      await _dio.delete('/files/$fileId');
      return true;
    } on DioException catch (e) {
      _handleDioError(e);
      return false;
    }
  }

  Future<bool> updateFile(String fileId, {
    String? fileName,
    Map<String, dynamic>? metadata,
    List<String>? tags,
  }) async {
    try {
      await _dio.put('/files/$fileId', data: {
        if (fileName != null) 'fileName': fileName,
        if (metadata != null) 'metadata': metadata,
        if (tags != null) 'tags': tags,
      });
      return true;
    } on DioException catch (e) {
      _handleDioError(e);
      return false;
    }
  }

  Future<Map<String, dynamic>?> getFileStats() async {
    try {
      final response = await _dio.get('/files/stats');
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
      return null;
    }
  }

  // User endpoints
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      final response = await _dio.get('/users/profile');
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
      return null;
    }
  }

  Future<bool> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      await _dio.put('/users/profile', data: {
        if (displayName != null) 'displayName': displayName,
        if (photoURL != null) 'photoURL': photoURL,
      });
      return true;
    } on DioException catch (e) {
      _handleDioError(e);
      return false;
    }
  }

  Future<bool> setPin(String pin) async {
    try {
      await _dio.post('/users/pin', data: {'pin': pin});
      return true;
    } on DioException catch (e) {
      _handleDioError(e);
      return false;
    }
  }

  Future<bool> validatePin(String pin) async {
    try {
      final response = await _dio.post('/users/pin/validate', data: {'pin': pin});
      return response.data['valid'] ?? false;
    } on DioException catch (e) {
      _handleDioError(e);
      return false;
    }
  }

  Future<bool> removePin() async {
    try {
      await _dio.delete('/users/pin');
      return true;
    } on DioException catch (e) {
      _handleDioError(e);
      return false;
    }
  }

  Future<bool> updateCloudSync(bool enabled) async {
    try {
      await _dio.put('/users/cloud-sync', data: {'enabled': enabled});
      return true;
    } on DioException catch (e) {
      _handleDioError(e);
      return false;
    }
  }

  Future<bool> deleteAccount() async {
    try {
      await _dio.delete('/users/account');
      await _secureStorage.delete(key: authTokenKey);
      return true;
    } on DioException catch (e) {
      _handleDioError(e);
      return false;
    }
  }

  Future<Map<String, dynamic>?> getUserStats() async {
    try {
      final response = await _dio.get('/users/stats');
      return response.data;
    } on DioException catch (e) {
      _handleDioError(e);
      return null;
    }
  }

  // Error handling
  void _handleDioError(DioException error) {
    String message = 'Ein Fehler ist aufgetreten';
    
    if (error.response != null) {
      final statusCode = error.response!.statusCode;
      final data = error.response!.data;
      
      switch (statusCode) {
        case 400:
          message = data['message'] ?? 'Ungültige Anfrage';
          break;
        case 401:
          message = 'Nicht autorisiert';
          break;
        case 403:
          message = 'Zugriff verweigert';
          break;
        case 404:
          message = 'Nicht gefunden';
          break;
        case 409:
          message = data['message'] ?? 'Konflikt';
          break;
        case 422:
          message = data['message'] ?? 'Validierungsfehler';
          break;
        case 500:
          message = 'Server-Fehler';
          break;
        default:
          message = data['message'] ?? 'Unbekannter Fehler';
      }
    } else if (error.type == DioExceptionType.connectionTimeout) {
      message = 'Verbindungszeitüberschreitung';
    } else if (error.type == DioExceptionType.receiveTimeout) {
      message = 'Empfangszeitüberschreitung';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'Verbindungsfehler';
    }
    
    throw Exception(message);
  }

  void _handleAuthError() {
    // Clear stored token and redirect to login
    _secureStorage.delete(key: authTokenKey);
    // TODO: Navigate to login screen
  }

  // Utility methods
  void updateBaseUrl(String newUrl) {
    _dio.options.baseUrl = newUrl;
  }

  void addAuthHeader(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  void removeAuthHeader() {
    _dio.options.headers.remove('Authorization');
  }
}