import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/file_model.dart';
import '../../providers/file_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/upload_progress_card.dart';

class UploadTab extends StatefulWidget {
  const UploadTab({super.key});

  @override
  State<UploadTab> createState() => _UploadTabState();
}

class _UploadTabState extends State<UploadTab> {
  final List<FileModel> _uploadQueue = [];
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Text(
            'Dateien hochladen',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onBackground,
            ),
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Wählen Sie Dateien von Ihrem Gerät aus oder erstellen Sie neue',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Upload Options
          Row(
            children: [
              // Gallery Button
              Expanded(
                child: _buildUploadOption(
                  icon: Icons.photo_library,
                  title: 'Galerie',
                  subtitle: 'Fotos & Videos',
                  color: AppTheme.primaryColor,
                  onTap: _selectFromGallery,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Camera Button
              Expanded(
                child: _buildUploadOption(
                  icon: Icons.camera_alt,
                  title: 'Kamera',
                  subtitle: 'Foto aufnehmen',
                  color: AppTheme.secondaryColor,
                  onTap: _takePhoto,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              // Document Button
              Expanded(
                child: _buildUploadOption(
                  icon: Icons.description,
                  title: 'Dokumente',
                  subtitle: 'PDF, DOC, etc.',
                  color: AppTheme.accentColor,
                  onTap: _selectDocuments,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Audio Button
              Expanded(
                child: _buildUploadOption(
                  icon: Icons.mic,
                  title: 'Audio',
                  subtitle: 'Sprachnotizen',
                  color: AppTheme.infoColor,
                  onTap: _recordAudio,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          
          // Drag & Drop Area
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                style: BorderStyle.solid,
                width: 2,
              ),
            ),
            child: InkWell(
              onTap: _selectFiles,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload,
                    size: 48,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Dateien hier ablegen oder tippen',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Unterstützte Formate: JPG, PNG, MP4, PDF, DOC, MP3...',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Upload Queue
          if (_uploadQueue.isNotEmpty) ...[
            Row(
              children: [
                Text(
                  'Upload-Warteschlange',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_uploadQueue.length} Dateien',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onBackground.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Expanded(
              child: ListView.builder(
                itemCount: _uploadQueue.length,
                itemBuilder: (context, index) {
                  final file = _uploadQueue[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: UploadProgressCard(
                      file: file,
                      onCancel: () => _removeFromQueue(index),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Upload All Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isUploading ? null : _uploadAllFiles,
                icon: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.upload),
                label: Text(_isUploading ? 'Wird hochgeladen...' : 'Alle hochladen'),
              ),
            ),
          ] else ...[
            // Empty State
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.upload_file,
                      size: 64,
                      color: Theme.of(context).colorScheme.onBackground.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Keine Dateien zum Hochladen',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Wählen Sie Dateien aus, um sie hochzuladen',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onBackground.withOpacity(0.4),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 32,
              color: color,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: color.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _selectFromGallery() {
    // TODO: Implement gallery selection
    _addToQueue(FileModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Foto_${DateTime.now().millisecondsSinceEpoch}.jpg',
      originalName: 'Foto_${DateTime.now().millisecondsSinceEpoch}.jpg',
      type: FileType.photo,
      size: 2048576, // 2MB
      uploadDate: DateTime.now(),
      isEncrypted: true,
      thumbnailPath: null,
      localPath: null,
      cloudPath: null,
    ));
  }

  void _takePhoto() {
    // TODO: Implement camera capture
    _addToQueue(FileModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Kamera_${DateTime.now().millisecondsSinceEpoch}.jpg',
      originalName: 'Kamera_${DateTime.now().millisecondsSinceEpoch}.jpg',
      type: FileType.photo,
      size: 1536000, // 1.5MB
      uploadDate: DateTime.now(),
      isEncrypted: true,
      thumbnailPath: null,
      localPath: null,
      cloudPath: null,
    ));
  }

  void _selectDocuments() {
    // TODO: Implement document selection
    _addToQueue(FileModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Dokument_${DateTime.now().millisecondsSinceEpoch}.pdf',
      originalName: 'Dokument_${DateTime.now().millisecondsSinceEpoch}.pdf',
      type: FileType.document,
      size: 1048576, // 1MB
      uploadDate: DateTime.now(),
      isEncrypted: true,
      thumbnailPath: null,
      localPath: null,
      cloudPath: null,
    ));
  }

  void _recordAudio() {
    // TODO: Implement audio recording
    _addToQueue(FileModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
      originalName: 'Audio_${DateTime.now().millisecondsSinceEpoch}.m4a',
      type: FileType.audio,
      size: 512000, // 500KB
      uploadDate: DateTime.now(),
      isEncrypted: true,
      thumbnailPath: null,
      localPath: null,
      cloudPath: null,
    ));
  }

  void _selectFiles() {
    // TODO: Implement file picker
    _addToQueue(FileModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: 'Datei_${DateTime.now().millisecondsSinceEpoch}.txt',
      originalName: 'Datei_${DateTime.now().millisecondsSinceEpoch}.txt',
      type: FileType.note,
      size: 1024, // 1KB
      uploadDate: DateTime.now(),
      isEncrypted: true,
      thumbnailPath: null,
      localPath: null,
      cloudPath: null,
    ));
  }

  void _addToQueue(FileModel file) {
    setState(() {
      _uploadQueue.add(file);
    });
  }

  void _removeFromQueue(int index) {
    setState(() {
      _uploadQueue.removeAt(index);
    });
  }

  Future<void> _uploadAllFiles() async {
    if (_uploadQueue.isEmpty) return;
    
    setState(() {
      _isUploading = true;
    });
    
    final fileProvider = context.read<FileProvider>();
    
    try {
      for (int i = 0; i < _uploadQueue.length; i++) {
        final file = _uploadQueue[i];
        
        // Simulate upload progress
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Add file to provider
        await fileProvider.addFile(file);
      }
      
      if (mounted) {
        setState(() {
          _uploadQueue.clear();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Alle Dateien wurden erfolgreich hochgeladen'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Hochladen: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }
}