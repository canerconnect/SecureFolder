import 'package:json_annotation/json_annotation.dart';

part 'secure_file.g.dart';

enum FileType {
  @JsonValue('photo')
  photo,
  @JsonValue('video')
  video,
  @JsonValue('note')
  note,
  @JsonValue('audio')
  audio,
  @JsonValue('document')
  document,
  @JsonValue('other')
  other,
}

enum FileStatus {
  @JsonValue('uploading')
  uploading,
  @JsonValue('synced')
  synced,
  @JsonValue('local_only')
  localOnly,
  @JsonValue('error')
  error,
}

@JsonSerializable()
class SecureFile {
  final String id;
  final String userId;
  final String fileName;
  final String originalFileName;
  final FileType fileType;
  final String mimeType;
  final int fileSize; // in bytes
  final String? thumbnailPath;
  final String? localPath;
  final String? cloudPath;
  final FileStatus status;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? lastModified;
  final DateTime? lastAccessed;
  final bool isEncrypted;
  final String? encryptionKey;
  final String? checksum;
  final List<String> tags;
  final bool isFavorite;
  final bool isDeleted;

  const SecureFile({
    required this.id,
    required this.userId,
    required this.fileName,
    required this.originalFileName,
    required this.fileType,
    required this.mimeType,
    required this.fileSize,
    this.thumbnailPath,
    this.localPath,
    this.cloudPath,
    required this.status,
    this.metadata,
    required this.createdAt,
    this.lastModified,
    this.lastAccessed,
    required this.isEncrypted,
    this.encryptionKey,
    this.checksum,
    this.tags = const [],
    this.isFavorite = false,
    this.isDeleted = false,
  });

  factory SecureFile.fromJson(Map<String, dynamic> json) => _$SecureFileFromJson(json);
  Map<String, dynamic> toJson() => _$SecureFileToJson(this);

  SecureFile copyWith({
    String? id,
    String? userId,
    String? fileName,
    String? originalFileName,
    FileType? fileType,
    String? mimeType,
    int? fileSize,
    String? thumbnailPath,
    String? localPath,
    String? cloudPath,
    FileStatus? status,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? lastModified,
    DateTime? lastAccessed,
    bool? isEncrypted,
    String? encryptionKey,
    String? checksum,
    List<String>? tags,
    bool? isFavorite,
    bool? isDeleted,
  }) {
    return SecureFile(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      fileName: fileName ?? this.fileName,
      originalFileName: originalFileName ?? this.originalFileName,
      fileType: fileType ?? this.fileType,
      mimeType: mimeType ?? this.mimeType,
      fileSize: fileSize ?? this.fileSize,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      localPath: localPath ?? this.localPath,
      cloudPath: cloudPath ?? this.cloudPath,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      lastAccessed: lastAccessed ?? this.lastAccessed,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      encryptionKey: encryptionKey ?? this.encryptionKey,
      checksum: checksum ?? this.checksum,
      tags: tags ?? this.tags,
      isFavorite: isFavorite ?? this.isFavorite,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  // Helper methods
  String get formattedFileSize {
    if (fileSize < 1024) {
      return '${fileSize} B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else if (fileSize < 1024 * 1024 * 1024) {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSize / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  String get fileTypeIcon {
    switch (fileType) {
      case FileType.photo:
        return '📷';
      case FileType.video:
        return '🎥';
      case FileType.note:
        return '📝';
      case FileType.audio:
        return '🎵';
      case FileType.document:
        return '📄';
      case FileType.other:
        return '📁';
    }
  }

  String get fileTypeName {
    switch (fileType) {
      case FileType.photo:
        return 'Foto';
      case FileType.video:
        return 'Video';
      case FileType.note:
        return 'Notiz';
      case FileType.audio:
        return 'Audio';
      case FileType.document:
        return 'Dokument';
      case FileType.other:
        return 'Andere';
    }
  }

  bool get isImage => fileType == FileType.photo;
  bool get isVideo => fileType == FileType.video;
  bool get isAudio => fileType == FileType.audio;
  bool get isNote => fileType == FileType.note;
  bool get isDocument => fileType == FileType.document;

  bool get hasThumbnail => thumbnailPath != null && thumbnailPath!.isNotEmpty;
  bool get isLocal => localPath != null && localPath!.isNotEmpty;
  bool get isCloud => cloudPath != null && cloudPath!.isNotEmpty;
  bool get isSynced => status == FileStatus.synced;
  bool get isUploading => status == FileStatus.uploading;
  bool get hasError => status == FileStatus.error;
}

@JsonSerializable()
class FileMetadata {
  final String? title;
  final String? description;
  final String? location;
  final DateTime? captureDate;
  final String? device;
  final Map<String, dynamic>? customFields;

  const FileMetadata({
    this.title,
    this.description,
    this.location,
    this.captureDate,
    this.device,
    this.customFields,
  });

  factory FileMetadata.fromJson(Map<String, dynamic> json) => _$FileMetadataFromJson(json);
  Map<String, dynamic> toJson() => _$FileMetadataToJson(this);

  FileMetadata copyWith({
    String? title,
    String? description,
    String? location,
    DateTime? captureDate,
    String? device,
    Map<String, dynamic>? customFields,
  }) {
    return FileMetadata(
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      captureDate: captureDate ?? this.captureDate,
      device: device ?? this.device,
      customFields: customFields ?? this.customFields,
    );
  }
}

@JsonSerializable()
class FileUploadProgress {
  final String fileId;
  final int bytesUploaded;
  final int totalBytes;
  final double progress; // 0.0 to 1.0
  final String status; // 'uploading', 'processing', 'completed', 'error'
  final String? errorMessage;

  const FileUploadProgress({
    required this.fileId,
    required this.bytesUploaded,
    required this.totalBytes,
    required this.progress,
    required this.status,
    this.errorMessage,
  });

  factory FileUploadProgress.fromJson(Map<String, dynamic> json) => _$FileUploadProgressFromJson(json);
  Map<String, dynamic> toJson() => _$FileUploadProgressToJson(this);

  String get progressPercentage => '${(progress * 100).toInt()}%';
  bool get isCompleted => status == 'completed';
  bool get hasError => status == 'error';
  bool get isUploading => status == 'uploading';
}