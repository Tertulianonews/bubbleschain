import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:audioplayers/audioplayers.dart';
import '../services/supabase_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
<<<<<<< HEAD
=======
import 'forest_runner_screen.dart';
>>>>>>> 757566ea8fc248ce85274975105fc358d44853b5

// Chip simples usado na intro para destacar elementos temáticos
class _IntroChip extends StatelessWidget {
  final String icon;
  final String label;

  const _IntroChip({required this.icon, required this.label});


  @override
  Widget build(BuildContext context) {
    return Chip(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      backgroundColor: Colors.white12,
      avatar: Text(icon, style: const TextStyle(fontSize: 21)),
      label: Text(label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          )),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      elevation: 0,
    );
  }

}

// ====================== EMOJI CATEGORIES ======================

class _CategoryEmojiSets {
  final List<String> enemyEmojis;
  final List<String> lakeEmojis;

  _CategoryEmojiSets({required this.enemyEmojis, required this.lakeEmojis});
}

/// For each category, produce emoji sets for enemies (floating) and lakes.
/// Can be expanded per level!
_CategoryEmojiSets _getEmojiSetsForCategory(String category) {
  switch (category) {
    case 'plantas':
      return _CategoryEmojiSets(
        // Macacos como inimigos da fase de plantas
        enemyEmojis: ['🐒', '🦍', '🦧', '🙈', '🙉', '🙊'],
        // Criaturas/elementos nos lagos com temática de plantas/flores
        lakeEmojis: ['🪷', '🌸', '🌼', '🌿', '🍃'],
      );
    case 'cidade':
      return _CategoryEmojiSets(
        enemyEmojis: [
          '🚗', '🚕', '🚙', '🚓', '🚑', '🚒', '🚐', '🚘', '🚌', '🚍', '🚚', '🚛',
          '🛻', '🏎️', '🚜'
        ],
        lakeEmojis: const ['🚦', '🚥', '🛑'],
      );
    case 'deserto':
      return _CategoryEmojiSets(
        enemyEmojis: ['🌵', '🐍', '🦂', '🦎'],
        lakeEmojis: ['🐍', '🦂', '🦎', '🌵'],
      );
    case 'animais':
      return _CategoryEmojiSets(
        enemyEmojis: ['🐝', '🦋', '🐞', '🕷️', '🐸', '🐦', '🐒', '🦆'],
        lakeEmojis: ['🦈', '🐍', '🐊', '🐢', '🦦', '🦭'],
      );
    case 'frutas':
      return _CategoryEmojiSets(
        enemyEmojis: ['🍓', '🍒', '🍇', '🍎', '🍌', '🍍', '🥝', '🥭'],
        lakeEmojis: ['🥝', '🍍', '🍈', '🍌', '🍉', '🍒'],
      );
    case 'alimentos':
      return _CategoryEmojiSets(
        enemyEmojis: ['🌭', '🍔', '🍕', '🍿', '🍩', '🍫'],
        lakeEmojis: ['🍦', '🥛', '🍵', '🍺', '🍲'],
      );
    case 'monstros':
      return _CategoryEmojiSets(
        enemyEmojis: ['👻', '🤖', '👽', '🎃', '🦄', '👾'],
        lakeEmojis: ['🦑', '🐙', '🧟', '👽'],
      );
    default:
      return _CategoryEmojiSets(
        enemyEmojis: ['🐝'],
        lakeEmojis: ['🦈'],
      );
  }
}

// ====================== CONSTANTES E CONFIGURAÇÕES ======================
const double BLOCK_SIZE = 50.0;
const double PLAYER_SIZE = 40.0;
const double GRAVITY = 0.6;
const double JUMP_FORCE = -15.0;
const double MOVE_SPEED = 5.0;
const double MAX_RUN_SPEED = 6.5;
const double SPRINT_MULTIPLIER = 1.35;
const double COYOTE_MAX = 0.12;
const double JUMP_BUFFER_MAX = 0.12;
const double SOL_TRIGGER_THRESHOLD = 0.000005;

// ====================== MODELOS DE DADOS ======================
class Block {
  final int type;
  final double x, y, z;

  Block(this.type, this.x, this.y, this.z);
}

class Mission {
  final String title;
  final String description;
  final bool Function() verification;
  final int reward;
  bool completed;

  Mission({
    required this.title,
    required this.description,
    required this.verification,
    required this.reward,
    this.completed = false,
  });
}

class LevelConfig {
  final String name;
  final String emojiCategory; // categoria de emojis usada na fase
  final int worldLength;
  final int worldDepth;
  final int maxHeight;
  final int groundY;
  final int coinCount;
  final int beeCount;
  final int wallCount;
  final Color skyTop;
  final Color skyBottom;

<<<<<<< HEAD
=======
  // Modo veículo: habilita dirigir um carro (ex.: Bug) e obstáculos dedicados
  final bool vehicleMode;
  final String vehicleEmoji;
  final double vehicleWidth;
  final double vehicleHeight;

  // Em níveis com veículo, normalmente não queremos buracos (lagos)
  final bool disableHoles;

>>>>>>> 757566ea8fc248ce85274975105fc358d44853b5
  const LevelConfig({
    required this.name,
    required this.emojiCategory,
    required this.worldLength,
    required this.worldDepth,
    required this.maxHeight,
    required this.groundY,
    required this.coinCount,
    required this.beeCount,
    required this.wallCount,
    required this.skyTop,
    required this.skyBottom,
<<<<<<< HEAD
=======
    this.vehicleMode = false,
    this.vehicleEmoji = '🚗',
    this.vehicleWidth = 60,
    this.vehicleHeight = 36,
    this.disableHoles = false,
>>>>>>> 757566ea8fc248ce85274975105fc358d44853b5
  });
}

class LightSource {
  final double x;
  final double y;
  final double intensity;
  final double radius;

  const LightSource({
    required this.x,
    required this.y,
    required this.intensity,
    required this.radius,
  });
}

class MaterialProperties {
  final Color albedo;
  final double metallic;
  final double roughness;
  final double specular;
  final double normalIntensity;

  const MaterialProperties({
    required this.albedo,
    this.metallic = 0.0,
    this.roughness = 0.5,
    this.specular = 0.5,
    this.normalIntensity = 1.0,
  });
}

// ====================== COMPONENTES VISUAIS ======================

// Tubo neon lateral para o prédio TerlineT
class _NeonTube extends StatelessWidget {
  final double height;

  const _NeonTube({required this.height});

  @override
  Widget build(BuildContext context) {
    final int now = DateTime
        .now()
        .millisecondsSinceEpoch;
    final double pulse = (sin(now * 0.006) * 0.7 + 0.8);
    final Color neonBlue = Colors.cyanAccent;
    return Container(
      width: 10,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            neonBlue.withOpacity(0.96),
            neonBlue.withOpacity(0.65),
            neonBlue.withOpacity(0.90),
          ],
        ),
        borderRadius: BorderRadius.circular(5),
        boxShadow: [
          BoxShadow(
            color: neonBlue.withOpacity(0.35 + 0.14 * pulse),
            blurRadius: 26 + 10 * pulse,
            spreadRadius: 3 + 2 * pulse,
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.67),
          width: 1.1,
        ),
      ),
    );
  }
}

// Letreiro neon lateral animado
class _SideNeonSign extends StatelessWidget {
  final double height;
  final String label;

  const _SideNeonSign({required this.height, required this.label});

  @override
  Widget build(BuildContext context) {
    final int now = DateTime
        .now()
        .millisecondsSinceEpoch;
    final double pulse = (sin(now * 0.007) * 0.5 + 0.5);
    final Color neon = Colors.pinkAccent;
    return Container(
      width: 24,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.7), width: 1),
        boxShadow: [
          BoxShadow(
            color: neon.withOpacity(0.35 + 0.25 * pulse),
            blurRadius: 18 + 10 * pulse,
            spreadRadius: 2 + 2 * pulse,
          )
        ],
      ),
      alignment: Alignment.center,
      child: RotatedBox(
        quarterTurns: 3,
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.0,
            shadows: [
              Shadow(color: neon.withOpacity(0.9), blurRadius: 10 + 8 * pulse),
            ],
          ),
        ),
      ),
    );
  }
}

// Holofote varrendo o céu
class _SearchLight extends StatelessWidget {
  final double length;
  final double baseWidth;
  final Color color;
  final double phase; // para alternar o tempo entre holofotes

  const _SearchLight({
    required this.length,
    required this.baseWidth,
    required this.color,
    required this.phase,
  });

  @override
  Widget build(BuildContext context) {
    final double t = DateTime
        .now()
        .millisecondsSinceEpoch * 0.001 + phase;
    final double angle = sin(t) * 0.45; // varre ~±26°
    return CustomPaint(
      size: Size(length, length),
      painter: _SearchLightPainter(
        angle: angle,
        length: length,
        baseWidth: baseWidth,
        color: color,
      ),
    );
  }
}

class _SearchLightPainter extends CustomPainter {
  final double angle;
  final double length;
  final double baseWidth;
  final Color color;

  _SearchLightPainter({
    required this.angle,
    required this.length,
    required this.baseWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    // Origem no centro inferior do canvas
    final Offset origin = Offset(size.width * 0.2, size.height * 0.85);
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(angle);

    final Path p = Path()
      ..moveTo(0, 0)
      ..lineTo(-baseWidth * 0.5, 0)..lineTo(0, -length)..lineTo(
          baseWidth * 0.5, 0)
      ..close();

    final Paint paint = Paint()
      ..shader = ui.Gradient.linear(
        const Offset(0, 0),
        Offset(0, -length),
        [
          color.withOpacity(0.22),
          color.withOpacity(0.08),
          Colors.transparent,
        ],
        [0.0, 0.4, 1.0],
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16)
      ..blendMode = BlendMode.plus;
    canvas.drawPath(p, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SearchLightPainter oldDelegate) => true;
}

class CloudWidget extends StatelessWidget {
  final double scale;

  const CloudWidget({this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120 * scale,
      height: 60 * scale,
      child: Stack(
        children: [
          Positioned(left: 10, top: 10, child: _CloudBall(r: 22 * scale)),
          Positioned(left: 34, top: 6, child: _CloudBall(r: 26 * scale)),
          Positioned(left: 62, top: 12, child: _CloudBall(r: 20 * scale)),
          Positioned(left: 46, top: 20, child: _CloudBall(r: 18 * scale)),
        ],
      ),
    );
  }
}

class _CloudBall extends StatelessWidget {
  final double r;

  const _CloudBall({required this.r});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: r * 2,
      height: r * 2,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(color: Colors.white70, blurRadius: 12)
        ],
      ),
    );
  }
}

class BeeWidget extends StatelessWidget {
  final double scale;
  final bool facingRight;
  final String emoji;

  const BeeWidget(
      {required this.scale, required this.facingRight, required this.emoji});

  @override
  Widget build(BuildContext context) {
    final s = 28.0 * scale;
    return SizedBox(
      width: s,
      height: s,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()..scale(facingRight ? 1.0 : -1.0, 1.0),
        child: Text(emoji, style: const TextStyle(fontSize: 28)),
      ),
    );
  }
}

class CarWidget extends StatelessWidget {
  final String emoji;
  final double scale;

  const CarWidget({super.key, required this.emoji, this.scale = 1.0});

  @override
  Widget build(BuildContext context) {
    return Transform.scale(
      scale: scale,
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 34),
      ),
    );
  }
}

<<<<<<< HEAD
=======
class BugCarWidget extends StatelessWidget {
  final double width;
  final double height;
  final bool facingRight;

  const BugCarWidget({
    super.key,
    required this.width,
    required this.height,
    required this.facingRight,
  });

  @override
  Widget build(BuildContext context) {
    final Widget paint = CustomPaint(
      size: Size(width, height),
      painter: _BugCarPainter(),
    );
    if (facingRight) return paint;
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..scale(-1.0, 1.0),
      child: paint,
    );
  }
}

class _BugCarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final double radius = h * 0.18;

    // Shadow
    final Paint shadow = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * 0.5, h * 0.98),
          width: w * 0.9,
          height: h * 0.25,
        ),
        shadow);

    // Body
    final RRect body = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.06, h * 0.32, w * 0.88, h * 0.42),
      Radius.circular(radius),
    );
    final Paint bodyPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, h * 0.3),
        Offset(0, h),
        [
          const Color(0xFF2196F3),
          const Color(0xFF1565C0),
        ],
      );
    canvas.drawRRect(body, bodyPaint);

    // Cabin
    final Path cabin = Path()
      ..moveTo(w * 0.28, h * 0.32)
      ..quadraticBezierTo(w * 0.40, h * 0.10, w * 0.58, h * 0.28)
      ..lineTo(w * 0.78, h * 0.28)..lineTo(w * 0.78, h * 0.32)
      ..close();
    final Paint cabinPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, h * 0.1),
        Offset(0, h * 0.4),
        [Colors.white.withOpacity(0.9), Colors.blueGrey.shade200],
      );
    canvas.drawPath(cabin, cabinPaint);

    // Window highlight
    final Path windowHighlight = Path()
      ..moveTo(w * 0.32, h * 0.30)
      ..quadraticBezierTo(w * 0.46, h * 0.15, w * 0.62, h * 0.28)
      ..lineTo(w * 0.60, h * 0.30)
      ..quadraticBezierTo(w * 0.46, h * 0.19, w * 0.34, h * 0.30)
      ..close();
    final Paint glassShine = Paint()
      ..color = Colors.white.withOpacity(0.25);
    canvas.drawPath(windowHighlight, glassShine);

    // Front bumper
    final RRect bumper = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.88, h * 0.50, w * 0.08, h * 0.12),
      Radius.circular(h * 0.08),
    );
    canvas.drawRRect(bumper, Paint()
      ..color = Colors.grey.shade300);

    // Headlight
    final Rect headlight = Rect.fromLTWH(
        w * 0.88, h * 0.40, w * 0.06, h * 0.10);
    final Paint lightPaint = Paint()
      ..shader = ui.Gradient.radial(
        Offset(headlight.center.dx, headlight.center.dy),
        h * 0.18,
        [Colors.yellowAccent.withOpacity(0.9), Colors.transparent],
      )
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6)
      ..blendMode = BlendMode.plus;
    canvas.drawOval(headlight, Paint()
      ..color = Colors.amber.shade200);
    canvas.drawCircle(headlight.center, h * 0.18, lightPaint);

    // Wheels
    void drawWheel(double cx, double cy, double r) {
      final Paint tire = Paint()
        ..color = const Color(0xFF212121);
      final Paint rim = Paint()
        ..color = Colors.grey.shade400;
      final Paint hub = Paint()
        ..color = Colors.grey.shade200;
      canvas.drawCircle(Offset(cx, cy), r, tire);
      canvas.drawCircle(Offset(cx, cy), r * 0.66, rim);
      canvas.drawCircle(Offset(cx, cy), r * 0.30, hub);
    }
    final double wheelY = h * 0.74;
    final double wheelR = h * 0.18;
    drawWheel(w * 0.28, wheelY, wheelR);
    drawWheel(w * 0.72, wheelY, wheelR);

    // Stripe
    final Paint stripe = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = h * 0.06;
    canvas.drawLine(
        Offset(w * 0.20, h * 0.52), Offset(w * 0.76, h * 0.52), stripe);
  }

  @override
  bool shouldRepaint(covariant _BugCarPainter oldDelegate) => false;
}

>>>>>>> 757566ea8fc248ce85274975105fc358d44853b5
class GoalWidget extends StatelessWidget {
  final double height;

  const GoalWidget({this.height = 90});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 30,
      height: height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            left: 13,
            child: Container(
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Positioned(
            bottom: height - 26,
            left: 16,
            child: Container(
              width: 20,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.amber.shade600,
                borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.orange.withOpacity(0.20),
                      blurRadius: 5,
                      spreadRadius: 2)
                ],
              ),
            ),
          ),
          Positioned(
            bottom: height - 4,
            left: 10,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.amberAccent.shade700,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HillWidget extends StatelessWidget {
  final Color color;
  final double scale;

  const HillWidget({required this.color, required this.scale});

  @override
  Widget build(BuildContext context) {
    final w = 240.0 * scale;
    final h = 120.0 * scale;
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(w),
          topRight: Radius.circular(w),
        ),
      ),
    );
  }
}

class TerlineTBuilding extends StatelessWidget {
  final double width;
  final double height;

  const TerlineTBuilding({super.key, this.width = 180, this.height = 260});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          // Corpo principal do prédio
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2B3A55),
                borderRadius: BorderRadius.circular(6),
                boxShadow: const [
                  BoxShadow(color: Colors.black54,
                      blurRadius: 10,
                      offset: Offset(0, 6)),
                ],
              ),
            ),
          ),
          // Faixa luminosa
          Positioned(
            left: 10,
            right: 10,
            top: height * 0.18,
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.cyanAccent.withOpacity(0.8),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          // Placa neon com o nome (pulsante)
          Positioned(
            left: width * 0.10,
            right: width * 0.10,
            top: 10,
            child: Builder(
              builder: (_) {
                final int now = DateTime
                    .now()
                    .millisecondsSinceEpoch;
                final double pulse = (sin(now * 0.007) * 0.5 + 0.5);
                final Color neonCyan = Colors.cyanAccent;
                final Color neonMagenta = Colors.pinkAccent;
                return Container(
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [neonCyan, neonMagenta],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.9),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: neonCyan.withOpacity(0.55 + 0.25 * pulse),
                        blurRadius: 18 + 12 * pulse,
                        spreadRadius: 2 + 2 * pulse,
                      ),
                      BoxShadow(
                        color: neonMagenta.withOpacity(0.45 + 0.25 * pulse),
                        blurRadius: 26 + 12 * pulse,
                        spreadRadius: 2 + 2 * pulse,
                      ),
                    ],
                  ),
                  child: Text(
                    'TerlineT AI',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      shadows: [
                        Shadow(
                          color: neonCyan.withOpacity(0.8),
                          blurRadius: 12 + 8 * pulse,
                        ),
                        Shadow(
                          color: neonMagenta.withOpacity(0.6),
                          blurRadius: 16 + 8 * pulse,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // Tubos neon laterais
          Positioned(
            left: 6,
            top: height * 0.22,
            child: _NeonTube(height: height * 0.62),
          ),
          Positioned(
            right: 6,
            top: height * 0.22,
            child: _NeonTube(height: height * 0.62),
          ),
          // Letreiro lateral neon
          Positioned(
            right: -28,
            top: height * 0.35,
            child: _SideNeonSign(height: height * 0.40, label: 'AI'),
          ),
          // Janelas
          ..._buildWindows(),
        ],
      ),
    );
  }

  // Gera uma grade simples de janelas iluminadas
  List<Widget> _buildWindows() {
    final List<Widget> children = [];
    const double leftPad = 12;
    const double topPad = 40;
    const double colGap = 10;
    const double rowGap = 12;
    const double winW = 14;
    const double winH = 18;
    final int cols = ((width - leftPad * 2) / (winW + colGap)).floor();
    final int rows = ((height - topPad - 10) / (winH + rowGap)).floor();
    for (int r = 0; r < rows; r++) {
      for (int c = 0; c < cols; c++) {
        final double x = leftPad + c * (winW + colGap);
        final double y = topPad + r * (winH + rowGap);
        final bool lit = ((r + c) % 3) != 0;
        children.add(Positioned(
          left: x,
          top: y,
          child: Container(
            width: winW,
            height: winH,
            decoration: BoxDecoration(
              color: lit ? const Color(0xFFFFF59D) : const Color(0xFF304A6B),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ));
      }
<<<<<<< HEAD
=======

>>>>>>> 757566ea8fc248ce85274975105fc358d44853b5
    }
    return children;
  }
}

// Helper: árvore grande para fundo da fase Plantas
Widget _buildTree(double width, double height, Color trunkColor,
    Color canopyColor) {
  final double trunkWidth = width * 0.16;
  final double trunkHeight = height * 0.45;
  final double canopyHeight = height * 0.62;
  return SizedBox(
    width: width,
    height: height,
    child: Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Positioned(
          bottom: 0,
          child: Container(
            width: trunkWidth,
            height: trunkHeight,
            decoration: BoxDecoration(
              color: trunkColor,
              borderRadius: BorderRadius.circular(trunkWidth * 0.25),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: trunkHeight - canopyHeight * 0.25,
          child: Container(
            width: width * 0.90,
            height: canopyHeight,
            decoration: BoxDecoration(
              color: canopyColor,
              borderRadius: BorderRadius.circular(width),
              boxShadow: [
                BoxShadow(
                  color: canopyColor.withOpacity(0.35),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

// ====================== PARTÍCULAS E EFEITOS ======================
class Particle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double life;
  double initialLife; // usado para calcular o fade-out
  bool isGlow; // define se a partícula é "glow" (suave) ou "spark" (brilhante)
  final Color color;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.life,
    required this.initialLife,
    this.isGlow = false,
    required this.color,
  });

  void update(double dt) {
    // Simples física com gravidade, arrasto e dissipação
    vy += isGlow ? 0.12 : 0.35;
    x += vx;
    y += vy;
    vx *= isGlow ? 0.96 : 0.985;
    size = (size - dt * (isGlow ? 0.35 : 0.8)).clamp(0.4, 100.0);
    life -= dt;
  }
}

class ParticleSystem {
  final List<Particle> particles = [];

  void addExplosion(double x, double y, Color color) {
    for (int i = 0; i < 30; i++) {
      final double ang = Random().nextDouble() * pi * 2;
      final double spd = 3 + Random().nextDouble() * 3.5;
      particles.add(Particle(
        x: x,
        y: y,
        vx: cos(ang) * spd,
        vy: sin(ang) * spd - 2,
        size: 2 + Random().nextDouble() * 4,
        life: 1.2 + Random().nextDouble() * 0.6,
        initialLife: 1.2 + Random().nextDouble() * 0.6,
        isGlow: false,
        color: color.withOpacity(0.8),
      ));
    }
  }

  // Efeito aprimorado para coleta de moeda: mistura faíscas e brilho suave
  void addCoinBurst(double x, double y) {
    final Random rng = Random();
    final Color sparkColor = Colors.amberAccent;
    final Color glowColor = Colors.orangeAccent.withOpacity(0.8);
    // Sparks brilhantes (aditivos)
    for (int i = 0; i < 26; i++) {
      final double ang = rng.nextDouble() * pi * 2;
      final double spd = 2.8 + rng.nextDouble() * 3.8;
      final double life = 0.7 + rng.nextDouble() * 0.7;
      particles.add(Particle(
        x: x,
        y: y,
        vx: cos(ang) * spd,
        vy: sin(ang) * spd - 1.6,
        size: 1.8 + rng.nextDouble() * 3.0,
        life: life,
        initialLife: life,
        isGlow: false,
        color: sparkColor,
      ));
    }
    // Glow suave (bolhas de luz)
    for (int i = 0; i < 14; i++) {
      final double ang = rng.nextDouble() * pi * 2;
      final double spd = 0.6 + rng.nextDouble() * 1.4;
      final double life = 0.9 + rng.nextDouble() * 0.9;
      particles.add(Particle(
        x: x,
        y: y,
        vx: cos(ang) * spd * 0.6,
        vy: sin(ang) * spd * 0.6 - 0.4,
        size: 4.0 + rng.nextDouble() * 8.0,
        life: life,
        initialLife: life,
        isGlow: true,
        color: glowColor,
      ));
    }
  }

  void update(double dt) {
    if (particles.isEmpty) return;
    for (int i = 0; i < particles.length; i++) {
      particles[i].update(dt);
    }
    particles.removeWhere((p) => p.life <= 0 || p.size <= 0.5);
    if (particles.length > 500) {
      particles.removeRange(0, particles.length - 500);
    }
  }
}

// Desenha partículas com mistura aditiva para faíscas e normal para brilho
class _ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double cameraOffset;

  _ParticlePainter({required this.particles, required this.cameraOffset});

  @override
  void paint(Canvas canvas, Size size) {
    if (particles.isEmpty) return;

    // Translada para alinhar com o mundo (scroll da câmera)
    canvas.save();
    canvas.translate(-cameraOffset, 0);

    final Paint paint = Paint();
    for (final p in particles) {
      final double t = (p.life / p.initialLife).clamp(0.0, 1.0);
      final double alpha = p.isGlow ? (0.55 * t) : (0.95 * t);
      paint
        ..color = p.color.withOpacity(alpha)
        ..maskFilter = MaskFilter.blur(
            BlurStyle.normal, p.isGlow ? 6 : 2)
        ..blendMode = p.isGlow ? BlendMode.srcOver : BlendMode.plus;
      canvas.drawCircle(Offset(p.x, p.y), p.size, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

// ====================== PERSONAGEM PRINCIPAL ======================
/// Desenha um personagem humanoide 2D com cabeça, tronco, braços e pernas.
/// Os membros balançam de acordo com o walkCycle e a velocidade normalizada.
class HumanoidPainter extends CustomPainter {
  final double bodyTilt;
  final double jumpSquash;
  final bool isJumping;
  final double walkCycle;
  final double speedNorm;
  final bool facingRight;

  HumanoidPainter({
    required this.bodyTilt,
    required this.jumpSquash,
    required this.isJumping,
    required this.walkCycle,
    required this.speedNorm,
    required this.facingRight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Cores do personagem
    final Color primary = const Color(0xFF1976D2);
    final Color secondary = const Color(0xFF64B5F6);
    final Color accent = const Color(0xFF0D47A1);

    // Pinturas básicas
    final Paint torsoPaint = Paint()
      ..shader = LinearGradient(
        colors: [primary, secondary],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final Paint limbPaint = Paint()
      ..color = primary;
    final Paint jointPaint = Paint()
      ..color = secondary;
    final Paint headPaint = Paint()
      ..color = secondary;
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Prepara transformações globais
    canvas.save();
    // Origem no centro do sprite
    canvas.translate(size.width / 2, size.height / 2);
    // Inclinação leve do corpo
    canvas.rotate(bodyTilt);
    // Squash vertical durante salto
    canvas.scale(1.0, jumpSquash);
    // Espelha se olhando para a esquerda
    if (!facingRight) {
      canvas.scale(-1.0, 1.0);
    }

    // Tamanhos proporcionais
    final double torsoWidth = size.width * 0.42;
    final double torsoHeight = size.height * 0.50;
    final double headRadius = size.width * 0.18;
    final double limbWidth = size.width * 0.10;
    final double upperArm = size.height * 0.22;
    final double foreArm = size.height * 0.20;
    final double thigh = size.height * 0.26;
    final double shin = size.height * 0.24;

    // Ponto central do quadril/torso
    final Offset hips = Offset(0, size.height * 0.10);
    final Offset chest = hips.translate(0, -torsoHeight * 0.45);
    final Offset neck = chest.translate(0, -torsoHeight * 0.35);

    // Sombra no chão (fora das transformações verticais de squash)
    canvas.save();
    canvas.scale(1.0, 1 / jumpSquash);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(0, size.height * 0.48),
          width: size.width * 0.6,
          height: size.height * 0.14),
      shadowPaint,
    );
    canvas.restore();

    // Ângulos de animação (em radianos)
    final double gait = (speedNorm.clamp(0.0, 1.0)) *
        1.0; // intensidade de balanço
    final double armSwing = sin(walkCycle) * 0.7 * gait;
    final double legSwing = sin(walkCycle) * 0.8 * gait;
    final double oppArmSwing = sin(walkCycle + pi) * 0.7 * gait;
    final double oppLegSwing = sin(walkCycle + pi) * 0.8 * gait;

    // Tronco
    final RRect torso = RRect.fromRectAndRadius(
      Rect.fromCenter(center: chest.translate(0, torsoHeight * 0.20),
          width: torsoWidth,
          height: torsoHeight),
      Radius.circular(torsoWidth * 0.25),
    );
    canvas.drawRRect(torso, torsoPaint);

    // Cabeça
    final Offset headCenter = neck.translate(0, -headRadius * 1.1);
    canvas.drawCircle(headCenter, headRadius, headPaint);
    // Rosto simples
    final Paint eyePaint = Paint()
      ..color = Colors.white;
    final Paint pupilPaint = Paint()
      ..color = accent;
    final double eyeOffsetX = headRadius * 0.45;
    final double eyeOffsetY = headRadius * 0.15;
    final double pupilShift = cos(walkCycle) * 1.5 +
        (facingRight ? 1.0 : -1.0) * 1.5;
    canvas.drawCircle(
        headCenter.translate(-eyeOffsetX, -eyeOffsetY), headRadius * 0.20,
        eyePaint);
    canvas.drawCircle(
        headCenter.translate(eyeOffsetX, -eyeOffsetY), headRadius * 0.20,
        eyePaint);
    canvas.drawCircle(
        headCenter.translate(-eyeOffsetX + pupilShift, -eyeOffsetY),
        headRadius * 0.10, pupilPaint);
    canvas.drawCircle(
        headCenter.translate(eyeOffsetX + pupilShift, -eyeOffsetY),
        headRadius * 0.10, pupilPaint);

    // Helper para desenhar segmentos com largura constante
    void drawLimb(Offset from, double length, double angle, Paint paint) {
      final Offset to = from + Offset(cos(angle), sin(angle)) * length;
      final Rect seg = Rect.fromCenter(
        center: Offset.lerp(from, to, 0.5)!,
        width: limbWidth,
        height: length,
      );
      canvas.save();
      canvas.translate(seg.center.dx, seg.center.dy);
      canvas.rotate(angle);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset.zero, width: limbWidth, height: length),
          Radius.circular(limbWidth * 0.45),
        ),
        paint,
      );
      canvas.restore();
      // Junta
      canvas.drawCircle(from, limbWidth * 0.55, jointPaint);
      canvas.drawCircle(to, limbWidth * 0.50, jointPaint);
    }

    // Braço direito (frente)
    final Offset shoulderR = chest.translate(
        torsoWidth * 0.50, -torsoHeight * 0.10);
    final double upperArmAngleR = -pi / 2 +
        armSwing * 0.9; // para baixo com swing
    final double foreArmAngleR = upperArmAngleR + 0.5 + armSwing * 0.4;
    final Offset elbowR = shoulderR +
        Offset(cos(upperArmAngleR), sin(upperArmAngleR)) * upperArm;
    drawLimb(shoulderR, upperArm, upperArmAngleR, limbPaint);
    drawLimb(elbowR, foreArm, foreArmAngleR, limbPaint);

    // Braço esquerdo (atrás)
    final Offset shoulderL = chest.translate(
        -torsoWidth * 0.50, -torsoHeight * 0.10);
    final double upperArmAngleL = -pi / 2 + oppArmSwing * 0.9;
    final double foreArmAngleL = upperArmAngleL + 0.5 + oppArmSwing * 0.4;
    final Offset elbowL = shoulderL +
        Offset(cos(upperArmAngleL), sin(upperArmAngleL)) * upperArm;
    drawLimb(shoulderL, upperArm, upperArmAngleL,
        limbPaint..color = primary.withOpacity(0.9));
    drawLimb(elbowL, foreArm, foreArmAngleL,
        limbPaint..color = primary.withOpacity(0.9));

    // Pernas
    final Offset hipR = hips.translate(torsoWidth * 0.22, 0);
    final Offset hipL = hips.translate(-torsoWidth * 0.22, 0);
    final double thighAngleR = pi / 2 + legSwing * 0.9;
    final double shinAngleR = thighAngleR + 0.6 - legSwing * 0.2;
    final double thighAngleL = pi / 2 + oppLegSwing * 0.9;
    final double shinAngleL = thighAngleL + 0.6 - oppLegSwing * 0.2;
    final Offset kneeR = hipR +
        Offset(cos(thighAngleR), sin(thighAngleR)) * thigh;
    final Offset kneeL = hipL +
        Offset(cos(thighAngleL), sin(thighAngleL)) * thigh;
    drawLimb(hipR, thigh, thighAngleR, limbPaint);
    drawLimb(kneeR, shin, shinAngleR, limbPaint);
    drawLimb(
        hipL, thigh, thighAngleL, limbPaint..color = primary.withOpacity(0.95));
    drawLimb(
        kneeL, shin, shinAngleL, limbPaint..color = primary.withOpacity(0.95));

    // Detalhe no tronco (faixa/energia ao correr)
    if (speedNorm > 0.5) {
      final Paint stripe = Paint()
        ..color = Colors.cyanAccent.withOpacity(0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      final Rect arcRect = Rect.fromCenter(
          center: chest, width: torsoWidth * 1.2, height: torsoHeight * 1.4);
      canvas.drawArc(arcRect, pi * 0.1, pi * 0.8, false, stripe);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HumanoidPainter oldDelegate) => true;
}

// ====================== TELA PRINCIPAL ======================
class TerlineTWordScreen extends StatefulWidget {
  const TerlineTWordScreen({super.key});

  @override
  State<TerlineTWordScreen> createState() => _TerlineTWordScreenState();
}

class _TerlineTWordScreenState extends State<TerlineTWordScreen>
    with WidgetsBindingObserver, TickerProviderStateMixin {
  // Variáveis do jogo
  double playerX = 0.0;
  double playerY = 0.0;
  double playerVelocityY = 0.0;
  double playerVelocityX = 0.0;
  double cameraOffset = 0.0;
  bool isJumping = false;
  bool isFacingRight = true;
  double gameSpeed = 1.0;
  double _coyoteTime = 0.0;
  double _jumpBuffer = 0.0;
  double _jumpSquash = 1.0;
  double walkCycle = 0.0;
  double walkIntensity = 0.0;
  int _jumpCount = 0; // controla combos de pulo (máx 3)
  bool _onGround = false; // indica se está no chão

  // Recompensas
  double balance = 0.0;
  int normalCollectCount = 0;
  bool showEmojiBadge = false;
  double emojiBadgeOpacity = 1.0;
  String? lastEmojiAwarded;
  double lastSolTriggerBalance = 0.0;
  bool showSolBadge = false;
  double solBadgeOpacity = 1.0;

  // Mundo do jogo
  double groundY = 420.0;
  double worldLength = 6000.0;
  final List<Rect> platforms = [];
  final List<_HoleSegment> _holes = [];
  final List<_LakeCreature> _lakeCreatures = [];
  final List<Offset> coins = [];
  Set<int> collectedCoins = {};
  int score = 0;
  int coinsCollected = 0;
  bool isGameOver = false;
  bool isGameStarted = false;
  bool isLevelComplete = false;
  double goalX = 0.0;
  double _lastGroundY = 420.0;
  bool _showIntro = true;
<<<<<<< HEAD
=======
  bool inVehicle = false; // indica se o jogador está dirigindo um veículo
  // Fluxo do veículo: 'onFoot' | 'approaching' | 'entering' | 'driving'
  String _vehiclePhase = 'onFoot';
  double _parkedCarX = 0.0;
  double _enterTimer = 0.0;
  bool _controlsLocked = false;
>>>>>>> 757566ea8fc248ce85274975105fc358d44853b5

  // Fases
  final List<LevelConfig> levels = [
    LevelConfig(
      name: 'Fase 1 — Bosque Claro',
      emojiCategory: 'animais',
      worldLength: 6000,
      worldDepth: 1200,
      maxHeight: 250,
      groundY: 420,
      coinCount: 80,
      beeCount: 14,
      wallCount: 8,
      skyTop: const Color(0xFF64B5F6),
      skyBottom: const Color(0xFF81C784),
    ),
    LevelConfig(
      name: 'Fase 2 — Picos Nebulosos',
      emojiCategory: 'frutas',
      worldLength: 7200,
      worldDepth: 1400,
      maxHeight: 300,
      groundY: 440,
      coinCount: 95,
      beeCount: 20,
      wallCount: 11,
      skyTop: const Color(0xFF4A90E2),
      skyBottom: const Color(0xFF4CAF50),
    ),
    LevelConfig(
      name: 'Fase 3 — Dunas Escaldantes',
      emojiCategory: 'deserto',
      worldLength: 7800,
      worldDepth: 1500,
      maxHeight: 280,
      groundY: 460,
      coinCount: 90,
      beeCount: 18,
      wallCount: 12,
      skyTop: const Color(0xFFF6D365),
      skyBottom: const Color(0xFFECC07C),
    ),
    LevelConfig(
      name: 'Fase 4 — Cidade Neon',
      emojiCategory: 'cidade',
      worldLength: 8200,
      worldDepth: 1600,
      maxHeight: 260,
      groundY: 460,
      coinCount: 95,
      beeCount: 0,
      wallCount: 0,
      skyTop: const Color(0xFF1F2A44),
      skyBottom: const Color(0xFF384B78),
    ),
    // Fase 5 — Plantas e Flores
    LevelConfig(
      name: 'Fase 5 — Floresta das Plantas',
      emojiCategory: 'plantas',
      worldLength: 7600,
      worldDepth: 1500,
      maxHeight: 280,
      groundY: 440,
      coinCount: 90,
      beeCount: 18,
      wallCount: 12,
      skyTop: const Color(0xFF4CAF50),
      skyBottom: const Color(0xFF2E7D32),
    ),
<<<<<<< HEAD
=======
    // Fase 6 — Corrida no deserto com Bug (carro) e cactos
    LevelConfig(
      name: 'Fase 6 — Bug nas Dunas',
      emojiCategory: 'deserto',
      worldLength: 8200,
      worldDepth: 1600,
      maxHeight: 260,
      groundY: 460,
      coinCount: 60,
      beeCount: 0,
      wallCount: 24,
      // usado como referência de quantidade de cactos
      skyTop: const Color(0xFFF6D365),
      skyBottom: const Color(0xFFECC07C),
      vehicleMode: true,
      vehicleEmoji: '🚗',
      // carro um pouco maior para melhor leitura visual
      vehicleWidth: 94,
      vehicleHeight: 62,
      disableHoles: true,
    ),
>>>>>>> 757566ea8fc248ce85274975105fc358d44853b5
  ];
  late LevelConfig currentLevel;
  int levelIndex = 0;

  // Elementos visuais
  final List<_Cloud> clouds = [];
  final List<_Bee> bees = [];
  final List<_Car> _cars = [];
  final List<_Log> _logs = [];
  final List<_Dust> dusts = [];
  final List<_Sparkle> sparkles = [];
  final ParticleSystem _particleSystem = ParticleSystem();
  final List<_CityBuilding> _cityBuildingsFar = [];
  final List<_CityBuilding> _cityBuildingsNear = [];
  final List<_BigTree> _treesFar = [];
  final List<_BigTree> _treesNear = [];
  double _carSpawnTimer = 0.0;
  final List<double> _terlineTBuildingXs = [];
<<<<<<< HEAD
=======
  final List<_Cactus> _cacti = []; // obstáculos da fase de veículo (deserto)
>>>>>>> 757566ea8fc248ce85274975105fc358d44853b5

  // Controles
  bool kLeft = false, kRight = false, kJumpHeld = false, kSprint = false;
  bool _sprintToggleUI = false;
  bool _joyActive = false;
  Offset _joyVector = Offset.zero;

  // Áudio
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _coinPlayer = AudioPlayer();
  final AudioPlayer _beePlayer = AudioPlayer();
  final AudioPlayer _laughPlayer = AudioPlayer();
  String userId = '';

  // Animação
  late AnimationController _playerAnimationController;
  late AnimationController _cameraShakeController;
  bool _hasRiveAsset = false;

  // Paisagem com parallax (opcional via assets do Tiled)
  // Se os PNGs existirem no projeto e no pubspec, ativamos camadas com repetição no eixo X.
  bool _parallaxReady = false; // indica que o céu via imagem está disponível
  bool _hasHillsV02 = false;
  bool _hasHillsV01 = false;
  bool _hasCloudsBG = false;

  // Poeira do deserto
  double _sandPuffTimer = 0.0; // controla taxa de emissão ao correr no deserto

  // Loop de jogo usando scheduleFrameCallback para evitar recursão
  Duration? _lastTick;
  bool _frameScheduled = false;

  // Caminhos padrão dos sprites de paisagem
  final String _skyAsset = 'assets/map/tiles/tile_sky_v02.png';
  final String _hillsV02Asset = 'assets/map/tiles/tile_plains_hills_v02.png';
  final String _hillsV01Asset = 'assets/map/tiles/tile_plains_hills_v01.png';
  final String _cloudsBGAsset = 'assets/map/tiles/tile_clouds_BG.png';


  // Teclado
  final FocusNode _focusNode = FocusNode();

  // Emojis flutuantes da tela de introdução
  final List<_IntroFloater> _introFloaters = [];
  AnimationController? _introController;
  Duration? _lastIntroTick;
  Size _introBounds = Size.zero;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Inicializar controladores de animação
    _playerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _cameraShakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    // Configurar áudio
    _configureAudio();

    // Configurar jogo
    currentLevel = levels[levelIndex];
    _applyLevel(currentLevel);
    _resetGame();
    // Ajuste inicial do solo conforme a altura disponível
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final Size logicalSize = Size(
      view.physicalSize.width / view.devicePixelRatio,
      view.physicalSize.height / view.devicePixelRatio,
    );
    _applyResponsiveGround(logicalSize.height);
    // Não iniciar automaticamente; aguardamos o usuário pressionar Play na intro

    // Detectar e preparar assets de paisagem (não quebra se não existirem)
    _initParallaxAssets();

    // Carregar progresso salvo (se existir) e aplicar (sem iniciar automaticamente)
    _loadAndApplySavedProgress();

    // Inicializar floaters da intro (após layout)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _introBounds = Size(
        MediaQuery
            .of(context)
            .size
            .width,
        MediaQuery
            .of(context)
            .size
            .height,
      );
      _initIntroFloaters();
      _introController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 1),
      );
      _introController!.addListener(_updateIntroFloaters);
      _introController!.repeat(period: const Duration(milliseconds: 15));
    });
  }

  void _configureAudio() {
    _sfxPlayer.setPlayerMode(PlayerMode.lowLatency);
    _sfxPlayer.setReleaseMode(ReleaseMode.stop);
    _coinPlayer.setPlayerMode(PlayerMode.lowLatency);
    _coinPlayer.setReleaseMode(ReleaseMode.stop);
    _beePlayer.setPlayerMode(PlayerMode.lowLatency);
    _beePlayer.setReleaseMode(ReleaseMode.stop);
    _laughPlayer.setPlayerMode(PlayerMode.lowLatency);
    _laughPlayer.setReleaseMode(ReleaseMode.stop);

    _sfxPlayer.setSourceAsset('grito2.mp3');
    _coinPlayer.setSourceAsset('assets/coletando.mp3');
    _beePlayer.setSourceAsset('assets/abelha.mp3');
    _laughPlayer.setSourceAsset('assets/risada.mp3');

    // Carregar saldo do usuário
    _loadUserBalance();
  }

  void _loadUserBalance() {
    userId = SupabaseService().getCurrentUserId();
    if (userId.isNotEmpty) {
      SupabaseService().getBubbleCoinBalance(userId).then((b) {
        if (mounted) setState(() {
          balance = b;
          lastSolTriggerBalance = b;
        });
      });
    }
  }

  void _applyLevel(LevelConfig cfg) {
    worldLength = cfg.worldLength.toDouble();
    groundY = cfg.groundY.toDouble();
    goalX = worldLength - 120.0;
  }

  void _resetGame() {
    playerX = 100;
    playerY = 300;
    playerVelocityY = 0;
    cameraOffset = 0;
    isJumping = false;
    isFacingRight = true;
    gameSpeed = 1.0;
    score = 0;
    coinsCollected = 0;
    isGameOver = false;
    isGameStarted = false;
    isLevelComplete = false;
    _jumpCount = 0;
    _onGround = false;
    collectedCoins.clear();
    coins.clear();
    platforms.clear();
    clouds.clear();
    bees.clear();
    _cars.clear();
    _logs.clear();
    dusts.clear();
    sparkles.clear();
    _lakeCreatures.clear();
    _cityBuildingsFar.clear();
    _cityBuildingsNear.clear();
    _treesFar.clear();
    _treesNear.clear();
    _carSpawnTimer = 0.0;
    _terlineTBuildingXs.clear();
<<<<<<< HEAD
=======
    inVehicle = currentLevel.vehicleMode ? false : false;
    if (currentLevel.vehicleMode) {
      // Carro estacionado um pouco à frente do player
      _vehiclePhase = 'approaching';
      _parkedCarX = playerX + 180;
      _enterTimer = 0.6;
      _controlsLocked = true;
    } else {
      _vehiclePhase = 'onFoot';
      _controlsLocked = false;
    }
    _cacti.clear();
>>>>>>> 757566ea8fc248ce85274975105fc358d44853b5

    // Gerar buracos no solo (segmentos sem plataforma) — não gerar na cidade
    _holes.clear();
    final Random random = Random();
<<<<<<< HEAD
    if (currentLevel.emojiCategory != 'cidade') {
=======
    if (currentLevel.emojiCategory != 'cidade' && !currentLevel.disableHoles) {
>>>>>>> 757566ea8fc248ce85274975105fc358d44853b5
      final int numHoles = (currentLevel.wallCount).clamp(4, 14);
      for (int i = 0; i < numHoles; i++) {
        final double holeWidth = (BLOCK_SIZE * (3 + random.nextInt(4)))
            .toDouble(); // 3..6 blocos
        final double minX = 220.0;
        final double maxX = worldLength - 220.0 - holeWidth;
        if (maxX <= minX) break;
        final double start = minX + random.nextDouble() * (maxX - minX);
        final _HoleSegment candidate = _HoleSegment(
            startX: start, endX: start + holeWidth);
        // Evitar sobreposição forte com outros buracos
        bool overlaps = _holes.any((h) =>
            candidate.overlaps(h, minGap: BLOCK_SIZE * 2));
        if (!overlaps) {
          _holes.add(candidate);
        }
      }
    }

    // Gerar plataformas (pulando segmentos de buraco)
    for (double x = 0; x < worldLength; x += BLOCK_SIZE) {
      final double center = x + BLOCK_SIZE / 2;
      final bool inHole = _holes.any((h) => h.contains(center));
      if (!inHole) {
        platforms.add(Rect.fromLTWH(x, groundY, BLOCK_SIZE, BLOCK_SIZE));
      }
    }
<<<<<<< HEAD
    // Posicionar jogador em pé sobre o chão no início
    playerY = groundY - PLAYER_SIZE;
=======
    // Posicionar jogador/veículo em pé sobre o chão no início
    final double startEntityH = inVehicle
        ? currentLevel.vehicleHeight
        : PLAYER_SIZE;
    playerY = groundY - startEntityH;
>>>>>>> 757566ea8fc248ce85274975105fc358d44853b5

    // Determinar sets de emojis pela categoria
    final _CategoryEmojiSets sets = _getEmojiSetsForCategory(
        currentLevel.emojiCategory);

    // Criar criaturas nos lagos (buracos) – não criar no deserto nem na cidade
    if (currentLevel.emojiCategory != 'deserto' &&
        currentLevel.emojiCategory != 'cidade') {
      for (final h in _holes) {
        final double width = h.endX - h.startX;
        final int count = 2 + Random().nextInt(2); // 2..3 criaturas por lago
        for (int i = 0; i < count; i++) {
          final double cx = h.startX + 20 +
              Random().nextDouble() * (width - 40);
          final double cy = groundY + 28 + Random().nextDouble() * 36;
          final String e = sets.lakeEmojis[Random().nextInt(
              sets.lakeEmojis.length)];
          _lakeCreatures.add(_LakeCreature(
            x: cx,
            baseY: cy,
            amp: 4 + Random().nextDouble() * 6,
            phase: Random().nextDouble() * pi * 2,
            emoji: e,
            scale: 1.0 + Random().nextDouble() * 0.4,
          ));
        }
      }
    }

    // Gerar moedas (cap em 100 por fase)
    // usar o mesmo random acima
    final int coinTarget = min(currentLevel.coinCount, 100);
    for (int i = 0; i < coinTarget; i++) {
      final double cx = 150 + random.nextDouble() * (worldLength - 300);
      final double cy = groundY - (100 + random.nextDouble() * 120);
      coins.add(Offset(cx, cy));
    }

    // Gerar nuvens
    for (int i = 0; i < 9; i++) {
      clouds.add(_Cloud(
        x: random.nextDouble() * worldLength,
        y: 60 + random.nextDouble() * 160,
        speed: 0.15 + random.nextDouble() * 0.25,
        scale: 0.8 + random.nextDouble() * 1.2,
      ));
    }

    // Gerar inimigos flutuantes (emojis da categoria) — não na cidade
    if (currentLevel.emojiCategory != 'cidade') {
      for (int i = 0; i < currentLevel.beeCount; i++) {
        final double bx = 400 + random.nextDouble() * (worldLength - 800);
        final double by = groundY - (70 + random.nextDouble() * 160);
        bees.add(_Bee(
          x: bx,
          baseY: by,
          amp: 16 + random.nextDouble() * 22,
          speed: 1.0 + random.nextDouble() * 1.6,
          dir: random.nextBool() ? 1.0 : -1.0,
          phase: random.nextDouble() * 6.283,
          emoji: sets.enemyEmojis[Random().nextInt(sets.enemyEmojis.length)],
          currentY: by,
        ));
      }
    }

    // Fase Plantas: gerar troncos no solo e árvores grandes no fundo
    if (currentLevel.emojiCategory == 'plantas') {
      // Troncos (obstáculos no solo)
      final int numLogs = currentLevel.wallCount.clamp(8, 18);
      for (int i = 0; i < numLogs; i++) {
        final double w = 28 + random.nextDouble() * 36; // largura 28..64
        final double h = 34 + random.nextDouble() * 26; // altura 34..60
        final double minX = 220.0;
        final double maxX = worldLength - 220.0 - w;
        if (maxX <= minX) break;
        final double x = minX + random.nextDouble() * (maxX - minX);
        // Evitar colocar troncos dentro de buracos/lagos e longe de outros troncos
        final bool inHole = _holes.any((hSeg) =>
        (x + w) > hSeg.startX && x < hSeg.endX);
        if (inHole) {
          // tenta uma alternativa simples
          continue;
        }
        bool overlapsOther = _logs.any((l) =>
        (x + w + BLOCK_SIZE) > l.x && (x - BLOCK_SIZE) < (l.x + l.width));
        if (overlapsOther) {
          continue;
        }
        _logs.add(_Log(x: x, width: w, height: h, yTop: groundY - h));
      }

      // Árvores grandes (duas camadas parallax)
      double xFar = -200;
      while (xFar < worldLength + 800) {
        final double w = 140 + random.nextDouble() * 140;
        final double h = 260 + random.nextDouble() * 220;
        _treesFar.add(_BigTree(
          x: xFar,
          width: w,
          height: h,
          trunkColor: const Color(0xFF6D4C41).withOpacity(0.9),
          canopyColor: Color.lerp(
              const Color(0xFF2E7D32), const Color(0xFF66BB6A),
              random.nextDouble())!,
        ));
        xFar += w + 140 + random.nextDouble() * 120;
      }
      double xNear = -200;
      while (xNear < worldLength + 800) {
        final double w = 160 + random.nextDouble() * 180;
        final double h = 320 + random.nextDouble() * 280;
        _treesNear.add(_BigTree(
          x: xNear,
          width: w,
          height: h,
          trunkColor: const Color(0xFF5D4037),
          canopyColor: Color.lerp(
              const Color(0xFF1B5E20), const Color(0xFF43A047),
              random.nextDouble())!,
        ));
        xNear += w + 160 + random.nextDouble() * 140;
      }
    }

    // Gerar prédios da cidade (camadas parallax)
    if (currentLevel.emojiCategory == 'cidade') {
      // Longe
      double xFar = -200;
      while (xFar < worldLength + 800) {
        final double w = 100 + random.nextDouble() * 160;
        final double h = 100 + random.nextDouble() * 220;
        _cityBuildingsFar.add(_CityBuilding(
          x: xFar,
          width: w,
          height: h,
          color: Color.lerp(const Color(0xFF263238), const Color(0xFF455A64),
              random.nextDouble())!,
        ));
        xFar += w + 60 + random.nextDouble() * 80;
      }
      // Perto
      double xNear = -200;
      while (xNear < worldLength + 800) {
        final double w = 120 + random.nextDouble() * 180;
        final double h = 140 + random.nextDouble() * 260;
        _cityBuildingsNear.add(_CityBuilding(
          x: xNear,
          width: w,
          height: h,
          color: Color.lerp(const Color(0xFF37474F), const Color(0xFF546E7A),
              random.nextDouble())!,
        ));
        xNear += w + 80 + random.nextDouble() * 90;
      }
      // Posições especiais para o prédio TerlineT ao longo da cidade
      double tx = 800;
      while (tx < worldLength - 600) {
        _terlineTBuildingXs.add(tx);
        tx += 1600; // repete a cada ~1600px
      }
    }
    _lastGroundY = groundY;
  }

<<<<<<< HEAD
=======

>>>>>>> 757566ea8fc248ce85274975105fc358d44853b5
  void _startGame() {
    isGameStarted = true;
    _playerAnimationController.repeat(
      period: const Duration(milliseconds: 500),
      reverse: true,
    );
    _lastTick = null;
    _scheduleNextFrame();
  }

  void _scheduleNextFrame() {
    if (_frameScheduled) return;
    _frameScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback(_onFrame);
  }

  void _onFrame(Duration timestamp) {
    _frameScheduled = false;
    if (!isGameStarted || isGameOver || isLevelComplete) return;
    final double dt = _lastTick == null
        ? 0.016
        : ((timestamp - _lastTick!).inMicroseconds / 1000000.0)
        .clamp(0.0, 0.033);
    _lastTick = timestamp;

    _applyPhysics(dt);
    _checkCollisions();
    _updateVisualElements(dt);
    if (mounted) setState(() {});
    _scheduleNextFrame();
  }

  void _applyPhysics(double dt) {
    // Gravidade
    double g = GRAVITY;
    if (playerVelocityY > 0) g += 0.22;
    if (!kJumpHeld && playerVelocityY < 0) g += 0.75;
    playerVelocityY += g;
    playerY += playerVelocityY;

    // Controle horizontal
    double targetMax = MAX_RUN_SPEED * (kSprint ? SPRINT_MULTIPLIER : 1.0);
    // Eixo analógico do joystick (quando ativo). Varia entre -1 (esquerda) e 1 (direita)
    double axis = _joyActive ? _joyVector.dx.clamp(-1.0, 1.0) : 0.0;
    final bool hasKeys = kLeft ^ kRight;
<<<<<<< HEAD
    if (_joyActive && axis.abs() > 0.05) {
=======
    // Se controles bloqueados (cutscene para entrar no carro), ignorar input
    if (_controlsLocked && currentLevel.vehicleMode) {
      axis = 1.0; // força seguir para a direita
    }
    if (_joyActive && axis.abs() > 0.05 && !_controlsLocked) {
>>>>>>> 757566ea8fc248ce85274975105fc358d44853b5
      playerVelocityX += MOVE_SPEED * axis * dt * 60;
      // espelha estado das teclas para manter lógica externa consistente
      kLeft = axis < 0;
      kRight = axis > 0;
<<<<<<< HEAD
    } else if (hasKeys) {
=======
    } else if (hasKeys && !_controlsLocked) {
>>>>>>> 757566ea8fc248ce85274975105fc358d44853b5
      final int dir = kLeft ? -1 : 1;
      playerVelocityX += MOVE_SPEED * dir * dt * 60;
    } else {
      playerVelocityX *= 0.9;
    }
    playerVelocityX = playerVelocityX.clamp(-targetMax, targetMax);
<<<<<<< HEAD
=======
    // Em modo veículo, lógica da fase de aproximação/entrada/dirigir
    if (currentLevel.vehicleMode) {
      if (_vehiclePhase == 'approaching') {
        // corre até chegar próximo do carro
        final double targetX = _parkedCarX - currentLevel.vehicleWidth * 0.45;
        final double dist = targetX - playerX;
        if (dist > 0) {
          playerVelocityX += MOVE_SPEED * 0.6 * dt * 60;
        }
        // lock direção para direita
        isFacingRight = true;
        if (dist <= 4.0 && _onGround) {
          _vehiclePhase = 'entering';
          _enterTimer = 0.45;
        }
      } else if (_vehiclePhase == 'entering') {
        // desacelera e toca a animação de entrada
        playerVelocityX *= 0.85;
        isFacingRight = true;
        _enterTimer -= dt;
        if (_enterTimer <= 0) {
          inVehicle = true;
          _vehiclePhase = 'driving';
          _controlsLocked = false;
          // encaixa o jogador ao carro
          playerX = _parkedCarX;
          playerY = groundY - currentLevel.vehicleHeight;
        }
      } else if (_vehiclePhase == 'driving') {
        // garante velocidade mínima para seguir nas dunas
        if (playerVelocityX < 2.5) {
          playerVelocityX = 2.5;
        }
      }
    }
>>>>>>> 757566ea8fc248ce85274975105fc358d44853b5
    playerX += playerVelocityX;

    // Atualizar direção do personagem
    if (playerVelocityX.abs() > 0.1) {
      isFacingRight = playerVelocityX > 0;
    }

    // Atualizar ciclo de caminhada
    walkCycle += 0.25 * dt * 60;
  }

  void _checkCollisions() {
<<<<<<< HEAD
    final playerRect = Rect.fromLTWH(playerX, playerY, PLAYER_SIZE, PLAYER_SIZE);
=======
    // Usa dimensões variáveis quando em veículo
    final double entityWidth = inVehicle
        ? currentLevel.vehicleWidth
        : PLAYER_SIZE;
    final double entityHeight = inVehicle
        ? currentLevel.vehicleHeight
        : PLAYER_SIZE;
    final playerRect = Rect.fromLTWH(
        playerX, playerY, entityWidth, entityHeight);
>>>>>>> 757566ea8fc248ce85274975105fc358d44853b5
    final bool wasOnGround = _onGround; // detectar transição ar->chão
    bool onGround = false;

    // Verificar colisão com plataformas
    for (final platform in platforms) {
      if (playerRect.overlaps(platform)) {
        if (playerVelocityY > 0 && playerY < platform.top) {
<<<<<<< HEAD
          playerY = platform.top - PLAYER_SIZE;
=======
          playerY = platform.top - entityHeight;
>>>>>>> 757566ea8fc248ce85274975105fc358d44853b5
          playerVelocityY = 0;
          onGround = true;
          isJumping = false;
          _jumpCount = 0; // reset combos ao tocar o chão
        }
      }
    }

    // Verificar coleta de moedas
    for (int i = 0; i < coins.length; i++) {
      if (!collectedCoins.contains(i)) {
        final coinRect = Rect.fromCircle(center: coins[i], radius: 15);
        if (playerRect.overlaps(coinRect)) {
          _collectCoin(i);
        }
      }
    }

    // Atualiza estado global de chão
    _onGround = onGround;

    // Poeira ao aterrissar no deserto
    if (onGround && !wasOnGround && currentLevel.emojiCategory == 'deserto') {
      _emitSandPuff(playerX + PLAYER_SIZE * 0.5, groundY - 2);
    }

    // Stomp em abelhas
    if (!isGameOver) {
      final List<_Bee> beesToRemove = [];
      for (final b in bees) {
        final Rect beeRect = Rect.fromLTWH(b.x - 14, b.currentY - 14, 28, 28);
        if (playerRect.overlaps(beeRect)) {
          // Considera stomp quando o jogador toca a REGIÃO SUPERIOR da abelha
          // Torna o jogo mais permissivo: topZone = 45% superior do sprite da abelha
          final double topZoneLimit = beeRect.top + beeRect.height * 0.45;
          final bool stomping = playerRect.bottom <= topZoneLimit;
          if (stomping) {
            // matar abelha
            beesToRemove.add(b);
            // bounce
            playerVelocityY = JUMP_FORCE * 0.6;
            // partículas
            _particleSystem.addExplosion(b.x, b.currentY, Colors.yellowAccent);
            // pontuação extra
            score += 150;
            // som ao matar inimigo
            _beePlayer.stop();
            _beePlayer.play(AssetSource('assets/abelha.mp3'), volume: 0.9);
          }
        }
      }
      if (beesToRemove.isNotEmpty) {
        bees.removeWhere((e) => beesToRemove.contains(e));
      }
    }

    // Stomp em criaturas dos lagos
    if (!isGameOver) {
      final List<_LakeCreature> creaturesToRemove = [];
      for (final c in _lakeCreatures) {
        final double size = 28 * c.scale;
        final Rect creatureRect = Rect.fromLTWH(
            c.x - size / 2, c.currentY - size / 2, size, size);
        if (playerRect.overlaps(creatureRect)) {
          // Stomp se tocar a região superior da criatura (top ~45%)
          final double topZoneLimit = creatureRect.top +
              creatureRect.height * 0.45;
          final bool stomping = playerRect.bottom <= topZoneLimit;
          if (stomping) {
            creaturesToRemove.add(c);
            playerVelocityY = JUMP_FORCE * 0.6;
            _particleSystem.addExplosion(
                c.x, c.currentY, Colors.lightBlueAccent);
            score += 100;
          }
        }
      }
      if (creaturesToRemove.isNotEmpty) {
        _lakeCreatures.removeWhere((e) => creaturesToRemove.contains(e));
      }
    }

    // Verificar colisão com inimigos (lados/baixo) => morte
    if (!isGameOver) {
      for (final b in bees) {
        final Rect beeRect = Rect.fromLTWH(b.x - 14, b.currentY - 14, 28, 28);
        if (playerRect.overlaps(beeRect)) {
          // Se não for stomp (região superior), então é colisão letal
          final double topZoneLimit = beeRect.top + beeRect.height * 0.45;
          final bool stomping = playerRect.bottom <= topZoneLimit;
          if (stomping) {
            continue; // já tratado acima
          }
          // risada quando inimigo mata o personagem
          _laughPlayer.stop();
          _laughPlayer.play(AssetSource('assets/risada.mp3'), volume: 0.9);
          _gameOver();
          break;
        }
      }
    }

    // Cidade: colisão com carros => morte (tem que pular por cima sem tocar)
    if (!isGameOver && currentLevel.emojiCategory == 'cidade') {
      for (final car in _cars) {
        if (playerRect.overlaps(car.rect)) {
          _laughPlayer.stop();
          _laughPlayer.play(AssetSource('assets/risada.mp3'), volume: 0.9);
          _gameOver();
          break;
        }
      }
    }

<<<<<<< HEAD
=======
    // Veículo no deserto: colisão com cactos => morte
    if (!isGameOver && currentLevel.vehicleMode &&
        currentLevel.emojiCategory == 'deserto') {
      for (final cactus in _cacti) {
        if (playerRect.overlaps(cactus.rect)) {
          _laughPlayer.stop();
          _laughPlayer.play(AssetSource('assets/risada.mp3'), volume: 0.9);
          _gameOver();
          break;
        }
      }
    }

>>>>>>> 757566ea8fc248ce85274975105fc358d44853b5
    // Plantas: colisão com troncos => morte (precisa pular por cima)
    if (!isGameOver && currentLevel.emojiCategory == 'plantas') {
      for (final log in _logs) {
        if (playerRect.overlaps(log.rect)) {
          _laughPlayer.stop();
          _laughPlayer.play(AssetSource('assets/risada.mp3'), volume: 0.9);
          _gameOver();
          break;
        }
      }
    }

    // Verificar morte por água (lagos)
    if (!isGameOver) {
      final double playerLeft = playerRect.left;
      final double playerRight = playerRect.right;
      final bool inAnyLake = _holes.any((h) =>
      playerRight > h.startX && playerLeft < h.endX);
      if (inAnyLake && playerRect.bottom > groundY + 2) {
        _gameOver();
      }
    }

    // Verificar morte por queda fora da tela (abaixo do viewport)
    if (!isGameOver) {
      final double screenHeight = MediaQuery
          .of(context)
          .size
          .height;
      if (playerRect.top > screenHeight + 20) {
        _gameOver();
      }
    }

    // Verificar chegada na meta (goal)
    if (!isGameOver && !isLevelComplete) {
      // Considera que cruzar a posição X da bandeira finaliza a fase
<<<<<<< HEAD
      if (playerX + PLAYER_SIZE >= goalX - 4) {
=======
      if (playerX + entityWidth >= goalX - 4) {
>>>>>>> 757566ea8fc248ce85274975105fc358d44853b5
        _completeLevel();
      }
    }
  }

  void _collectCoin(int index) {
    collectedCoins.add(index);
    coinsCollected++;
    score += 100;

    // Tocar som
    _coinPlayer.stop();
    _coinPlayer.play(AssetSource('assets/coletando.mp3'), volume: 0.7);

    // Adicionar partículas
    _particleSystem.addCoinBurst(
        coins[index].dx,
        coins[index].dy,
    );

    // Atualizar saldo
    _updateBalance();
  }

  void _updateBalance() {
    double added = 0.00000001;
    balance += added;

    // Atualizar no Supabase
    if (userId.isNotEmpty) {
      SupabaseService().addBubbleCoin(userId, added);
    }

    // Verificar bonus
    _checkBonus();
  }

  void _checkBonus() {
    normalCollectCount++;

    // Bonus de emoji a cada 5 moedas
    if (normalCollectCount % 5 == 0) {
      final emojis = ['😀', '😃', '😄', '😁', '😆', '😅', '😂', '😊', '😇'];
      lastEmojiAwarded = emojis[Random().nextInt(emojis.length)];
      showEmojiBadge = true;
      emojiBadgeOpacity = 1.0;

      Future.delayed(const Duration(milliseconds: 1700), () {
        if (mounted) setState(() => showEmojiBadge = false);
      });
    }

    // Bonus de Solana
    if (balance - lastSolTriggerBalance >= SOL_TRIGGER_THRESHOLD) {
      showSolBadge = true;
      solBadgeOpacity = 1.0;
      lastSolTriggerBalance = balance;

      Future.delayed(const Duration(milliseconds: 2000), () {
        if (mounted) setState(() => showSolBadge = false);
      });
    }
  }

  void _updateVisualElements(double dt) {
    // Atualizar nuvens
    for (final c in clouds) {
      c.x -= c.speed;
      if (c.x < -200) c.x = worldLength + 200;
    }

    // Atualizar abelhas
    for (final b in bees) {
      b.x += b.dir * b.speed * 0.9;
      if (b.x < 60) b.x = 60;
      if (b.x > worldLength - 60) b.x = worldLength - 60;
      // Atualiza posição vertical animada para uso em colisão e render
      b.currentY = b.baseY + sin(b.phase + DateTime
          .now()
          .millisecondsSinceEpoch * 0.003) * b.amp;
    }

    // Atualizar criaturas nos lagos (posição animada)
    for (final c in _lakeCreatures) {
      c.currentY = c.baseY + sin(DateTime
          .now()
          .millisecondsSinceEpoch * 0.004 + c.phase) * c.amp;
    }

    // Atualizar partículas
    _particleSystem.update(dt);

    // Cidade: spawn e movimento de carros
    if (currentLevel.emojiCategory == 'cidade') {
      // Atualiza posição dos carros existentes
      _cars.removeWhere((c) => c.x < cameraOffset - 200);
      for (final car in _cars) {
        car.x -= car.speed;
        // Atualiza a posição vertical caso o solo tenha mudado
        car.yTop = groundY - car.height;
      }

      // Spawn controlado por tempo
      _carSpawnTimer += dt;
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final double screenW = view.physicalSize.width / view.devicePixelRatio;
      final double interval = (kSprint ? 0.9 : 1.3) +
          Random().nextDouble() * 0.6;
      if (_carSpawnTimer >= interval) {
        _carSpawnTimer = 0.0;
        final _CategoryEmojiSets citySets = _getEmojiSetsForCategory('cidade');
        final String emoji = citySets.enemyEmojis[
        Random().nextInt(citySets.enemyEmojis.length)
        ];
        final double spawnX = cameraOffset + screenW + 120 +
            Random().nextDouble() * 240;
        final double speed = 3.2 + Random().nextDouble() * 3.6;
        _cars.add(_Car(
          x: spawnX,
          yTop: groundY - 26,
          width: 40,
          height: 26,
          speed: speed,
          emoji: emoji,
        ));
      }
    }

    // Poeira contínua ao correr no deserto
    if (currentLevel.emojiCategory == 'deserto' && _onGround &&
        playerVelocityX.abs() > 1.5) {
      _sandPuffTimer += dt;
      final double interval = kSprint ? 0.05 : 0.09;
      if (_sandPuffTimer >= interval) {
        _sandPuffTimer = 0.0;
        _emitSandPuff(
          playerX + (isFacingRight ? PLAYER_SIZE * 0.2 : PLAYER_SIZE * 0.8),
          groundY - 2,
        );
      }
    } else {
      _sandPuffTimer = 0.0;
    }

    // Atualizar câmera
    cameraOffset = playerX - 200;
  }

  // Emite pequenas poeiras de areia (efeito deserto)
  void _emitSandPuff(double x, double y) {
    final Random rng = Random();
    final int count = 6 + rng.nextInt(6);
    for (int i = 0; i < count; i++) {
      final double ang = (-0.25 + rng.nextDouble() * 0.5); // leque horizontal
      final double spd = 0.5 + rng.nextDouble() * 1.2;
      final double vy = (-0.2 + rng.nextDouble() * 0.4);
      final double life = 0.9 + rng.nextDouble() * 0.7;
      _particleSystem.particles.add(Particle(
        x: x + rng.nextDouble() * 30 - 15,
        y: y + rng.nextDouble() * 16 - 8,
        vx: cos(ang) * spd * (isFacingRight ? 1.0 : -1.0),
        vy: vy,
        size: 1.2 + rng.nextDouble() * 2.0,
        life: life,
        initialLife: life,
        isGlow: true,
        color: const Color(0xFFB38B5D).withOpacity(0.35),
      ));
    }
  }

  void _jump() {
    if (_jumpCount >= 3) return; // limita a 3 pulos consecutivos
    setState(() {
      if (_onGround) {
        _jumpCount = 0; // caso esteja no chão, reinicia o combo
      }
      playerVelocityY = JUMP_FORCE;
      isJumping = true;
      _jumpCount += 1;
      _playerAnimationController.forward(from: 0.0);
    });
  }

  void _gameOver() {
    setState(() {
      isGameOver = true;
      _cameraShakeController.forward(from: 0.0);
      _sfxPlayer.play(AssetSource('grito2.mp3'), volume: 0.9);
    });
  }

  void _restartGame() {
    setState(() {
      _resetGame();
      // Ajusta o solo conforme a altura lógica atual (orientação/landscape)
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final double logicalH = view.physicalSize.height / view.devicePixelRatio;
      _applyResponsiveGround(logicalH);
      _startGame();
    });
  }

  void _completeLevel() {
    // Apenas marca como concluída; a navegação/salvamento é decidida na UI
    setState(() {
      isLevelComplete = true;
    });
  }

  // ====================== PROGRESSO PERSISTENTE ======================
  Future<void> _saveProgress() async {
    // Salva o índice da próxima fase (ou a última disponível)
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int nextIndex = (levelIndex + 1).clamp(0, levels.length - 1);
    await prefs.setInt('saved_level_index', nextIndex);
  }

  Future<void> _loadAndApplySavedProgress() async {
    // Carrega índice salvo e aplica como ponto de continuação
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final int? saved = prefs.getInt('saved_level_index');
    if (saved != null && saved >= 0 && saved < levels.length) {
      if (!mounted) return;
      setState(() {
        levelIndex = saved;
        currentLevel = levels[levelIndex];
        _applyLevel(currentLevel);
        _resetGame();
        // Garante ajuste do solo para a altura atual da tela
        final view = WidgetsBinding.instance.platformDispatcher.views.first;
        final double logicalH = view.physicalSize.height /
            view.devicePixelRatio;
        _applyResponsiveGround(logicalH);
        // não iniciamos aqui; a intro cuida de começar no botão Play
      });
    }
  }

  Future<void> _clearProgress() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('saved_level_index');
  }

  Widget _buildPlayer() {
<<<<<<< HEAD
=======
    if (inVehicle) {
      final double w = currentLevel.vehicleWidth;
      final double h = currentLevel.vehicleHeight;
      return SizedBox(
        width: w,
        height: h,
        child: Stack(
          children: [
            BugCarWidget(
              width: w,
              height: h,
              facingRight: isFacingRight,
            ),
            // Motorista visível dentro da cabine
            Positioned(
              left: w * 0.34,
              top: h * 0.10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(h * 0.06),
                child: SizedBox(
                  width: w * 0.38,
                  height: h * 0.28,
                  child: Center(
                    child: SizedBox(
                      width: h * 0.26,
                      height: h * 0.26,
                      child: CustomPaint(
                        painter: HumanoidPainter(
                          bodyTilt: 0.0,
                          jumpSquash: 1.0,
                          isJumping: false,
                          walkCycle: walkCycle,
                          speedNorm: (playerVelocityX.abs() / MAX_RUN_SPEED)
                              .clamp(0.0, 1.0),
                          facingRight: isFacingRight,
                        ),
                        size: Size(h * 0.26, h * 0.26),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
>>>>>>> 757566ea8fc248ce85274975105fc358d44853b5
    return CustomPaint(
      painter: HumanoidPainter(
        bodyTilt: sin(walkCycle) * 0.1,
        jumpSquash: _jumpSquash,
        isJumping: isJumping,
        walkCycle: walkCycle,
        speedNorm: playerVelocityX.abs() / MAX_RUN_SPEED,
        facingRight: isFacingRight,
      ),
      size: Size(PLAYER_SIZE, PLAYER_SIZE),
    );
  }

  Widget _buildMobileControls() {
    // Layout de controles móveis estilo Roblox/Minecraft:
    // - Joystick analógico à esquerda
    // - Botão de pulo à direita
    // - Botão de sprint acima/direita
    const double pad = 20;
    const double joySize = 130;
    const double baseRadius = 50; // raio útil para normalizar o vetor
    final Offset knobOffset = Offset(
      (joySize / 2) + _joyVector.dx.clamp(-1.0, 1.0) * baseRadius,
      (joySize / 2) + _joyVector.dy.clamp(-1.0, 1.0) * baseRadius,
    );

    return Stack(
      children: [
        // Joystick
        Positioned(
          left: pad,
          bottom: pad,
          child: Listener(
            onPointerDown: (e) {
              final local = e.localPosition;
              final center = Offset(joySize / 2, joySize / 2);
              Offset v = local - center;
              if (v.distance > baseRadius) {
                v = v / v.distance * baseRadius;
              }
              setState(() {
                _joyActive = true;
                _joyVector = Offset(v.dx / baseRadius, v.dy / baseRadius);
              });
            },
            onPointerMove: (e) {
              final local = e.localPosition;
              final center = Offset(joySize / 2, joySize / 2);
              Offset v = local - center;
              if (v.distance > baseRadius) {
                v = v / v.distance * baseRadius;
              }
              setState(() {
                _joyActive = true;
                _joyVector = Offset(v.dx / baseRadius, v.dy / baseRadius);
              });
            },
            onPointerUp: (_) {
              setState(() {
                _joyActive = false;
                _joyVector = Offset.zero;
                kLeft = false;
                kRight = false;
              });
            },
            onPointerCancel: (_) {
              setState(() {
                _joyActive = false;
                _joyVector = Offset.zero;
                kLeft = false;
                kRight = false;
              });
            },
            child: SizedBox(
              width: joySize,
              height: joySize,
              child: Stack(
                children: [
                  // Base do joystick
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 12,
                        )
                      ],
                    ),
                  ),
                  // Anel indicativo
                  Center(
                    child: Container(
                      width: baseRadius * 2,
                      height: baseRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white.withOpacity(0.35),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  // Knob
                  Positioned(
                    left: knobOffset.dx - 28,
                    top: knobOffset.dy - 28,
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.85),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.25),
                            blurRadius: 8,
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Botão de pulo
        Positioned(
          right: pad,
          bottom: pad,
          child: GestureDetector(
            onTapDown: (_) => _jump(),
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                color: Colors.blueAccent.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                      color: Colors.blue.withOpacity(0.5),
                      blurRadius: 12,
                      spreadRadius: 2)
                ],
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.arrow_upward, color: Colors.white, size: 40),
            ),
          ),
        ),

        // Botão de sprint (segurar)
        Positioned(
          right: pad + 12,
          bottom: pad + 96,
          child: Listener(
            onPointerDown: (_) => setState(() => kSprint = true),
            onPointerUp: (_) => setState(() => kSprint = false),
            onPointerCancel: (_) => setState(() => kSprint = false),
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 10,
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Icon(Icons.run_circle,
                  color: kSprint ? Colors.green : Colors.black54, size: 34),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final bool isDesert = currentLevel.emojiCategory == 'deserto';
    final bool isCity = currentLevel.emojiCategory == 'cidade';
    final bool isPlants = currentLevel.emojiCategory == 'plantas';
    // Dimensões destacadas para o prédio TerlineT AI (maior e mais largo)
    const double terlineTWidth = 320;
    const double terlineTHeight = 380;

    return Scaffold(
      body: RawKeyboardListener(
        focusNode: _focusNode,
        autofocus: true,
        onKey: _onRawKey,
        child: Stack(
          children: [
            // Céu: usa imagem se disponível; caso contrário, mantém gradiente
            if (_parallaxReady)
              Positioned.fill(
                child: Image.asset(
                  _skyAsset,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      currentLevel.skyTop,
                      currentLevel.skyBottom,
                    ],
                  ),
                ),
              ),
            // Camada de nuvens de fundo (parallax suave, repetindo em X)
            if (_hasCloudsBG)
              Positioned(
                left: -cameraOffset * 0.06,
                top: 20,
                child: Opacity(
                  opacity: 0.45,
                  child: Container(
                    width: worldLength + 1200,
                    height: 180,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(_cloudsBGAsset),
                        repeat: ImageRepeat.repeatX,
                        alignment: Alignment.topLeft,
                        fit: BoxFit.none,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ),
                ),
              ),
            // Colinas distantes
            if (!isDesert && !isCity && (_hasHillsV02 || _hasHillsV01))
              Positioned(
                left: -cameraOffset * 0.10,
                top: groundY - 268,
                child: Opacity(
                  opacity: 0.80,
                  child: Container(
                    width: worldLength + 1400,
                    height: 220,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                            _hasHillsV02 ? _hillsV02Asset : _hillsV01Asset),
                        repeat: ImageRepeat.repeatX,
                        alignment: Alignment.bottomLeft,
                        fit: BoxFit.none,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ),
                ),
              ),
            // Colinas próximas (se tivermos as duas variantes, usamos a outra camada)
            if (!isDesert && !isCity && _hasHillsV02 && _hasHillsV01)
              Positioned(
                left: -cameraOffset * 0.18,
                top: groundY - 218,
                child: Opacity(
                  opacity: 0.90,
                  child: Container(
                    width: worldLength + 1400,
                    height: 200,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(_hillsV01Asset),
                        repeat: ImageRepeat.repeatX,
                        alignment: Alignment.bottomLeft,
                        fit: BoxFit.none,
                        filterQuality: FilterQuality.none,
                      ),
                    ),
                  ),
                ),
              ),
            // Nuvens (parallax leve)
            for (final c in clouds)
              Positioned(
                left: c.x - cameraOffset * 0.15,
                top: c.y,
                child: Transform.scale(
                  scale: c.scale,
                  child: const CloudWidget(),
                ),
              ),

            // Árvores grandes no plano de fundo (fase Plantas)
            if (isPlants) ...[
              // Camada distante de árvores
              for (final t in _treesFar)
                Positioned(
                  left: t.x - cameraOffset * 0.10,
                  top: groundY - t.height - 120,
                  child: _buildTree(
                      t.width, t.height, t.trunkColor.withOpacity(0.9),
                      t.canopyColor.withOpacity(0.9)),
                ),
              // Camada próxima de árvores
              for (final t in _treesNear)
                Positioned(
                  left: t.x - cameraOffset * 0.18,
                  top: groundY - t.height - 40,
                  child: _buildTree(
                      t.width, t.height, t.trunkColor, t.canopyColor),
                ),
            ],

            // Holofotes varrendo o céu (atrás dos prédios)
            if (isCity)
              for (final tx in _terlineTBuildingXs) ...[
                Positioned(
                  left: (tx - 20) - cameraOffset * 0.10,
                  top: groundY - 380 - 200,
                  child: IgnorePointer(
                    child: _SearchLight(
                      length: 320,
                      baseWidth: 90,
                      color: Colors.yellowAccent,
                      phase: tx * 0.0003,
                    ),
                  ),
                ),
                Positioned(
                  left: (tx + 80) - cameraOffset * 0.10,
                  top: groundY - 380 - 200,
                  child: IgnorePointer(
                    child: _SearchLight(
                      length: 300,
                      baseWidth: 80,
                      color: Colors.cyanAccent,
                      phase: 1.2 + tx * 0.00037,
                    ),
                  ),
                ),
              ],

            // Skyline da cidade (prédios em duas camadas + prédio TerlineT)
            if (isCity) ...[
              // Camada distante
              for (final b in _cityBuildingsFar)
                Positioned(
                  left: b.x - cameraOffset * 0.08,
                  top: groundY - b.height - 80,
                  child: Container(
                    width: b.width,
                    height: b.height,
                    decoration: BoxDecoration(
                      color: b.color.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              // Camada próxima
              for (final b in _cityBuildingsNear)
                Positioned(
                  left: b.x - cameraOffset * 0.14,
                  top: groundY - b.height - 30,
                  child: Container(
                    width: b.width,
                    height: b.height,
                    decoration: BoxDecoration(
                      color: b.color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
    // Renderiza prédios TerlineT na camada próxima do skyline (maiores)
              for (final tx in _terlineTBuildingXs)
                Positioned(
                  left: tx - cameraOffset * 0.14,
    top: groundY - terlineTHeight,
    child: TerlineTBuilding(width: terlineTWidth, height: terlineTHeight),
                ),
            ],

            // Dunas (parallax) quando deserto
            if (isDesert)
              ...[
                for (double x = 0; x < worldLength + 800; x += 360)
                  Positioned(
                    left: x - cameraOffset * 0.10,
                    top: groundY - 240,
                    child: const HillWidget(
                      color: Color(0xFFE6C78E),
                      scale: 1.2,
                    ),
                  ),
                for (double x = 0; x < worldLength + 800; x += 420)
                  Positioned(
                    left: x - cameraOffset * 0.18,
                    top: groundY - 200,
                    child: const HillWidget(
                      color: Color(0xFFC9A56A),
                      scale: 1.1,
                    ),
                  ),
              ],

            // Chão
            Positioned(
              left: -cameraOffset,
              top: groundY,
              child: Container(
                width: worldLength,
                height: MediaQuery
                    .of(context)
                    .size
                    .height - groundY,
                decoration: BoxDecoration(
                  gradient: isDesert
                      ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFEED9A6), // areia clara
                      Color(0xFFDAB77E), // areia média
                    ],
                  )
                      : (isCity
                      ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF424242),
                      Color(0xFF212121),
                    ],
                  )
                      : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.green.shade600,
                      Colors.green.shade800,
                    ],
                  )),
                ),
              ),
            ),
            // Faixas da pista (tracejadas) para cidade
            if (isCity)
              ...[
                for (double x = 0; x < worldLength; x += 60)
                  Positioned(
                    left: x - cameraOffset,
                    top: groundY + 26,
                    child: Container(
                      width: 32,
                      height: 4,
                      color: Colors.amberAccent.withOpacity(0.9),
                    ),
                  ),
                for (double x = 30; x < worldLength; x += 60)
                  Positioned(
                    left: x - cameraOffset,
                    top: groundY + 58,
                    child: Container(
                      width: 32,
                      height: 4,
                      color: Colors.amberAccent.withOpacity(0.9),
                    ),
                  ),
              ],
            // Lagos (água nos buracos) - desenhar antes das plataformas (não na cidade)
            if (!isCity)
              for (final h in _holes)
                Positioned(
                  left: h.startX - cameraOffset,
                  top: groundY,
                  child: Container(
                    width: (h.endX - h.startX),
                    height: MediaQuery
                        .of(context)
                        .size
                        .height - groundY,
                    decoration: BoxDecoration(
                      gradient: isDesert
                          ? const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFE6C78E), // areia do topo
                          Color(0xFFC9A56A), // areia mais funda
                        ],
                      )
                          : LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.blueAccent.withOpacity(0.75),
                          Color(0xFF303F9F).withOpacity(0.9),
                        ],
                      ),
                    ),
                  ),
                ),
            // Superfície da água (linha mais clara)
            if (!isDesert && !isCity)
              for (final h in _holes)
                Positioned(
                  left: h.startX - cameraOffset,
                  top: groundY - 2,
                  child: Container(
                    width: (h.endX - h.startX),
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.lightBlueAccent.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.lightBlueAccent.withOpacity(0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                ),

            // Criaturas dos lagos (emojis boiando) — não na cidade
            if (!isCity)
              for (final c in _lakeCreatures)
                Positioned(
                  left: c.x - cameraOffset - 14,
                  top: (c.baseY + sin(nowMs * 0.004 + c.phase) * c.amp) - 14,
                  child: Transform.scale(
                    scale: c.scale,
                    child: Text(c.emoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),

            // Plataformas (não desenhar na cidade; mantidas para colisão)
            if (!isCity)
              for (final platform in platforms)
                if ((platform.right - cameraOffset) > -50 &&
                    (platform.left - cameraOffset) < screenWidth + 50)
                  Positioned(
                    left: platform.left - cameraOffset,
                    top: platform.top,
                    child: Container(
                      width: platform.width,
                      height: platform.height,
                      decoration: BoxDecoration(
                        color: isDesert
                            ? const Color(0xFFD2B48C) // areia/terra
                            : Colors.green.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),

            // Troncos (obstáculos da fase Plantas)
            if (isPlants)
              for (final log in _logs)
                Positioned(
                  left: log.x - cameraOffset,
                  top: log.yTop,
                  child: Container(
                    width: log.width,
                    height: log.height,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFA1887F), Color(0xFF6D4C41)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.brown.shade200.withOpacity(0.8),
                          borderRadius: const BorderRadius.vertical(top: Radius
                              .circular(6)),
                        ),
                      ),
                    ),
                  ),
                ),
<<<<<<< HEAD
=======
            // Carro estacionado (antes de entrar no veículo)
            if (currentLevel.vehicleMode && _vehiclePhase != 'driving')
              Positioned(
                left: _parkedCarX - cameraOffset,
                top: groundY - currentLevel.vehicleHeight,
                child: BugCarWidget(
                  width: currentLevel.vehicleWidth,
                  height: currentLevel.vehicleHeight,
                  facingRight: true,
                ),
              ),
            // Cactos (obstáculos da fase veículo no deserto)
            if (currentLevel.vehicleMode && isDesert)
              for (final c in _cacti)
                Positioned(
                  left: c.x - cameraOffset,
                  top: c.yTop,
                  child: Transform.scale(
                    scale: c.height / 28.0,
                    child: Text(c.emoji, style: const TextStyle(fontSize: 28)),
                  ),
                ),
>>>>>>> 757566ea8fc248ce85274975105fc358d44853b5

            // Moedas
            for (final entry in coins
                .asMap()
                .entries)
              if (!collectedCoins.contains(entry.key))
                Positioned(
                  left: entry.value.dx - cameraOffset - 10,
                  top: entry.value.dy - 10,
                  child: Transform.scale(
                    scale: 0.9 + 0.15 * sin((nowMs * 0.008) + entry.key),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [Colors.amber, Colors.orange],
                          stops: [0.3, 1.0],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

            // Inimigos da fase (emojis por categoria)
            for (final b in bees)
              Positioned(
                left: b.x - cameraOffset - 24,
                top: b.currentY - 12,
                child: BeeWidget(
                    scale: 1.0, facingRight: b.dir >= 0, emoji: b.emoji),
              ),

            // Carros da cidade
            if (isCity)
              for (final car in _cars)
                Positioned(
                  left: car.x - cameraOffset,
                  top: car.yTop,
                  child: CarWidget(emoji: car.emoji, scale: 1.0),
                ),

            // Personagem
            Positioned(
              left: playerX - cameraOffset,
              top: playerY,
              child: _buildPlayer(),
            ),

            // Meta
            Positioned(
              left: goalX - cameraOffset - 8,
              top: groundY - 90,
              child: const GoalWidget(height: 90),
            ),

            // Partículas
            Positioned(
              left: 0,
              top: 0,
              child: CustomPaint(
                painter: _ParticlePainter(
                  particles: _particleSystem.particles,
                  cameraOffset: cameraOffset,
                ),
                size: Size(screenWidth, MediaQuery
                    .of(context)
                    .size
                    .height),
              ),
            ),

            // UI
            Positioned(
              top: 30,
              left: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Pontuação
                  Text(
                    'Pontos: $score',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),

                  // Moedas
                  Text(
                    'Moedas: $coinsCollected',
                    style: const TextStyle(
                      color: Colors.amber,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),

                  // Saldo Bubble Coin
                  Row(
                    children: [
                      Image.asset(
                          'assets/icon_bolhas.png', width: 24, height: 24),
                      const SizedBox(width: 8),
                      Text(
                        balance.toStringAsFixed(8),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Indicador de fase no canto superior direito
            Positioned(
              top: 30,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Fase ${levelIndex + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Badges de recompensa
            if (showEmojiBadge)
              Positioned(
                top: 100,
                left: screenWidth / 2 - 100,
                child: AnimatedOpacity(
                  opacity: emojiBadgeOpacity,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.deepOrangeAccent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      '$lastEmojiAwarded +1 BUBBLE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            if (showSolBadge)
              Positioned(
                top: 150,
                left: screenWidth / 2 - 120,
                child: AnimatedOpacity(
                  opacity: solBadgeOpacity,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.purpleAccent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Text(
                      'SOLANA POP! +0.0000001 SOL',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),

            // Controles móveis
            if (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS)
              _buildMobileControls(),

            // Telas de estado
            if (isGameOver) _buildGameOverOverlay(),
            if (isLevelComplete) _buildLevelCompleteOverlay(),

            // Tela de introdução (sobrepõe tudo até o usuário iniciar)
            if (_showIntro) Positioned.fill(child: _buildIntroOverlay()),

            // Mãozinha de voltar (sempre por cima)
            Positioned(
              top: 12,
              left: 12,
              child: SafeArea(
                child: GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.35),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text('👈', style: TextStyle(fontSize: 24)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroOverlay() {
    final Size size = MediaQuery
        .of(context)
        .size;
    final List<String> heroEmojis = ['🌲', '🏙️', '🏞️', '🐝', '🍓', '👾', '🍀', '💎'];
    // Atualiza limites e cria floaters na primeira construção ou quando o tamanho muda
    if (_introBounds != size) {
      _introBounds = size;
      if (_introFloaters.isEmpty) {
        _initIntroFloaters();
      }
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
        ),
      ),
      child: Stack(
        children: [
          // Emojis decorativos flutuantes
          Positioned.fill(
            child: IgnorePointer(
              child: Stack(
                children: [
                  for (final floater in _introFloaters)
                    Positioned(
                      left: floater.x,
                      top: floater.y,
                      child: Opacity(
                        opacity: floater.opacity,
                        child: Transform.scale(
                          scale: floater.scale,
                          child: Text(floater.emoji,
                              style: const TextStyle(
                                fontSize: 32,
                                shadows: [
                                  Shadow(
                                    blurRadius: 6,
                                    color: Colors.black45,
                                    offset: Offset(2, 3),
                                  )
                                ],
                              )),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Conteúdo principal
          Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: size.width * 0.9, maxHeight: size.height * 0.9),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text('Bubbles',
                          style: TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            letterSpacing: 1.0,
                            shadows: [Shadow(color: Colors.black54,
                                blurRadius: 8)
                            ],
                          )),
                      SizedBox(width: 8),
                      Text('Chain',
                          style: TextStyle(
                            fontSize: 46,
                            fontWeight: FontWeight.w800,
                            color: Colors.cyanAccent,
                            letterSpacing: 1.0,
                            shadows: [Shadow(color: Colors.black54,
                                blurRadius: 8)
                            ],
                          )),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Se aventure em florestas, bosques e cidades coletando coins para receber BubblesCoins\n'
                        'e trocá-las por MicroBitCoins. Desvie de inimigos, explore e conquiste as fases!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white, fontSize: 16, height: 1.4),
                  ),
                  const SizedBox(height: 26),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 8,
                    children: const [
                      _IntroChip(icon: '🌲', label: 'Bosques'),
                      _IntroChip(icon: '🏙️', label: 'Cidades'),
                      _IntroChip(icon: '🐝', label: 'Inimigos'),
                      _IntroChip(icon: '💰', label: 'Coins'),
                      _IntroChip(icon: '🫧', label: 'BubblesCoins'),
                      _IntroChip(icon: '₿', label: 'MicroBitCoins'),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 220,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _showIntro = false;
                          _startGame();
                          // Parar animação dos floaters da intro
                          if (_introController?.isAnimating == true) {
                            _introController!.stop();
                          }
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        shadowColor: Colors.black54,
                        elevation: 6,
                      ),
                      child: SizedBox(
                        height: 28,
                        child: Stack(
                          alignment: Alignment.center,
                          children: const [
                            Positioned(
                              left: 6,
                              child: Icon(Icons.play_arrow_rounded, size: 28),
                            ),
                            Center(
                              child: Text(
                                'Play',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onRawKey(RawKeyEvent event) {
    final bool isDown = event is RawKeyDownEvent;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.keyA || key == LogicalKeyboardKey.arrowLeft) {
      kLeft = isDown;
      if (isDown) kRight = false;
    } else if (key == LogicalKeyboardKey.keyD ||
        key == LogicalKeyboardKey.arrowRight) {
      kRight = isDown;
      if (isDown) kLeft = false;
    } else if (key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) {
      kSprint = isDown;
    } else if (key == LogicalKeyboardKey.space) {
      kJumpHeld = isDown;
      if (isDown) _jump();
    }
  }

  Widget _buildGameOverOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Game Over',
              style: TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                shadows: const <Shadow>[
                  Shadow(
                    blurRadius: 10,
                    color: Colors.red,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Pontuação: $score',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _restartGame,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar Novamente'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                backgroundColor: Colors.blueAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelCompleteOverlay() {
    final bool isLastLevel = levelIndex >= levels.length - 1;
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLastLevel ? 'Todas as fases concluídas!' : 'Fase Concluída!',
              style: TextStyle(
                color: Colors.amber.shade300,
                fontSize: 48,
                fontWeight: FontWeight.bold,
                shadows: const [
                  Shadow(
                      blurRadius: 10,
                      color: Colors.black,
                      offset: Offset(0, 0)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              currentLevel.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 30),
            if (!isLastLevel)
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    isLevelComplete = false;
                    levelIndex = (levelIndex + 1).clamp(0, levels.length - 1);
                    currentLevel = levels[levelIndex];
                    _applyLevel(currentLevel);
                    _resetGame();
                    // Ajusta o solo para a orientação atual
                    final view = WidgetsBinding.instance.platformDispatcher
                        .views.first;
                    final double logicalH = view.physicalSize.height /
                        view.devicePixelRatio;
                    _applyResponsiveGround(logicalH);
                    _startGame();
                  });
                },
                icon: const Icon(Icons.arrow_forward),
                label: const Text('Próxima Fase'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 15),
                  backgroundColor: Colors.green,
                ),
              )
            else
              ...[
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      isLevelComplete = false;
                      levelIndex = 0;
                      currentLevel = levels[levelIndex];
                      _applyLevel(currentLevel);
                      _resetGame();
                      _startGame();
                    });
                  },
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Recomeçar do Início'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    backgroundColor: Colors.blueAccent,
                  ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    isLevelComplete = false;
                    _applyLevel(currentLevel);
                    _resetGame();
                    // Ajusta o solo para a orientação atual
                    final view = WidgetsBinding.instance.platformDispatcher
                        .views.first;
                    final double logicalH = view.physicalSize.height /
                        view.devicePixelRatio;
                    _applyResponsiveGround(logicalH);
                    _startGame();
                  });
                },
                icon: const Icon(Icons.replay),
                label: const Text('Repetir Fase Atual'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 30, vertical: 15),
                  side: const BorderSide(color: Colors.white70),
                  foregroundColor: Colors.white,
                ),
              ),
<<<<<<< HEAD
=======
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ForestRunnerScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.nature),
                  label: const Text('Modo Floresta — Atirar Emojis'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white70),
                    foregroundColor: Colors.white,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                ),
>>>>>>> 757566ea8fc248ce85274975105fc358d44853b5
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _playerAnimationController.dispose();
    _cameraShakeController.dispose();
    _sfxPlayer.dispose();
    _coinPlayer.dispose();
    _beePlayer.dispose();
    _laughPlayer.dispose();
    _introController?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Verifica se um asset está registrado no bundle.
  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Inicializa sinalizadores para camadas de parallax com base nos assets disponíveis.
  Future<void> _initParallaxAssets() async {
    final bool skyOk = await _assetExists(_skyAsset);
    final bool hills02Ok = await _assetExists(_hillsV02Asset);
    final bool hills01Ok = await _assetExists(_hillsV01Asset);
    final bool cloudsOk = await _assetExists(_cloudsBGAsset);

    if (!mounted) return;
    setState(() {
      _parallaxReady = skyOk;
      _hasHillsV02 = hills02Ok;
      _hasHillsV01 = hills01Ok;
      _hasCloudsBG = cloudsOk;
    });
  }

  @override
  void didChangeMetrics() {
    // Detecta mudança de orientação/tamanho e ajusta o solo.
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    final Size logicalSize = Size(
      view.physicalSize.width / view.devicePixelRatio,
      view.physicalSize.height / view.devicePixelRatio,
    );
    _applyResponsiveGround(logicalSize.height);
    if (mounted) setState(() {});
  }

  void _applyResponsiveGround(double screenHeight) {
    // Mantém um colchão de 120 px para o chão visível
    final double maxGroundTop = (screenHeight - 120).clamp(100.0, screenHeight);
    final double base = currentLevel.groundY.toDouble();
    final double newGroundY = base > maxGroundTop ? maxGroundTop : base;
    if ((newGroundY - groundY).abs() > 0.5) {
      final double delta = newGroundY - groundY;
      groundY = newGroundY;
      platforms.clear();
      for (double x = 0; x < worldLength; x += BLOCK_SIZE) {
        final double center = x + BLOCK_SIZE / 2;
        final bool inHole = _holes.any((h) => h.contains(center));
        if (!inHole) {
          platforms.add(Rect.fromLTWH(x, groundY, BLOCK_SIZE, BLOCK_SIZE));
        }
      }
      // Ajustar elementos que dependem do solo
      for (int i = 0; i < coins.length; i++) {
        coins[i] = coins[i] + Offset(0, delta);
      }
      for (final b in bees) {
        b.baseY += delta;
      }
      // Ajustar carros da cidade
      for (int i = 0; i < _cars.length; i++) {
        _cars[i].yTop = groundY - _cars[i].height;
      }
      // Ajustar troncos da fase Plantas
      for (int i = 0; i < _logs.length; i++) {
        _logs[i].yTop = groundY - _logs[i].height;
      }
<<<<<<< HEAD
=======
      // Ajustar cactos do deserto (fase veículo)
      for (int i = 0; i < _cacti.length; i++) {
        _cacti[i].yTop = groundY - _cacti[i].height;
      }
>>>>>>> 757566ea8fc248ce85274975105fc358d44853b5
      // Ajustar criaturas dos lagos
      for (int i = 0; i < _lakeCreatures.length; i++) {
        _lakeCreatures[i].baseY += delta;
      }
      // Ajustar jogador mantendo posição relativa
      playerY += delta;
      _lastGroundY = groundY;
    }
  }

  // ====================== INTRO FLOATERS (EMOJIS ANIMADOS DA INTRO) ======================

  void _initIntroFloaters() {
    _introFloaters.clear();
    final emojis = [
      '🌲',
      '🐝',
      '💰',
      '👾',
      '🍀',
      '🫧',
      '🍓',
      '🏞️',
      '🏙️',
      '💎',
      '🦋',
      '🦄'
    ];
    final rnd = Random();
    final int count = 24;
    final double w = _introBounds.width;
    final double h = _introBounds.height;
    for (int i = 0; i < count; i++) {
      final double x = rnd.nextDouble() * (w - 36);
      final double y = rnd.nextDouble() * (h - 36);
      final double vx = (rnd.nextDouble() - 0.5) * 0.7;
      final double vy = (rnd.nextDouble() - 0.5) * 0.7;
      final double scale = 0.80 + rnd.nextDouble() * 0.32;
      final String emoji = emojis[rnd.nextInt(emojis.length)];
      _introFloaters.add(_IntroFloater(
        x: x,
        y: y,
        vx: vx,
        vy: vy,
        scale: scale,
        emoji: emoji,
        opacity: 0.13 + rnd.nextDouble() * 0.08,
      ));
    }
  }

  void _updateIntroFloaters() {
    final double boundsW = _introBounds.width;
    final double boundsH = _introBounds.height;
    final double dt = 1 / 60.0;
    for (final floater in _introFloaters) {
      floater.x += floater.vx * (dt * 50);
      floater.y += floater.vy * (dt * 50);
      // Limites: rebater suave nas bordas
      if (floater.x < 0) {
        floater.x = 0;
        floater.vx = floater.vx.abs() * 0.7;
      }
      if (floater.x > boundsW - 36) {
        floater.x = boundsW - 36;
        floater.vx = -floater.vx.abs() * 0.7;
      }
      if (floater.y < 0) {
        floater.y = 0;
        floater.vy = floater.vy.abs() * 0.7;
      }
      if (floater.y > boundsH - 36) {
        floater.y = boundsH - 36;
        floater.vy = -floater.vy.abs() * 0.7;
      }
      // Onda na opacidade: oscila suavemente
      floater.opacity =
          0.12 + 0.08 * sin((DateTime
              .now()
              .millisecondsSinceEpoch * 0.0005) + floater.x * 0.03 +
              floater.y * 0.02);
    }
    if (mounted) setState(() {});
  }
}

// ====================== CLASSES AUXILIARES ======================

class _Log {
  double x;
  double width;
  double height;
  double yTop;

  _Log({
    required this.x,
    required this.width,
    required this.height,
    required this.yTop,
  });

  Rect get rect => Rect.fromLTWH(x, yTop, width, height);
}

class _BigTree {
  double x;
  double width;
  double height;
  Color trunkColor;
  Color canopyColor;

  _BigTree({
    required this.x,
    required this.width,
    required this.height,
    required this.trunkColor,
    required this.canopyColor,
  });
}

class _HoleSegment {
  final double startX;
  final double endX;

  _HoleSegment({required this.startX, required this.endX});

  bool contains(double x) => x >= startX && x <= endX;

  bool overlaps(_HoleSegment other, {double minGap = 0.0}) {
    // Returns true if two holes overlap or are too close
    return !(endX + minGap < other.startX || startX - minGap > other.endX);
  }
}

class _Cloud {
  double x;
  double y;
  double speed;
  double scale;

  _Cloud({
    required this.x,
    required this.y,
    required this.speed,
    required this.scale,
  });
}

class _Bee {
  double x;
  double baseY;
  double amp;
  double speed;
  double dir;
  double phase;
  String emoji;
  double currentY;

  _Bee({
    required this.x,
    required this.baseY,
    required this.amp,
    required this.speed,
    required this.dir,
    required this.phase,
    required this.emoji,
    this.currentY = 0.0,
  });
}

class _Dust {
  double x;
  double y;
  double vx;
  double vy;
  double life;

  _Dust({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
  });
}

class _Sparkle {
  double x;
  double y;
  double vx;
  double vy;
  double size;
  double life;
  Color color;

  _Sparkle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
    required this.life,
    required this.color,
  });
}

class _LakeCreature {
  double x;
  double baseY;
  double amp;
  double phase;
  String emoji;
  double scale;
  double currentY;

  _LakeCreature({
    required this.x,
    required this.baseY,
    required this.amp,
    required this.phase,
    required this.emoji,
    required this.scale,
    double? currentY,
  }) : currentY = currentY ?? 0.0;
}

// ====================== CLASSE FLOATER DA INTRO ======================
class _IntroFloater {
  double x;
  double y;
  double vx;
  double vy;
  double scale;
  double opacity;
  String emoji;

  _IntroFloater({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.scale,
    required this.emoji,
    required this.opacity,
  });
}

<<<<<<< HEAD
=======
// Obstáculo de cacto para fase de veículo no deserto
class _Cactus {
  double x;
  double width;
  double height;
  double yTop;
  String emoji;

  _Cactus({
    required this.x,
    required this.width,
    required this.height,
    required this.yTop,
    this.emoji = '🌵',
  });

  Rect get rect => Rect.fromLTWH(x, yTop, width, height);
}

>>>>>>> 757566ea8fc248ce85274975105fc358d44853b5
// ====================== CIDADE: CARROS E PRÉDIOS ======================
class _Car {
  double x;
  double yTop;
  double width;
  double height;
  double speed;
  String emoji;

  _Car({
    required this.x,
    required this.yTop,
    this.width = 40,
    this.height = 26,
    required this.speed,
    required this.emoji,
  });

  Rect get rect => Rect.fromLTWH(x, yTop, width, height);
}

class _CityBuilding {
  double x;
  double width;
  double height;
  Color color;

  _CityBuilding({
    required this.x,
    required this.width,
    required this.height,
    required this.color,
  });
}