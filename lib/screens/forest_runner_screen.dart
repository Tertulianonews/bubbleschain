import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Floresta densa em perspectiva: o jogador pilota um avião visível na frente,
/// desviando de emojis que vêm do horizonte até chegar ao final do percurso.
class ForestRunnerScreen extends StatefulWidget {
  static const String routeName = '/forest_runner';

  const ForestRunnerScreen({super.key});

  @override
  State<ForestRunnerScreen> createState() => _ForestRunnerScreenState();
}

class _ForestRunnerScreenState extends State<ForestRunnerScreen>
    with TickerProviderStateMixin {
  // Estado básico do jogo
  bool _running = false;
  bool _gameOver = false;
  bool _finished = false;
  int _score = 0;
  int _lives = 3;

  // Loop
  Duration? _lastTick;
  bool _frameScheduled = false;

  // Mundo/escala
  // d = profundidade normalizada (1.0 = longe/horizonte, 0.0 = perto)
  final List<_Obstacle> _obstacles = [];
  final List<_FRTree> _trees = [];
  double _spawnTimer = 0.0;
  double _treeTimer = 0.0;
  final Random _rng = Random();

  // Plano e controle
  double _planeX = 0.0; // [-1, 1]
  double _planeY = 0.65; // [0.45, 0.85] relativo à tela (fração vertical)
  double _targetPlaneX = 0.0;
  double _targetPlaneY = 0.65;
  bool _dragging = false;

  // Progresso
  double _distance = 0.0; // 0..1
  final double _trackSeconds = 45.0; // tempo-alvo para concluir, aprox.
  double _elapsed = 0.0;
  double _baseSpeed = 0.55; // fator de aproximação de obstáculos

  // Tamanho da tela
  late Size _screenSize;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _screenSize = MediaQuery
          .of(context)
          .size;
      _resetWorld();
      _start();
    });
  }

  void _resetWorld() {
    _obstacles.clear();
    _trees.clear();
    _score = 0;
    _lives = 3;
    _gameOver = false;
    _finished = false;
    _spawnTimer = 0.0;
    _treeTimer = 0.0;
    _distance = 0.0;
    _elapsed = 0.0;
    _planeX = 0.0;
    _planeY = 0.65;
    _targetPlaneX = _planeX;
    _targetPlaneY = _planeY;

    // Pré-popula algumas árvores para densidade inicial
    for (int i = 0; i < 40; i++) {
      _trees.add(_FRTree(
        x: _rng.nextDouble() * 2 - 1, // [-1, 1]
        d: _rng.nextDouble(), // [0..1]
        speed: 0.25 + _rng.nextDouble() * 0.35,
        emoji: _rng.nextBool() ? '🌲' : '🌳',
      ));
    }
  }

  void _start() {
    _running = true;
    _lastTick = null;
    _scheduleNextFrame();
  }

  void _stop() {
    _running = false;
  }

  void _scheduleNextFrame() {
    if (_frameScheduled) return;
    _frameScheduled = true;
    SchedulerBinding.instance.scheduleFrameCallback(_onFrame);
  }

  void _onFrame(Duration timestamp) {
    _frameScheduled = false;
    if (!_running) return;

    final double dt = _lastTick == null
        ? 0.016
        : ((timestamp - _lastTick!).inMicroseconds / 1000000.0)
        .clamp(0.0, 0.033);
    _lastTick = timestamp;

    _update(dt);
    if (mounted) setState(() {});
    _scheduleNextFrame();
  }

  void _update(double dt) {
    if (_gameOver || _finished) return;

    _elapsed += dt;
    _distance = (_elapsed / _trackSeconds).clamp(0.0, 1.0);
    if (_distance >= 1.0) {
      _finished = true;
      _stop();
      return;
    }

    // Suaviza movimento do avião para o alvo (arraste do usuário)
    _planeX = lerpDoubleClamped(_planeX, _targetPlaneX, 0.20);
    _planeY = lerpDoubleClamped(_planeY, _targetPlaneY, 0.18);

    // Atualiza árvores (floresta densa)
    for (int i = _trees.length - 1; i >= 0; i--) {
      final t = _trees[i];
      t.d -= t.speed * dt; // aproximam
      if (t.d <= 0) {
        // recicla
        t.d = 1.0;
        t.x = _rng.nextDouble() * 2 - 1;
        t.speed = 0.25 + _rng.nextDouble() * 0.35;
        t.emoji = _rng.nextBool() ? '🌲' : '🌳';
      }
    }

    // Spawn de árvores extra para variar densidade
    _treeTimer += dt;
    if (_treeTimer >= 0.06) {
      _treeTimer = 0.0;
      if (_trees.length < 70) {
        _trees.add(_FRTree(
          x: _rng.nextDouble() * 2 - 1,
          d: 0.8 + _rng.nextDouble() * 0.2,
          speed: 0.25 + _rng.nextDouble() * 0.35,
          emoji: _rng.nextBool() ? '🌲' : '🌳',
        ));
      }
    }

    // Spawn de obstáculos (carinhas amarelas)
    _spawnTimer += dt;
    final double enemyInterval = 0.7 + _rng.nextDouble() * 0.6;
    if (_spawnTimer >= enemyInterval) {
      _spawnTimer = 0.0;
      final int group = 1 + (_rng.nextDouble() < 0.5 ? 1 : 0);
      for (int k = 0; k < group; k++) {
        _obstacles.add(_Obstacle(
          x: (_rng.nextDouble() * 2 - 1) * 0.92,
          d: 1.0,
          speed: _baseSpeed + _rng.nextDouble() * 0.35,
          emoji: _smileys[_rng.nextInt(_smileys.length)],
        ));
      }
    }

    // Atualiza obstáculos e checa colisões
    final Size size = _screenSize;
    final _ScreenPos planePos = _project(_planeX, 0.08, size); // avião "perto"
    final double planeR = 22.0 * planePos.scale; // raio aprox do avião

    for (int i = _obstacles.length - 1; i >= 0; i--) {
      final e = _obstacles[i];
      e.d -= e.speed * dt;
      if (e.d <= 0.01) {
        _obstacles.removeAt(i);
        continue;
      }
      // colisão aproximada quando estiver próximo do avião
      if (e.d <= 0.20) {
        final _ScreenPos p = _project(e.x, e.d, size);
        final double r = 14.0 * p.scale;
        final double dx = (p.x - planePos.x);
        final double dy = (p.y - planePos.y);
        if ((dx * dx + dy * dy) <= (r + planeR) * (r + planeR)) {
          _obstacles.removeAt(i);
          _lives -= 1;
          if (_lives <= 0) {
            _gameOver = true;
            _stop();
            return;
          }
        }
      }
    }

    // Pontos por sobrevivência
    _score = (_distance * 10000).floor();
  }

  // Projeta um ponto (x in [-1,1], d in [0,1]) para tela
  _ScreenPos _project(double x, double d, Size size) {
    final double horizonY = size.height * 0.30; // linha do horizonte
    final double groundY = size.height * 0.88;
    final double y = horizonY + (1.0 - d) * (groundY - horizonY);

    // Largura efetiva aumenta com proximidade para simular perspectiva
    final double baseHalfW = size.width * 0.30;
    final double spread = baseHalfW * (0.4 + (1.0 - d) * 1.6);
    final double xScreen = size.width * 0.5 + x * spread;

    final double scale = 0.45 + (1.0 - d) * 1.25;
    return _ScreenPos(x: xScreen, y: y, scale: scale);
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery
        .of(context)
        .size;

    final _ScreenPos planePos = _project(_planeX, 0.08, size);

    return Scaffold(
      body: GestureDetector(
        onPanStart: (d) {
          _dragging = true;
          _updateTargetFromLocal(d.localPosition, size);
        },
        onPanUpdate: (d) {
          _updateTargetFromLocal(d.localPosition, size);
        },
        onPanEnd: (_) => _dragging = false,
        onPanCancel: () => _dragging = false,
        child: Stack(
          children: [
            // Fundo: céu e chão em gradiente verde escuro
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF274D2D), Color(0xFF0F2A14)],
                  ),
                ),
              ),
            ),

            // Névoa do horizonte
            Positioned(
              top: size.height * 0.26,
              left: 0,
              right: 0,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.10),
                      blurRadius: 18,
                      spreadRadius: 2,
                    )
                  ],
                ),
              ),
            ),

            // Árvores
            ..._trees.map((t) {
              final p = _project(t.x, t.d, size);
              return Positioned(
                left: p.x - 16 * p.scale,
                top: p.y - 18 * p.scale,
                child: Opacity(
                  opacity: (0.35 + (1.0 - t.d) * 0.65).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: p.scale,
                    child: Text(t.emoji, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              );
            }),

            // Obstáculos (carinhas amarelas)
            ..._obstacles.map((e) {
              final p = _project(e.x, e.d, size);
              return Positioned(
                left: p.x - 16 * p.scale,
                top: p.y - 16 * p.scale,
                child: Transform.scale(
                  scale: p.scale * 1.2,
                  child: Text(e.emoji, style: const TextStyle(fontSize: 24)),
                ),
              );
            }),

            // Avião (próximo do jogador)
            Positioned(
              left: planePos.x - 36 * planePos.scale,
              top: size.height * _planeY - 26 * planePos.scale,
              child: Transform.scale(
                scale: planePos.scale,
                child: _PlaneWidget(),
              ),
            ),

            // HUD
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _hudChip(Icons.stacked_line_chart, 'Pontos: $_score'),
                        const SizedBox(height: 6),
                        _hudChip(Icons.favorite, 'Vidas: $_lives'),
                      ],
                    ),
                    // Mensagem + Barra de progresso
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Desvie dos Emojis!',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _progressBar(_distance),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Overlays de fim de jogo
            if (_gameOver) _buildOverlay('Game Over', Colors.redAccent),
            if (_finished) _buildOverlay('Chegada!', Colors.lightGreen),

            // Botão voltar
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

  void _updateTargetFromLocal(Offset p, Size size) {
    // Converte posição em tela para alvo de [-1,1] e fração vertical
    final double nx = ((p.dx / size.width) - 0.5) * 2.0; // [-1,1]
    final double ny = (p.dy / size.height); // [0..1]
    _targetPlaneX = nx.clamp(-1.0, 1.0);
    _targetPlaneY = ny.clamp(0.45, 0.85);
  }

  Widget _hudChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _progressBar(double t) {
    return Container(
      width: 160,
      height: 12,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: t.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.lightGreenAccent, Colors.green],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverlay(String title, Color color) {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: color,
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Pontuação: $_score',
                style: const TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  _resetWorld();
                  _start();
                  setState(() {});
                },
                icon: const Icon(Icons.restart_alt),
                label: const Text('Reiniciar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Voltar'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }
}

// ======= Desenho do avião =======
class _PlaneWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 56,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: const Size(84, 56),
            painter: _PlanePainter(),
          ),
        ],
      ),
    );
  }
}

class _PlanePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    // Sombra (suave)
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

    // Fuselagem principal (elíptica alongada)
    final RRect fuselage = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.10, h * 0.28, w * 0.78, h * 0.30),
      Radius.circular(h * 0.22),
    );
    final Paint fuselagePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFB3E5FC), Color(0xFF1E88E5)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(fuselage, fuselagePaint);

    // Nariz (cone suave)
    final Path nose = Path()
      ..moveTo(w * 0.88, h * 0.32)
      ..quadraticBezierTo(w * 0.96, h * 0.43, w * 0.88, h * 0.56)
      ..lineTo(w * 0.82, h * 0.52)
      ..quadraticBezierTo(w * 0.88, h * 0.43, w * 0.82, h * 0.36)
      ..close();
    canvas.drawPath(nose, Paint()
      ..color = const Color(0xFF90CAF9));

    // Cockpit (vidro) próximo ao nariz
    final RRect cockpit = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.58, h * 0.22, w * 0.22, h * 0.22),
      Radius.circular(h * 0.10),
    );
    final Paint glass = Paint()
      ..shader = const LinearGradient(
        colors: [Colors.white70, Color(0xFFB3E5FC)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    canvas.drawRRect(cockpit, glass);
    canvas.drawRRect(
      cockpit.inflate(1.0),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = Colors.white.withOpacity(0.85),
    );

    // Asas em V (path) — esquerda e direita
    final Paint wingPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    Path wingLeft = Path()
      ..moveTo(w * 0.28, h * 0.42)
      ..lineTo(w * 0.02, h * 0.56)
      ..quadraticBezierTo(w * 0.06, h * 0.50, w * 0.22, h * 0.40)
      ..close();
    Path wingRight = Path()
      ..moveTo(w * 0.42, h * 0.42)
      ..lineTo(w * 0.72, h * 0.56)
      ..quadraticBezierTo(w * 0.68, h * 0.50, w * 0.48, h * 0.40)
      ..close();
    canvas.drawPath(wingLeft, wingPaint);
    canvas.drawPath(wingRight, wingPaint);

    // Estabilizador vertical (cauda)
    final Path tailFin = Path()
      ..moveTo(w * 0.16, h * 0.30)
      ..lineTo(w * 0.14, h * 0.14)..lineTo(w * 0.24, h * 0.26)
      ..close();
    canvas.drawPath(tailFin, Paint()
      ..color = const Color(0xFF1565C0));

    // Detalhe de luz frontal
    final Paint lightPaint = Paint()
      ..shader = const RadialGradient(
        colors: [Colors.yellowAccent, Colors.transparent],
      ).createShader(
          Rect.fromCircle(center: Offset(w * 0.92, h * 0.40), radius: 20))
      ..blendMode = BlendMode.plus
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(w * 0.92, h * 0.40), 16, lightPaint);
  }

  @override
  bool shouldRepaint(covariant _PlanePainter oldDelegate) => false;
}

class _FRTree {
  double x; // [-1, 1]
  double d; // profundidade [0..1]
  double speed;
  String emoji; // 🌲 ou 🌳

  _FRTree({
    required this.x,
    required this.d,
    required this.speed,
    required this.emoji,
  });
}

class _Obstacle {
  double x; // [-1, 1]
  double d; // [0..1]
  double speed;
  String emoji; // carinha amarela

  _Obstacle({
    required this.x,
    required this.d,
    required this.speed,
    required this.emoji,
  });
}

class _ScreenPos {
  final double x;
  final double y;
  final double scale;

  _ScreenPos({required this.x, required this.y, required this.scale});
}

const List<String> _smileys = [
  '😀', '😃', '😄', '😁', '😆', '😅', '🙂', '😊'
];

// Helper de interpolação suave e clamp
double lerpDoubleClamped(double a, double b, double t) {
  return (a + (b - a) * t).clamp(-1.0, 1.0);
}