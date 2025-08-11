import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors
  static const Color primaryColor = Color(0xFF2196F3);
  static const Color primaryLightColor = Color(0xFF64B5F6);
  static const Color primaryDarkColor = Color(0xFF1976D2);
  
  // Secondary colors
  static const Color secondaryColor = Color(0xFF4CAF50);
  static const Color secondaryLightColor = Color(0xFF81C784);
  static const Color secondaryDarkColor = Color(0xFF388E3C);
  
  // Accent colors
  static const Color accentColor = Color(0xFFFF9800);
  static const Color accentLightColor = Color(0xFFFFB74D);
  static const Color accentDarkColor = Color(0xFFF57C00);
  
  // Error colors
  static const Color errorColor = Color(0xFFF44336);
  static const Color errorLightColor = Color(0xFFE57373);
  static const Color errorDarkColor = Color(0xFFD32F2F);
  
  // Success colors
  static const Color successColor = Color(0xFF4CAF50);
  static const Color successLightColor = Color(0xFF81C784);
  static const Color successDarkColor = Color(0xFF388E3C);
  
  // Warning colors
  static const Color warningColor = Color(0xFFFF9800);
  static const Color warningLightColor = Color(0xFFFFB74D);
  static const Color warningDarkColor = Color(0xFFF57C00);
  
  // Info colors
  static const Color infoColor = Color(0xFF2196F3);
  static const Color infoLightColor = Color(0xFF64B5F6);
  static const Color infoDarkColor = Color(0xFF1976D2);

  // Light theme
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryLightColor,
        secondary: secondaryColor,
        secondaryContainer: secondaryLightColor,
        tertiary: accentColor,
        tertiaryContainer: accentLightColor,
        error: errorColor,
        errorContainer: errorLightColor,
        surface: Colors.white,
        surfaceVariant: Color(0xFFF5F5F5),
        background: Colors.white,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onTertiary: Colors.white,
        onError: Colors.white,
        onSurface: Colors.black87,
        onSurfaceVariant: Colors.black54,
        onBackground: Colors.black87,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(8),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.grey.shade200,
        selectedColor: primaryLightColor,
        labelStyle: const TextStyle(color: Colors.black87),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.grey,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: primaryColor,
        size: 24,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.grey.shade800,
        contentColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
      ),
    );
  }

  // Dark theme
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: primaryLightColor,
        primaryContainer: primaryDarkColor,
        secondary: secondaryLightColor,
        secondaryContainer: secondaryDarkColor,
        tertiary: accentLightColor,
        tertiaryContainer: accentDarkColor,
        error: errorLightColor,
        errorContainer: errorDarkColor,
        surface: Color(0xFF121212),
        surfaceVariant: Color(0xFF1E1E1E),
        background: Color(0xFF000000),
        onPrimary: Colors.black87,
        onSecondary: Colors.black87,
        onTertiary: Colors.black87,
        onError: Colors.black87,
        onSurface: Colors.white,
        onSurfaceVariant: Colors.white70,
        onBackground: Colors.white,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLightColor,
          foregroundColor: Colors.black87,
          elevation: 2,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryLightColor,
          side: const BorderSide(color: primaryLightColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryLightColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryLightColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorLightColor, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: errorLightColor, width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(8),
        color: const Color(0xFF1E1E1E),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF2E2E2E),
        selectedColor: primaryDarkColor,
        labelStyle: const TextStyle(color: Colors.white),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Colors.grey,
        thickness: 1,
        space: 1,
      ),
      iconTheme: const IconThemeData(
        color: primaryLightColor,
        size: 24,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryLightColor,
        foregroundColor: Colors.black87,
        elevation: 6,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: primaryLightColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Colors.grey.shade200,
        contentColor: Colors.black87,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        behavior: SnackBarBehavior.floating,
      ),
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
        backgroundColor: const Color(0xFF1E1E1E),
      ),
    );
  }

  // Custom color schemes for specific use cases
  static ColorScheme get successColorScheme {
    return const ColorScheme.light(
      primary: successColor,
      primaryContainer: successLightColor,
      onPrimary: Colors.white,
      onPrimaryContainer: Colors.black87,
    );
  }

  static ColorScheme get warningColorScheme {
    return const ColorScheme.light(
      primary: warningColor,
      primaryContainer: warningLightColor,
      onPrimary: Colors.white,
      onPrimaryContainer: Colors.black87,
    );
  }

  static ColorScheme get errorColorScheme {
    return const ColorScheme.light(
      primary: errorColor,
      primaryContainer: errorLightColor,
      onPrimary: Colors.white,
      onPrimaryContainer: Colors.black87,
    );
  }

  static ColorScheme get infoColorScheme {
    return const ColorScheme.light(
      primary: infoColor,
      primaryContainer: infoLightColor,
      onPrimary: Colors.white,
      onPrimaryContainer: Colors.black87,
    );
  }
}