import 'package:flutter/material.dart';
import 'package:secure_folder/models/secure_file.dart';
import 'package:secure_folder/utils/theme.dart';

class FileCategoryScreen extends StatelessWidget {
  final FileType fileType;

  const FileCategoryScreen({super.key, required this.fileType});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.systemBackground,
      appBar: AppBar(
        title: Text(_getTitle()),
      ),
      body: Center(
        child: Text('${_getTitle()} Ansicht - TODO: Implementieren'),
      ),
    );
  }

  String _getTitle() {
    switch (fileType) {
      case FileType.photo:
        return 'Fotos';
      case FileType.video:
        return 'Videos';
      case FileType.document:
        return 'Dokumente';
      case FileType.note:
        return 'Notizen';
      case FileType.audio:
        return 'Sprachmemos';
    }
  }
}