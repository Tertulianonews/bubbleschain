import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:flame/components.dart';
import 'package:flame/input.dart';
import 'package:flame/events.dart';
import 'package:flutter/services.dart';
import 'dart:math';

class SniperFpsGameScreen extends StatelessWidget {
  const SniperFpsGameScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sniperFpsGame = SniperFpsGame();
    return Scaffold(
      body: MouseRegion(
        onHover: (event) {
          final box = context.findRenderObject() as RenderBox?;
          if (box != null) {
            final local = box.globalToLocal(event.position);
            SniperFpsGame.setMiraGlobal(local);
          }
        },
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onPanUpdate: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box != null) {
              final local = box.globalToLocal(details.globalPosition);
              SniperFpsGame.setMiraGlobal(local);
            }
          },
          onTapDown: (details) {
            final box = context.findRenderObject() as RenderBox?;
            if (box != null) {
              final local = box.globalToLocal(details.globalPosition);
              SniperFpsGame.setMiraGlobal(local);
            }
          },
          child: GameWidget(game: sniperFpsGame),
        ),
      ),
    );
  }
}

class SniperFpsGame extends FlameGame
    with KeyboardEvents, TapCallbacks {
  static SniperFpsGame? instance;
  late PlayerComponent player;
  late CameraComponent cameraComponent;
  late World world;
  late CrosshairComponent crosshair;
  final List<TreeComponent> trees = [];
  final List<ZombieEnemy> zombies = [];
  int score = 0;
  final Random rand = Random();

  @override
  Color backgroundColor() => const Color(0xff232919);

  @override
  Future<void> onLoad() async {
    instance = this;
    world = World();
    add(world);
    cameraComponent = CameraComponent.withFixedResolution(
      world: world,
      width: 900, height: 600,
    );
    add(cameraComponent);

    // Floresta
    for (final pos in [
      Vector2(100, 220),
      Vector2(500, 180),
      Vector2(350, 400),
      Vector2(800, 360),
      Vector2(670, 520),
      Vector2(550, 600),
      Vector2(250, 530),
      Vector2(740, 180),
      Vector2(850, 420),
    ]) {
      final tree = TreeComponent(pos: pos);
      trees.add(tree);
      world.add(tree);
    }
    // Player
    player = PlayerComponent();
    world.add(player);
    cameraComponent.follow(player); // <-- Segue o player, só agora!

    // Mira
    crosshair = CrosshairComponent(player: player);
    world.add(crosshair);

    // Inimigos iniciais
    for (int i = 0; i < 2; i++) {
      spawnZombie(hideBehindTree: true);
    }
    // HUD
    add(HudTextComponent(game: this));
  }

  void spawnZombie({bool hideBehindTree = false}) {
    Vector2 spawnPos;
    if (hideBehindTree && trees.isNotEmpty) {
      final tree = trees[rand.nextInt(trees.length)];
      final angle = rand.nextDouble() * pi * 2;
      spawnPos = tree.position +
          Vector2(cos(angle), sin(angle)) * (tree.size.x * 0.52 + 20);
    } else {
      spawnPos = Vector2(
        rand.nextDouble() * (900 - 120) + 60,
        rand.nextDouble() * (600 - 120) + 60,
      );
    }
    final zumbi = ZombieEnemy(pos: spawnPos, game: this);
    zombies.add(zumbi);
    world.add(zumbi);
  }

  void shoot(Vector2 positionTarget) {
    for (final zombie in zombies) {
      if (!zombie.dead && (zombie.position - positionTarget).length < 38) {
        zombie.hit();
        score += 1;
        break;
      }
    }
  }

  // Métodos para integração Flutter GestureDetector:
  void moveCrosshair(Offset pos) {
    crosshair.aimAt(Vector2(pos.dx, pos.dy));
  }

  void shootAt(Offset pos) {
    crosshair.aimAt(Vector2(pos.dx, pos.dy));
    shoot(Vector2(pos.dx, pos.dy));
  }

  @override
  void onTapDown(TapDownEvent event) {
    final worldPos = cameraComponent.viewfinder.position + event.localPosition;
    crosshair.aimAt(worldPos);
    shoot(worldPos);
  }

  // Interface para Flutter UI integrada
  static void setMiraGlobal(Offset pos) {
    final g = SniperFpsGame.instance;
    if (g == null || g.crosshair == null) return;
    g.crosshair.aimAt(Vector2(pos.dx, pos.dy));
  }
}

class PlayerComponent extends PositionComponent
    with KeyboardHandler, HasGameRef<SniperFpsGame> {
  static const double speed = 180;
  final Vector2 sizeVec = Vector2(42, 42);
  final Paint bodyPaint = Paint()
    ..color = Colors.blueAccent;

  PlayerComponent() {
    size.setFrom(sizeVec);
    position = Vector2(210, 310);
    anchor = Anchor.center;
  }
  Vector2 velocity = Vector2.zero();

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    position.x = position.x.clamp(24, 900 - 24);
    position.y = position.y.clamp(24, 600 - 24);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x / 2, bodyPaint);
    final armLen = size.x * 0.48;
    var center = Offset(size.x / 2, size.y / 2);
    canvas.drawRect(Rect.fromCenter(
        center: center.translate(armLen, 0), width: armLen * 0.25, height: 8),
        Paint()
          ..color = Colors.deepPurpleAccent);
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    velocity = Vector2.zero();
    if (keysPressed.contains(LogicalKeyboardKey.keyW) ||
        keysPressed.contains(LogicalKeyboardKey.arrowUp)) velocity.y -= speed;
    if (keysPressed.contains(LogicalKeyboardKey.keyS) ||
        keysPressed.contains(LogicalKeyboardKey.arrowDown)) velocity.y += speed;
    if (keysPressed.contains(LogicalKeyboardKey.keyA) ||
        keysPressed.contains(LogicalKeyboardKey.arrowLeft)) velocity.x -= speed;
    if (keysPressed.contains(LogicalKeyboardKey.keyD) ||
        keysPressed.contains(LogicalKeyboardKey.arrowRight))
      velocity.x += speed;
    return true;
  }
}

class CrosshairComponent extends PositionComponent {
  final PlayerComponent player;
  Vector2 aimPos;

  CrosshairComponent({required this.player})
      : aimPos = player.position.clone() {
    size = Vector2(44, 44);
    anchor = Anchor.center;
  }

  void aimAt(Vector2 pos) {
    aimPos = pos.clone();
  }

  @override
  void render(Canvas canvas) {
    final Offset center = Offset(size.x / 2, size.y / 2);
    canvas.drawCircle(center, size.x * 0.37, Paint()
      ..color = Colors.redAccent.withOpacity(0.7)
      ..strokeWidth = 2.1
      ..style = PaintingStyle.stroke);
    canvas.drawLine(center + Offset(-9, 0), center + Offset(9, 0), Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 2);
    canvas.drawLine(center + Offset(0, -9), center + Offset(0, 9), Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 2);
  }

  @override
  void update(double dt) {
    position = aimPos;
  }
}

class TreeComponent extends PositionComponent {
  final Vector2 pos;
  TreeComponent({required this.pos}) {
    size = Vector2(56, 62);
    position = pos;
    anchor = Anchor.center;
  }

  @override
  void render(Canvas canvas) {
    final trunkPaint = Paint()
      ..color = Colors.brown[700]!;
    canvas.drawRect(Rect.fromCenter(center: Offset(size.x / 2, size.y - 16),
        width: size.x * 0.17,
        height: size.y * 0.67), trunkPaint);
    final foliagePaint = Paint()
      ..color = Colors.green[400]!;
    canvas.drawCircle(
        Offset(size.x / 2, size.y * 0.37), size.x * 0.44, foliagePaint);
    final textPainter = TextPainter(
        text: TextSpan(text: '🌳', style: TextStyle(fontSize: 29)),
        textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.x / 2 - 14, size.y * 0.37 - 16));
  }
}

class ZombieEnemy extends PositionComponent with HasGameRef<SniperFpsGame> {
  bool dead = false;
  double appearTime = 0.0;
  final double maxAppearTime = 1.5;
  @override
  int priority = 20;

  ZombieEnemy({required Vector2 pos, required SniperFpsGame game}) {
    position = pos;
    size = Vector2(41, 41);
    anchor = Anchor.center;
  }

  void hit() {
    dead = true;
    Future.delayed(const Duration(milliseconds: 330), () {
      removeFromParent();
    });
    Future.delayed(const Duration(milliseconds: 900), () {
      gameRef.spawnZombie(hideBehindTree: true);
    });
  }

  @override
  void update(double dt) {
    super.update(dt);
    appearTime += dt;
    if (dead) return;
    if (appearTime < maxAppearTime) {
      // Pode animar entrada
    }
  }

  @override
  void render(Canvas canvas) {
    double op = (appearTime / maxAppearTime).clamp(0.0, 1.0);
    if (dead) op = 0.26;
    final painter = TextPainter(
        text: const TextSpan(text: '🧟', style: TextStyle(fontSize: 44)),
        textDirection: TextDirection.ltr);
    painter.layout();
    painter.paint(canvas, Offset(size.x / 2 - 20, size.y / 2 - 23));
    canvas.drawCircle(
        Offset(size.x / 2, size.y / 2 + 16), size.x * 0.47, Paint()
      ..color = Colors.green.withOpacity(op * 0.22));
  }
}

class HudTextComponent extends PositionComponent
    with HasGameRef<SniperFpsGame> {
  final SniperFpsGame game;

  HudTextComponent({required this.game});

  @override
  void render(Canvas canvas) {
    final textPainter = TextPainter(
        text: TextSpan(text: 'Score: ${game.score}',
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22)),
        textDirection: TextDirection.ltr);
    textPainter.layout();
    textPainter.paint(canvas, Offset(25, 10));
    final text2 = TextPainter(
        text: const TextSpan(
            text: 'Use W,A,S,D ou setas para andar. Clique/toque para mirar e atirar!',
            style: TextStyle(color: Colors.white70, fontSize: 14)),
        textDirection: TextDirection.ltr);
    text2.layout(maxWidth: 520);
    text2.paint(canvas, Offset(25, 43));
  }
}
