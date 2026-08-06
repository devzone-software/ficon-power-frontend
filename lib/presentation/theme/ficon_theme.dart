import 'package:flutter/material.dart';

/// Identidad visual inspirada en FICON: fibra óptica, estabilidad,
/// velocidad y monitoreo eléctrico.
class FiconColors {
  FiconColors._();

  static const Color ink = Color(0xFF11233B);
  static const Color primary = Color(0xFF073B73);
  static const Color primaryDark = Color(0xFF052A53);
  static const Color fiberBlue = Color(0xFF009FE3);
  static const Color signalGreen = Color(0xFF22A447);
  static const Color lime = Color(0xFF9BD23C);
  static const Color energy = Color(0xFFFF7A00);
  static const Color danger = Color(0xFFE11D48);
  static const Color resolved = Color(0xFF557286);
  static const Color surface = Color(0xFFF4F8FC);
  static const Color cardBorder = Color(0xFFD6E2EC);
}

class FiconGradients {
  FiconGradients._();

  static const LinearGradient brand = LinearGradient(
    colors: [
      FiconColors.primaryDark,
      FiconColors.primary,
      FiconColors.fiberBlue,
      FiconColors.signalGreen,
    ],
  );

  static const LinearGradient signal = LinearGradient(
    colors: [
      FiconColors.fiberBlue,
      FiconColors.signalGreen,
      FiconColors.lime,
    ],
  );
}

ThemeData buildFiconTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: FiconColors.primary,
    primary: FiconColors.primary,
    secondary: FiconColors.fiberBlue,
    tertiary: FiconColors.signalGreen,
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
      backgroundColor: Colors.white,
      foregroundColor: FiconColors.ink,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: Colors.white,
      margin: EdgeInsets.zero,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: FiconColors.cardBorder),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: FiconColors.primary,
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
        borderSide: const BorderSide(color: FiconColors.fiberBlue, width: 1.5),
      ),
    ),
    dataTableTheme: DataTableThemeData(
      headingRowColor: WidgetStatePropertyAll(
        FiconColors.primary.withValues(alpha: 0.06),
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
  const FiconBrandMark({super.key, this.size = 36, this.compact = false});

  final double size;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: FiconGradients.brand,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: FiconColors.fiberBlue.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: CustomPaint(
            painter: _FiconSignalPainter(),
            child: const Center(
              child: Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
            ),
          ),
        ),
        if (!compact) ...[
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FICON',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: FiconColors.ink,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      height: 1,
                    ),
              ),
              Text(
                'Power',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: FiconColors.resolved,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      height: 1.1,
                    ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _FiconSignalPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.36)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final path = Path()
      ..moveTo(size.width * 0.16, size.height * 0.70)
      ..cubicTo(
        size.width * 0.34,
        size.height * 0.54,
        size.width * 0.48,
        size.height * 0.84,
        size.width * 0.66,
        size.height * 0.50,
      )
      ..cubicTo(
        size.width * 0.76,
        size.height * 0.30,
        size.width * 0.86,
        size.height * 0.30,
        size.width * 0.92,
        size.height * 0.26,
      );
    canvas.drawPath(path, paint);

    final dotPaint = Paint()..color = Colors.white;
    canvas.drawCircle(
      Offset(size.width * 0.84, size.height * 0.30),
      size.width * 0.045,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
