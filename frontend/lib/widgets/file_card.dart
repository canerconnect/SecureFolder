import 'package:flutter/material.dart';
import '../models/file_model.dart';
import '../utils/app_theme.dart';

class FileCard extends StatelessWidget {
  final FileModel file;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onShare;
  final VoidCallback? onDownload;

  const FileCard({
    super.key,
    required this.file,
    this.onTap,
    this.onDelete,
    this.onShare,
    this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // File thumbnail/icon
              _buildThumbnail(context),
              const SizedBox(width: 16),
              
              // File information
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      file.originalName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatFileSize(file.size),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _buildFileTypeChip(),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(file.uploadDate),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action buttons
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(BuildContext context) {
    final theme = Theme.of(context);
    final size = 60.0;
    
    if (file.thumbnailPath != null && file.thumbnailPath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(file.thumbnailPath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildFileIcon(size, theme);
          },
        ),
      );
    }
    
    return _buildFileIcon(size, theme);
  }

  Widget _buildFileIcon(double size, ThemeData theme) {
    IconData iconData;
    Color iconColor;
    
    switch (file.type) {
      case FileType.photo:
        iconData = Icons.photo;
        iconColor = Colors.blue;
        break;
      case FileType.video:
        iconData = Icons.videocam;
        iconColor = Colors.red;
        break;
      case FileType.audio:
        iconData = Icons.audiotrack;
        iconColor = Colors.green;
        break;
      case FileType.note:
        iconData = Icons.note;
        iconColor = Colors.orange;
        break;
      case FileType.document:
        iconData = Icons.description;
        iconColor = Colors.purple;
        break;
      case FileType.other:
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.grey;
        break;
    }
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        size: size * 0.4,
        color: iconColor,
      ),
    );
  }

  Widget _buildFileTypeChip() {
    String label;
    Color color;
    
    switch (file.type) {
      case FileType.photo:
        label = 'Foto';
        color = Colors.blue;
        break;
      case FileType.video:
        label = 'Video';
        color = Colors.red;
        break;
      case FileType.audio:
        label = 'Audio';
        color = Colors.green;
        break;
      case FileType.note:
        label = 'Notiz';
        color = Colors.orange;
        break;
      case FileType.document:
        label = 'Dokument';
        color = Colors.purple;
        break;
      case FileType.other:
      default:
        label = 'Sonstiges';
        color = Colors.grey;
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onDownload != null)
          IconButton(
            onPressed: onDownload,
            icon: const Icon(Icons.download),
            tooltip: 'Herunterladen',
            iconSize: 20,
          ),
        if (onShare != null)
          IconButton(
            onPressed: onShare,
            icon: const Icon(Icons.share),
            tooltip: 'Teilen',
            iconSize: 20,
          ),
        if (onDelete != null)
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete),
            tooltip: 'Löschen',
            iconSize: 20,
            color: Colors.red,
          ),
      ],
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'vor ${difference.inMinutes} Min';
      }
      return 'vor ${difference.inHours} Std';
    } else if (difference.inDays == 1) {
      return 'Gestern';
    } else if (difference.inDays < 7) {
      return 'vor ${difference.inDays} Tagen';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}