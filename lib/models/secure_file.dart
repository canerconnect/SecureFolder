import 'package:cloud_firestore/cloud_firestore.dart';

enum FileType {
  photo,
  video,
  document,
  note,
  audio,
}

class SecureFile {
  final String id;
  final String name;
  final String encryptedName;
  final FileType type;
  final String? localPath;
  final String? cloudPath;
  final String? thumbnailPath;
  final int size;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final bool isEncrypted;
  final bool isSynced;
  final String userId;
  final Map<String, dynamic>? metadata;

  SecureFile({
    required this.id,
    required this.name,
    required this.encryptedName,
    required this.type,
    this.localPath,
    this.cloudPath,
    this.thumbnailPath,
    required this.size,
    required this.createdAt,
    required this.modifiedAt,
    this.isEncrypted = true,
    this.isSynced = false,
    required this.userId,
    this.metadata,
  });

  factory SecureFile.fromMap(Map<String, dynamic> map) {
    return SecureFile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      encryptedName: map['encryptedName'] ?? '',
      type: FileType.values.firstWhere(
        (e) => e.toString() == 'FileType.${map['type']}',
        orElse: () => FileType.document,
      ),
      localPath: map['localPath'],
      cloudPath: map['cloudPath'],
      thumbnailPath: map['thumbnailPath'],
      size: map['size'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      modifiedAt: (map['modifiedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isEncrypted: map['isEncrypted'] ?? true,
      isSynced: map['isSynced'] ?? false,
      userId: map['userId'] ?? '',
      metadata: map['metadata'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'encryptedName': encryptedName,
      'type': type.toString().split('.').last,
      'localPath': localPath,
      'cloudPath': cloudPath,
      'thumbnailPath': thumbnailPath,
      'size': size,
      'createdAt': Timestamp.fromDate(createdAt),
      'modifiedAt': Timestamp.fromDate(modifiedAt),
      'isEncrypted': isEncrypted,
      'isSynced': isSynced,
      'userId': userId,
      'metadata': metadata,
    };
  }

  SecureFile copyWith({
    String? id,
    String? name,
    String? encryptedName,
    FileType? type,
    String? localPath,
    String? cloudPath,
    String? thumbnailPath,
    int? size,
    DateTime? createdAt,
    DateTime? modifiedAt,
    bool? isEncrypted,
    bool? isSynced,
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    return SecureFile(
      id: id ?? this.id,
      name: name ?? this.name,
      encryptedName: encryptedName ?? this.encryptedName,
      type: type ?? this.type,
      localPath: localPath ?? this.localPath,
      cloudPath: cloudPath ?? this.cloudPath,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      size: size ?? this.size,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      isSynced: isSynced ?? this.isSynced,
      userId: userId ?? this.userId,
      metadata: metadata ?? this.metadata,
    );
  }

  String get fileExtension {
    return name.split('.').last.toLowerCase();
  }

  String get displaySize {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    if (size < 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  bool get isImage => type == FileType.photo;
  bool get isVideo => type == FileType.video;
  bool get isDocument => type == FileType.document;
  bool get isNote => type == FileType.note;
  bool get isAudio => type == FileType.audio;
}

class SecureNote extends SecureFile {
  final String content;
  final String encryptedContent;

  SecureNote({
    required super.id,
    required super.name,
    required super.encryptedName,
    required this.content,
    required this.encryptedContent,
    super.localPath,
    super.cloudPath,
    required super.size,
    required super.createdAt,
    required super.modifiedAt,
    super.isEncrypted = true,
    super.isSynced = false,
    required super.userId,
    super.metadata,
  }) : super(type: FileType.note);

  factory SecureNote.fromMap(Map<String, dynamic> map) {
    return SecureNote(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      encryptedName: map['encryptedName'] ?? '',
      content: map['content'] ?? '',
      encryptedContent: map['encryptedContent'] ?? '',
      localPath: map['localPath'],
      cloudPath: map['cloudPath'],
      size: map['size'] ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      modifiedAt: (map['modifiedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isEncrypted: map['isEncrypted'] ?? true,
      isSynced: map['isSynced'] ?? false,
      userId: map['userId'] ?? '',
      metadata: map['metadata'],
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = super.toMap();
    map.addAll({
      'content': content,
      'encryptedContent': encryptedContent,
    });
    return map;
  }
}