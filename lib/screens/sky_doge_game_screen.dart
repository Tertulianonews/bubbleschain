import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // Importar corretamente o defaultTargetPlatform
import 'package:flutter/services.dart'; // Importar corretamente os símbolos de teclado do Flutter
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/balance_service.dart';
import 'package:audioplayers/audioplayers.dart';

// Game constants
const double rocketWidth = 56;
const double rocketHeight = 56;
const double obstacleSize = 58;

// == Classes auxiliares fora do State ==
class Obstacle {
  double x, y, vx, vy;
  String emoji;

  Obstacle(
      {required this.x, required this.y, required this.vx, required this.vy, required this.emoji});
}

class Projectile {
  double x, y;
  double vy;

  Projectile({required this.x, required this.y, this.vy = -0.015});
}

class SkyDogeGameScreen extends StatefulWidget {
  const SkyDogeGameScreen({Key? key}) : super(key: key);

  @override
  State<SkyDogeGameScreen> createState() => _SkyDogeGameScreenState();
}

class _SkyDogeGameScreenState extends State<SkyDogeGameScreen> with TickerProviderStateMixin {
  late double rocketX;
  double rocketY = 0.8;
  int score = 0;
  int lives = 5;
  late Timer _gameTimer;
  final Random rng = Random();
  List<Obstacle> obstacles = [];
  bool isPlaying = true;
  bool showHowToPlay = true;

  // -- NOVOS CAMPOS --
  String userId = '';
  final BalanceService _balanceService = BalanceService();
  double bubblesCoinsBalance = 0.0; // Saldo do usuário

  // Lista de emojis natalinos para obstáculos:
  final List<String> obstacleEmojis = ['❄️', '☃️', '🎄', '🧑‍🎄', '🎅', '🧝‍♂️'];

  List<Projectile> projectiles = [];
  // Feedback visual das moedas ganhas
  Offset? lastHitPosition;
  double? lastHitRewardShownAt;
  final double bubblesCoinReward = 0.0000005;

  // FASES SKYDOGE
  int currentStage = 1; // começa na 1
  int hitsOnStage = 0;
  static const int totalStages = 10;
  static const List<int> obstaclesToAdvance = [
    10,
    13,
    15,
    18,
    20,
    23,
    25,
    28,
    33,
    40
  ]; // obstáculos p/ cada fase
  // Configurações de cada fase (velocidade etc)
  final List<Map<String, dynamic>> stageConfigs = [
    // Fase 1: Fácil, devagar, poucos obstáculos
    {'minVy': 0.007, 'maxVy': 0.010, 'maxObs': 4, 'emojis': ['❄️', '☃️']},
    {'minVy': 0.010, 'maxVy': 0.013, 'maxObs': 5, 'emojis': ['❄️', '☃️', '🎄']},
    {'minVy': 0.013, 'maxVy': 0.016, 'maxObs': 6, 'emojis': ['☃️', '🎄', '🎅']},
    {'minVy': 0.017, 'maxVy': 0.020, 'maxObs': 7, 'emojis': ['🎄', '🧑‍🎄', '🎅']},
    {'minVy': 0.020, 'maxVy': 0.023, 'maxObs': 8, 'emojis': ['🧑‍🎄', '🎅']},
    {'minVy': 0.023, 'maxVy': 0.026, 'maxObs': 8, 'emojis': ['🎄', '🎅', '🧝‍♂️']},
    {
      'minVy': 0.027,
      'maxVy': 0.031,
      'maxObs': 8,
      'emojis': ['☃️', '🎄', '🧑‍🎄', '🎅', '🧝‍♂️']
    },
    {
      'minVy': 0.032,
      'maxVy': 0.036,
      'maxObs': 8,
      'emojis': ['❄️', '🎅', '🧝‍♂️']
    },
    {
      'minVy': 0.036,
      'maxVy': 0.042,
      'maxObs': 9,
      'emojis': ['🎄', '🎅', '🧝‍♂️', '❄️']
    },
    // Fase 10: máx dificuldade
    {
      'minVy': 0.045,
      'maxVy': 0.065,
      'maxObs': 10,
      'emojis': ['☃️', '🎄', '🧑‍🎄', '🎅', '🧝‍♂️', '❄️']
    },
  ];

  bool showExplosion = false;
  Offset? explosionPosition;

  final FocusNode _focusNode = FocusNode();
  bool _movingLeft = false;
  bool _movingRight = false;
  late final AudioPlayer _musicPlayer;
  late final AudioPlayer _explosionPlayer;
  late final AudioPlayer _shootPlayer;

  // Variáveis do joystick mobile
  bool _joyActive = false;
  Offset _joyVector = Offset.zero;

  double get speedFactor => 1.0 + pow((currentStage - 1), 1.73) * 0.06;

  @override
  void initState() {
    super.initState();
    rocketX = 0.5;
    _startGame();
    _loadBubblesCoinsBalance(); // Carregar saldo BubblesCoins no início
    showHowToPlay = true;
    // Ajuste para audioplayers igual TerlineT Word:
    _musicPlayer = AudioPlayer();
    _explosionPlayer = AudioPlayer();
    _shootPlayer = AudioPlayer();
    _musicPlayer.setReleaseMode(ReleaseMode.loop);
    _explosionPlayer.setReleaseMode(ReleaseMode.stop);
    _shootPlayer.setReleaseMode(ReleaseMode.stop);
    _explosionPlayer.setSourceAsset('assets/explosao1.mp3');
    _shootPlayer.setSourceAsset('assets/short1.mp3');
    _musicPlayer.setSourceAsset(
        'assets/Brian Rian Rehan Survey God - Good Times.mp3');
    // Só inicia MUSICA na primeira interação (corrige autoplay Web), então pode mover essa linha para após o fechamento do balão de instrução:
    //_musicPlayer.resume();
  }

  Future<void> _loadBubblesCoinsBalance() async {
    if (userId.isEmpty) {
      setState(() => bubblesCoinsBalance = 0.0);
      return;
    }
    final bal = await _balanceService.getBubbleCoinBalance(userId);
    if (mounted) setState(() {
      bubblesCoinsBalance = bal;
    });
  }

  void _startGame() {
    score = 0;
    lives = 5;
    rocketX = 0.5;
    rocketY = 0.8;
    obstacles.clear();
    projectiles.clear();
    isPlaying = true;
    currentStage = 1;
    hitsOnStage = 0;
    // Obter userId via Supabase
    final user = Supabase.instance.client.auth.currentUser;
    userId = user?.id ?? '';
    _gameTimer = Timer.periodic(const Duration(milliseconds: 16), _updateGame);
    _loadBubblesCoinsBalance(); // Atualizar saldo no início do jogo
  }

  void _updateGame(Timer timer) {
    if (!isPlaying) return;
    // Avançar para a próxima fase a cada N acertos de obstáculo
    if (hitsOnStage >= obstaclesToAdvance[currentStage - 1] &&
        currentStage < totalStages) {
      currentStage++;
      hitsOnStage = 0;
      // Breve badge ou efeito pode ser adicionado
      // Pode adicionar um feedback visual aqui!
    }
    // Finalizar após fase 10, parabéns
    if (currentStage > totalStages) {
      isPlaying = false;
      return;
    }
    // Dados da fase
    final config = stageConfigs[currentStage - 1];
    // Obstáculo: gerar
    if (rng.nextInt(36) == 0 && obstacles.length < config['maxObs']) {
      double startX = rng.nextDouble() * 0.8 + 0.1;
      double vy = config['minVy'] +
          rng.nextDouble() * (config['maxVy'] - config['minVy']);
      List<String> emjs = List<String>.from(config['emojis']);
      obstacles.add(
        Obstacle(
          x: startX,
          y: -0.2,
          vx: (rng.nextDouble() - 0.5) * 0.004 * speedFactor * 0.7,
          vy: vy,
          emoji: emjs[rng.nextInt(emjs.length)],
        ),
      );
    }
    // Obstáculo: mover
    for (final ob in obstacles) {
      ob.x += ob.vx * speedFactor;
      ob.y += ob.vy * speedFactor;
    }
    obstacles.removeWhere((ob) => ob.y > 1.1);
    // Projéteis: mover para cima
    for (final p in projectiles) {
      p.y += p.vy * speedFactor;
    }
    projectiles.removeWhere((p) => p.y < -0.1);
    // Detecção de colisão
    for (int pi = projectiles.length - 1; pi >= 0; pi--) {
      final p = projectiles[pi];
      for (int oi = obstacles.length - 1; oi >= 0; oi--) {
        final ob = obstacles[oi];
        if ((ob.x - p.x).abs() < 0.07 && (ob.y - p.y).abs() < 0.08) {
          // Hit!
          obstacles.removeAt(oi);
          projectiles.removeAt(pi);
          _onObstacleDestroyed(ob.x, ob.y);
          break;
        }
      }
    }
    // Colisão obstáculo/foguete
    for (final ob in obstacles) {
      if ((ob.x - rocketX).abs() < 0.09 && (ob.y - rocketY).abs() < 0.09) {
        lives -= 1;
        ob.y = 1.2;
        if (lives > 0) {
          // Explosão! Mostra animação rápida no local do foguete
          showExplosion = true;
          explosionPosition = Offset(rocketX, rocketY);
          _explosionPlayer.play(
              AssetSource('assets/explosao1.mp3'), volume: 0.7);
          Future.delayed(const Duration(milliseconds: 500), () {
            if (!mounted) return;
            setState(() {
              showExplosion = false;
              explosionPosition = null;
            });
          });
        }
        if (lives <= 0) {
          isPlaying = false;
          showExplosion = true;
          explosionPosition = Offset(rocketX, rocketY);
          _explosionPlayer.play(
              AssetSource('assets/explosao1.mp3'), volume: 0.7);
        }
      }
    }
    score += 1;
    // Limpa feedback da tela após ~1.2s
    if (lastHitRewardShownAt != null && (DateTime.now().millisecondsSinceEpoch/1000.0 - (lastHitRewardShownAt ?? 0)) > 1.1) {
      lastHitPosition = null;
      lastHitRewardShownAt = null;
    }
    if (mounted) setState(() {});
  }

  void _fire() {
    if (!isPlaying) return;
    _shootPlayer.play(AssetSource('assets/short1.mp3'), volume: 0.41);
    // Adiciona projétil começando no topo do foguete
    projectiles.add(Projectile(x: rocketX, y: rocketY - 0.07));
    setState(() {});
  }

  // Feedback visual e crédito de moedas
  void _onObstacleDestroyed(double ox, double oy) async {
    lastHitPosition = Offset(ox, oy);
    lastHitRewardShownAt = DateTime
        .now()
        .millisecondsSinceEpoch / 1000.0;
    if (userId.isNotEmpty) {
      await _balanceService.updateBubbleCoinBalance(userId, bubblesCoinReward);
      await _loadBubblesCoinsBalance(); // Sincronizar saldo
    }
    hitsOnStage++;
  }

  @override
  void dispose() {
    _gameTimer.cancel();
    _focusNode.dispose();
    _musicPlayer.stop();
    _musicPlayer.dispose();
    _explosionPlayer.dispose();
    _shootPlayer.dispose();
    super.dispose();
  }

  void _moveRocket(double deltaX) {
    setState(() {
      rocketX = (rocketX + deltaX).clamp(0.06, 0.94);
    });
  }

  void _restart() {
    setState(() {
      _startGame();
    });
  }

  Widget _buildButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: CircleAvatar(
        backgroundColor: Colors.white.withOpacity(0.15),
        child: Icon(icon, color: Colors.white, size: 34),
        radius: 32,
      ),
    );
  }

  Widget _buildShootButton() {
    return GestureDetector(
      onTap: _fire,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 80),
        curve: Curves.easeOut,
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFfd9600), Color(0xFFff2222), Color(0xFFffe15f)],
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
          ),
          boxShadow: [
            BoxShadow(
                color: Colors.amber.withOpacity(0.55),
                blurRadius: 18,
                offset: Offset(0, 4)),
            BoxShadow(
                color: Colors.red.withOpacity(0.2),
                blurRadius: 27,
                offset: Offset(0, 0)),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.72), width: 2.6),
        ),
        child: Center(
          child: Text(
            '💣',
            style: TextStyle(fontSize: 41, shadows: [
              Shadow(blurRadius: 10, color: Colors.black),
              Shadow(blurRadius: 13, color: Colors.orangeAccent),
            ]),
          ),
        ),
      ),
    );
  }

  // Handler de teclado (setas, A/D, espaço)
  void _handleRawKey(RawKeyEvent event) {
    final isDown = event is RawKeyDownEvent;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.keyA) {
      _movingLeft = isDown;
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.keyD) {
      _movingRight = isDown;
    } else if (isDown && key == LogicalKeyboardKey.space) {
      _fire();
    }
    _updateRocketDir();
  }

  void _updateRocketDir() {
    double move = 0;
    // Teclado
    if (_movingLeft && !_movingRight) {
      move = -0.06;
    } else if (_movingRight && !_movingLeft) {
      move = 0.06;
    }
    // Joystick mobile
    if (_joyActive && _joyVector.dx.abs() > 0.12) {
      move = _joyVector.dx * 0.08;
    }
    if (move != 0) _moveRocket(move);
  }

  // Adicionar função para controles móveis:
  Widget _buildMobileControls() {
    const double pad = 20;
    const double joySize = 120;
    const double baseRadius = 46;
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
              if (v.distance > baseRadius) v = v / v.distance * baseRadius;
              setState(() {
                _joyActive = true;
                _joyVector = Offset(v.dx / baseRadius, v.dy / baseRadius);
                _updateRocketDir();
              });
            },
            onPointerMove: (e) {
              final local = e.localPosition;
              final center = Offset(joySize / 2, joySize / 2);
              Offset v = local - center;
              if (v.distance > baseRadius) v = v / v.distance * baseRadius;
              setState(() {
                _joyActive = true;
                _joyVector = Offset(v.dx / baseRadius, v.dy / baseRadius);
                _updateRocketDir();
              });
            },
            onPointerUp: (_) {
              setState(() {
                _joyActive = false;
                _joyVector = Offset.zero;
              });
            },
            onPointerCancel: (_) {
              setState(() {
                _joyActive = false;
                _joyVector = Offset.zero;
              });
            },
            child: SizedBox(
              width: joySize,
              height: joySize,
              child: Stack(
                children: [
                  // base
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.19),
                    ),
                  ),
                  Center(
                    child: Container(
                      width: baseRadius * 2,
                      height: baseRadius * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(
                            0.27), width: 2),
                      ),
                    ),
                  ),
                  // knob
                  Positioned(
                    left: knobOffset.dx - 26,
                    top: knobOffset.dy - 26,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.90),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.32),
                              blurRadius: 8),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Botão de tiro
        Positioned(
          right: pad,
          bottom: pad + 6,
          child: _buildShootButton(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade900.withOpacity(0.97),
      appBar: AppBar(
        title: const Text('SkyDoge 🚀'),
        backgroundColor: Colors.blueGrey[900],
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: Colors.amberAccent.shade200,
                size: 27),
            tooltip: 'Como jogar',
            onPressed: () => setState(() => showHowToPlay = true),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          return RawKeyboardListener(
            focusNode: _focusNode,
            autofocus: true,
            onKey: _handleRawKey,
            child: Stack(
              children: [
                if (showHowToPlay)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.82),
                      child: Center(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 22),
                          padding: EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: Colors.blueGrey[800]?.withOpacity(0.98),
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(
                                color: Colors.amberAccent.shade700.withOpacity(
                                    0.45), width: 2.2),
                            boxShadow: [BoxShadow(blurRadius: 35,
                                color: Colors.black.withOpacity(0.44))
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Como jogar SkyDoge',
                                style: TextStyle(
                                  fontSize: 23,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amberAccent,
                                  letterSpacing: 0.3,
                                  shadows: [
                                    Shadow(blurRadius: 9, color: Colors.black)
                                  ],
                                ),
                              ),
                              SizedBox(height: 16),
                              Text(
                                '• Desvie dos obstáculos e atire neles usando o botão bombinha! \n'
                                    '• Cada fase exige que você destrua uma quantidade específica de obstáculos para avançar. \n'
                                    '• Quanto maior a fase, maior a dificuldade: mais obstáculos, mais rápidos e diferentes! \n'
                                    '• Você ganha BubblesCoins a cada obstáculo destruído. \n'
                                    '• O game termina se todas as suas vidas acabarem. \n'
                                    'Dica: tente zerar todas as 10 fases para pegar o prêmio máximo e competir no ranking! 🚀💎',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.92),
                                  height: 1.38,
                                ),
                                textAlign: TextAlign.left,
                              ),
                              SizedBox(height: 25),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  setState(() => showHowToPlay = false);
                                  await _musicPlayer.resume();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.amberAccent,
                                  foregroundColor: Colors.blueGrey[900],
                                  textStyle: TextStyle(
                                      fontWeight: FontWeight.bold),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 28, vertical: 15),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(17)),
                                ),
                                icon: Icon(
                                    Icons.check_circle, color: Colors.green,
                                    size: 23),
                                label: Text('OK, entendi!'),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF14152B),
                          Color(0xFF23233E),
                          Colors.black
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 7,
                  left: 10,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.37),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.amber.withOpacity(0.23)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Fase $currentStage', style: TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black54)
                            ])),
                        SizedBox(width: 12),
                        // Vidas em forma de coração:
                        Row(
                          children: List.generate(5, (idx) =>
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 1.5),
                                child: Text(
                                  idx < lives ? '❤️' : '🤍',
                                  style: TextStyle(fontSize: 24,
                                      shadows: [
                                        Shadow(blurRadius: 4,
                                            color: Colors.red.shade800)
                                      ]),
                                ),
                              ),
                          ),
                        ),
                        SizedBox(width: 11),
                        Text('Saldo:', style: TextStyle(color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                        SizedBox(width: 7),
                        Text(
                          bubblesCoinsBalance.toStringAsFixed(8),
                          style: TextStyle(color: Colors.amberAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              letterSpacing: 0.5,
                              shadows: [Shadow(
                                  blurRadius: 7, color: Colors.black26)
                              ]),
                        ),
                        SizedBox(width: 4),
                        const Text('🫧', style: TextStyle(fontSize: 15)),
                      ],
                    ),
                  ),
                ),
                ...obstacles.map((ob) {
                  // Renderiza cada obstáculo como um emoji natalino aleatório
                  return Positioned(
                    left: ob.x * width - obstacleSize / 2,
                    top: ob.y * height - obstacleSize / 2,
                    child: Text(
                      ob.emoji,
                      style: TextStyle(
                        fontSize: obstacleSize * 0.9,
                        shadows: [
                          Shadow(blurRadius: 6,
                              color: Colors.black45,
                              offset: Offset(0, 2)),
                          Shadow(blurRadius: 15, color: Colors.white24)
                        ],
                      ),
                    ),
                  );
                }),
                // Projéteis desenhados como bomba:
                ...projectiles.map((p) =>
                    Positioned(
                      left: p.x * width - 13,
                      top: p.y * height - 29,
                      child: Text(
                        '💣',
                        style: TextStyle(fontSize: 27,
                            shadows: [Shadow(blurRadius: 10, color: Colors
                                .cyanAccent), Shadow(
                                blurRadius: 15, color: Colors
                                .black45)
                            ]),
                      ),
                    )),
                // Feedback de ganho de coin
                if (lastHitPosition != null)
                  Positioned(
                    left: (lastHitPosition!.dx) * width - 5,
                    top: (lastHitPosition!.dy) * height - 35,
                    child: AnimatedOpacity(
                        duration: Duration(milliseconds: 350),
                        opacity: 1,
                        child: Row(children: [
                          Icon(Icons.add, color: Colors.amberAccent, size: 22),
                          Text(
                            '+🫧',
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                              shadows: [
                                Shadow(blurRadius: 10, color: Colors.black),
                                Shadow(
                                    blurRadius: 5, color: Colors.yellowAccent)
                              ],
                            ),
                          ),
                        ])),
                  ),
                if (lives > 0 && !showExplosion)
                  Positioned(
                    left: rocketX * width - rocketWidth / 2,
                    top: rocketY * height - rocketHeight / 2,
                    child: Image.asset(
                      'assets/assets/sky_doge.png',
                      // Caminho correto conforme seu projeto
                      width: rocketWidth,
                      height: rocketHeight,
                    ),
                  ),
                // Animação de explosão (emoji animado)
                if (showExplosion && explosionPosition != null)
                  Positioned(
                    left: explosionPosition!.dx * width - 30,
                    top: explosionPosition!.dy * height - 30,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 1.0, end: 1.7),
                      duration: const Duration(milliseconds: 400),
                      builder: (context, scale, child) =>
                          Transform.scale(
                            scale: scale,
                            child: Opacity(
                              opacity: 2 - scale, // fade out
                              child: Text(
                                '💥',
                                style: TextStyle(fontSize: 60, shadows: [
                                  Shadow(blurRadius: 24,
                                      color: Colors.redAccent.shade200),
                                ]),
                              ),
                            ),
                          ),
                    ),
                  ),
                Positioned(
                  bottom: 16, left: 32, right: 32,
                  child: (defaultTargetPlatform == TargetPlatform.android ||
                      defaultTargetPlatform == TargetPlatform.iOS)
                      ? SizedBox
                      .shrink() // Não mostra barra de botões principal no mobile
                      : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildButton(Icons.arrow_left, () => _moveRocket(-0.06)),
                      _buildShootButton(),
                      _buildButton(Icons.arrow_right, () => _moveRocket(0.06)),
                    ],
                  ),
                ),
                if (defaultTargetPlatform == TargetPlatform.android ||
                    defaultTargetPlatform == TargetPlatform.iOS)
                  _buildMobileControls(),
                if (!isPlaying)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.62),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (currentStage > totalStages)
                              Text(
                                'PARABÉNS! Você zerou o SkyDoge. 🏆🚀',
                                style: TextStyle(
                                  fontSize: 32,
                                  color: Colors.yellowAccent,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(blurRadius: 12,
                                        color: Colors.orangeAccent)
                                  ],
                                ),
                                textAlign: TextAlign.center,
                              )
                            else
                              ...[
                                const Text(
                                  'GAME OVER',
                                  style: TextStyle(
                                    fontSize: 38,
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Pontuação: $score',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                  ),
                                ),
                              ],
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _restart,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 30, vertical: 16),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('Jogar Novamente'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
      ),
    );
  }
}
