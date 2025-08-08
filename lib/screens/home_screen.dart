import 'package:flutter/material.dart';
import '../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

class QuantumAnimatedBackground extends StatefulWidget {
  const QuantumAnimatedBackground({super.key});

  @override
  State<QuantumAnimatedBackground> createState() =>
      _QuantumAnimatedBackgroundState();
}

class _QuantumAnimatedBackgroundState extends State<QuantumAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(QuantumColors.neonBlue, QuantumColors.neonGreen,
                    _controller.value)!,
                Color.lerp(QuantumColors.neonPurple, QuantumColors.neonYellow,
                    1 - _controller.value)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      },
    );
  }
}

class HomeScreen extends StatelessWidget {
  final String email;

  const HomeScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: ShaderMask(
          shaderCallback: (rect) => quantumGradient.createShader(rect),
          child: Text(
            'Bem-vindo ao ChatCrypto',
            style: GoogleFonts.orbitron(
              fontWeight: FontWeight.bold,
              fontSize: 22,
              color: QuantumColors.neonGreen,
              letterSpacing: 2.2,
              shadows: [
                Shadow(blurRadius: 12,
                    color: QuantumColors.neonGreen,
                    offset: Offset(0, 0)),
              ],
            ),
          ),
        ),
        centerTitle: true,
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          const QuantumAnimatedBackground(),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (rect) => quantumGradient.createShader(rect),
                  child: Icon(Icons.account_circle, size: 60,
                      color: QuantumColors.neonGreen),
                ),
                const SizedBox(height: 32),
                Text("Usuário: $email", style: GoogleFonts.orbitron(
                    fontSize: 20,
                    color: QuantumColors.neonBlue,
                    letterSpacing: 1)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
