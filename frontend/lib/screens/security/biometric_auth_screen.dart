import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/security_provider.dart';
import '../../utils/app_theme.dart';
import '../main/home_screen.dart';
import 'pin_auth_screen.dart';

class BiometricAuthScreen extends StatefulWidget {
  const BiometricAuthScreen({super.key});

  @override
  State<BiometricAuthScreen> createState() => _BiometricAuthScreenState();
}

class _BiometricAuthScreenState extends State<BiometricAuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  
  bool _isAuthenticating = false;
  bool _showFallback = false;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.8, 1.0, curve: Curves.easeInOut),
    ));
    
    _animationController.forward();
    
    // Auto-trigger biometric auth after animation
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        _authenticateWithBiometrics();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return;
    
    setState(() {
      _isAuthenticating = true;
    });
    
    final securityProvider = context.read<SecurityProvider>();
    
    try {
      final success = await securityProvider.authenticateWithBiometrics();
      
      if (success && mounted) {
        // Authentication successful, navigate to home
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 500),
          ),
        );
      } else {
        // Authentication failed, show fallback options
        setState(() {
          _showFallback = true;
        });
      }
    } catch (e) {
      // Biometric not available, show fallback
      setState(() {
        _showFallback = true;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  void _navigateToPinAuth() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const PinAuthScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 1.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App Logo
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.folder_secure,
                          size: 60,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Title
                      Text(
                        'App entsperren',
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onBackground,
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Subtitle
                      Text(
                        'Verwenden Sie Ihren Fingerabdruck\noder Gesichtserkennung',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      
                      const SizedBox(height: 60),
                      
                      // Biometric Icon
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _pulseAnimation.value,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: _isAuthenticating
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(40),
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.primary,
                                  width: 2,
                                ),
                              ),
                              child: Icon(
                                _isAuthenticating
                                    ? Icons.fingerprint
                                    : Icons.fingerprint_outlined,
                                size: 40,
                                color: _isAuthenticating
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Status Text
                      Text(
                        _isAuthenticating
                            ? 'Authentifizierung läuft...'
                            : 'Berühren Sie den Sensor',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: _isAuthenticating
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                          fontWeight: _isAuthenticating ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      
                      if (_showFallback) ...[
                        const SizedBox(height: 40),
                        
                        // Fallback Options
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'Alternative Anmeldemethoden',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onBackground,
                                ),
                              ),
                              
                              const SizedBox(height: 16),
                              
                              // PIN Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: ElevatedButton.icon(
                                  onPressed: _navigateToPinAuth,
                                  icon: const Icon(Icons.pin),
                                  label: const Text('Mit PIN anmelden'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(context).colorScheme.secondary,
                                    foregroundColor: Theme.of(context).colorScheme.onSecondary,
                                  ),
                                ),
                              ),
                              
                              const SizedBox(height: 12),
                              
                              // Retry Biometric Button
                              SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: OutlinedButton.icon(
                                  onPressed: _authenticateWithBiometrics,
                                  icon: const Icon(Icons.refresh),
                                  label: const Text('Biometrie erneut versuchen'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 40),
                      
                      // Help Text
                      Text(
                        'Ihre Daten sind sicher verschlüsselt',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}