import 'package:flutter/material.dart';

/// Identidad visual tomada del logo oficial de FICON.
class FiconColors {
  FiconColors._();

  static const Color ink = Color(0xFF001020);
  static const Color deep = Color(0xFF002030);
  static const Color deepAlt = Color(0xFF003040);
  static const Color logoBlue = Color(0xFF1080C0);
  static const Color cyan = Color(0xFF20E0F0);
  static const Color cyanSoft = Color(0xFF20C0D0);
  static const Color surface = Color(0xFFF2F7F9);
  static const Color cardBorder = Color(0xFF8FD8E2);
  static const Color cardBorderSoft = Color(0xFFDCE9EF);

  // Estados expresados con variaciones de la paleta del logo.
  static const Color success = cyan;
  static const Color warning = cyanSoft;
  static const Color danger = logoBlue;
  static const Color slate = deepAlt;
}

class FiconGradients {
  FiconGradients._();

  static const LinearGradient brand = LinearGradient(
    colors: [
      FiconColors.ink,
      FiconColors.deep,
      FiconColors.logoBlue,
      FiconColors.cyan,
    ],
  );

  static const LinearGradient signal = LinearGradient(
    colors: [
      FiconColors.logoBlue,
      FiconColors.cyanSoft,
      FiconColors.cyan,
    ],
  );
}

class FiconAssets {
  FiconAssets._();

  static const String logo = 'assets/brand/logo.png';
}

ThemeData buildFiconTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: FiconColors.logoBlue,
    primary: FiconColors.logoBlue,
    secondary: FiconColors.cyan,
    tertiary: FiconColors.cyanSoft,
    error: FiconColors.danger,
    surface: FiconColors.surface,
    brightness: Brightness.light,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: FiconColors.surface,
    appBarTheme: const AppBarTheme(
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      backgroundColor: FiconColors.ink,
      foregroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: FiconColors.cardBorderSoft),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: FiconColors.logoBlue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: FiconColors.cardBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: FiconColors.cyan, width: 1.5),
      ),
    ),
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(
        FiconColors.logoBlue.withValues(alpha: 0.08),
      ),
      dividerThickness: 0.6,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: FiconColors.ink,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  );
}

class FiconBrandMark extends StatelessWidget {
  const FiconBrandMark({
    super.key,
    this.height = 42,
    this.showPowerLabel = true,
  });

  final double height;
  final bool showPowerLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(FiconAssets.logo, height: height, fit: BoxFit.contain),
        if (showPowerLabel) ...[
          const SizedBox(width: 10),
          Text(
            'Power',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
          ),
        ],
      ],
    );
  }
}
