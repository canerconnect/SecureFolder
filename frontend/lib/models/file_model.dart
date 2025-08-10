enum FileType {
  photo,
  video,
  note,
  audio,
  document,
  other,
}

class FileModel {
  final String id;
  final String name;
  final String originalName;
  final FileType type;
  final int size; // in bytes
  final DateTime uploadDate;
  final bool isEncrypted;
  final String? thumbnailPath;
  final String? localPath;
  final String? cloudPath;

  const FileModel({
    required this.id,
    required this.name,
    required this.originalName,
    required this.type,
    required this.size,
    required this.uploadDate,
    required this.isEncrypted,
    this.thumbnailPath,
    this.localPath,
    this.cloudPath,
  });

  FileModel copyWith({
    String? id,
    String? name,
    String? originalName,
    FileType? type,
    int? size,
    DateTime? uploadDate,
    bool? isEncrypted,
    String? thumbnailPath,
    String? localPath,
    String? cloudPath,
  }) {
    return FileModel(
      id: id ?? this.id,
      name: name ?? this.name,
      originalName: originalName ?? this.originalName,
      type: type ?? this.type,
      size: size ?? this.size,
      uploadDate: uploadDate ?? this.uploadDate,
      isEncrypted: isEncrypted ?? this.isEncrypted,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      localPath: localPath ?? this.localPath,
      cloudPath: cloudPath ?? this.cloudPath,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FileModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'FileModel(id: $id, name: $name, type: $type, size: $size)';
  }
}