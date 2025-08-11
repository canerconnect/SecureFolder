import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/security_provider.dart';
import '../../utils/app_theme.dart';
import '../main/home_screen.dart';

class PinAuthScreen extends StatefulWidget {
  const PinAuthScreen({super.key});

  @override
  State<PinAuthScreen> createState() => _PinAuthScreenState();
}

class _PinAuthScreenState extends State<PinAuthScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  final List<String> _pin = [];
  final int _pinLength = 6;
  bool _isAuthenticating = false;
  bool _showError = false;
  int _attempts = 0;
  final int _maxAttempts = 3;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _addDigit(String digit) {
    if (_pin.length < _pinLength && !_isAuthenticating) {
      setState(() {
        _pin.add(digit);
        _showError = false;
      });
      
      // Auto-authenticate when PIN is complete
      if (_pin.length == _pinLength) {
        _authenticatePin();
      }
    }
  }

  void _removeDigit() {
    if (_pin.isNotEmpty && !_isAuthenticating) {
      setState(() {
        _pin.removeLast();
        _showError = false;
      });
    }
  }

  void _clearPin() {
    if (!_isAuthenticating) {
      setState(() {
        _pin.clear();
        _showError = false;
      });
    }
  }

  Future<void> _authenticatePin() async {
    if (_isAuthenticating) return;
    
    setState(() {
      _isAuthenticating = true;
    });
    
    final securityProvider = context.read<SecurityProvider>();
    final pinString = _pin.join();
    
    try {
      final success = await securityProvider.authenticateWithPin(pinString);
      
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
        // Authentication failed
        setState(() {
          _showError = true;
          _attempts++;
        });
        
        // Clear PIN after failed attempt
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            setState(() {
              _pin.clear();
            });
          }
        });
        
        // Show error message
        if (_attempts >= _maxAttempts) {
          _showMaxAttemptsDialog();
        }
      }
    } catch (e) {
      setState(() {
        _showError = true;
        _attempts++;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler bei der Authentifizierung: $e'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAuthenticating = false;
        });
      }
    }
  }

  void _showMaxAttemptsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Zu viele Versuche'),
        content: const Text(
          'Sie haben zu viele falsche PIN-Versuche unternommen. '
          'Die App wird für 5 Minuten gesperrt.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement app lockout timer
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: const Text('PIN-Eingabe'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 40),
                      
                      // Header
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Icon(
                                Icons.pin,
                                size: 40,
                                color: Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            Text(
                              'PIN eingeben',
                              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onBackground,
                              ),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Text(
                              'Geben Sie Ihre 6-stellige PIN ein',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // PIN Display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _showError
                                ? AppTheme.errorColor
                                : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                            width: _showError ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(_pinLength, (index) {
                            final hasDigit = index < _pin.length;
                            return Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: hasDigit
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: hasDigit
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outline.withOpacity(0.5),
                                  width: 2,
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                      
                      if (_showError) ...[
                        const SizedBox(height: 16),
                        
                        Text(
                          'Falsche PIN. Versuche: $_attempts/$_maxAttempts',
                          style: TextStyle(
                            color: AppTheme.errorColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                      
                      const SizedBox(height: 40),
                      
                      // Number Pad
                      Expanded(
                        child: Column(
                          children: [
                            // Row 1-3
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNumberButton('1'),
                                _buildNumberButton('2'),
                                _buildNumberButton('3'),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Row 4-6
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNumberButton('4'),
                                _buildNumberButton('5'),
                                _buildNumberButton('6'),
                              ],
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Row 7-9
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildNumberButton('7'),
                                _buildNumberButton('8'),
                                _buildNumberButton('9'),
                              ],
                        ),
                            
                            const SizedBox(height: 20),
                            
                            // Row 0, clear, backspace
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildActionButton(
                                  icon: Icons.clear,
                                  onPressed: _clearPin,
                                  color: AppTheme.warningColor,
                                ),
                                _buildNumberButton('0'),
                                _buildActionButton(
                                  icon: Icons.backspace,
                                  onPressed: _removeDigit,
                                  color: AppTheme.errorColor,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Help Text
                      Text(
                        'Ihre PIN wird sicher gespeichert',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onBackground.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return SizedBox(
      width: 70,
      height: 70,
      child: ElevatedButton(
        onPressed: _isAuthenticating ? null : () => _addDigit(number),
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          foregroundColor: Theme.of(context).colorScheme.onSurfaceVariant,
          shape: const CircleBorder(),
          elevation: 2,
        ),
        child: Text(
          number,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: 70,
      height: 70,
      child: ElevatedButton(
        onPressed: _isAuthenticating ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: const CircleBorder(),
          elevation: 2,
        ),
        child: Icon(icon, size: 28),
      ),
    );
  }
}