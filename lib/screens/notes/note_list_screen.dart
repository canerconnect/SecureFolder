import 'package:flutter/material.dart';
import 'package:secure_folder/utils/theme.dart';

class NoteListScreen extends StatelessWidget {
  const NoteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.systemBackground,
      appBar: AppBar(
        title: const Text('Notizen'),
      ),
      body: const Center(
        child: Text('Notizen Liste - TODO: Implementieren'),
      ),
    );
  }
}