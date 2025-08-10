import 'package:flutter/material.dart';
import 'package:secure_folder/utils/theme.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.systemBackground,
      appBar: AppBar(
        title: const Text('Registrieren'),
      ),
      body: const Center(
        child: Text('Registrierung - TODO: Implementieren'),
      ),
    );
  }
}