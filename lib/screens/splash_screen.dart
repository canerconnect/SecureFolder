import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:secure_folder/providers/auth_provider.dart';
import 'package:secure_folder/providers/biometric_provider.dart';
import 'package:secure_folder/providers/file_provider.dart';
import 'package:secure_folder/screens/auth/login_screen.dart';
import 'package:secure_folder/screens/auth/biometric_lock_screen.dart';
import 'package:secure_folder/screens/home/main_screen.dart';
import 'package:secure_folder/utils/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
    ));

    _controller.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Wait for minimum splash duration
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final biometricProvider = Provider.of<BiometricProvider>(context, listen: false);
      final fileProvider = Provider.of<FileProvider>(context, listen: false);

      // Check if user is authenticated
      if (authProvider.isAuthenticated) {
        // Initialize file provider
        await fileProvider.initialize(authProvider.user!.uid);

        // Check if biometric authentication is required
        if (biometricProvider.isEnabled && !biometricProvider.isAuthenticated) {
          _navigateToScreen(const BiometricLockScreen());
        } else {
          _navigateToScreen(const MainScreen());
        }
      } else {
        _navigateToScreen(const LoginScreen());
      }
    } catch (e) {
      // If any error occurs, go to login
      _navigateToScreen(const LoginScreen());
    }
  }

  void _navigateToScreen(Widget screen) {
    if (!mounted) return;
    
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.systemBackground,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // App Icon
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryBlue,
                            Color(0xFF5AC8FA),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryBlue.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.folder_special_rounded,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // App Name
                    Text(
                      'SecureFolder',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.label,
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Subtitle
                    Text(
                      'Sicher • Privat • Verschlüsselt',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.secondaryLabel,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    
                    const SizedBox(height: 64),
                    
                    // Loading Indicator
                    Container(
                      width: 32,
                      height: 32,
                      child: const CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryBlue),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}