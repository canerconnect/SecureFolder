import 'package:flutter/material.dart';
import 'package:secure_folder/utils/theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.systemBackground,
      appBar: AppBar(
        title: const Text('Einstellungen'),
      ),
      body: const Center(
        child: Text('Einstellungen - TODO: Implementieren'),
      ),
    );
  }
}