import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String email;
  final String? displayName;
  final String? photoURL;
  final bool emailVerified;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final UserSettings settings;
  final UserStats stats;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.emailVerified,
    required this.createdAt,
    this.lastLogin,
    required this.settings,
    required this.stats,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoURL,
    bool? emailVerified,
    DateTime? createdAt,
    DateTime? lastLogin,
    UserSettings? settings,
    UserStats? stats,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      emailVerified: emailVerified ?? this.emailVerified,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      settings: settings ?? this.settings,
      stats: stats ?? this.stats,
    );
  }
}

@JsonSerializable()
class UserSettings {
  final bool biometricEnabled;
  final bool pinEnabled;
  final bool cloudSyncEnabled;
  final bool autoLockEnabled;
  final int autoLockTimeout; // in minutes
  final String? theme; // 'light', 'dark', 'system'
  final bool notificationsEnabled;
  final bool dataUsageOptimization;

  const UserSettings({
    this.biometricEnabled = false,
    this.pinEnabled = false,
    this.cloudSyncEnabled = true,
    this.autoLockEnabled = true,
    this.autoLockTimeout = 5,
    this.theme = 'system',
    this.notificationsEnabled = true,
    this.dataUsageOptimization = false,
  });

  factory UserSettings.fromJson(Map<String, dynamic> json) => _$UserSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$UserSettingsToJson(this);

  UserSettings copyWith({
    bool? biometricEnabled,
    bool? pinEnabled,
    bool? cloudSyncEnabled,
    bool? autoLockEnabled,
    int? autoLockTimeout,
    String? theme,
    bool? notificationsEnabled,
    bool? dataUsageOptimization,
  }) {
    return UserSettings(
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      pinEnabled: pinEnabled ?? this.pinEnabled,
      cloudSyncEnabled: cloudSyncEnabled ?? this.cloudSyncEnabled,
      autoLockEnabled: autoLockEnabled ?? this.autoLockEnabled,
      autoLockTimeout: autoLockTimeout ?? this.autoLockTimeout,
      theme: theme ?? this.theme,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      dataUsageOptimization: dataUsageOptimization ?? this.dataUsageOptimization,
    );
  }
}

@JsonSerializable()
class UserStats {
  final int totalFiles;
  final int totalPhotos;
  final int totalVideos;
  final int totalNotes;
  final int totalAudioFiles;
  final int totalStorageUsed; // in bytes
  final DateTime lastSync;
  final int syncCount;

  const UserStats({
    this.totalFiles = 0,
    this.totalPhotos = 0,
    this.totalVideos = 0,
    this.totalNotes = 0,
    this.totalAudioFiles = 0,
    this.totalStorageUsed = 0,
    required this.lastSync,
    this.syncCount = 0,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) => _$UserStatsFromJson(json);
  Map<String, dynamic> toJson() => _$UserStatsToJson(this);

  UserStats copyWith({
    int? totalFiles,
    int? totalPhotos,
    int? totalVideos,
    int? totalNotes,
    int? totalAudioFiles,
    int? totalStorageUsed,
    DateTime? lastSync,
    int? syncCount,
  }) {
    return UserStats(
      totalFiles: totalFiles ?? this.totalFiles,
      totalPhotos: totalPhotos ?? this.totalPhotos,
      totalVideos: totalVideos ?? this.totalVideos,
      totalNotes: totalNotes ?? this.totalNotes,
      totalAudioFiles: totalAudioFiles ?? this.totalAudioFiles,
      totalStorageUsed: totalStorageUsed ?? this.totalStorageUsed,
      lastSync: lastSync ?? this.lastSync,
      syncCount: syncCount ?? this.syncCount,
    );
  }

  String get formattedStorageUsed {
    if (totalStorageUsed < 1024) {
      return '${totalStorageUsed} B';
    } else if (totalStorageUsed < 1024 * 1024) {
      return '${(totalStorageUsed / 1024).toStringAsFixed(1)} KB';
    } else if (totalStorageUsed < 1024 * 1024 * 1024) {
      return '${(totalStorageUsed / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(totalStorageUsed / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}