import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AppTheme {
  // iOS-style colors
  static const Color primaryBlue = Color(0xFF007AFF);
  static const Color systemGray = Color(0xFF8E8E93);
  static const Color systemGray2 = Color(0xFFAEAEB2);
  static const Color systemGray3 = Color(0xFFC7C7CC);
  static const Color systemGray4 = Color(0xFFD1D1D6);
  static const Color systemGray5 = Color(0xFFE5E5EA);
  static const Color systemGray6 = Color(0xFFF2F2F7);
  static const Color systemBackground = Color(0xFFFFFFFF);
  static const Color secondarySystemBackground = Color(0xFFF2F2F7);
  static const Color label = Color(0xFF000000);
  static const Color secondaryLabel = Color(0xFF3C3C43);
  static const Color tertiaryLabel = Color(0xFF3C3C43);
  
  // Custom colors
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFF9500);
  static const Color error = Color(0xFFFF3B30);
  static const Color lockBackground = Color(0xFF1C1C1E);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'SF Pro Display',
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: systemBackground,
      backgroundColor: systemBackground,
      
      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: systemBackground,
        foregroundColor: label,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: label,
        ),
      ),
      
      // Card Theme
      cardTheme: CardTheme(
        color: systemBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          textStyle: const TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryBlue,
          textStyle: const TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 17,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: secondarySystemBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        hintStyle: const TextStyle(
          color: systemGray,
          fontFamily: 'SF Pro Display',
          fontSize: 17,
        ),
        labelStyle: const TextStyle(
          color: systemGray,
          fontFamily: 'SF Pro Display',
          fontSize: 17,
        ),
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 34,
          fontWeight: FontWeight.bold,
          color: label,
        ),
        displayMedium: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: label,
        ),
        displaySmall: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: label,
        ),
        headlineMedium: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: label,
        ),
        headlineSmall: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: label,
        ),
        titleLarge: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: label,
        ),
        bodyLarge: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: label,
        ),
        bodyMedium: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: label,
        ),
        bodySmall: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 13,
          fontWeight: FontWeight.w400,
          color: secondaryLabel,
        ),
        labelLarge: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: label,
        ),
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: systemGray,
        size: 24,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: systemGray4,
        thickness: 0.5,
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: systemBackground,
        selectedItemColor: primaryBlue,
        unselectedItemColor: systemGray,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        titleTextStyle: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 17,
          fontWeight: FontWeight.w400,
          color: label,
        ),
        subtitleTextStyle: TextStyle(
          fontFamily: 'SF Pro Display',
          fontSize: 15,
          fontWeight: FontWeight.w400,
          color: secondaryLabel,
        ),
      ),
    );
  }
}

// Custom widgets for iOS-style components
class IOSButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isDestructive;
  final double? width;

  const IOSButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isPrimary = true,
    this.isDestructive = false,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 50,
      child: CupertinoButton(
        onPressed: onPressed,
        color: isPrimary 
            ? (isDestructive ? AppTheme.error : AppTheme.primaryBlue)
            : null,
        borderRadius: BorderRadius.circular(10),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'SF Pro Display',
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: isPrimary 
                ? Colors.white 
                : (isDestructive ? AppTheme.error : AppTheme.primaryBlue),
          ),
        ),
      ),
    );
  }
}