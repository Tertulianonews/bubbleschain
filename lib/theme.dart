import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

typedef GradientQuantum = LinearGradient;

class QuantumColors {
  static const neonGreen = Color(0xFF00FF84);
  static const neonBlue = Color(0xFF00C8FF);
  static const neonPurple = Color(0xFF7F4EFF);
  static const neonYellow = Color(0xFFFFF000);
  static const neonPink = Color(0xFFFF29CB);
  static const black = Color(0xFF060817);
  static const white = Color(0xFFFFFFFF);
}

final quantumGradient = LinearGradient(
  colors: [
    QuantumColors.neonBlue,
    QuantumColors.neonGreen,
    QuantumColors.neonPurple,
    QuantumColors.neonYellow,
    QuantumColors.neonPink,
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

final quantumButtonGradient = LinearGradient(
  colors: [
    QuantumColors.neonGreen,
    QuantumColors.neonYellow,
    QuantumColors.neonBlue,
  ],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
);

final quantumTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: QuantumColors.black,
  colorScheme: ColorScheme.dark(
    primary: QuantumColors.neonGreen,
    secondary: QuantumColors.neonBlue,
    background: QuantumColors.black,
    onPrimary: QuantumColors.black,
    onSecondary: QuantumColors.black,
    error: QuantumColors.neonPink,
  ),
  textTheme: GoogleFonts.orbitronTextTheme(
    const TextTheme(
      headlineLarge: TextStyle(
        fontWeight: FontWeight.bold,
        color: QuantumColors.neonGreen,
        fontSize: 36,
        letterSpacing: 2.5,
        shadows: [
          Shadow(blurRadius: 18,
              color: QuantumColors.neonGreen,
              offset: Offset(0, 3)),
          Shadow(blurRadius: 24,
              color: QuantumColors.neonBlue,
              offset: Offset(1, 2)),
        ],
      ),
      bodyMedium: TextStyle(
        color: QuantumColors.white,
        fontWeight: FontWeight.w600,
        fontSize: 17,
        letterSpacing: 1.2,
      ),
      labelLarge: TextStyle(
        color: QuantumColors.neonGreen,
        fontWeight: FontWeight.bold,
      ),
    ).apply(
      fontSizeFactor: 1,
    ),
  ),
);

// Decorador glassmorphism para backgrounds dos campos/input
BoxDecoration quantumGlass({double radius = 20}) =>
    BoxDecoration(
      color: Colors.white.withOpacity(0.08),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
          color: QuantumColors.neonGreen.withOpacity(0.4), width: 2),
      boxShadow: [
        BoxShadow(color: QuantumColors.neonGreen.withOpacity(0.13),
            blurRadius: 24,
            spreadRadius: 1),
      ],
    );
