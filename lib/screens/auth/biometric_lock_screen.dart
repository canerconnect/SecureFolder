import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secure_folder/providers/biometric_provider.dart';
import 'package:secure_folder/utils/theme.dart';
import 'package:secure_folder/screens/home/main_screen.dart';

class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  final _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _attemptBiometricAuth();
  }

  Future<void> _attemptBiometricAuth() async {
    final biometricProvider = Provider.of<BiometricProvider>(context, listen: false);
    
    if (biometricProvider.authMethod == AuthMethod.biometric) {
      final success = await biometricProvider.authenticateWithBiometric();
      if (success && mounted) {
        _navigateToMain();
      }
    }
  }

  Future<void> _authenticateWithPin() async {
    final biometricProvider = Provider.of<BiometricProvider>(context, listen: false);
    final success = await biometricProvider.authenticateWithPin(_pinController.text);
    
    if (success && mounted) {
      _navigateToMain();
    }
  }

  void _navigateToMain() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lockBackground,
      body: Consumer<BiometricProvider>(
        builder: (context, biometricProvider, child) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.lock_rounded,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'SecureFolder',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  if (biometricProvider.authMethod == AuthMethod.pin) ...[
                    TextField(
                      controller: _pinController,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'PIN eingeben',
                        hintStyle: TextStyle(color: Colors.white70),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white70),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.white),
                        ),
                      ),
                      onSubmitted: (_) => _authenticateWithPin(),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _authenticateWithPin,
                      child: const Text('Entsperren'),
                    ),
                  ] else ...[
                    ElevatedButton(
                      onPressed: _attemptBiometricAuth,
                      child: Text('Mit ${biometricProvider.getBiometricTypeName(biometricProvider.primaryBiometricType)} entsperren'),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}