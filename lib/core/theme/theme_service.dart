import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Egyptian-inspired color palette
class KemetColors {
  // Primary brand colors
  static const Color primary = Color(0xFFFF7D29);      // Egyptian Orange
  static const Color secondary = Color(0xFFFFBF78);    // Light Orange
  static const Color accent = Color(0xFF5A2D0C);       // Papyrus Brown
  
  // Background colors
  static const Color background = Color(0xFFFEFFD2);   // Papyrus
  static const Color cardBackground = Colors.white;    // White
  static const Color secondaryBackground = Color(0xFFFFEEA9); // Light Gold
  
  // Text colors
  static const Color textPrimary = Color(0xFF333333);  // Near Black
  static const Color textSecondary = Color(0xFF666666); // Dark Gray
  static const Color textLight = Color(0xFF999999);    // Light Gray
  
  // Feedback colors
  static const Color success = Color(0xFF388E3C);      // Green
  static const Color warning = Color(0xFFF57C00);      // Amber
  static const Color error = Color(0xFFD32F2F);        // Red
  static const Color info = Color(0xFF1976D2);         // Blue
  
  // Other UI colors
  static const Color divider = Color(0xFFE0E0E0);      // Light Gray
  static const Color disabled = Color(0xFFBDBDBD);     // Mid Gray
  static const Color inactiveIcon = Colors.grey;       // Gray
  static const Color shadow = Color(0x40000000);       // Black with alpha
}

class KemetGradients {
  // Beautiful gradients for headers, buttons, etc.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [KemetColors.primary, Color(0xFFFF9D49)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFFFD700), Color(0xFFFFC107)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient nightSkyGradient = LinearGradient(
    colors: [Color(0xFF1A237E), Color(0xFF000000)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
  
  static const LinearGradient desertGradient = LinearGradient(
    colors: [Color(0xFFFFCC80), Color(0xFFFFE0B2)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

class KemetTheme {
  static ThemeData get lightTheme {
    final ThemeData base = ThemeData.light();
    
    return base.copyWith(
      primaryColor: KemetColors.primary,
      scaffoldBackgroundColor: KemetColors.background,
      colorScheme: ColorScheme.light(
        primary: KemetColors.primary,
        secondary: KemetColors.secondary,
        surface: KemetColors.cardBackground,
        background: KemetColors.background,
        error: KemetColors.error,
      ),
      
      // Text Theme
      textTheme: _buildTextTheme(base.textTheme),
      primaryTextTheme: _buildTextTheme(base.primaryTextTheme),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        elevation: 0,
        color: KemetColors.primary,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.white,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      
      // Card Theme
      cardTheme: CardTheme(
        elevation: 4,
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KemetColors.primary,
          foregroundColor: Colors.white,
          elevation: 3,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KemetColors.primary,
          side: BorderSide(color: KemetColors.primary, width: 2),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KemetColors.primary,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          textStyle: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: KemetColors.divider, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: KemetColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: KemetColors.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide(color: KemetColors.error, width: 2),
        ),
        hintStyle: TextStyle(color: KemetColors.textLight),
        prefixIconColor: KemetColors.primary,
        suffixIconColor: KemetColors.primary,
      ),
      
      // Dialog Theme
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        elevation: 8,
        backgroundColor: Colors.white,
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: KemetColors.textPrimary,
        ),
        contentTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          color: KemetColors.textSecondary,
        ),
      ),
      
      // Bottom Navigation Bar
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: KemetColors.primary,
        unselectedItemColor: KemetColors.inactiveIcon,
        selectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 12,
        ),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Tab Bar Theme
      tabBarTheme: TabBarTheme(
        indicatorColor: KemetColors.primary,
        labelColor: KemetColors.primary,
        unselectedLabelColor: KemetColors.textSecondary,
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 14,
        ),
      ),
      
      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: KemetColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      
      // Checkbox Theme
      checkboxTheme: CheckboxThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.disabled)) {
              return KemetColors.disabled;
            }
            return KemetColors.primary;
          }
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      
      // Radio Button Theme
      radioTheme: RadioThemeData(
        fillColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.disabled)) {
              return KemetColors.disabled;
            }
            return KemetColors.primary;
          }
        ),
      ),
      
      // Switch Theme
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.disabled)) {
              return KemetColors.disabled;
            } else if (states.contains(MaterialState.selected)) {
              return KemetColors.primary;
            }
            return Colors.white;
          }
        ),
        trackColor: MaterialStateProperty.resolveWith<Color>(
          (Set<MaterialState> states) {
            if (states.contains(MaterialState.disabled)) {
              return KemetColors.disabled.withOpacity(0.5);
            } else if (states.contains(MaterialState.selected)) {
              return KemetColors.primary.withOpacity(0.5);
            }
            return KemetColors.textLight.withOpacity(0.5);
          }
        ),
      ),
      
      // Progress Indicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: KemetColors.primary,
        circularTrackColor: KemetColors.divider,
        linearTrackColor: KemetColors.divider,
      ),
      
      // Slider Theme
      sliderTheme: SliderThemeData(
        activeTrackColor: KemetColors.primary,
        inactiveTrackColor: KemetColors.divider,
        thumbColor: KemetColors.primary,
        overlayColor: KemetColors.primary.withOpacity(0.2),
        valueIndicatorColor: KemetColors.primary,
        valueIndicatorTextStyle: TextStyle(
          color: Colors.white,
        ),
      ),
    );
  }
  
  static TextTheme _buildTextTheme(TextTheme base) {
    return base.copyWith(
      displayLarge: base.displayLarge!.copyWith(
        fontFamily: 'Poppins',
        fontSize: 32,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: KemetColors.textPrimary,
      ),
      displayMedium: base.displayMedium!.copyWith(
        fontFamily: 'Poppins',
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: KemetColors.textPrimary,
      ),
      displaySmall: base.displaySmall!.copyWith(
        fontFamily: 'Poppins',
        fontSize: 24,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: KemetColors.textPrimary,
      ),
      headlineLarge: base.headlineLarge!.copyWith(
        fontFamily: 'Poppins',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: KemetColors.textPrimary,
      ),
      headlineMedium: base.headlineMedium!.copyWith(
        fontFamily: 'Poppins',
        fontSize: 22,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: KemetColors.textPrimary,
      ),
      headlineSmall: base.headlineSmall!.copyWith(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: KemetColors.textPrimary,
      ),
      titleLarge: base.titleLarge!.copyWith(
        fontFamily: 'Poppins',
        fontSize: 20,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: KemetColors.textPrimary,
      ),
      titleMedium: base.titleMedium!.copyWith(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: KemetColors.textPrimary,
      ),
      titleSmall: base.titleSmall!.copyWith(
        fontFamily: 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        color: KemetColors.textPrimary,
      ),
      bodyLarge: base.bodyLarge!.copyWith(
        fontFamily: 'Poppins',
        fontSize: 16,
        letterSpacing: 0.5,
        color: KemetColors.textSecondary,
      ),
      bodyMedium: base.bodyMedium!.copyWith(
        fontFamily: 'Poppins',
        fontSize: 14,
        letterSpacing: 0.25,
        color: KemetColors.textSecondary,
      ),
      bodySmall: base.bodySmall!.copyWith(
        fontFamily: 'Poppins',
        fontSize: 12,
        letterSpacing: 0.4,
        color: KemetColors.textLight,
      ),
      labelLarge: base.labelLarge!.copyWith(
        fontFamily: 'Poppins',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: KemetColors.textPrimary,
      ),
      labelMedium: base.labelMedium!.copyWith(
        fontFamily: 'Poppins',
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: KemetColors.textPrimary,
      ),
      labelSmall: base.labelSmall!.copyWith(
        fontFamily: 'Poppins',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
        color: KemetColors.textPrimary,
      ),
    );
  }
}

// Theme Manager class to handle theme changes
class ThemeManager with ChangeNotifier {
  final String _themeKey = 'theme_mode';
  final SharedPreferences _prefs;
  
  ThemeMode _themeMode;
  
  ThemeManager(this._prefs) : _themeMode = ThemeMode.light {
    _loadTheme();
  }
  
  ThemeMode get themeMode => _themeMode;
  
  void _loadTheme() {
    final int storageTheme = _prefs.getInt(_themeKey) ?? 0;
    _themeMode = ThemeMode.values[storageTheme];
    notifyListeners();
  }
  
  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light 
        ? ThemeMode.dark 
        : ThemeMode.light;
    
    await _prefs.setInt(_themeKey, _themeMode.index);
    notifyListeners();
  }
  
  static ThemeManager initialize() {
    final SharedPreferences prefs = SharedPreferences.getInstance() as SharedPreferences;
    return ThemeManager(prefs);
  }
}