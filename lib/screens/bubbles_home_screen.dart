import 'dart:math';
import 'package:flutter/material.dart';
import 'profile_setup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'bubble_game_screen.dart';

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

  UserBubble({required this.id,
    required this.name,
    required this.avatarUrl,
    required this.x,
    required this.y,
    required this.dx,
    required this.dy,
    required this.size,
    required this.color,
    this.hasNotification = false});
}

class BubbleWidget extends StatefulWidget {
  final double size;
  final String? avatarUrl;
  final String initial;
  final VoidCallback onTap;
  final Color color;
  final bool shouldPulse;

  const BubbleWidget({
    Key? key,
    required this.size,
    this.avatarUrl,
    required this.initial,
    required this.onTap,
    required this.color,
    this.shouldPulse = false,
  }) : super(key: key);

  @override
  State<BubbleWidget> createState() => _BubbleWidgetState();
}

class _BubbleWidgetState extends State<BubbleWidget>
    with SingleTickerProviderStateMixin {
  AnimationController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.shouldPulse) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      )
        ..repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant BubbleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldPulse && _controller == null) {
      _controller = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 800),
      )
        ..repeat(reverse: true);
    } else if (!widget.shouldPulse && _controller != null) {
      _controller!.dispose();
      _controller = null;
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = Stack(
      children: [
        Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                widget.color.withOpacity(0.45),
                Colors.white.withOpacity(0.18),
                widget.color.withOpacity(0.80)
              ],
              stops: [0.24, 0.80, 1.0],
              center: Alignment(-0.25, -0.23),
              radius: 0.99,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.25),
                blurRadius: widget.size * 0.47,
                offset: Offset(0, widget.size * 0.12),
              ),
            ],
            border: Border.all(
                color: Colors.white.withOpacity(0.79),
                width: widget.size * 0.07),
          ),
        ),
        // Highlight (brilho principal)
        Positioned(
          left: widget.size * 0.23, top: widget.size * 0.13,
          child: Container(
            width: widget.size * 0.36, height: widget.size * 0.19,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.29),
              borderRadius: BorderRadius.circular(widget.size * 0.19),
            ),
          ),
        ),
        // Avatar ou inicial
        if (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty)
          ClipOval(child: Image.network(
              widget.avatarUrl!, width: widget.size,
              height: widget.size,
              fit: BoxFit.cover)),
        if (widget.avatarUrl == null || widget.avatarUrl!.isEmpty)
          Center(
            child: Text(
              widget.initial.isNotEmpty ? widget.initial.toUpperCase() : '',
              style: TextStyle(
                fontSize: widget.size * 0.39,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
                shadows: const [
                  Shadow(blurRadius: 10, color: Colors.black45)
                ],
              ),
            ),
          ),
      ],
    );
    if (widget.shouldPulse && _controller != null) {
      return AnimatedBuilder(
        animation: _controller!,
        builder: (context, _) {
          final pulse = 8 + 9 * _controller!.value;
          return GestureDetector(
            onTap: widget.onTap,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.greenAccent.withOpacity(0.48),
                    blurRadius: pulse,
                    spreadRadius: pulse * 0.6,
                  ),
                ],
              ),
              child: child,
            ),
          );
        },
      );
    } else {
      return GestureDetector(onTap: widget.onTap, child: child);
    }
  }
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
        duration: const Duration(seconds: 2)
    )
      ..repeat();
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
              border: Border.all(color: Colors.white.withOpacity(0.94),
                  width: widget.size * 0.15),
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
                      boxShadow: [BoxShadow(color: Colors.green.shade700,
                          blurRadius: 6)
                      ],
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
      if (res == null) return {};
      return res.map<String>((m) => m['sender_id'] as String).toSet();
    } catch (e) {
      return {};
    }
  }

  Future<void> _carregarMeuPerfil() async {
    if (currentUserId.isEmpty) {
      setState(() {
        profileLoaded = true;
      });
      return;
    }
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('nickname, avatar_url')
          .eq('id', currentUserId)
          .maybeSingle();
      setState(() {
        currentUserName = response?['nickname'] ?? 'Meu Perfil';
        currentUserAvatar = response?['avatar_url'] ?? '';
        profileLoaded = true;
      });
    } catch (e) {
      setState(() {
        profileLoaded = true;
      });
    }
  }

  void _moveBubblesPhysics() {
    final w = MediaQuery
        .of(context)
        .size
        .width;
    final h = MediaQuery
        .of(context)
        .size
        .height;
    for (int i = 0; i < bubbles.length; ++i) {
      var b = bubbles[i];
      final offset = Offset(
        sin((DateTime
            .now()
            .millisecondsSinceEpoch / 7200.0) + i * 0.86) * 0.00033,
        cos((DateTime
            .now()
            .millisecondsSinceEpoch / 9700.0) - i * 0.73) * 0.00031,
      );
      b.x += b.dx + offset.dx;
      b.y += b.dy + offset.dy;
      if (b.x * w < b.size / 2 + 4 && b.dx < 0) b.dx = -b.dx * 0.9;
      if (b.x * w > w - b.size / 2 - 4 && b.dx > 0) b.dx = -b.dx * 0.9;
      if (b.y * h < b.size / 2 + 7 && b.dy < 0) b.dy = -b.dy * 0.9;
      if (b.y * h > h - b.size / 2 - 7 && b.dy > 0) b.dy = -b.dy * 0.9;
      for (int j = i + 1; j < bubbles.length; ++j) {
        var o = bubbles[j];
        final dx = (b.x - o.x) * w;
        final dy = (b.y - o.y) * h;
        final dist = sqrt(dx * dx + dy * dy);
        final minDist = (b.size + o.size) / 2 + 2;
        if (dist < minDist && dist > 1) {
          final overlap = 0.3 * (minDist - dist) / dist;
          final ox = dx * overlap,
              oy = dy * overlap;
          b.x += ox / w;
          b.y += oy / h;
          o.x -= ox / w;
          o.y -= oy / h;
          final v1 = Offset(b.dx, b.dy),
              v2 = Offset(o.dx, o.dy);
          b.dx += (v1.dx - v2.dx) * 0.01;
          b.dy += (v1.dy - v2.dy) * 0.01;
          o.dx += (v2.dx - v1.dx) * 0.01;
          o.dy += (v2.dy - v1.dy) * 0.01;
        }
      }
      // Clamp velocidade
      double maxVel = 0.0008;
      b.dx = b.dx.clamp(-maxVel, maxVel);
      b.dy = b.dy.clamp(-maxVel, maxVel);
      b.dx *= 0.998;
      b.dy *= 0.998;
      b.x = b.x.clamp(0.0, 1.0);
      b.y = b.y.clamp(0.0, 1.0);
    }
    setState(() {});
  }

  Future<void> _loadAllUsersBubbles() async {
    try {
      final resposta = await Supabase.instance.client
          .from('users')
          .select('id, nickname, avatar_url');
      final outros = resposta.where((u) => u['id'] != currentUserId).toList();
      final Random rand = Random();
      final notificantes = await _buscarNotificantes();
      List<UserBubble> novas = [];

      // --- BUSCAR BOLHAS SOCIAIS DO SUPABASE ---
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
          if (app['color'] != null && app['color']
              .toString()
              .isNotEmpty) {
            bubbleColor = Color(
                int.parse(app['color'].toString().replaceFirst('#', '0xff')));
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
          size: 75,
          color: bubbleColor,
        ));
        added++;
      }

      // --- USUÁRIOS (como antes) ---
      for (int i = 0; i < outros.length; i++) {
        final u = outros[i];
        final baseHue = 205 + ((i * 21) % 140);
        final color = HSVColor
            .fromAHSV(1, baseHue.toDouble(), 0.65, 0.94)
            .toColor();
        novas.add(UserBubble(
          id: u['id'],
          name: u['nickname'] ?? '-',
          avatarUrl: u['avatar_url'] ?? '',
          x: (1 / 3) + rand.nextDouble() * (1 / 3),
          y: (1 / 3) + rand.nextDouble() * (1 / 3),
          dx: (rand.nextDouble() - 0.5) * 0.00035,
          dy: (rand.nextDouble() - 0.5) * 0.00040,
          size: 64 + rand.nextDouble() * 44,
          color: color,
          hasNotification: notificantes.contains(u['id']),
        ));
      }
      setState(() {
        bubbles = novas;
        // Adiciona bolha GAME!
        bubbles.add(
          UserBubble(
            id: 'game_bubble',
            name: 'GAME',
            avatarUrl: '',
            x: 0.81,
            y: 0.25,
            dx: 0,
            dy: 0,
            size: 76,
            color: Colors.greenAccent,
          ),
        );
      });
    } catch (e) {
      setState(() {
        bubbles = [];
      });
    }
  }

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    currentUserId = user?.id ?? '';
    _carregarMeuPerfil();
    bubbles = [];
    controller =
    AnimationController(vsync: this, duration: const Duration(days: 9999))
      ..addListener(_moveBubblesPhysics)
      ..repeat(period: const Duration(milliseconds: 44));
    _loadAllUsersBubbles();
  }

  @override
  void dispose() {
    controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onBubbleTap(UserBubble user) async {
    // Descobre se é bolha social (tem link_url no supabase)
    try {
      final social = await Supabase.instance.client
          .from('socialBubbles')
          .select('link_url')
          .eq('id', user.id)
          .maybeSingle();
      if (social != null && social['link_url'] != null && social['link_url']
          .toString()
          .isNotEmpty) {
        await launchUrl(Uri.parse(social['link_url']));
        return;
      }
    } catch (e) {}
    // Se não for social, segue fluxo normal
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChatScreen(
              otherUserId: user.id,
              otherUserName: user.name,
              otherUserAvatar: user.avatarUrl,
            ),
      ),
    );
    _loadAllUsersBubbles();
  }

  void _onMyProfileTap() {
    Navigator.push(context, MaterialPageRoute(
        builder: (_) => ProfileSetupScreen(userIdOverride: currentUserId)));
  }

  List<UserBubble> get bubblesFiltered {
    if (searchText
        .trim()
        .isEmpty) return bubbles;
    final query = searchText.trim().toLowerCase();
    return bubbles.where((b) =>
    b.name.toLowerCase().contains(query)
        || (b.name.isNotEmpty && b.name[0].toLowerCase() == query)
    ).toList();
  }

  void _jumpToBubbleCluster() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final perRow = sqrt(bubbles.length).ceil();
      final gridCellW = 180.0;
      final gridCellH = 180.0;
      final rows = (bubbles.length / perRow).ceil();
      final gridW = perRow * gridCellW;
      final gridH = rows * gridCellH;
      final universeWidth = gridW + 400;
      final universeHeight = gridH + 400;
      final vx = (universeWidth - gridW) / 2;
      final vy = (universeHeight - gridH) / 2;
      _centerController.value = Matrix4.identity()
        ..translate(-vx, -vy);
    });
  }

  // Novo: centralizar na bolha ao pesquisar
  Map<String, Offset>? _bolhasOriginais;

  void _centralizarBolhaPesquisadaV2() {
    if (!isSearching || bubblesFiltered.isEmpty) {
      // Saiu da busca, restaura as posições
      if (_bolhasOriginais != null) {
        for (final b in bubbles) {
          if (_bolhasOriginais!.containsKey(b.id)) {
            b.x = _bolhasOriginais![b.id]!.dx;
            b.y = _bolhasOriginais![b.id]!.dy;
          }
        }
        setState(() {});
        _bolhasOriginais = null;
      }
      return;
    }
    // Backup original (se ainda não fez)
    _bolhasOriginais ??= {
      for (final b in bubbles)
        b.id: Offset(b.x, b.y)
    };
    // Centraliza a primeira bolha filtrada na área visível (sem cobrir as barras)
    final match = bubbles.firstWhere((b) => b.id == bubblesFiltered.first.id);
    final contextW = MediaQuery
        .of(context)
        .size
        .width;
    final contextH = MediaQuery
        .of(context)
        .size
        .height;
    final barsHeight = kTopBarHeight + (isSearching ? kSearchBarHeight : 0.0);
    final centerYdisp = barsHeight / contextH +
        ((contextH - barsHeight) / 2) / contextH;
    match.x = 0.5;
    // Calcula a posição y como centro da área livre abaixo das barras
    match.y = (barsHeight + ((contextH - barsHeight) / 2)) / contextH;
    setState(() {});
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
    final double topBarHeight = kTopBarHeight;
    // Define modo de distribuição
    final bool usaUniverso = bubbles.length > 40; // limiar para universe/grid
    late double universeWidth, universeHeight, centerX, centerY, gridCellW,
        gridCellH;
    int perRow = 1;
    if (usaUniverso) {
      // universo maior + grid centralizado
      perRow = sqrt(bubbles.length).ceil();
      gridCellW = 170;
      gridCellH = 170;
      final rows = (bubbles.length / perRow).ceil();
      universeWidth = perRow * gridCellW + 200;
      universeHeight = rows * gridCellH + 200;
      centerX = (universeWidth - w) / 2;
      centerY = (universeHeight - h) / 2;
    } else {
      universeWidth = w;
      universeHeight = h;
      centerX = 0;
      centerY = 0;
    }
    return Scaffold(
      body: Stack(
        children: [
          // Plano de fundo gif
          Positioned.fill(
            child: Image.asset(
              'assets/gifmaster.gif',
              fit: BoxFit.cover,
            ),
          ),
          // TOP BAR [PERFIL, NICKNAME, BUSCA]
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _onMyProfileTap,
                    child: profileLoaded
                        ? BubbleWidget(
                      size: 48,
                      avatarUrl: currentUserAvatar,
                      initial: (currentUserName.isNotEmpty
                          ? currentUserName[0]
                          : ''),
                      onTap: _onMyProfileTap,
                      color: const Color(0xff45e3f3),
                    )
                        : const CircleAvatar(
                        radius: 25, child: CircularProgressIndicator()),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(currentUserName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 17,
                            color: Colors.white,
                            fontWeight: FontWeight.w600)),
                  ),
                  IconButton(
                    icon: const Text('🔎', style: TextStyle(fontSize: 24)),
                    onPressed: () {
                      setState(() {
                        if (isSearching) {
                          searchText = '';
                          _searchController.clear();
                          isSearching = false;
                          _centralizarBolhaPesquisadaV2();
                        } else {
                          isSearching = true;
                        }
                      });
                    },
                  ),
                ],
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
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    cursorColor: Colors.cyanAccent,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
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
                          setState(() {
                            searchText = '';
                            _searchController.clear();
                            _centralizarBolhaPesquisadaV2();
                          });
                        },
                      ),
                    ),
                    onChanged: (v) =>
                        setState(() {
                          searchText = _searchController.text;
                          _centralizarBolhaPesquisadaV2();
                        }),
                  ),
                ),
              ),
            ),
          if (!usaUniverso) ...[
            // MODO PADRÃO: stack sobre a tela
            // Prioriza a bolha pesquisada (coloca ela por último, para ficar "no topo" do stack).
            ...[bubblesFiltered.isEmpty
                ? bubbles
                : [
              ...bubbles.where((b) => b.id != bubblesFiltered[0].id),
              bubbles.firstWhere((b) => b.id == bubblesFiltered[0].id,
                  orElse: () => bubbles[0])
            ]
            ]
                .expand((bList) =>
                bList.map((user) {
                  if (user.id == 'game_bubble') {
                    return Positioned(
                      left: user.x * w - user.size / 2,
                      top: user.y * (h - topBarHeight) - user.size / 2 +
                          topBarHeight,
                      child: GameBubbleWidget(
                        size: user.size,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const BubbleGameScreen(),
                            ),
                          );
                        },
                      ),
                    );
                  }
                  final highlight = searchText.isEmpty ||
                      user.name.toLowerCase().contains(
                          searchText.toLowerCase()) ||
                      (user.name.isNotEmpty && user.name[0].toLowerCase() ==
                          searchText.toLowerCase());
                  final isSearched = bubblesFiltered.isNotEmpty &&
                      bubblesFiltered.first.id == user.id;
                  final double totalBarHeight = kTopBarHeight +
                      (isSearching ? kSearchBarHeight : 0.0);
                  return Positioned(
                    left: user.x * w - user.size / 2,
                    top: user.y * (h - totalBarHeight) - user.size / 2 +
                        totalBarHeight,
                    child: Opacity(
                      opacity: searchText.isEmpty ? 1.0 : (highlight
                          ? 1.0
                          : 0.18),
                      child: AnimatedScale(
                        scale: isSearched ? 1.55 : 1.0,
                        duration: const Duration(milliseconds: 390),
                        child: Container(
                          decoration: isSearched
                              ? BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.redAccent,
                                width: 5 + 3 * sin(DateTime
                                    .now()
                                    .millisecondsSinceEpoch / 440)),
                          )
                              : null,
                          child: BubbleWidget(
                            size: user.size,
                            avatarUrl: user.avatarUrl,
                            initial: user.name.isNotEmpty ? user.name[0] : '',
                            onTap: () => _onBubbleTap(user),
                            color: user.color,
                            shouldPulse: user.hasNotification,
                          ),
                        ),
                      ),
                    ),
                  );
                })),
          ] else
            ...[
              // MODO UNIVERSE: canvas/grade grande e pan/zoom
              Positioned(
                top: kTopBarHeight,
                left: 0,
                right: 0,
                bottom: 0,
                child: InteractiveViewer(
                  minScale: 0.7,
                  maxScale: 2.5,
                  panEnabled: true,
                  scaleEnabled: true,
                  boundaryMargin: const EdgeInsets.all(200),
                  child: SizedBox(
                    width: universeWidth,
                    height: universeHeight,
                    child: Stack(
                      children: [
                        ...bubbles
                            .asMap()
                            .entries
                            .map((entry) {
                          final i = entry.key;
                          final user = entry.value;
                          final highlight = searchText.isEmpty ||
                              user.name.toLowerCase().contains(
                                  searchText.toLowerCase()) ||
                              (user.name.isNotEmpty &&
                                  user.name[0].toLowerCase() ==
                                      searchText.toLowerCase());
                          final col = i % perRow;
                          final row = i ~/ perRow;
                          final x = centerX + col * gridCellW + gridCellW / 2;
                          final y = centerY + row * gridCellH + gridCellH / 2;
                          return Positioned(
                            left: x - user.size / 2,
                            top: y - user.size / 2,
                            child: Opacity(
                              opacity: searchText.isEmpty ? 1.0 : (highlight
                                  ? 1.0
                                  : 0.18),
                              child: BubbleWidget(
                                size: user.size,
                                avatarUrl: user.avatarUrl,
                                initial: user.name.isNotEmpty
                                    ? user.name[0]
                                    : '',
                                onTap: () => _onBubbleTap(user),
                                color: user.color,
                                shouldPulse: user.hasNotification,
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
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
