import 'package:flutter/material.dart';
import 'dart:math';

/// Fundo animado simples de partículas para o app, inspirado no fundo Kotlin Compose.
class ParticleBackground extends StatefulWidget {
  const ParticleBackground({super.key});

  @override
  State<ParticleBackground> createState() => _ParticleBackgroundState();
}

class _ParticleBackgroundState extends State<ParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final int totalParticles = 50;
  final Random rand = Random();
  late List<Offset> _particles;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(duration: const Duration(seconds: 10), vsync: this)
      ..repeat();
    _particles = List.generate(
        totalParticles, (_) => Offset(rand.nextDouble(), rand.nextDouble()));
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
        return CustomPaint(
          size: Size.infinite,
          painter: _ParticlePainter(_particles, _controller.value),
        );
      },
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<Offset> particles;
  final double progress;

  _ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3);
    for (var p in particles) {
      final dx = (p.dx * size.width + sin(progress * 2 * pi + p.dy * 10) * 16);
      final dy = (p.dy * size.height + cos(progress * 2 * pi + p.dx * 10) * 16);
      canvas.drawCircle(
        Offset(dx, dy),
        2 + 3 * (0.5 + 0.5 * sin(progress * 2 * pi + p.dx * 15)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) => true;
}
