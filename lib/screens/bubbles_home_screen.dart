import 'dart:math';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'profile_setup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'bubble_game_screen.dart';
import 'package:http/http.dart' as http;
import 'terlinet_word_screen.dart'; // Importação adicionada

class UserBubble {
  final String id;
  final String name;
  final String avatarUrl;
  double x;
  double y;
  double dx;
  double dy;
  double size;
  Color color;
  bool hasNotification;
  final bool isSocial;

  UserBubble({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.size,
    required this.color,
    this.hasNotification = false,
    this.isSocial = false,
  });
}

class GameBubbleWidget extends StatefulWidget {
  final double size;
  final VoidCallback onTap;

  const GameBubbleWidget({Key? key, required this.size, required this.onTap})
      : super(key: key);

  @override
  State<GameBubbleWidget> createState() => _GameBubbleWidgetState();
}

class _GameBubbleWidgetState extends State<GameBubbleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<List<Color>> combos = [
      [Colors.blueAccent, Colors.purpleAccent, Colors.cyanAccent],
      [Colors.lightBlue, Colors.pinkAccent, Colors.amberAccent],
      [Colors.cyanAccent, Colors.greenAccent, Colors.yellowAccent],
      [Colors.purpleAccent, Colors.blueAccent, Colors.white],
      [Colors.orangeAccent, Colors.lightBlueAccent, Colors.pinkAccent],
    ];
    final List<Color> gradientColors = combos[0];

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.88),
                  gradientColors[0].withOpacity(0.96),
                  gradientColors[1].withOpacity(0.96),
                  gradientColors[2].withOpacity(0.92),
                ],
                stops: const [0.05, 0.36, 0.74, 1.0],
                center: Alignment(-0.28, -0.25),
                radius: 0.97,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradientColors[0].withOpacity(0.22),
                  blurRadius: widget.size * 0.19,
                  offset: Offset(0, widget.size * 0.09),
                )
              ],
              border: Border.all(
                  color: Colors.white.withOpacity(0.94),
                  width: widget.size * 0.15
              ),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: const Alignment(-0.27, -0.47),
                  child: Container(
                    width: widget.size * 0.18,
                    height: widget.size * 0.09,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.79),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                Align(
                  alignment: const Alignment(0.31, 0.35),
                  child: Container(
                    width: widget.size * 0.11,
                    height: widget.size * 0.05,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.65),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double angle = _controller.value * 2 * 3.1415926;
              final double radius = widget.size * 0.78 / 2;
              final double dx = radius * cos(angle);
              final double dy = radius * sin(angle);
              return Positioned(
                left: widget.size / 2 + dx,
                top: widget.size / 2 + dy,
                child: Transform.rotate(
                  angle: angle,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.shade400,
                      borderRadius: BorderRadius.circular(21),
                      boxShadow: [BoxShadow(
                          color: Colors.green.shade700,
                          blurRadius: 6
                      )],
                      border: Border.all(color: Colors.white, width: 1.7),
                    ),
                    child: const Text('GAME',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 17,
                          color: Colors.white,
                          letterSpacing: 2.1,
                          shadows: [
                            Shadow(blurRadius: 8, color: Colors.green)
                          ]),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class BubblesHomeScreen extends StatefulWidget {
  const BubblesHomeScreen({super.key});

  @override
  State<BubblesHomeScreen> createState() => _BubblesHomeScreenState();
}

class _BubblesHomeScreenState extends State<BubblesHomeScreen>
    with SingleTickerProviderStateMixin {
  static const double minDist = 12.0;
  late AnimationController controller;
  final Random random = Random();
  late List<UserBubble> bubbles;

  String currentUserId = '';
  String currentUserName = '';
  String currentUserAvatar = '';
  bool profileLoaded = false;
  final double selfBubbleSize = 105;

  final TextEditingController _searchController = TextEditingController();
  String searchText = '';
  bool isSearching = false;
  final TransformationController _centerController = TransformationController();

  Future<Set<String>> _buscarNotificantes() async {
    try {
      final res = await Supabase.instance.client
          .from('messages')
          .select('sender_id')
          .eq('receiver_id', currentUserId)
          .eq('was_read', false);
      return res.map<String>((m) => m['sender_id'] as String).toSet();
    } catch (e) {
      print("[DEBUG] Erro em _buscarNotificantes: $e");
      return {};
    }
  }

  Future<void> _carregarMeuPerfil() async {
    print("[DEBUG] _carregarMeuPerfil chamado. currentUserId: $currentUserId");
    if (currentUserId.isEmpty) {
      print("[DEBUG] currentUserId está vazio. Setando profileLoaded = true.");
      if (mounted) {
        setState(() {
          profileLoaded = true;
        });
      }
      return;
    }
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('nickname, avatar_url')
          .eq('id', currentUserId)
          .maybeSingle();
      if (mounted) {
        setState(() {
          currentUserName = response?['nickname'] ?? 'Meu Perfil';
          currentUserAvatar = response?['avatar_url'] ?? '';
          profileLoaded = true;
          print("[DEBUG] Perfil carregado: Nome: $currentUserName, Avatar: $currentUserAvatar");
        });
      }
    } catch (e) {
      print("[DEBUG] Erro em _carregarMeuPerfil: $e");
      if (mounted) {
        setState(() {
          profileLoaded = true;
        });
      }
    }
  }

  void _moveBubblesPhysics() {
    if (!mounted || !ModalRoute.of(context)!.isCurrent) return;
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final topBarHeightAdjusted = kTopBarHeight + (isSearching ? kSearchBarHeight : 0.0);
    final availableH = h - topBarHeightAdjusted;

    for (int i = 0; i < bubbles.length; ++i) {
      var b = bubbles[i];
      final offset = Offset(
        sin((DateTime.now().millisecondsSinceEpoch / 7200.0) + i * 0.86) * 0.00033,
        cos((DateTime.now().millisecondsSinceEpoch / 9700.0) - i * 0.73) * 0.00031,
      );
      b.x += b.dx + offset.dx;
      b.y += b.dy + offset.dy;

      double drawSize = b.size * 0.65;
      if (b.id == 'game_bubble' || b.id == 'terlinet_word')
        drawSize = b.size * 1.18;
      else if (isSearching && bubblesFiltered.isNotEmpty && bubblesFiltered.first.id == b.id) {
        drawSize = b.size * 1.55;
      }

      if (b.x * w < drawSize / 2 + 4 && b.dx < 0) b.dx = -b.dx * 0.9;
      if (b.x * w > w - drawSize / 2 - 4 && b.dx > 0) b.dx = -b.dx * 0.9;
      if (b.y * availableH < drawSize / 2 + 7 && b.dy < 0) b.dy = -b.dy * 0.9;
      if (b.y * availableH > availableH - drawSize / 2 - 7 && b.dy > 0) b.dy = -b.dy * 0.9;

      for (int j = i + 1; j < bubbles.length; ++j) {
        var o = bubbles[j];
        final dxBubbles = (b.x - o.x) * w;
        final dyBubbles = (b.y - o.y) * availableH;
        final dist = sqrt(dxBubbles * dxBubbles + dyBubbles * dyBubbles);

        double bDrawSize = b.size * 0.65;
        if (b.id == 'game_bubble' || b.id == 'terlinet_word')
          bDrawSize = b.size * 1.18;
        else if (isSearching && bubblesFiltered.isNotEmpty && bubblesFiltered.first.id == b.id) bDrawSize = b.size * 1.55;

        double oDrawSize = o.size * 0.65;
        if (o.id == 'game_bubble' || o.id == 'terlinet_word')
          oDrawSize = o.size * 1.18;
        else if (isSearching && bubblesFiltered.isNotEmpty && bubblesFiltered.first.id == o.id) oDrawSize = o.size * 1.55;

        final minDistBubbles = (bDrawSize + oDrawSize) / 2 + 2;

        if (dist < minDistBubbles && dist > 1) {
          final overlap = 0.3 * (minDistBubbles - dist) / dist;
          final oxAdjust = dxBubbles * overlap;
          final oyAdjust = dyBubbles * overlap;

          b.x += oxAdjust / w;
          b.y += oyAdjust / availableH;
          o.x -= oxAdjust / w;
          o.y -= oyAdjust / availableH;

          final v1 = Offset(b.dx, b.dy), v2 = Offset(o.dx, o.dy);
          b.dx += (v1.dx - v2.dx) * 0.01;
          b.dy += (v1.dy - v2.dy) * 0.01;
          o.dx += (v2.dx - v1.dx) * 0.01;
          o.dy += (v2.dy - v1.dy) * 0.01;
        }
      }
      double maxVel = 0.0008;
      b.dx = b.dx.clamp(-maxVel, maxVel);
      b.dy = b.dy.clamp(-maxVel, maxVel);
      b.dx *= 0.998;
      b.dy *= 0.998;

      b.x = b.x.clamp(0.001 + (drawSize/2)/w, 0.999 - (drawSize/2)/w);
      b.y = b.y.clamp(0.001 + (drawSize/2)/availableH, 0.999 - (drawSize/2)/availableH);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _loadAllUsersBubbles() async {
    print("[DEBUG] _loadAllUsersBubbles chamado.");
    try {
      final resposta = await Supabase.instance.client
          .from('users')
          .select('id, nickname, avatar_url');
      final outros = resposta.where((u) => u['id'] != currentUserId).toList();
      final Random rand = Random();
      final notificantes = await _buscarNotificantes();
      List<UserBubble> novas = [];

      final socialResp = await Supabase.instance.client
          .from('socialBubbles')
          .select('*');
      double startX = 0.18;
      double startY = 0.20;
      const double stepX = 0.14;
      int added = 0;
      for (final app in socialResp) {
        Color bubbleColor = Colors.blueGrey;
        try {
          if (app['color'] != null && app['color'].toString().isNotEmpty) {
            bubbleColor = Color(int.parse(app['color'].toString().replaceFirst('#', '0xff')));
          }
        } catch (_) {}
        novas.add(UserBubble(
          id: app['id'] as String,
          name: (app['id'] as String).capitalize(),
          avatarUrl: app['avatar_url'] ?? '',
          x: startX + stepX * added,
          y: startY,
          dx: 0,
          dy: 0,
          size: 44 + rand.nextDouble() * 11,
          color: bubbleColor,
        ));
        _loadAvatarImage(novas.last);
        added++;
      }

      for (int i = 0; i < outros.length; i++) {
        final u = outros[i];
        final baseHue = 205 + ((i * 21) % 140);
        final color = HSVColor.fromAHSV(1, baseHue.toDouble(), 0.65, 0.94).toColor();
        novas.add(UserBubble(
          id: u['id'],
          name: u['nickname'] ?? '-',
          avatarUrl: u['avatar_url'] ?? '',
          x: (1 / 3) + rand.nextDouble() * (1 / 3),
          y: (1 / 3) + rand.nextDouble() * (1 / 3),
          dx: (rand.nextDouble() - 0.5) * 0.00035,
          dy: (rand.nextDouble() - 0.5) * 0.00040,
          size: 44 + rand.nextDouble() * 11,
          color: color,
          hasNotification: notificantes.contains(u['id']),
        ));
        _loadAvatarImage(novas.last);
      }
      if (mounted) {
        setState(() {
          bubbles = novas;
          // Adiciona a bolha do jogo
          bubbles.add(
            UserBubble(
              id: 'game_bubble',
              name: 'GAME',
              avatarUrl: '',
              x: 0.81,
              y: 0.25,
              dx: 0,
              dy: 0,
              size: 60,
              color: Colors.greenAccent,
            ),
          );
          // Adiciona a bolha do TerlineT Word (ATUALIZAÇÃO)
          bubbles.add(
            UserBubble(
              id: 'terlinet_word',
              name: 'TerlineT Word',
              avatarUrl: '',
              x: 0.81,
              y: 0.45,
              dx: 0,
              dy: 0,
              size: 60,
              color: Colors.blueAccent,
              isSocial: true,
            ),
          );
          print("[DEBUG] Bolhas carregadas. Total: ${bubbles.length}");
        });
      }
    } catch (e) {
      print("[DEBUG] Erro em _loadAllUsersBubbles: $e");
      if (mounted) {
        setState(() {
          bubbles = [];
        });
      }
    }
  }

  final Map<String, ui.Image?> _bubbleImages = {};

  Future<void> _loadAvatarImage(UserBubble bubble) async {
    if (bubble.avatarUrl.isEmpty) return;
    if (_bubbleImages.containsKey(bubble.id)) return;
    try {
      final response = await http.get(Uri.parse(bubble.avatarUrl));
      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;
        final codec = await ui.instantiateImageCodec(bytes);
        final frame = await codec.getNextFrame();
        if (mounted) {
          setState(() {
            _bubbleImages[bubble.id] = frame.image;
          });
        }
      } else {
        print("[DEBUG] Falha ao carregar avatar de ${bubble.name}: Status ${response.statusCode}");
        _bubbleImages[bubble.id] = null;
      }
    } catch (e) {
      print("[DEBUG] Erro ao carregar avatar de ${bubble.name}: $e");
      _bubbleImages[bubble.id] = null;
    }
  }

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    currentUserId = user?.id ?? '';
    print("[DEBUG initState] currentUserId definido como: '$currentUserId'");
    _carregarMeuPerfil();
    bubbles = [];
    controller = AnimationController(vsync: this, duration: const Duration(days: 9999))
      ..addListener(_moveBubblesPhysics)
      ..repeat(period: const Duration(milliseconds: 30));
    _loadAllUsersBubbles();
  }

  @override
  void dispose() {
    controller.dispose();
    _searchController.dispose();
    _centerController.dispose();
    super.dispose();
  }

  void _onBubbleTap(UserBubble user) async {
    print("[DEBUG] _onBubbleTap chamado para: ${user.name} (ID: ${user.id})");
    try {
      final social = await Supabase.instance.client
          .from('socialBubbles')
          .select('link_url')
          .eq('id', user.id)
          .maybeSingle();
      if (social != null && social['link_url'] != null && social['link_url'].toString().isNotEmpty) {
        print("[DEBUG] Bolha social detectada. Abrindo URL: ${social['link_url']}");
        await launchUrl(Uri.parse(social['link_url']));
        return;
      }
    } catch (e) {
      print("[DEBUG] Erro ao verificar bolha social: $e");
    }

    // ATUALIZAÇÃO: Verificação para TerlineT Word
    if (user.id == 'terlinet_word') {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TerlineTWordScreen()),
      );
      return;
    }

    print("[DEBUG] Navegando para ChatScreen com ${user.name}");
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatScreen(
          otherUserId: user.id,
          otherUserName: user.name,
          otherUserAvatar: user.avatarUrl,
        ),
      ),
    );
    _loadAllUsersBubbles();
  }

  void _onMyProfileTap() {
    print("[DEBUG _onMyProfileTap] CLICOU NA BOLHA DO PERFIL!");
    print("[DEBUG _onMyProfileTap] currentUserId antes de navegar: '$currentUserId'");
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => ProfileSetupScreen(userIdOverride: currentUserId)));
  }

  List<UserBubble> get bubblesFiltered {
    if (searchText.trim().isEmpty) return bubbles;
    final query = searchText.trim().toLowerCase();
    return bubbles.where((b) =>
    b.name.toLowerCase().contains(query) || (b.name.isNotEmpty && b.name[0].toLowerCase() == query)
    ).toList();
  }

  Map<String, Offset>? _bolhasOriginaisPosicoes;

  void _centralizarBolhaPesquisadaV2() {
    if (!mounted) return;

    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final topBarHeightAdjusted = kTopBarHeight + (isSearching ? kSearchBarHeight : 0.0);
    final availableH = h - topBarHeightAdjusted;

    if (!isSearching || bubblesFiltered.isEmpty) {
      if (_bolhasOriginaisPosicoes != null) {
        for (final b in bubbles) {
          if (_bolhasOriginaisPosicoes!.containsKey(b.id)) {
            b.x = _bolhasOriginaisPosicoes![b.id]!.dx;
            b.y = _bolhasOriginaisPosicoes![b.id]!.dy;
          }
        }
        _bolhasOriginaisPosicoes = null;
        if (mounted) setState(() {});
      }
      return;
    }

    _bolhasOriginaisPosicoes ??= {
      for (final b in bubbles) b.id: Offset(b.x, b.y)
    };

    final alvo = bubblesFiltered.first;
    alvo.x = 0.5;
    alvo.y = 0.5;

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/gifmaster.gif',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                height: kTopBarHeight,
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _onMyProfileTap,
                      child: profileLoaded && currentUserAvatar.isNotEmpty
                          ? CircleAvatar(
                        radius: 25,
                        backgroundImage: NetworkImage(currentUserAvatar),
                        onBackgroundImageError: (exception, stackTrace) {
                          print("[DEBUG] Erro ao carregar avatar: $exception");
                          if (mounted) setState(() {});
                        },
                      )
                          : CircleAvatar(
                          radius: 25,
                          child: profileLoaded
                              ? const Icon(Icons.person, size: 30)
                              : const CircularProgressIndicator(strokeWidth: 2)
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(currentUserName.isNotEmpty ? currentUserName : "Carregando...",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 17,
                              color: Colors.white,
                              fontWeight: FontWeight.w600)),
                    ),
                    IconButton(
                      icon: const Text('🔎', style: TextStyle(fontSize: 24)),
                      onPressed: () {
                        if (!mounted) return;
                        setState(() {
                          if (isSearching) {
                            searchText = '';
                            _searchController.clear();
                            isSearching = false;
                          } else {
                            isSearching = true;
                          }
                          _centralizarBolhaPesquisadaV2();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isSearching)
            Positioned(
              top: kTopBarHeight,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    height: kSearchBarHeight,
                    alignment: Alignment.center,
                    child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        cursorColor: Colors.cyanAccent,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                          fillColor: Colors.white.withOpacity(0.04),
                          filled: true,
                          hintText: 'Pesquisar usuário/bolha...',
                          hintStyle: const TextStyle(color: Colors.white54),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(32),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: const Text('🔎', style: TextStyle(fontSize: 22)),
                            onPressed: () {
                              if (!mounted) return;
                              setState(() {
                                _centralizarBolhaPesquisadaV2();
                              });
                            },
                          ),
                        ),
                        onChanged: (v) {
                          if (!mounted) return;
                          setState(() {
                            searchText = _searchController.text;
                            _centralizarBolhaPesquisadaV2();
                          });
                        }
                    ),
                  ),
                ),
              ),
            ),
          Positioned.fill(
            top: kTopBarHeight + (isSearching ? kSearchBarHeight : 0.0),
            child: LayoutBuilder(
                builder: (context, constraints) {
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTapUp: (details) {
                      if (!mounted) return;
                      final tapPos = details.localPosition;

                      final List<UserBubble> listToCheck = bubblesFiltered.isEmpty ? bubbles : bubblesFiltered;

                      for (final bubble in List.from(listToCheck).reversed) {
                        final bool isSpecial = bubble.id == 'game_bubble' ||
                            bubble.id == 'terlinet_word';
                        double baseSize = isSpecial ? 60.0 : bubble.size;
                        bool isSearchedForThisBubble = isSearching &&
                            bubblesFiltered.isNotEmpty &&
                            bubblesFiltered.first.id == bubble.id;
                        if (isSpecial) isSearchedForThisBubble = false;

                        double drawSize = isSpecial
                            ? baseSize * 1.18
                            : baseSize * 0.65;
                        if (isSearchedForThisBubble && !isSpecial)
                          drawSize = baseSize * 1.55;

                        final double painterCenterX = bubble.x * constraints.maxWidth;
                        final double painterCenterY = bubble.y * constraints.maxHeight;
                        final Offset bubblePainterCenter = Offset(painterCenterX, painterCenterY);

                        final raio = drawSize / 2;
                        final dist = (tapPos - bubblePainterCenter).distance;

                        if (dist <= raio) {
                          print('[DEBUG] Bolha ${bubble.name} TOCADA!');
                          if (bubble.id == 'game_bubble') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const BubbleGameScreen(),
                              ),
                            );
                          } else {
                            _onBubbleTap(bubble);
                          }
                          break;
                        }
                      }
                    },
                    child: CustomPaint(
                      painter: BubblesPainter(
                        bubbles: bubbles,
                        bubblesFiltered: bubblesFiltered,
                        isSearching: isSearching,
                        bubbleImages: _bubbleImages,
                        searchText: searchText,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  );
                }
            ),
          ),
        ],
      ),
    );
  }
}

const double kTopBarHeight = 87.0;
const double kSearchBarHeight = 67.0;

extension StringCasingExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}

class BubblesPainter extends CustomPainter {
  final List<UserBubble> bubbles;
  final List<UserBubble> bubblesFiltered;
  final bool isSearching;
  final Map<String, ui.Image?> bubbleImages;
  final String searchText;

  BubblesPainter({
    required this.bubbles,
    required this.bubblesFiltered,
    required this.isSearching,
    required this.bubbleImages,
    required this.searchText,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double availableWidth = size.width;
    final double availableHeight = size.height;

    final List<UserBubble> bolhasParaDesenhar = [];
    UserBubble? searchedBubbleInstance;

    if (isSearching && bubblesFiltered.isNotEmpty) {
      searchedBubbleInstance = bubbles.firstWhere(
              (b) => b.id == bubblesFiltered.first.id,
          orElse: () => bubblesFiltered.first
      );
      bolhasParaDesenhar.addAll(bubbles.where((b) => b.id != searchedBubbleInstance!.id));
      bolhasParaDesenhar.add(searchedBubbleInstance!);
    } else {
      bolhasParaDesenhar.addAll(bubbles);
    }

    for (final bubble in bolhasParaDesenhar) {
      final bool isSpecial = bubble.id == 'game_bubble' ||
          bubble.id == 'terlinet_word';
      double baseSize = isSpecial ? 60.0 : bubble.size;

      bool isThisTheSearchedBubble = isSearching &&
          searchedBubbleInstance != null &&
          bubble.id == searchedBubbleInstance!.id;

      double drawSize = isSpecial ? baseSize * 1.18 : baseSize * 0.65;
      if (isThisTheSearchedBubble && !isSpecial) drawSize = baseSize * 1.55;

      final left = bubble.x * availableWidth - drawSize / 2;
      final top = bubble.y * availableHeight - drawSize / 2;

      double opacity = 1.0;
      if (isSearching && bubblesFiltered.isNotEmpty &&
          !isThisTheSearchedBubble && !isSpecial) {
        if (bubble.name.toLowerCase().contains(searchText.toLowerCase())) {
          opacity = 0.5;
        } else {
          opacity = 0.18;
        }
      }

      if (isSpecial) {
        final List<Color> neonColors = [
          Colors.blueAccent, Colors.cyanAccent, Colors.limeAccent, Colors.greenAccent,
        ];
        final double anim = (DateTime.now().millisecondsSinceEpoch % 2000) / 2000.0;
        final sweep = 6.283 * anim;
        final Rect gameRect = Rect.fromCircle(
            center: Offset(left + drawSize / 2, top + drawSize / 2),
            radius: drawSize / 2);
        final Paint gradPaint = Paint()
          ..shader = SweepGradient(
            center: FractionalOffset.center,
            colors: neonColors,
            stops: [0.0, 0.25, 0.6, 1.0],
            startAngle: sweep,
            endAngle: sweep + 6.283,
          ).createShader(gameRect)
          ..style = PaintingStyle.stroke
          ..strokeWidth = drawSize * 0.08;
        // Desenha o anel apenas se NÃO for a bolha terlinet_word
        if (bubble.id != 'terlinet_word') {
          canvas.drawCircle(
              Offset(left + drawSize / 2, top + drawSize / 2), drawSize / 2,
              gradPaint);
        }

        final Paint glowPaint = Paint()
          ..color = Colors.cyanAccent.withOpacity(
              (0.35 + 0.25 * (0.5 + 0.5 * sin(anim * 6.283))) * opacity)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
        canvas.drawCircle(
            Offset(left + drawSize / 2, top + drawSize / 2), drawSize / 2 + 7,
            glowPaint);

        final double hexRadius = drawSize * 0.24;
        for (int i = 0; i < 6; i++) {
          final double angle = 6.283 * i / 6;
          final double x = left + drawSize / 2 + hexRadius * cos(angle);
          final double y = top + drawSize / 2 + hexRadius * sin(angle);
          canvas.drawCircle(Offset(x, y), drawSize * 0.04, Paint()
            ..color = Colors.white.withOpacity(0.15 * opacity));
        }
        for (int i = 0; i < 3; i++) {
          final double ang1 = 6.283 * i / 3;
          final double ang2 = 6.283 * (i + 1) / 3;
          final double x1 = left + drawSize / 2 + hexRadius * cos(ang1);
          final double y1 = top + drawSize / 2 + hexRadius * sin(ang1);
          final double x2 = left + drawSize / 2 + hexRadius * cos(ang2);
          final double y2 = top + drawSize / 2 + hexRadius * sin(ang2);
          canvas.drawLine(
            Offset(x1, y1), Offset(x2, y2),
            Paint()
              ..color = Colors.cyanAccent.withOpacity(0.15 * opacity)
              ..strokeWidth = 2.2,
          );
        }
        final String label = (bubble.id == 'game_bubble')
            ? 'GAME'
            : 'TerlineT Word';
        final TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.w900,
              fontSize: drawSize * (label == 'GAME' ? 0.31 : 0.27),
              color: Colors.white.withOpacity(opacity),
              letterSpacing: label == 'GAME' ? 3.1 : 2.0,
              shadows: [
                Shadow(
                  blurRadius: 10,
                  color: Colors.cyanAccent.withOpacity(opacity),
                ),
                Shadow(
                  blurRadius: 20,
                  color: Colors.blueAccent.withOpacity(opacity),
                ),
              ],
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(minWidth: 0, maxWidth: double.infinity);
        final double tx = left + (drawSize - textPainter.width) / 2;
        final double ty = top + (drawSize - textPainter.height) / 2;
        textPainter.paint(canvas, Offset(tx, ty));
        if (bubble.id == 'terlinet_word') {
          final int np = 36; // mais partículas para maior densidade
          final double cx = left + drawSize / 2;
          final double cy = top + drawSize / 2;
          for (int i = 0; i < np; i++) {
            // Semente determinística por partícula para parecer aleatório
            final double seed = (i * 37.0 + 13.0);
            // Velocidade reduzida e direção aleatória por partícula
            final double dir = sin(seed * 0.53) > 0 ? 1.0 : -1.0;
            final double speed = (0.15 + 0.35 * (0.5 + 0.5 * sin(seed * 1.1))) *
                dir;
            // Ângulo com velocidade variável e fase distinta
            final double a = sweep * speed + seed * 0.23;
            // Raio base com variação maior + jitter radial
            final double baseOrbit = drawSize *
                (0.46 + 0.12 * (0.5 + 0.5 * sin(seed * 1.7)));
            final double jitterR = drawSize * 0.035 * sin(sweep * 2.4 + seed);
            final double orbit = baseOrbit + jitterR;
            // Wobble elíptico pequeno (direções diferentes para x/y)
            final double wobble = drawSize * 0.05 *
                (0.5 + 0.5 * cos(seed * 0.9));
            final double px = cx + orbit * cos(a) +
                wobble * cos(a * 0.6 + seed);
            final double py = cy + orbit * sin(a) +
                wobble * sin(a * 0.7 + seed * 1.3);
            // Tamanho e halo
            final double r = max(1.5,
                drawSize * (0.013 + 0.006 * (0.5 + 0.5 * sin(seed * 2.3))));
            // Variação sutil de cor ciano/azulada
            final double colorMix = 0.5 + 0.5 * sin(seed * 0.7 + sweep * 0.3);
            final Color dotColor = Color.lerp(
                Colors.cyanAccent, Colors.lightBlueAccent, colorMix)!
                .withOpacity(
                (0.72 + 0.28 * (0.5 + 0.5 * sin(seed * 1.7))) * opacity);
            final Color haloColor = Color.lerp(
                Colors.cyanAccent, Colors.blueAccent,
                0.3 + 0.7 * (0.5 + 0.5 * sin(seed * 0.5)))!
                .withOpacity(0.24 * opacity);

            final Paint haloPaint = Paint()
              ..color = haloColor
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.5);
            final Paint dotPaint = Paint()
              ..color = dotColor
              ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
            canvas.drawCircle(Offset(px, py), r * 1.8, haloPaint);
            canvas.drawCircle(Offset(px, py), r, dotPaint);
          }
        }
      } else {
        final paint = Paint()
          ..color = bubble.color.withOpacity(opacity)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(
            Offset(left + drawSize / 2, top + drawSize / 2), drawSize / 2,
            paint);
      }

      final glowPaint = Paint()
        ..color = bubble.color.withOpacity(0.16 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);

      if (isThisTheSearchedBubble || !isSearching) {
        canvas.drawCircle(
            Offset(left + drawSize / 2, top + drawSize / 2), drawSize / 2 + 9,
            glowPaint);
      }

      if (bubble.avatarUrl.isNotEmpty && bubble.id != 'game_bubble' &&
          bubble.id != 'terlinet_word') {
        final avatarImage = bubbleImages[bubble.id];
        final imageOpacity = opacity;

        if (avatarImage != null) {
          final dst = Rect.fromCenter(
            center: Offset(left + drawSize / 2, top + drawSize / 2),
            width: drawSize,
            height: drawSize,
          );

          canvas.saveLayer(dst.inflate(1.0), Paint()..color = Colors.white.withAlpha((255 * imageOpacity).toInt()));
          canvas.clipPath(Path()..addOval(dst));
          canvas.drawImageRect(
            avatarImage,
            Rect.fromLTWH(0, 0, avatarImage.width.toDouble(), avatarImage.height.toDouble()),
            dst,
            Paint()..color = Colors.white.withAlpha((255 * imageOpacity).toInt()),
          );
          canvas.restore();

          final borderPaint = Paint()
            ..color = Colors.white.withOpacity(0.82 * imageOpacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.8;
          canvas.drawCircle(
              Offset(left + drawSize / 2, top + drawSize / 2), drawSize / 2,
              borderPaint);
        } else {
          final avatarPaint = Paint()..color = Colors.grey.withOpacity(imageOpacity * 0.5);
          canvas.drawCircle(
              Offset(left + drawSize / 2, top + drawSize / 2), drawSize / 2,
              avatarPaint);
          final borderPaint = Paint()
            ..color = Colors.white.withOpacity(0.82 * imageOpacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.8;
          canvas.drawCircle(
              Offset(left + drawSize / 2, top + drawSize / 2), drawSize / 2,
              borderPaint);
        }
      } else if (bubble.id != 'game_bubble' && bubble.id != 'terlinet_word') {
        final textPainter = TextPainter(
          text: TextSpan(
            text: bubble.name.isNotEmpty ? bubble.name[0].toUpperCase() : '',
            style: TextStyle(
              fontSize: drawSize * 0.33,
              fontWeight: FontWeight.bold,
              color: Colors.white70.withOpacity(opacity),
              shadows: [const Shadow(blurRadius: 7.5, color: Colors.black45)],
            ),
          ),
          textDirection: TextDirection.ltr,
        );
        textPainter.layout(minWidth: 0, maxWidth: drawSize);
        textPainter.paint(
            canvas, Offset(left + (drawSize - textPainter.width) / 2, top + (drawSize - textPainter.height) / 2));
      }

      if (isThisTheSearchedBubble && bubble.id != 'game_bubble' &&
          bubble.id != 'terlinet_word') {
        final highlightPaint = Paint()
          ..color = Colors.redAccent.withOpacity(0.9 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5 + 3 * sin(DateTime.now().millisecondsSinceEpoch / 440);
        canvas.drawCircle(
            Offset(left + drawSize / 2, top + drawSize / 2), drawSize / 2 + 3,
            highlightPaint);
      }

      if (bubble.hasNotification) {
        final notifPaint = Paint()
          ..color = Colors.greenAccent.withOpacity(0.9 * opacity)
          ..style = PaintingStyle.fill;
        final notifBorderPaint = Paint()
          ..color = Colors.white.withOpacity(0.8 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

        final notifRadius = drawSize * 0.1;
        final notifCenter = Offset(
            left + drawSize - (drawSize * 0.15), top + (drawSize * 0.15));

        canvas.drawCircle(notifCenter, notifRadius, notifPaint);
        canvas.drawCircle(notifCenter, notifRadius, notifBorderPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant BubblesPainter oldDelegate) {
    return oldDelegate.bubbles != bubbles ||
        oldDelegate.bubblesFiltered != bubblesFiltered ||
        oldDelegate.isSearching != isSearching ||
        oldDelegate.bubbleImages != bubbleImages ||
        oldDelegate.searchText != searchText;
  }
}