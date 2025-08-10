import 'package:flutter/material.dart';
import 'dart:io';
import '../models/file_model.dart';
import '../utils/app_theme.dart';

class UploadProgressCard extends StatelessWidget {
  final FileModel file;
  final double progress;
  final UploadStatus status;
  final VoidCallback? onCancel;
  final VoidCallback? onRetry;
  final String? errorMessage;

  const UploadProgressCard({
    super.key,
    required this.file,
    required this.progress,
    required this.status,
    this.onCancel,
    this.onRetry,
    this.errorMessage,
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // File header with icon and name
            Row(
              children: [
                _buildFileIcon(theme),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.originalName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatFileSize(file.size),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusIcon(theme),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Progress bar
            if (status == UploadStatus.uploading || status == UploadStatus.encrypting)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _getStatusText(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ],
              ),
            
            // Error message
            if (status == UploadStatus.error && errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.error.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: theme.colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Action buttons
            if (status == UploadStatus.uploading || status == UploadStatus.encrypting)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onCancel != null)
                    TextButton(
                      onPressed: onCancel,
                      child: const Text('Abbrechen'),
                    ),
                ],
              )
            else if (status == UploadStatus.error)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onRetry != null)
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Wiederholen'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileIcon(ThemeData theme) {
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
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        iconData,
        size: 20,
        color: iconColor,
      ),
    );
  }

  Widget _buildStatusIcon(ThemeData theme) {
    IconData iconData;
    Color iconColor;
    
    switch (status) {
      case UploadStatus.encrypting:
        iconData = Icons.lock;
        iconColor = Colors.orange;
        break;
      case UploadStatus.uploading:
        iconData = Icons.cloud_upload;
        iconColor = Colors.blue;
        break;
      case UploadStatus.completed:
        iconData = Icons.check_circle;
        iconColor = Colors.green;
        break;
      case UploadStatus.error:
        iconData = Icons.error;
        iconColor = Colors.red;
        break;
      case UploadStatus.cancelled:
        iconData = Icons.cancel;
        iconColor = Colors.grey;
        break;
    }
    
    return Icon(
      iconData,
      color: iconColor,
      size: 24,
    );
  }

  String _getStatusText() {
    switch (status) {
      case UploadStatus.encrypting:
        return 'Verschlüsselung läuft...';
      case UploadStatus.uploading:
        return 'Upload läuft...';
      case UploadStatus.completed:
        return 'Upload abgeschlossen';
      case UploadStatus.error:
        return 'Upload fehlgeschlagen';
      case UploadStatus.cancelled:
        return 'Upload abgebrochen';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

enum UploadStatus {
  encrypting,
  uploading,
  completed,
  error,
  cancelled,
}