import 'package:flutter/material.dart';

/// Tela do jogo SNIPER desenhando floresta manualmente, usando somente widgets/emojis.
class SniperGameScreen extends StatefulWidget {
  const SniperGameScreen({Key? key}) : super(key: key);

  @override
  State<SniperGameScreen> createState() => _SniperGameScreenState();
}

class _SniperGameScreenState extends State<SniperGameScreen> {
  /// Posição da mira na tela (de 0.0 a 1.0)
  Offset aiming = const Offset(0.5, 0.5);

  /// Lista dos inimigos zumbis
  final List<_EnemyZombie> zombies = [
    _EnemyZombie(pos: Offset(0.7, 0.62)),
    _EnemyZombie(pos: Offset(0.35, 0.53)),
    _EnemyZombie(pos: Offset(0.2, 0.77)),
    _EnemyZombie(pos: Offset(0.85, 0.81)),
  ];

  bool get isMobile {
    final platform = Theme
        .of(context)
        .platform;
    return platform == TargetPlatform.android || platform == TargetPlatform.iOS;
  }

  void updateAim(Offset newPos) {
    setState(() {
      aiming = newPos;
    });
  }

  void tryShoot() {
    for (final z in zombies) {
      if ((z.pos - aiming).distance < 0.09) {
        setState(() {
          z.dead = true;
        });
        // Adicione efeitos sonoros/visuais aqui
      }
    }
  }

  /// Desenha uma 'árvore cartoon' simples (tronco + copa) manualmente
  Widget buildCartoonTree(
      {double size = 95, required double left, required double top}) {
    return Positioned(
      left: left,
      top: top,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            // Tronco
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: size * 0.18,
                height: size * 0.48,
                decoration: BoxDecoration(
                  color: Colors.brown[800],
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: [
                    BoxShadow(blurRadius: 5,
                        color: Colors.brown.shade900.withOpacity(0.18))
                  ],
                ),
              ),
            ),
            // Copa
            Align(
              alignment: Alignment.topCenter,
              child: Container(
                width: size * 0.72,
                height: size * 0.56,
                decoration: BoxDecoration(
                  color: Colors.green[300],
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(blurRadius: 19,
                        color: Colors.green.shade700.withOpacity(0.14))
                  ],
                ),
              ),
            ),
            // Emoji de folha/floresta para estilizar
            Align(
              alignment: Alignment.center,
              child: Text('🌳', style: TextStyle(fontSize: size * 0.44)),
            )
          ],
        ),
      ),
    );
  }

  /// Desenha vários matinhos/folhas pelo cenário
  List<Widget> buildGrass({required double w, required double h}) {
    final grassPos = [
      [0.04, 0.93, 1.1], [0.19, 0.95, 0.95], [0.36, 0.92, 1.1],
      [0.57, 0.9, 1.16], [0.71, 0.93, 1.11], [0.85, 0.96, 0.98],
      [0.91, 0.90, 1.15],
    ];
    return [
      for (final g in grassPos)
        Positioned(
            left: w * g[0],
            top: h * g[1],
            child: Transform.scale(
              scale: g[2],
              child: Text('🌾', style: const TextStyle(fontSize: 33)),
            )
        )
    ];
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery
        .of(context)
        .size
        .width;
    final h = MediaQuery
        .of(context)
        .size
        .height;
    return Scaffold(
      backgroundColor: const Color(0xff232919),
      body: Stack(
        children: [
          // Caminho de grama densa ao fundo
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xff38491c),
                    Color(0xff233011),
                    Color(0xff1e220c)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // ÁRVORES
          buildCartoonTree(size: 110, left: w * 0.15, top: h * 0.12),
          buildCartoonTree(size: 122, left: w * 0.42, top: h * 0.07),
          buildCartoonTree(size: 105, left: w * 0.68, top: h * 0.18),
          buildCartoonTree(size: 88, left: w * 0.78, top: h * 0.53),
          buildCartoonTree(size: 73, left: w * 0.11, top: h * 0.61),
          // MATOS E FOLHAS
          ...buildGrass(w: w, h: h),
          // Zumbis espalhados
          for (final z in zombies)
            if (!z.dead)
              Positioned(
                left: w * z.pos.dx - 31,
                top: h * z.pos.dy - 31,
                child: Text('🧟', style: TextStyle(fontSize: 62,
                    shadows: [Shadow(color: Colors.green, blurRadius: 11)])),
              ),
          // Mira central
          Positioned(
            left: aiming.dx * w - 21,
            top: aiming.dy * h - 21,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.transparent,
                border: Border.all(color: Colors.redAccent, width: 2.5),
              ),
              child: const Center(
                  child: Icon(Icons.circle, color: Colors.redAccent, size: 13)),
            ),
          ),
          // Mouse PC: mira e atira
          if (!isMobile)
            Positioned.fill(
              child: Listener(
                onPointerHover: (details) {
                  final px = details.localPosition.dx / w;
                  final py = details.localPosition.dy / h;
                  updateAim(Offset(px.clamp(0.0, 1.0), py.clamp(0.0, 1.0)));
                },
                onPointerDown: (details) {
                  tryShoot();
                },
                child: Container(color: Colors.transparent),
              ),
            ),
          if (isMobile)
            Positioned(
              bottom: 38,
              left: w / 2 - 56,
              child: ElevatedButton(
                onPressed: tryShoot,
                style: ElevatedButton.styleFrom(
                  shape: const CircleBorder(),
                  minimumSize: const Size(72, 72),
                  backgroundColor: Colors.redAccent,
                  elevation: 5,
                ),
                child: const Icon(
                    Icons.gps_fixed, color: Colors.white, size: 42),
              ),
            ),
          if (isMobile)
            Positioned.fill(
              child: GestureDetector(
                onPanUpdate: (details) {
                  final px = (aiming.dx + details.delta.dx / w).clamp(0.0, 1.0);
                  final py = (aiming.dy + details.delta.dy / h).clamp(0.0, 1.0);
                  updateAim(Offset(px, py));
                },
                child: Container(color: Colors.transparent),
              ),
            ),
          // TÍTULO E AJUDA
          Positioned(
            top: 21,
            left: 0,
            right: 0,
            child: Column(
              children: [
                const Text('Floresta Densa - Zumbis', style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 19)),
                Text(isMobile
                    ? 'Arraste para mirar e toque para atirar!'
                    : 'Use o mouse para mirar, clique para atirar.',
                    style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EnemyZombie {
  final Offset pos;
  bool dead;
  _EnemyZombie({required this.pos, this.dead = false});
}
