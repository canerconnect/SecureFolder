import 'package:flutter/material.dart';
import 'package:secure_folder/utils/theme.dart';

class NoteEditScreen extends StatelessWidget {
  const NoteEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.systemBackground,
      appBar: AppBar(
        title: const Text('Notiz bearbeiten'),
      ),
      body: const Center(
        child: Text('Notiz Editor - TODO: Implementieren'),
      ),
    );
  }
}