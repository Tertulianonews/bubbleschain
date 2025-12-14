import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'terline_t_logo.dart';

/// Composição desejada: partículas azuis/brancas animadas,
/// anel de partículas ao redor do logo centralizado.
class TerlineTParticlesDisplayStateful extends StatefulWidget {
  final double width;
  final double height;
  final int totalParticles;

  const TerlineTParticlesDisplayStateful({
    Key? key,
    this.width = 340,
    this.height = 170,
    this.totalParticles = 200,
  }) : super(key: key);

  @override
  State<TerlineTParticlesDisplayStateful> createState() =>
      _TerlineTParticlesDisplayStatefulState();
}

class _TerlineTParticlesDisplayStatefulState
    extends State<TerlineTParticlesDisplayStateful>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_ParticleData> _particles;
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 26),
    )
      ..repeat();
    // Gera partículas: metade dispersas, metade faz anel
    _particles = List.generate(widget.totalParticles, (i) {
      final isRing = i < (widget.totalParticles * 0.42);
      if (isRing) {
        final angle = _rand.nextDouble() * 2 * pi;
        final radius = lerpDouble(
            widget.height * 0.61, widget.height * 0.72, _rand.nextDouble())!;
        return _ParticleData(
          base: Offset(
            widget.width / 2 + radius * cos(angle),
            widget.height / 2 + radius * sin(angle),
          ),
          speed: lerpDouble(0.09, 0.21, _rand.nextDouble())!,
          angle: angle,
          isRing: true,
          color: _rand.nextBool() ? Colors.cyanAccent : Colors.white,
          size: lerpDouble(1, 2.4, _rand.nextDouble())!,
          offsetSeed: _rand.nextDouble() * 1000,
        );
      } else {
        // Partículas dispersas
        return _ParticleData(
          base: Offset(
            _rand.nextDouble() * widget.width,
            _rand.nextDouble() * widget.height,
          ),
          speed: lerpDouble(0.07, 0.13, _rand.nextDouble())!,
          angle: _rand.nextDouble() * 2 * pi,
          isRing: false,
          color: _rand.nextDouble() < 0.7 ? Colors.cyanAccent.shade100 : Colors
              .white,
          size: lerpDouble(1, 2.3, _rand.nextDouble())!,
          offsetSeed: _rand.nextDouble() * 1000,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Fundo de partículas animadas
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return CustomPaint(
                size: Size(widget.width, widget.height),
                painter: _ParticlesPainter(_particles, _controller.value),
              );
            },
          ),
          // Logo centralizado, ALINHADO MAIS PARA BAIXO DO TOPO
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: widget.height * 0.24),
              // ajuste fino: muda conforme o visual
              child: TerlineTLogo(width: widget.width * 0.80),
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticleData {
  final Offset base;
  final double speed;
  final double angle;
  final bool isRing;
  final Color color;
  final double size;
  final double offsetSeed;

  _ParticleData({
    required this.base,
    required this.speed,
    required this.angle,
    required this.isRing,
    required this.color,
    required this.size,
    required this.offsetSeed,
  });
}

class _ParticlesPainter extends CustomPainter {
  final List<_ParticleData> particles;
  final double progress;

  _ParticlesPainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final now = DateTime
        .now()
        .millisecondsSinceEpoch;
    for (final p in particles) {
      if (p.isRing) {
        // Anima sutilmente no círculo usando ruído do tempo
        final localAng = p.angle +
            0.035 * sin(progress * 2 * pi + p.offsetSeed * 0.2);
        final r = (p.base - size.center(Offset.zero)).distance *
            (0.98 + 0.09 * sin(progress * 2 * pi + p.offsetSeed));
        final pos = Offset(
          size.width / 2 + r * cos(localAng),
          size.height / 2 + r * sin(localAng),
        );
        canvas.drawCircle(
            pos, p.size + sin(progress * pi + p.offsetSeed) * 0.6, Paint()
          ..color = p.color.withOpacity(0.87));
      } else {
        // Partícula dispersa: oscilação lenta e caótica
        final dx = p.base.dx +
            5 * sin((progress + p.offsetSeed) * 2 * pi + p.angle) +
            2 * cos(progress * 2 * pi + p.offsetSeed);
        final dy = p.base.dy +
            5 * cos((progress + p.offsetSeed) * 2 * pi + p.angle) +
            2 * sin(progress * 2 * pi + p.offsetSeed);
        canvas.drawCircle(
            Offset(dx, dy), p.size + sin(progress * pi + p.offsetSeed) * 0.29,
            Paint()
              ..color = p.color.withOpacity(0.71));
      }
    }
  }

  @override
  bool shouldRepaint(_ParticlesPainter oldDelegate) => true;
}

class TerlineTParticlesDisplay extends StatelessWidget {
  final double size;

  const TerlineTParticlesDisplay({Key? key, this.size = 180}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TerlineTParticlesDisplayStateful(width: size, height: size);
  }
}
