import 'package:flutter/material.dart';
import 'package:secure_folder/utils/theme.dart';

class AudioRecorderScreen extends StatelessWidget {
  const AudioRecorderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.systemBackground,
      appBar: AppBar(
        title: const Text('Sprachmemo aufnehmen'),
      ),
      body: const Center(
        child: Text('Audio Recorder - TODO: Implementieren'),
      ),
    );
  }
}