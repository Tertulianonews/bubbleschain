import 'package:flutter/material.dart';
import 'dart:math';
import '../services/supabase_service.dart';
import 'package:audioplayers/audioplayers.dart';

class BubbleGameScreen extends StatefulWidget {
  const BubbleGameScreen({super.key});

  @override
  State<BubbleGameScreen> createState() => _BubbleGameScreenState();
}

class _BubbleGameScreenState extends State<BubbleGameScreen>
    with TickerProviderStateMixin {
  double balance = 0.0;
  final SupabaseService _supabaseService = SupabaseService();
  String userId = '';
  bool loading = true;
  final Random random = Random();

  List<_GameBubble> bubbles = [];
  int _bubbleId = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioPlayer _emojiPlayer = AudioPlayer();
  final AudioPlayer _solanaPlayer = AudioPlayer();

  double solTriggerThreshold = 0.000005;
  double lastSolTriggerBalance = 0.0;
  bool hasPendingSolana = false;
  List<_SolanaBubble> solBubbles = [];

  // --- COMBO EXTRAS ---
  int comboCount = 0;
  DateTime? lastPopTime;
  Offset? lastComboPosition;
  double comboBonus = 0.0;
  String? comboText;
  double comboTextScale = 1.0;
  double comboTextOpacity = 1.0;

  // --- Emojis ---
  final List<String> emojis = [
    '😀', '😃', '😄', '😁', '😆', '😅', '😂', '😊', '😇', '😉', '😍', '😎', '😋', '😜',
    '😝', '😛', '🥳', '🤩', '🤑', '🤪', '😏', '😈', '👻', '🥸', '🤠', '🥺', '😲', '🥰', '🤗'
  ];
  int normalPopCount = 0;
  bool showEmojiBadge = false;
  double emojiBadgeOpacity = 1.0;

  void _showCombo(int combo, Offset pos) {
    setState(() {
      comboText = 'COMBO x$combo!';
      comboTextScale = 1.9;
      comboTextOpacity = 1.0;
      lastComboPosition = pos;
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() {
        comboTextScale = 1.0;
      });
    });
    Future.delayed(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() {
        comboTextOpacity = 0.0;
      });
    });
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, _loadUserIdAndBalance);
    _spawnInitialBubbles();
  }

  void _loadUserIdAndBalance() async {
    final currentUser = SupabaseService().getCurrentUserId();
    if (currentUser.isNotEmpty) {
      final bal = await _supabaseService.getBubbleCoinBalance(currentUser);
      setState(() {
        userId = currentUser;
        balance = bal;
        loading = false;
      });
    }
  }

  void _spawnInitialBubbles() {
    for (int i = 0; i < 8; i++) {
      _addBubble();
    }
  }

  void _addBubble() {
    setState(() {
      double x = random.nextDouble() * 0.82 + 0.09;
      double size = random.nextDouble() * 38 + 56;
      final colorCombos = [
        [Colors.blueAccent, Colors.purpleAccent, Colors.cyanAccent],
        [Colors.lightBlue, Colors.pinkAccent, Colors.amberAccent],
        [Colors.cyanAccent, Colors.greenAccent, Colors.yellowAccent],
        [Colors.purpleAccent, Colors.blueAccent, Colors.white],
        [Colors.orangeAccent, Colors.lightBlueAccent, Colors.pinkAccent],
      ];
      final gradient = colorCombos[random.nextInt(colorCombos.length)];
      // A cada 5 bolhas, aparece uma EmojiBubble!
      if (normalPopCount > 0 && normalPopCount % 5 == 0) {
        bubbles.add(_GameBubble(
          id: _bubbleId++,
          x: x,
          size: size,
          duration: Duration(milliseconds: 2400 + random.nextInt(1500)),
          gradientColors: gradient,
          emoji: emojis[random.nextInt(emojis.length)],
        ));
      } else {
        bubbles.add(_GameBubble(
          id: _bubbleId++,
          x: x,
          size: size,
          duration: Duration(milliseconds: 2400 + random.nextInt(1500)),
          gradientColors: gradient,
        ));
      }
    });
  }

  void playPopSound() async {
    await _audioPlayer.play(AssetSource('bubble_pop.mp3'), volume: 0.6);
  }

  void _onBubblePop(int id, {TapDownDetails? tapDetails}) async {
    final bubble = bubbles.firstWhere((b) => b.id == id,
        orElse: () => _GameBubble.fallback());
    setState(() {
      bubbles.removeWhere((b) => b.id == id);
    });
    if (bubble.emoji != null) {
      // Emoji Bubble bonus!
      final picked = random.nextBool() ? 'grito.mp3' : 'grito2.mp3';
      await _emojiPlayer.play(AssetSource(picked), volume: 0.85);
      setState(() {
        balance += 0.000000025;
        showEmojiBadge = true;
        emojiBadgeOpacity = 1.0;
      });
      Future.delayed(const Duration(milliseconds: 1560), () {
        if (mounted) setState(() {
          emojiBadgeOpacity = 0.0;
        });
      });
      Future.delayed(const Duration(milliseconds: 1800), () {
        if (mounted) setState(() {
          showEmojiBadge = false;
        });
      });
      if (userId.isNotEmpty) {
        await _supabaseService.addBubbleCoin(userId, 0.000000025);
      }
    } else {
      playPopSound();
      setState(() {
        poppedCount += 1;
        normalPopCount += 1;
      });
      // Combo, badge, shake... (restante do código já presente)
      // ... existing combo logic ...
      DateTime now = DateTime.now();
      if (lastPopTime != null &&
          now.difference(lastPopTime!) < const Duration(milliseconds: 1000)) {
        comboCount += 1;
      } else {
        comboCount = 1;
      }
      lastPopTime = now;
      comboBonus = 0.0;
      if (comboCount >= 2) {
        comboBonus =
            0.00000001 * [0.0, 0.1, 0.2, 0.3][comboCount.clamp(1, 4) - 1];
        _showCombo(comboCount, tapDetails?.globalPosition ?? Offset.zero);
      }
      double added = 0.00000001 + comboBonus;
      setState(() {
        balance += added;
      });
      if (userId.isNotEmpty) {
        await _supabaseService.addBubbleCoin(userId, added);
      }
      // Solana, etc
      if ((balance / solTriggerThreshold).floor() >
          (lastSolTriggerBalance / solTriggerThreshold).floor()) {
        if (!hasPendingSolana) {
          _addSolanaBubble();
          hasPendingSolana = true;
        }
        lastSolTriggerBalance = balance;
      }
    }
    // Repor bolha
    Future.delayed(const Duration(milliseconds: 550), () {
      if (mounted && bubbles.length < 8) {
        _addBubble();
      }
    });
  }

  void _onBubbleOut(int id) {
    setState(() {
      bubbles.removeWhere((b) => b.id == id);
    });
    if (bubbles.length < 8) {
      _addBubble();
    }
  }

  void _addSolanaBubble() {
    setState(() {
      solBubbles.add(_SolanaBubble(
        id: _bubbleId++,
        duration: const Duration(milliseconds: 6500),
      ));
    });
  }

  void _onSolanaPop(int id) async {
    final solBubble = solBubbles.firstWhere((b) => b.id == id, orElse: () =>
        _SolanaBubble(id: id, duration: Duration(milliseconds: 6500)));
    setState(() {
      solBubbles.removeWhere((b) => b.id == id);
      hasPendingSolana = false;
      // Preparar explosão especial (posição centro do Solana)
      solanaExplosionPos = _lastSolanaCenterPos;
      showSolanaExplosion = true;
    });
    await _solanaPlayer.play(AssetSource('assets/plimplim.mp3'), volume: 0.92);
    // --- Mega shake
    for (int i = 0; i < 8; i++) {
      Future.delayed(Duration(milliseconds: i * 44), () {
        if (mounted) setState(() {
          shakeOffsetX = (Random().nextBool() ? 1 : -1) *
              (26.0 + Random().nextDouble() * 14);
          shakeOffsetY = (Random().nextBool() ? 1 : -1) *
              (11.0 + Random().nextDouble() * 8);
        });
      });
    }
    Future.delayed(const Duration(milliseconds: 360), () {
      if (mounted) setState(() {
        shakeOffsetX = 0;
        shakeOffsetY = 0;
      });
    });
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) setState(() {
        showSolanaExplosion = false;
        solanaExplosionPos = null;
      });
    });
    // --- Badge, saldo etc
    setState(() {
      balance += 0.000000100;
      showSolBadge = true;
      solBadgeOpacity = 1.0;
      animateGain = true;
    });
    Future.delayed(const Duration(milliseconds: 1850), () =>
        setState(() {
          solBadgeOpacity = 0.0;
        }));
    Future.delayed(const Duration(milliseconds: 2100), () =>
        setState(() {
          showSolBadge = false;
        }));
    Future.delayed(const Duration(milliseconds: 550), () =>
        setState(() {
          animateGain = false;
        }));
    if (userId.isNotEmpty) {
      await _supabaseService.addBubbleCoin(userId, 0.000000100);
    }
  }

  void _onSolanaOut(int id) {
    setState(() {
      solBubbles.removeWhere((b) => b.id == id);
      hasPendingSolana = false;
    });
  }

  // Contador de bolhas estouradas na sessão
  int poppedCount = 0;

  // Shake effect
  double shakeOffsetX = 0;
  double shakeOffsetY = 0;

  // Badge Solana
  bool showSolBadge = false;
  double solBadgeOpacity = 1.0;

  // Para animar saldo
  bool animateGain = false;

  Offset? solanaExplosionPos;
  bool showSolanaExplosion = false;
  Offset? _lastSolanaCenterPos;

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
    // Progresso até próxima Solana
    double progressToSol = (balance % solTriggerThreshold) /
        solTriggerThreshold;
    // Fundo dinâmico
    Color fondo1 = Color.lerp(Colors.lightBlueAccent, Colors.deepPurpleAccent,
        (balance / 0.05).clamp(0, 1))!;
    Color fondo2 = Color.lerp(
        Colors.blue[100]!, Colors.amber, (balance / 0.19).clamp(0, 1))!;
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(104),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: SafeArea(
            child: Column(
              children: [
                // Botão Regras acima
                Padding(
                  padding: const EdgeInsets.only(top: 4.0, left: 10, right: 10),
                  child: Align(
                    alignment: Alignment.topRight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: const Text('Regras para Saque'),
                              content: Text(
                                  '''
Após conseguir o saldo mínimo para saque (200 BubbleCoin), 
envie um e-mail para bubblescoinmaster@gmail.com e prepare a sua carteira para receber 10 MBC.

Se você não tem a carteira MBC, acesse este site para fazer o download:
https://microbitcoin.org/
'''
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Fechar')),
                              ],
                            );
                          },
                        );
                      },
                      icon: const Icon(Icons.rule, color: Colors.white),
                      label: const Text('Regras', style: TextStyle(color: Colors
                          .white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 7),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900,
                            fontSize: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius
                            .circular(16)),
                        elevation: 2,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Padding(
                          padding: EdgeInsets.only(left: 6),
                          child: Text(
                            '👈',
                            style: TextStyle(
                              fontSize: 34,
                              shadows: [
                                Shadow(blurRadius: 6, color: Colors.black26)
                              ],
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          ClipOval(
                            child: Image.asset(
                              'assets/icon_bolhas.png',
                              width: 33,
                              height: 33,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 9),
                          loading
                              ? const CircularProgressIndicator(strokeWidth: 2)
                              :
                          AnimatedScale(
                            scale: animateGain ? 1.55 : 1.0,
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.elasticOut,
                            child: Text(
                              balance.toStringAsFixed(8),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xff21537f),
                                fontSize: 19,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                )
              ],
            ),
          ),
        ),
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 900),
        decoration: BoxDecoration(
          gradient: LinearGradient(
              colors: [fondo1, fondo2],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight
          ),
        ),
        child: Transform.translate(
          offset: Offset(shakeOffsetX, shakeOffsetY),
          child: SizedBox.expand(
            child: Stack(
              children: [
                // Barra de progresso Solana
                Positioned(
                  left: 18, right: 18, top: 13,
                  child: SizedBox(
                    height: 11,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progressToSol,
                        backgroundColor: Colors.white.withOpacity(0.15),
                        color: Colors.deepPurpleAccent,
                        minHeight: 11,
                      ),
                    ),
                  ),
                ),
                // Badge Solana
                if (showSolBadge) Positioned(
                  top: 52,
                  left: w / 2 - 90,
                  child: AnimatedOpacity(
                    opacity: solBadgeOpacity,
                    duration: const Duration(milliseconds: 330),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 23, vertical: 12),
                      decoration: BoxDecoration(
                          color: Colors.purple.shade600.withOpacity(0.94),
                          borderRadius: BorderRadius.circular(38),
                          border: Border.all(color: Colors.white, width: 2.2),
                          boxShadow: [BoxShadow(blurRadius: 21, color: Colors
                              .purple.shade200.withOpacity(0.35))
                          ]
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.asset('assets/sol_bubble.jpg', width: 32,
                              height: 32,
                              fit: BoxFit.cover),
                          const SizedBox(width: 18),
                          Text('Solana Pop!', style: TextStyle(fontSize: 21,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.8)),
                        ],
                      ),
                    ),
                  ),
                ),
                // Efeito de explosão especial Solana
                if (showSolanaExplosion && solanaExplosionPos != null)
                  Positioned(
                    left: solanaExplosionPos!.dx - 120,
                    top: solanaExplosionPos!.dy - 120,
                    child: IgnorePointer(
                      child: _SolanaExplosionEffect(size: 240),
                    ),
                  ),
                // Contador estouradas
                Positioned(
                  top: 25, right: 26,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 380),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 13, vertical: 6),
                    child: RichText(
                      text: TextSpan(
                          children: [
                            WidgetSpan(
                              child: Icon(Icons.bubble_chart_rounded, size: 22,
                                  color: Colors.white.withOpacity(0.82)),
                            ),
                            TextSpan(
                                text: '  $poppedCount',
                                style: const TextStyle(fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1)
                            )
                          ]
                      ),
                    ),
                  ),
                ),
                // Combo text animation
                if (comboText != null && lastComboPosition != null)
                  Positioned(
                    left: (lastComboPosition!.dx - 70).clamp(26, MediaQuery
                        .of(context)
                        .size
                        .width - 140),
                    top: (lastComboPosition!.dy - 90).clamp(80, MediaQuery
                        .of(context)
                        .size
                        .height - 140),
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 500),
                      opacity: comboTextOpacity,
                      child: AnimatedScale(
                        scale: comboTextScale,
                        duration: const Duration(milliseconds: 240),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.yellow.withOpacity(0.82),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(blurRadius: 18,
                                  color: Colors.orange.withOpacity(0.31))
                            ],
                          ),
                          child: Text(
                            comboText!,
                            style: TextStyle(
                                color: Colors.deepOrange[900],
                                fontWeight: FontWeight.w900,
                                fontSize: 27,
                                letterSpacing: 2.0,
                                shadows: const [
                                  Shadow(blurRadius: 11, color: Colors
                                      .orange)
                                ]
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Solana Bubble atravessando na horizontal
                for(final solana in solBubbles)
                  _SolanaBubbleWidget(
                    key: ValueKey(solana.id),
                    id: solana.id,
                    duration: solana.duration,
                    onPop: () => _onSolanaPop(solana.id),
                    onOut: () => _onSolanaOut(solana.id),
                  ),
                for (final bubble in bubbles)
                  _GameVisualBubble(
                    key: ValueKey(bubble.id),
                    x: bubble.x,
                    size: bubble.size,
                    duration: bubble.duration,
                    onPop: (TapDownDetails? details) =>
                        _onBubblePop(bubble.id, tapDetails: details),
                    onOut: () => _onBubbleOut(bubble.id),
                    gradientColors: bubble.gradientColors,
                    emoji: bubble.emoji,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameBubble {
  final int id;
  final double x;
  final double size;
  final Duration duration;
  final List<Color> gradientColors;
  final String? emoji;

  _GameBubble(
      {required this.id, required this.x, required this.size, required this.duration, required this.gradientColors, this.emoji});

  factory _GameBubble.fallback() =>
      _GameBubble(id: -1,
          x: 0.5,
          size: 80,
          duration: const Duration(milliseconds: 1000),
          gradientColors: [
            Colors.blueAccent,
            Colors.blueAccent,
            Colors.blueAccent
          ]);
}

class _GameVisualBubble extends StatefulWidget {
  final double x;
  final double size;
  final Duration duration;
  final void Function(TapDownDetails?) onPop;
  final VoidCallback onOut;
  final List<Color> gradientColors;
  final String? emoji;

  const _GameVisualBubble(
      {Key? key, required this.x, required this.size, required this.duration, required this.onPop, required this.onOut, required this.gradientColors, this.emoji})
      : super(key: key);

  @override
  State<_GameVisualBubble> createState() => __GameVisualBubbleState();
}

class __GameVisualBubbleState extends State<_GameVisualBubble>
    with TickerProviderStateMixin {
  late AnimationController moveController;
  late Animation<double> posYAnim;
  late AnimationController popController;
  late AnimationController? explosionController;
  bool popped = false;
  bool shouldShowParticles = false;

  @override
  void initState() {
    super.initState();
    moveController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )
      ..forward();
    posYAnim = Tween<double>(begin: 1.11, end: -0.17).animate(
        CurvedAnimation(parent: moveController, curve: Curves.easeIn))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && !popped) {
          widget.onOut();
        }
      });
    popController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    explosionController = null;
  }

  @override
  void dispose() {
    moveController.dispose();
    popController.dispose();
    explosionController?.dispose();
    super.dispose();
  }

  void _pop(TapDownDetails details) {
    setState(() {
      popped = true;
      shouldShowParticles = true;
    });
    explosionController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800))
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {
            shouldShowParticles = false;
          });
          widget.onPop(details); // passa o tapDetails aqui
        }
      })
      ..forward();
    popController.forward();
  }

  Widget buildExplosionParticles() {
    if (!shouldShowParticles || explosionController == null)
      return const SizedBox();
    final n = 14;
    return AnimatedBuilder(
      animation: explosionController!,
      builder: (context, _) {
        final value = explosionController!.value;
        return Stack(
          children: List.generate(n, (i) {
            final angle = i * 2 * 3.1416 / n;
            final radius = widget.size * (0.30 + 0.44 * value);
            final x = radius * cos(angle);
            final y = radius * sin(angle);
            return Positioned(
              left: widget.size / 2 + x - widget.size * 0.06 / 2,
              top: widget.size / 2 + y - widget.size * 0.06 / 2,
              child: Opacity(
                opacity: 1.0 - value * 0.8,
                child: Container(
                  width: widget.size * 0.13 * (1 - value * 0.32),
                  height: widget.size * 0.13 * (1 - value * 0.32),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.gradientColors[i % widget.gradientColors
                        .length].withOpacity(0.92 - value * 0.7),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.27),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
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
    return AnimatedBuilder(
      animation: Listenable.merge([moveController, popController]),
      builder: (context, child) {
        double y = posYAnim.value * h;
        double scale = 1 + popController.value * 0.35;
        double opacity = 1 - popController.value;
        return Positioned(
          left: widget.x * w - widget.size / 2,
          top: y,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: opacity,
                  child: Transform.scale(
                    scale: scale,
                    child: GestureDetector(
                      onTapDown: popped ? null : _pop,
                      child: widget.emoji != null
                          ? Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.22),
                        ),
                        child: Center(
                          child: Text(widget.emoji!,
                              style: TextStyle(fontSize: widget.size * 0.69)),
                        ),
                      )
                          : Container(
                        width: widget.size,
                        height: widget.size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              Colors.white.withOpacity(0.88),
                              widget.gradientColors[0].withOpacity(0.96),
                              widget.gradientColors[1].withOpacity(0.96),
                              widget.gradientColors[2].withOpacity(0.92),
                            ],
                            stops: const [0.05, 0.36, 0.74, 1.0],
                            center: Alignment(-0.28, -0.25),
                            radius: 0.97,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: widget.gradientColors[0].withOpacity(
                                  0.37),
                              blurRadius: widget.size * 0.21,
                              offset: Offset(0, widget.size * 0.12),
                            )
                          ],
                          border: Border.all(color: Colors.white.withOpacity(
                              0.99), width: widget.size * 0.16),
                        ),
                        child: Stack(
                          children: [
                            Align(
                              alignment: const Alignment(-0.25, -0.44),
                              child: Container(
                                width: widget.size * 0.20,
                                height: widget.size * 0.10,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.69),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Align(
                              alignment: const Alignment(0.30, 0.33),
                              child: Container(
                                width: widget.size * 0.13,
                                height: widget.size * 0.06,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.61),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            Align(
                              alignment: const Alignment(0.35, -0.49),
                              child: Container(
                                width: widget.size * 0.10,
                                height: widget.size * 0.10,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.93),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                buildExplosionParticles(),
                if (popped) Positioned(
                  left: 0,
                  top: 0,
                  child: _SparkleBurst(size: widget.size),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// CLASSE DA BOLHA SOLANA ESPECIAL
class _SolanaBubble {
  final int id;
  final Duration duration;

  _SolanaBubble({required this.id, required this.duration});
}

class _SolanaBubbleWidget extends StatefulWidget {
  final int id;
  final Duration duration;
  final VoidCallback onPop;
  final VoidCallback onOut;

  const _SolanaBubbleWidget(
      {Key? key, required this.id, required this.duration, required this.onPop, required this.onOut})
      : super(key: key);

  @override
  State<_SolanaBubbleWidget> createState() => __SolanaBubbleWidgetState();
}

class __SolanaBubbleWidgetState extends State<_SolanaBubbleWidget>
    with TickerProviderStateMixin {
  late AnimationController moveCtrl;
  late Animation<double> posXAnim;
  late AnimationController popCtrl;
  bool popped = false;

  @override
  void initState() {
    super.initState();
    moveCtrl = AnimationController(vsync: this, duration: widget.duration)
      ..forward();
    posXAnim = Tween<double>(begin: -0.22, end: 1.22).animate(
        CurvedAnimation(parent: moveCtrl, curve: Curves.easeInOut));
    moveCtrl.addStatusListener((status) {
      if (status == AnimationStatus.completed && !popped) {
        widget.onOut();
      }
    });
    popCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void dispose() {
    moveCtrl.dispose();
    popCtrl.dispose();
    super.dispose();
  }

  void _doPop() {
    setState(() {
      popped = true;
    });
    popCtrl.forward().then((_) => widget.onPop());
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
    double bubbleSize = h * 0.15;
    double top = h * 0.32;
    return AnimatedBuilder(
      animation: Listenable.merge([moveCtrl, popCtrl]),
      builder: (context, child) {
        double x = posXAnim.value * w;
        double scale = 1.0 + 0.5 * popCtrl.value;
        double opacity = 1.0 - popCtrl.value;
        // CAPTURA o centro da bola da Solana para efeito...
        if (!popped && popCtrl.value < 0.1) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            final screenPos = Offset(x + bubbleSize / 2, top + bubbleSize / 2);
            final parentState = context.findAncestorStateOfType<
                _BubbleGameScreenState>();
            if (parentState != null)
              parentState._lastSolanaCenterPos = screenPos;
          });
        }
        return Positioned(
          top: top,
          left: x,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: GestureDetector(
                onTap: popped ? null : _doPop,
                child: ClipOval(
                  child: Image.asset('assets/sol_bubble.jpg',
                    width: bubbleSize,
                    height: bubbleSize,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SparkleBurst extends StatelessWidget {
  final double size;
  final bool center;

  const _SparkleBurst({Key? key, required this.size, this.center = false})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Random rnd = Random();
    final rays = List.generate(9, (i) {
      final angle = i * 2 * 3.1415 / 9 + rnd.nextDouble() * 0.12;
      final rayLen = size * 0.89;
      final rayColor = i % 3 == 0 ? Colors.yellowAccent : i % 3 == 1 ? Colors
          .white : Colors.orangeAccent;
      return Positioned(
        left: size / 2 + cos(angle) * rayLen * 0.44,
        top: size / 2 + sin(angle) * rayLen * 0.44,
        child: Transform.rotate(
          angle: angle,
          child: Container(
            width: 13,
            height: rayLen * 0.21,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [Colors.white, rayColor]),
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(color: Colors.yellow.withOpacity(0.32), blurRadius: 8)
              ],
            ),
          ),
        ),
      );
    });
    return SizedBox(
      width: size,
      height: size,
      child: Stack(children: rays),
    );
  }
}

class _SolanaExplosionEffect extends StatelessWidget {
  final double size;

  const _SolanaExplosionEffect({super.key, required this.size});

  @override
  Widget build(BuildContext context) {
    final List<Color> colors = [
      Colors.purpleAccent,
      Colors.yellowAccent,
      Colors.greenAccent,
      Colors.blueAccent,
      Colors.orangeAccent,
      Colors.lightBlueAccent,
      Colors.deepPurpleAccent,
      Colors.amber,
      Colors.white,
      Colors.pinkAccent,
    ];
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 970),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, anim, _) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              for (int i = 0; i < 27; i++) ...[
                Positioned(
                  left: size / 2 +
                      cos(i * 2 * 3.1415 / 27) * size * 0.21 * anim -
                      size * 0.10,
                  top: size / 2 +
                      sin(i * 2 * 3.1415 / 27) * size * 0.21 * anim -
                      size * 0.10,
                  child: Opacity(
                    opacity: 1.0 - anim,
                    child: Container(
                      width: size * 0.18 * (0.92 - anim * 0.6),
                      height: size * 0.18 * (0.92 - anim * 0.6),
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors[i % colors.length].withOpacity(0.65 -
                              0.45 * anim),
                          boxShadow: [
                            BoxShadow(color: Colors.white.withOpacity(
                                0.15 + 0.29 * (1 - anim)), blurRadius: 14)
                          ]
                      ),
                    ),
                  ),
                ),
              ]
            ],
          ),
        );
      },
    );
  }
}
