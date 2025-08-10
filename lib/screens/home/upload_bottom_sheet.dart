import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secure_folder/providers/file_provider.dart';
import 'package:secure_folder/utils/theme.dart';
import 'package:secure_folder/screens/notes/note_edit_screen.dart';
import 'package:secure_folder/screens/audio/audio_recorder_screen.dart';

class UploadBottomSheet extends StatelessWidget {
  const UploadBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 5,
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              decoration: BoxDecoration(
                color: AppTheme.systemGray3,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Hinzufügen',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Photo/Video Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _UploadOption(
                      icon: Icons.photo_camera_rounded,
                      title: 'Foto aufnehmen',
                      color: const Color(0xFF34C759),
                      onTap: () => _uploadFromCamera(context, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _UploadOption(
                      icon: Icons.videocam_rounded,
                      title: 'Video aufnehmen',
                      color: const Color(0xFFFF3B30),
                      onTap: () => _uploadFromCamera(context, true),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Gallery Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _UploadOption(
                      icon: Icons.photo_library_rounded,
                      title: 'Foto auswählen',
                      color: const Color(0xFF5AC8FA),
                      onTap: () => _uploadFromGallery(context, false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _UploadOption(
                      icon: Icons.video_library_rounded,
                      title: 'Video auswählen',
                      color: const Color(0xFFAF52DE),
                      onTap: () => _uploadFromGallery(context, true),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Divider
            Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 20),
              color: AppTheme.systemGray5,
            ),
            
            const SizedBox(height: 20),
            
            // Other Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _UploadListItem(
                    icon: Icons.description_rounded,
                    title: 'Dokument auswählen',
                    color: const Color(0xFF007AFF),
                    onTap: () => _uploadDocument(context),
                  ),
                  _UploadListItem(
                    icon: Icons.note_alt_rounded,
                    title: 'Notiz erstellen',
                    color: const Color(0xFFFF9500),
                    onTap: () => _createNote(context),
                  ),
                  _UploadListItem(
                    icon: Icons.mic_rounded,
                    title: 'Sprachmemo aufnehmen',
                    color: const Color(0xFFFF9500),
                    onTap: () => _recordAudio(context),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadFromCamera(BuildContext context, bool isVideo) async {
    Navigator.pop(context);
    
    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    final success = await fileProvider.uploadFromCamera(isVideo: isVideo);
    
    if (context.mounted) {
      _showResult(context, success, isVideo ? 'Video' : 'Foto');
    }
  }

  Future<void> _uploadFromGallery(BuildContext context, bool isVideo) async {
    Navigator.pop(context);
    
    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    final success = await fileProvider.uploadFromGallery(isVideo: isVideo);
    
    if (context.mounted) {
      _showResult(context, success, isVideo ? 'Video' : 'Foto');
    }
  }

  Future<void> _uploadDocument(BuildContext context) async {
    Navigator.pop(context);
    
    final fileProvider = Provider.of<FileProvider>(context, listen: false);
    final success = await fileProvider.uploadDocument();
    
    if (context.mounted) {
      _showResult(context, success, 'Dokument');
    }
  }

  void _createNote(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NoteEditScreen(),
      ),
    );
  }

  void _recordAudio(BuildContext context) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AudioRecorderScreen(),
      ),
    );
  }

  void _showResult(BuildContext context, bool success, String fileType) {
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$fileType erfolgreich hinzugefügt'),
          backgroundColor: AppTheme.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Hinzufügen des $fileType'),
          backgroundColor: AppTheme.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      );
    }
  }
}

class _UploadOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _UploadOption({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: AppTheme.secondarySystemBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.systemGray5,
            width: 0.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 28,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _UploadListItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _UploadListItem({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppTheme.systemGray2,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        tileColor: AppTheme.secondarySystemBackground,
      ),
    );
  }
}