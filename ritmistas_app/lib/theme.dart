import 'package:flutter/material.dart';

// ============================================================
// RITMISTAS B10 — Design System (Single Source of Truth)
// ============================================================

// --- 1. COLOR TOKENS ---
class AppColors {
  // Core
  static const Color background = Color(0xFF000000);       // True OLED black
  static const Color surface = Color(0xFF0D0D0D);          // Slightly lifted
  static const Color cardBackground = Color(0xFF141414);   // Card base
  static const Color cardBackgroundAlt = Color(0xFF1A1A1A);// Card elevated
  static const Color surfaceVariant = Color(0xFF242424);   // Inputs, chips

  // Brand
  static const Color primaryGold = Color(0xFFFFD700);     // Primary accent
  static const Color primaryGoldDark = Color(0xFFB8960F); // Pressed state
  static const Color primaryGoldLight = Color(0xFFFFF0A0);// Highlight

  // Text
  static const Color textWhite = Colors.white;
  static const Color textSecondary = Color(0xFFB0B0B0);
  static const Color textTertiary = Color(0xFF707070);
  static const Color textOnGold = Color(0xFF1A1A00);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // Dividers & borders
  static const Color divider = Color(0xFF2A2A2A);
  static const Color border = Color(0xFF333333);
  static const Color borderGold = Color(0x40FFD700);       // 25% gold

  // Shimmer
  static const Color shimmerBase = Color(0xFF1A1A1A);
  static const Color shimmerHighlight = Color(0xFF2E2E2E);

  // Medals (ranking)
  static const Color medalGold = Color(0xFFFFD700);
  static const Color medalSilver = Color(0xFFC0C0C0);
  static const Color medalBronze = Color(0xFFCD7F32);

  // Backward-compatible aliases (used across 20+ existing pages)
  static const Color primaryYellow = primaryGold;
  static const Color textGrey = textTertiary;
}

// --- 2. SPACING TOKENS ---
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
  static const double xxxl = 64;

  // For bottom nav overlap
  static const double bottomNavPadding = 100;
}

// --- 3. RADIUS TOKENS ---
class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double pill = 999;
}

// --- 4. SHADOW TOKENS ---
class AppShadows {
  static List<BoxShadow> get card => [
    BoxShadow(
      color: Colors.black.withOpacity(0.4),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get elevated => [
    BoxShadow(
      color: Colors.black.withOpacity(0.6),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> glow(Color color, {double intensity = 0.3}) => [
    BoxShadow(
      color: color.withOpacity(intensity),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> get goldGlow => glow(AppColors.primaryGold, intensity: 0.25);
}

// --- 5. GRADIENT TOKENS ---
class AppGradients {
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1A1A1A), Color(0xFF0D0D0D)],
  );

  static const LinearGradient goldShimmer = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFD700), Color(0xFFFFA500), Color(0xFFFFD700)],
  );

  static const LinearGradient darkFade = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Colors.transparent, Color(0xFF000000)],
  );

  static const LinearGradient subtleGold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x15FFD700), Color(0x05FFD700)],
  );

  static const LinearGradient profileCard = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1E1E1E), Color(0xFF0A0A0A)],
  );
}

// --- 6. ANIMATION TOKENS ---
class AppAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration shimmer = Duration(milliseconds: 1500);
  static const Duration counter = Duration(milliseconds: 800);

  static const Curve standard = Curves.easeInOut;
  static const Curve enter = Curves.easeOut;
  static const Curve exit = Curves.easeIn;
  static const Curve bounce = Curves.elasticOut;
}

// --- 7. TYPOGRAPHY ---
class AppTypography {
  static const String fontFamily = 'Roboto';

  static const TextStyle headline = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: AppColors.textWhite,
    letterSpacing: -0.5,
  );

  static const TextStyle title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textWhite,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textWhite,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textWhite,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
  );

  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: AppColors.textTertiary,
    letterSpacing: 1.2,
  );

  static const TextStyle goldAccent = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: AppColors.primaryGold,
  );
}

// --- 8. GLOBAL THEME ---
final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.background,
  primaryColor: AppColors.primaryGold,
  fontFamily: AppTypography.fontFamily,

  colorScheme: const ColorScheme.dark(
    primary: AppColors.primaryGold,
    secondary: AppColors.primaryGold,
    surface: AppColors.cardBackground,
    error: AppColors.error,
    onPrimary: AppColors.textOnGold,
    onSecondary: AppColors.textOnGold,
    onSurface: AppColors.textWhite,
    onError: AppColors.textWhite,
  ),

  // AppBar
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.bold,
      color: AppColors.textWhite,
      fontFamily: AppTypography.fontFamily,
    ),
    iconTheme: IconThemeData(color: AppColors.textWhite),
  ),

  // Cards
  cardTheme: CardTheme(
    color: AppColors.cardBackground,
    elevation: 0,
    margin: const EdgeInsets.only(bottom: 12),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.lg),
    ),
  ),

  // Elevated Buttons
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primaryGold,
      foregroundColor: AppColors.textOnGold,
      elevation: 0,
      shadowColor: AppColors.primaryGold.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        fontFamily: AppTypography.fontFamily,
      ),
    ),
  ),

  // Outlined buttons
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryGold,
      side: const BorderSide(color: AppColors.borderGold, width: 1.5),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        fontFamily: AppTypography.fontFamily,
      ),
    ),
  ),

  // Text buttons
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryGold,
      textStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontFamily: AppTypography.fontFamily,
      ),
    ),
  ),

  // Inputs
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surfaceVariant,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.border, width: 0.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.primaryGold, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
      borderSide: const BorderSide(color: AppColors.error, width: 1),
    ),
    hintStyle: const TextStyle(color: AppColors.textTertiary),
    prefixIconColor: AppColors.textTertiary,
    labelStyle: const TextStyle(color: AppColors.textSecondary),
  ),

  // Dialogs
  dialogTheme: DialogTheme(
    backgroundColor: AppColors.cardBackground,
    elevation: 24,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.xl),
    ),
    titleTextStyle: const TextStyle(
      color: AppColors.textWhite,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontFamily: AppTypography.fontFamily,
    ),
  ),

  // SnackBars
  snackBarTheme: SnackBarThemeData(
    backgroundColor: AppColors.cardBackgroundAlt,
    contentTextStyle: const TextStyle(color: AppColors.textWhite),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    ),
    behavior: SnackBarBehavior.floating,
  ),

  // Chips
  chipTheme: ChipThemeData(
    backgroundColor: AppColors.surfaceVariant,
    labelStyle: const TextStyle(
      color: AppColors.textWhite,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    side: const BorderSide(color: AppColors.border, width: 0.5),
  ),

  // TabBar
  tabBarTheme: const TabBarTheme(
    indicatorColor: AppColors.primaryGold,
    labelColor: AppColors.primaryGold,
    unselectedLabelColor: AppColors.textTertiary,
    labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
    unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
    indicatorSize: TabBarIndicatorSize.label,
  ),

  // Dividers
  dividerTheme: const DividerThemeData(
    color: AppColors.divider,
    thickness: 0.5,
  ),

  // Progress indicators
  progressIndicatorTheme: const ProgressIndicatorThemeData(
    color: AppColors.primaryGold,
  ),

  // Bottom sheet
  bottomSheetTheme: const BottomSheetThemeData(
    backgroundColor: AppColors.cardBackground,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
  ),
);