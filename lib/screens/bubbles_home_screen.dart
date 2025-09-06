import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;

// Timer is used in this file. dart:async import ensures Timer works.
import 'package:flutter/material.dart';
import 'profile_setup_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'chat_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'bubble_game_screen.dart';
import 'package:http/http.dart' as http;
import 'terlinet_word_screen.dart';
import 'channels_screen.dart';
import '../widgets/live_video_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import 'terms_privacy_screen.dart';
import '../widgets/pepe_logo.dart';

// Modelo para notificação
class NotificationItem {
  final String id;
  final String senderId;
  final String senderName;
  final String senderAvatar;
  final String lastMessage;
  final DateTime timestamp;
  final int unreadCount;

  NotificationItem({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
    required this.lastMessage,
    required this.timestamp,
    required this.unreadCount,
  });
}

// Widget para a tela de notificações
class NotificationsScreen extends StatefulWidget {
  final String currentUserId;

  const NotificationsScreen({Key? key, required this.currentUserId})
      : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<NotificationItem> notifications = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    print(
        "[DEBUG NotificationsScreen] _loadNotifications iniciado para userId: ${widget
            .currentUserId}");

    if (!mounted) return;

    try {
      // Buscar mensagens não lidas individualmente, exibindo cada mensagem como uma notificação separada (não mais agrupadas por remetente)
      print(
          "[DEBUG NotificationsScreen] Fazendo query para mensagens não lidas...");

      final response = await Supabase.instance.client
          .from('messages')
          .select('*')
          .eq('receiver_id', widget.currentUserId)
          .eq('was_read', false)
          .order('created_at', ascending: false);

      print("[DEBUG NotificationsScreen] Resposta da query: ${response
          .length} mensagens");
      print("[DEBUG NotificationsScreen] Dados: $response");

      if (!mounted) return;

      // Agrupar mensagens não lidas por remetente para criar uma notificação por usuário
      Map<String, List<dynamic>> messagesBySender = {};

      for (var message in response) {
        String senderId = message['sender_id'];
        if (!messagesBySender.containsKey(senderId)) {
          messagesBySender[senderId] = [];
        }
        messagesBySender[senderId]!.add(message);
      }

      List<NotificationItem> notificationsList = [];
      for (final entry in messagesBySender.entries) {
        final senderId = entry.key;
        final messagesList = entry.value;

        // Ordenar mensagens do usuário por data decrescente
        messagesList.sort((a, b) =>
            DateTime.parse(b['created_at']).compareTo(
                DateTime.parse(a['created_at'])));

        final lastMessage = messagesList.first;

        try {
          print(
              "[DEBUG NotificationsScreen] Processando grupo de $senderId com ${messagesList
                  .length} mensagens.");

          final userResponse = await Supabase.instance.client
              .from('users')
              .select('nickname, avatar_url')
              .eq('id', senderId)
              .maybeSingle();

          print(
              "[DEBUG NotificationsScreen] Dados do usuário $senderId: $userResponse");

          if (userResponse != null) {
            final notificationItem = NotificationItem(
              id: lastMessage['id'],
              // Usa o id da última mensagem como identificador
              senderId: senderId,
              senderName: userResponse['nickname'] ?? 'Usuário',
              senderAvatar: userResponse['avatar_url'] ?? '',
              lastMessage: lastMessage['message'] ?? 'Nova mensagem',
              timestamp: DateTime.parse(lastMessage['created_at']),
              unreadCount: messagesList
                  .length, // Número de mensagens não lidas deste usuário
            );

            print(
                "[DEBUG NotificationsScreen] Criada notificação agrupada para ${notificationItem
                    .senderName} contendo ${notificationItem
                    .unreadCount} mensagens");
            notificationsList.add(notificationItem);
          } else {
            print(
                "[DEBUG NotificationsScreen] Usuário $senderId não encontrado na tabela users");
          }
        } catch (e) {
          print(
              "[DEBUG NotificationsScreen] Erro ao processar grupo de mensagens: $e");
        }
      }


      print(
          "[DEBUG NotificationsScreen] Total de notificações criadas: ${notificationsList
              .length}");

      if (mounted) {
        setState(() {
          notifications = notificationsList;
          isLoading = false;
        });
        print(
            "[DEBUG NotificationsScreen] Estado atualizado - isLoading: false, notifications: ${notifications
                .length}");
      }
    } catch (e) {
      print(
          "[DEBUG NotificationsScreen] ERRO GERAL ao carregar notificações: $e");
      print("[DEBUG NotificationsScreen] Stack trace: ${StackTrace.current}");
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Agora';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    print(
        "[DEBUG NotificationsScreen] build chamado - isLoading: $isLoading, notifications.length: ${notifications
            .length}");

    return Scaffold(
      backgroundColor: Colors.black, // Garantir fundo escuro
      body: SafeArea(
        child: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.blueGrey.shade900,
                      Colors.black87,
                      Colors.black,
                    ],
                  ),
                ),
                child: Image.asset(
                  'assets/gifmaster.gif',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print(
                        "[DEBUG NotificationsScreen] Erro ao carregar background: $error");
                    return Container(
                      color: Colors.blueGrey.shade900,
                    );
                  },
                ),
              ),
            ),

            // Conteúdo principal
            Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          print(
                              "[DEBUG NotificationsScreen] Botão voltar pressionado");
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                            Icons.arrow_back, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Notificações',
                        style: GoogleFonts.orbitron(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '🔔',
                        style: TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      // Contador debug
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${notifications.length}',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Lista de notificações
                Expanded(
                  child: Container(
                    color: Colors.transparent,
                    child: isLoading
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.cyanAccent),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Carregando notificações...',
                            style: GoogleFonts.orbitron(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )
                        : notifications.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '🔕',
                            style: TextStyle(fontSize: 64),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Nenhuma notificação',
                            style: GoogleFonts.orbitron(
                              fontSize: 18,
                              color: Colors.white.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Quando alguém te enviar uma mensagem\nvocê verá aqui',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        print(
                            "[DEBUG NotificationsScreen] Renderizando item $index: ${notification
                                .senderName}");
                        return _buildNotificationItem(notification);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationItem notification) {
    print(
        "[DEBUG NotificationsScreen] _buildNotificationItem para ${notification
            .senderName}");

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withOpacity(0.15),
            Colors.white.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            print("[DEBUG NotificationsScreen] Item clicado para ${notification
                .senderName} (${notification.senderId})");
            print(
                "[DEBUG NotificationsScreen] Mensagem ID: ${notification.id}");

            // Marcar TODAS as mensagens desse remetente como lidas
            try {
              print(
                  "[DEBUG NotificationsScreen] Marcando TODAS as mensagens desse remetente (${notification
                      .senderId}) como lidas...");

              await Supabase.instance.client
                  .from('messages')
                  .update({'was_read': true})
                  .eq('sender_id', notification.senderId)
                  .eq('receiver_id', widget.currentUserId)
                  .eq('was_read', false);

              print(
                  "[DEBUG NotificationsScreen] Todas as mensagens desse remetente marcadas como lidas");

              // Remover todas as notificações do remetente da lista local imediatamente
              if (mounted) {
                setState(() {
                  notifications.removeWhere((n) =>
                  n.senderId == notification.senderId);
                });
              }
            } catch (e) {
              print(
                  "[DEBUG NotificationsScreen] Erro ao marcar mensagens como lidas: $e");
            }

            if (!mounted) {
              print(
                  "[DEBUG NotificationsScreen] Widget não está montado, cancelando navegação");
              return;
            }

            print(
                "[DEBUG NotificationsScreen] Abrindo chat com ${notification
                    .senderName}...");

            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ChatScreen(
                      otherUserId: notification.senderId,
                      otherUserName: notification.senderName,
                      otherUserAvatar: notification.senderAvatar,
                    ),
              ),
            );

            print("[DEBUG NotificationsScreen] Retornou do chat: $result");

            // Recarregar notificações após voltar do chat para capturar novas mensagens
            if (mounted) {
              _loadNotifications();
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar + indicador de não lida/múltiplas mensagens
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      // Aumentar um pouco o avatar
                      backgroundImage: notification.senderAvatar.isNotEmpty
                          ? NetworkImage(notification.senderAvatar)
                          : null,
                      backgroundColor: Colors.blueGrey.withOpacity(0.4),
                      onBackgroundImageError: (exception, stackTrace) {
                        print(
                            "[DEBUG NotificationsScreen] Erro ao carregar avatar de ${notification
                                .senderName}: $exception");
                      },
                      child: notification.senderAvatar.isEmpty
                          ? Text(
                        notification.senderName.isNotEmpty
                            ? notification.senderName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      )
                          : null,
                    ),
                    // Indicador visual de "Não lida" (single) ou badge numerado
                    if (notification.unreadCount > 1)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.redAccent.withOpacity(0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            notification.unreadCount > 99
                                ? '99+'
                                : '${notification.unreadCount}',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                              height: 1.1,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          width: 15,
                          height: 15,
                          decoration: BoxDecoration(
                            color: Colors.greenAccent,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.greenAccent.withOpacity(0.4),
                                blurRadius: 6,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(width: 16),

                // Conteúdo da notificação
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.senderName,
                              style: GoogleFonts.orbitron(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            _formatTimestamp(notification.timestamp),
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.white.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notification.lastMessage.isNotEmpty
                            ? notification.lastMessage
                            : 'Nova mensagem',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Indicador textual de mensagem não lida ou múltiplas
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: notification.unreadCount > 1
                              ? Colors.redAccent.withOpacity(0.17)
                              : Colors.cyanAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: notification.unreadCount > 1
                                  ? Colors.redAccent.withOpacity(0.38)
                                  : Colors.cyanAccent.withOpacity(0.4)),
                        ),
                        child: Text(
                          notification.unreadCount > 1
                              ? '${notification.unreadCount} novas mensagens'
                              : 'Nova mensagem • Não lida',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: notification.unreadCount > 1
                                ? Colors.redAccent
                                : Colors.cyanAccent,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Ícone de seta
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withOpacity(0.5),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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
  bool isLive;
  String? liveChannel;

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
    this.isLive = false,
    this.liveChannel,
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

  // Notificações/Contador de não lidas
  int notificationsCount = 0;
  bool isLoadingNotifications = false;

  bool get isLoggedIn {
    final user = Supabase.instance.client.auth.currentUser;
    return user != null;
  }

  // Carrega notificações de novos chats/mensagens: Contador e lista para badge
  Future<void> _loadNotificationBadgeCount() async {
    print(
        "[DEBUG] _loadNotificationBadgeCount iniciado para userId: $currentUserId");

    if (currentUserId.isEmpty) {
      print("[DEBUG] currentUserId vazio, setando contador para 0");
      if (mounted) setState(() => notificationsCount = 0);
      return;
    }

    try {
      final res = await Supabase.instance.client
          .from('messages')
          .select('id') // Só precisamos contar
          .eq('receiver_id', currentUserId)
          .eq('was_read', false);

      print("[DEBUG] Query resultado: ${res.length} mensagens não lidas");

      if (mounted) setState(() {
        notificationsCount = res.length; // Contar total de mensagens
        print(
            "[DEBUG] notificationsCount atualizado para: $notificationsCount");
      });
    } catch (e) {
      print("[DEBUG] Erro em _loadNotificationBadgeCount: $e");
      if (mounted) setState(() => notificationsCount = 0);
    }
  }

  // Pega lista de remetentes (usado em _loadAllUsersBubbles para badge nas bolhas)
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
      if (b.id == 'game_bubble' || b.id == 'terlinet_word' ||
          b.id == 'bitcoin_bubble' || b.id == 'canais_bubble')
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
        if (b.id == 'game_bubble' || b.id == 'terlinet_word' ||
            b.id == 'bitcoin_bubble' || b.id == 'canais_bubble')
          bDrawSize = b.size * 1.18;
        else if (isSearching && bubblesFiltered.isNotEmpty && bubblesFiltered.first.id == b.id) bDrawSize = b.size * 1.55;

        double oDrawSize = o.size * 0.65;
        if (o.id == 'game_bubble' || o.id == 'terlinet_word' ||
            o.id == 'bitcoin_bubble' || o.id == 'canais_bubble')
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
          .select('id, nickname, avatar_url, is_live, live_channel');

      print("[DEBUG] Dados recebidos do Supabase: ${resposta.length} usuários");

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
          name: app['name'] ?? (app['id'] as String).capitalize(),
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

      int liveCount = 0;
      for (int i = 0; i < outros.length; i++) {
        final u = outros[i];
        final bool isLive = u['is_live'] == true;
        final String? liveChannel = u['live_channel'];

        if (isLive) {
          liveCount++;
          print(
              "[DEBUG] Usuário ao vivo encontrado: ${u['nickname']} (${u['id']}) - Canal: $liveChannel");
        }

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
          isLive: isLive,
          liveChannel: liveChannel,
        ));
        _loadAvatarImage(novas.last);
      }

      print("[DEBUG] Total de usuários ao vivo: $liveCount");

      // Definir contagem atual de usuários
      _lastUserCount = outros.length;

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
          // Adiciona a bolha do Bitcoin (nova bolha social fixa)
          bubbles.add(
            UserBubble(
              id: 'bitcoin_bubble',
              name: '₿ Bitcoin',
              avatarUrl: '',
              x: 0.81,
              y: 0.55,
              dx: 0,
              dy: 0,
              size: 60,
              color: Color(0xFFF7931A),
              // Cor laranja ouro oficial Bitcoin
              isSocial: true,
            ),
          );
          // Adiciona a bolha CANAIS (nova bolha especial)
          bubbles.add(
            UserBubble(
              id: 'canais_bubble',
              name: 'CANAIS',
              avatarUrl: '',
              x: 0.81,
              y: 0.65,
              dx: 0,
              dy: 0,
              size: 60,
              color: Colors.greenAccent,
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

  int _lastUserCount = 0;

  Future<void> _checkForNewUsers() async {
    try {
      final resposta = await Supabase.instance.client
          .from('users')
          .select('id')
          .neq('id', currentUserId);

      final currentCount = resposta.length;

      if (currentCount != _lastUserCount) {
        print(
            "[DEBUG] Detectados novos usuários: $_lastUserCount -> $currentCount. Recarregando bolhas.");
        _lastUserCount = currentCount;
        await _loadAllUsersBubbles();
      }
    } catch (e) {
      print("[DEBUG] Erro em _checkForNewUsers: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    currentUserId = user?.id ?? '';
    print("[DEBUG initState] currentUserId definido como: '$currentUserId'");

    // Adicionar listener para mudanças de autenticação
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;
      final User? newUser = data.session?.user;
      print("[DEBUG] Auth state changed: $event, user: ${newUser?.id}");

      if (event == AuthChangeEvent.signedIn && newUser != null) {
        if (mounted) {
          setState(() {
            currentUserId = newUser.id;
            print("[DEBUG] User signed in: $currentUserId");
          });
          _carregarMeuPerfil();
          _loadAllUsersBubbles();
          _loadNotificationBadgeCount();
        }
      } else if (event == AuthChangeEvent.signedOut) {
        if (mounted) {
          setState(() {
            currentUserId = '';
            currentUserName = '';
            currentUserAvatar = '';
            profileLoaded = false;
            notificationsCount = 0;
            print("[DEBUG] User signed out");
          });
        }
      }
    });

    if (currentUserId.isNotEmpty) {
      _carregarMeuPerfil();
    }
    bubbles = [];
    controller = AnimationController(vsync: this, duration: const Duration(days: 9999))
      ..addListener(_moveBubblesPhysics)
      ..repeat(period: const Duration(milliseconds: 30));
    _loadAllUsersBubbles();
    _loadNotificationBadgeCount();

    // Timer para atualizar status de live a cada 15 segundos (mais rápido)
    Timer.periodic(const Duration(seconds: 15), (timer) {
      if (mounted) {
        _updateLiveStatus();
      } else {
        timer.cancel();
      }
    });

    // Timer para verificar novos usuários a cada 60 segundos (menos frequente)
    Timer.periodic(const Duration(seconds: 60), (timer) {
      if (mounted) {
        _checkForNewUsers();
        _loadNotificationBadgeCount();
      } else {
        timer.cancel();
      }
    });

    // Timer específico para notificações a cada 30 segundos
    Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        _loadNotificationBadgeCount();
      } else {
        timer.cancel();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameBubble = bubbles.firstWhere(
            (bubble) => bubble.id == 'game_bubble',
        orElse: () =>
            UserBubble(
              id: '',
              name: '',
              avatarUrl: '',
              x: 0.5,
              y: 0.5,
              dx: 0,
              dy: 0,
              size: 50,
              color: Colors.transparent,
            ),
      );
      if (gameBubble.id != '') {
        setState(() {
          _gameBubble = gameBubble;
          _showDemoPreview = true;
        });
      }
    });
  }

  bool _showDemoPreview = false;
  late UserBubble _gameBubble = UserBubble(
    id: '',
    name: '',
    avatarUrl: '',
    x: 0.5,
    y: 0.5,
    dx: 0,
    dy: 0,
    size: 50,
    color: Colors.transparent,
  );

  @override
  void dispose() {
    controller.dispose();
    _searchController.dispose();
    _centerController.dispose();
    super.dispose();
  }

  void _onBubbleTap(UserBubble user) async {
    print("[DEBUG] _onBubbleTap chamado para: ${user.name} (ID: ${user.id})");
    // Abrir tela de canais se for canais_bubble
    if (user.id == 'canais_bubble') {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ChannelsScreen()),
      );
      return;
    }

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


    if (user.isLive) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              LiveVideoWidget(
                channelName: user.liveChannel ?? 'live_${user.id}',
                userId: currentUserId,
                isHost: false, // Como viewer
              ),
        ),
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
    // Atualizar status de live e notificações após voltar do chat
    _updateLiveStatus();
    _loadNotificationBadgeCount();
  }

  void _onMyProfileTap() async {
    print("[DEBUG _onMyProfileTap] CLICOU NA BOLHA DO PERFIL!");
    print("[DEBUG _onMyProfileTap] currentUserId antes de navegar: '$currentUserId'");
    if (!mounted) return;
    await Navigator.push(context, MaterialPageRoute(
        builder: (_) => ProfileSetupScreen(userIdOverride: currentUserId)));

    // Atualizar status de live e notificações após voltar do perfil (pode ter iniciado/parado live)
    _updateLiveStatus();
    _loadNotificationBadgeCount();
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

    if (!isSearching || bubblesFiltered.isEmpty) {
      if (_bolhasOriginaisPosicoes != null) {
        for (final b in bubbles) {
          final originalPos = _bolhasOriginaisPosicoes?[b.id];
          if (originalPos != null) {
            b.x = originalPos.dx;
            b.y = originalPos.dy;
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

  // Método para atualizar apenas status de live sem reorganizar bolhas
  Future<void> _updateLiveStatus() async {
    print(
        "[DEBUG] _updateLiveStatus chamado - atualizando apenas status de live");
    try {
      final resposta = await Supabase.instance.client
          .from('users')
          .select('id, is_live, live_channel');

      final liveUsersMap = <String, Map<String, dynamic>>{};
      for (final user in resposta) {
        liveUsersMap[user['id']] = {
          'is_live': user['is_live'] == true,
          'live_channel': user['live_channel'],
        };
      }

      int liveCount = 0;
      bool hasChanges = false;

      for (final bubble in bubbles) {
        if (liveUsersMap.containsKey(bubble.id)) {
          final userData = liveUsersMap[bubble.id];
          if (userData != null) {
            final wasLive = bubble.isLive;
            final isNowLive = userData['is_live'] as bool;

            if (wasLive != isNowLive) {
              hasChanges = true;
              bubble.isLive = isNowLive;
              bubble.liveChannel = userData['live_channel'];

              if (isNowLive) {
                liveCount++;
                print("[DEBUG] Usuário ${bubble.name} iniciou live");
              } else {
                print("[DEBUG] Usuário ${bubble.name} parou live");
              }
            } else if (isNowLive) {
              liveCount++;
            }
          }
        }
      }

      print("[DEBUG] Total de usuários ao vivo: $liveCount");

      if (hasChanges && mounted) {
        setState(() {
          // Apenas atualizar UI, bolhas mantêm posições
        });
      }
    } catch (e) {
      print("[DEBUG] Erro em _updateLiveStatus: $e");
    }
    // Atualiza também notificações
    _loadNotificationBadgeCount();
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;
    final bool loggedIn = isLoggedIn;


    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            // Background
            Positioned.fill(
              child: Image.asset(
                'assets/gifmaster.gif',
                fit: BoxFit.cover,
              ),
            ),

            // Top bar com perfil, sino de notificações e busca
            if (loggedIn)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
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
                            print(
                                "[DEBUG] Erro ao carregar avatar: $exception");
                            if (mounted) setState(() {});
                          },
                        )
                            : CircleAvatar(
                            radius: 25,
                            child: profileLoaded
                                ? const Icon(Icons.person, size: 30)
                                : const CircularProgressIndicator(
                                strokeWidth: 2)
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(currentUserName.isNotEmpty
                            ? currentUserName
                            : "Carregando...",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 17,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ),
                      // Botão do sino de notificação com badge
                      Builder(
                        builder: (context) {
                          return NotificationBell(
                            count: notificationsCount,
                            onTap: () async {
                              print(
                                  "[DEBUG] NotificationBell clicado! Count: $notificationsCount");
                              // Abrir tela de notificações
                              if (!mounted) return;
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      NotificationsScreen(
                                          currentUserId: currentUserId),
                                ),
                              );
                              if (mounted) {
                                _loadNotificationBadgeCount();
                              }
                            },
                          );
                        },
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
            if (!loggedIn)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SizedBox(height: kTopBarHeight),
              ),

            // Barra de pesquisa
            if (loggedIn && isSearching)
              Positioned(
                top: kTopBarHeight,
                left: 0,
                right: 0,
                child: Container(
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
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10.0, horizontal: 15.0),
                            fillColor: Colors.white.withOpacity(0.04),
                            filled: true,
                            hintText: 'Pesquisar usuário/bolha...',
                            hintStyle: const TextStyle(color: Colors.white54),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(32),
                              borderSide: BorderSide.none,
                            ),
                            suffixIcon: IconButton(
                              icon: const Text(
                                  '🔎', style: TextStyle(fontSize: 22)),
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
            if (!loggedIn)
              Positioned(
                top: kTopBarHeight,
                left: 0,
                right: 0,
                child: SizedBox(height: kSearchBarHeight),
              ),

            // Preview do game bubble
            if (loggedIn && _gameBubble.id != '')
              Positioned(
                left: _gameBubble.x * w - 60,
                top: _gameBubble.y * h - 120 + kTopBarHeight +
                    (isSearching ? kSearchBarHeight : 0.0),
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    opacity: _showDemoPreview ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 300),
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: SizedBox(
                        width: 390,
                        height: 800,
                        child: BubbleGameScreen(demoMode: true),
                      ),
                    ),
                  ),
                ),
              ),

            // Área principal das bolhas
            Positioned.fill(
              top: kTopBarHeight +
                  (isSearching && loggedIn ? kSearchBarHeight : 0.0),
              child: LayoutBuilder(
                  builder: (context, constraints) {
                    final specialIds = ['game_bubble', 'canais_bubble'];
                    final previews = bubbles
                        .where((b) => specialIds.contains(b.id))
                        .map((bubble) {
                      final double baseSize = 60.0;
                      final double drawSize = baseSize * 1.18;
                      double miniWidth = 120;
                      double miniHeight = 150;
                      Widget previewWidget;
                      if (bubble.id == 'game_bubble') {
                        previewWidget = FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: 390,
                            height: 650,
                            child: BubbleGameScreen(demoMode: true),
                          ),
                        );
                      } else {
                        previewWidget = const SizedBox();
                      }
                      final double centerX = bubble.x * constraints.maxWidth;
                      final double centerY = bubble.y * constraints.maxHeight;
                      return Positioned(
                        left: centerX - miniWidth / 2,
                        top: centerY - drawSize / 2 - miniHeight - 18,
                        child: IgnorePointer(
                          child: SizedBox(
                            width: miniWidth,
                            height: miniHeight,
                            child: previewWidget,
                          ),
                        ),
                      );
                    }).toList();

                    final livePreviews = bubbles
                        .where((b) => b.isLive && !specialIds.contains(b.id))
                        .map((bubble) {
                      final double baseSize = bubble.size;

                      bool isThisTheSearchedBubble = isSearching &&
                          bubblesFiltered.isNotEmpty &&
                          bubblesFiltered.first.id == bubble.id;
                      double drawSize = baseSize * 0.65;
                      if (isThisTheSearchedBubble) drawSize = baseSize * 1.55;

                      final double centerX = bubble.x * constraints.maxWidth;
                      final double centerY = bubble.y * constraints.maxHeight;

                      return Positioned(
                        left: centerX - 40,
                        top: centerY - drawSize / 2 - 30,
                        child: _LiveIndicatorWidget(),
                      );
                    }).toList();

                    final canaisTvEmoji = bubbles
                        .where((b) => b.id == 'canais_bubble')
                        .map((bubble) {
                      final double baseSize = 60.0;
                      final double drawSize = baseSize * 1.18;
                      final double centerX = bubble.x * constraints.maxWidth;
                      final double centerY = bubble.y * constraints.maxHeight;

                      return Positioned(
                        left: centerX - 30,
                        top: centerY - drawSize / 2 - 45,
                        child: Container(
                          width: 60,
                          alignment: Alignment.center,
                          child: Text(
                            "📺",
                            style: TextStyle(
                              fontSize: 32,
                              shadows: [
                                Shadow(
                                    blurRadius: 8,
                                    color: Colors.black,
                                    offset: Offset(2, 2)
                                ),
                                Shadow(
                                    blurRadius: 15,
                                    color: Colors.limeAccent.withOpacity(0.7),
                                    offset: Offset(0, 0)
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList();

                    Widget bubblesMainLayer = Stack(
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.translucent,
                          onPanUpdate: (details) {},
                          onTapUp: (details) async {
                            if (!loggedIn) return;
                            print(details);
                            if (!mounted) return;
                            final tapPos = details.localPosition;
                            final List<UserBubble> listToCheck = bubblesFiltered
                                .isEmpty ? bubbles : bubblesFiltered;
                            for (final bubble in List
                                .from(listToCheck)
                                .reversed) {
                              final bool isSpecial = bubble.id ==
                                  'game_bubble' ||
                                  bubble.id == 'terlinet_word' ||
                                  bubble.id == 'bitcoin_bubble' ||
                                  bubble.id == 'canais_bubble';
                              double baseSize = isSpecial ? 60.0 : bubble.size;

                              bool isThisTheSearchedBubble = isSearching &&
                                  bubblesFiltered.isNotEmpty &&
                                  bubblesFiltered.first.id == bubble.id;

                              double drawSize = isSpecial
                                  ? baseSize * 1.18
                                  : baseSize * 0.65;
                              if (isThisTheSearchedBubble && !isSpecial)
                                drawSize = baseSize * 1.55;

                              final double painterCenterX = bubble.x *
                                  constraints.maxWidth;
                              final double painterCenterY = bubble.y *
                                  constraints.maxHeight;
                              final raio = drawSize / 2;
                              final dist = (tapPos - Offset(
                                  painterCenterX, painterCenterY))
                                  .distance;
                              if (dist <= raio) {
                                print('[DEBUG] Bolha ${bubble.name} TOCADA!');
                                if (bubble.id == 'game_bubble') {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const BubbleGameScreen(),
                                    ),
                                  );
                                } else if (bubble.id == 'bitcoin_bubble') {
                                  await launchUrl(
                                      Uri.parse('https://bitcoin.org/'));
                                } else if (bubble.id == 'canais_bubble') {
                                  if (!mounted) return;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChannelsScreen(),
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
                        ),
                        ...canaisTvEmoji,
                        ...previews,
                        ...livePreviews,
                      ],
                    );

                    return bubblesMainLayer;
                  }
              ),
            ),

            // Overlay de login translúcido e bonito
            if (!loggedIn)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.15),
                        Colors.black.withOpacity(0.35),
                        Colors.black.withOpacity(0.25),
                      ],
                    ),
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: 390),
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 28),
                          padding: EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withOpacity(0.08),
                                Colors.white.withOpacity(0.03),
                                Colors.white.withOpacity(0.06),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.25),
                                blurRadius: 32,
                                offset: Offset(0, 12),
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: Colors.cyanAccent.withOpacity(0.1),
                                blurRadius: 48,
                                offset: Offset(0, 0),
                                spreadRadius: -5,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // LOGO com efeito de brilho
                              Container(
                                margin: EdgeInsets.only(bottom: 9),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.cyanAccent.withOpacity(
                                          0.25),
                                      blurRadius: 16,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const PepeLogo(size: 59),
                              ),

                              // Saudação inspiradora
                              Container(
                                margin: EdgeInsets.only(bottom: 9),
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Column(
                                  children: [
                                    ShaderMask(
                                      shaderCallback: (rect) =>
                                          LinearGradient(
                                            colors: [
                                              Colors.white,
                                              Colors.cyanAccent.shade100,
                                              Colors.white,
                                            ],
                                          ).createShader(rect),
                                      child: Text(
                                        "Bem-vindo ao Bubbles!",
                                        style: GoogleFonts.orbitron(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 21,
                                          color: Colors.white,
                                          letterSpacing: 0.5,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    Text(
                                      "O berço de tecnologias disruptivas e ideias inovadoras que transformam o futuro digital",
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.white.withOpacity(0.82),
                                        height: 1.25,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),

                              // Formulário com toggle login/cadastro
                              _LoginRegisterFormWidget(),

                              SizedBox(height: 6),

                              // Rodapé com referência à TerlineT
                              Column(
                                children: [
                                  // Link para termos
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => TermsPrivacyScreen(),
                                        ),
                                      );
                                    },
                                    child: Text(
                                      "Termos de Uso e Privacidade",
                                      style: GoogleFonts.orbitron(
                                        color: Color(0xFF8AC5EC).withOpacity(
                                            0.7),
                                        fontSize: 11,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 4),

                                  // Divisor sutil
                                  Container(
                                    height: 1,
                                    width: 62,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.transparent,
                                          Colors.white.withOpacity(0.3),
                                          Colors.transparent,
                                        ],
                                      ),
                                    ),
                                  ),

                                  SizedBox(height: 5),

                                  // Créditos TerlineT
                                  Column(
                                    children: [
                                      Text(
                                        "Powered by",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withOpacity(0.5),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                      SizedBox(height: 1),
                                      ShaderMask(
                                        shaderCallback: (rect) =>
                                            LinearGradient(
                                              colors: [
                                                Color(0xFF8AC5EC),
                                                Colors.cyanAccent.shade200,
                                                Color(0xFF8AC5EC),
                                              ],
                                            ).createShader(rect),
                                        child: Text(
                                          "TerlineT",
                                          style: GoogleFonts.orbitron(
                                            color: Colors.white,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: 1),
                                      Text(
                                        "Conectando pessoas • Transformando ideias",
                                        style: GoogleFonts.poppins(
                                          color: Colors.white.withOpacity(0.6),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: 0.25,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Widget para o indicador "AO VIVO" acima das bolhas ao vivo.
class _LiveIndicatorWidget extends StatefulWidget {
  const _LiveIndicatorWidget({Key? key}) : super(key: key);

  @override
  State<_LiveIndicatorWidget> createState() => _LiveIndicatorWidgetState();
}

class _LiveIndicatorWidgetState extends State<_LiveIndicatorWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF3B30),
            Color(0xFFFF5252),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF3B30).withOpacity(0.4),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.6),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              double scale = 1.0 + 0.7 * _pulseController.value;
              double opacity = 0.62 + 0.38 * (1.0 - _pulseController.value);
              return Container(
                width: 7.5 * scale,
                height: 7.5 * scale,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(opacity),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.88 * opacity),
                      blurRadius: 6 * scale,
                      spreadRadius: 1.0 * scale,
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          const Text(
            'AO VIVO',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              shadows: [
                Shadow(
                  color: Colors.black38,
                  offset: Offset(0, 0.5),
                  blurRadius: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

const double kTopBarHeight = 87.0;
const double kSearchBarHeight = 67.0;

// Widget do sino de notificação com badge (contador vermelho)
class NotificationBell extends StatefulWidget {
  final int count;
  final VoidCallback onTap;

  const NotificationBell({
    Key? key,
    required this.count,
    required this.onTap,
  }) : super(key: key);

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Iniciar animação se há notificações
    if (widget.count > 0) {
      _animationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(NotificationBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Controlar animação baseado no contador
    if (widget.count > 0 && oldWidget.count == 0) {
      _animationController.repeat(reverse: true);
    } else if (widget.count == 0 && oldWidget.count > 0) {
      _animationController.stop();
      _animationController.reset();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Sino sempre visível
        IconButton(
          icon: const Icon(Icons.notifications, color: Colors.white, size: 28),
          onPressed: () {
            print(
                "[DEBUG NotificationBell] IconButton pressionado! Count: ${widget
                    .count}");
            widget.onTap();
          },
        ),
        // Badge só aparece quando há notificações
        if (widget.count > 0)
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Positioned(
                right: 8,
                top: 10,
                child: Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withOpacity(0.6),
                          blurRadius: 6,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 22,
                      minHeight: 18,
                    ),
                    child: Text(
                      widget.count > 99 ? '99+' : widget.count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10.5,
                        height: 1,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

// Login/Register Toggle widget
class _LoginRegisterFormWidget extends StatefulWidget {
  @override
  State<_LoginRegisterFormWidget> createState() =>
      _LoginRegisterFormWidgetState();
}

class _LoginRegisterFormWidgetState extends State<_LoginRegisterFormWidget>
    with SingleTickerProviderStateMixin {
  int _mode = 0; // 0 = login, 1 = cadastro
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  String? _errorMsg;

  // Animation controller for particle system
  late AnimationController _particleController;

  @override
  void initState() {
    super.initState();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20), // Elegant slow orbit
    )
      ..repeat();
  }

  // Função para recuperar senha
  void _showForgotPasswordDialog() async {
    final TextEditingController emailCtrl = TextEditingController(
        text: _emailController.text);
    String? resetMsg;
    bool resetLoading = false;

    await showDialog(
      context: context,
      builder: (context) =>
          StatefulBuilder(
            builder: (context, setStateDialog) =>
                AlertDialog(
                  backgroundColor: Colors.white.withOpacity(0.95),
                  title: Text(
                    "Recuperar senha",
                    style: GoogleFonts.orbitron(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8AC5EC),
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Informe seu e-mail cadastrado para receber o link de redefinição de senha.',
                        style: GoogleFonts.orbitron(fontSize: 13),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: emailCtrl,
                        decoration: InputDecoration(
                          labelText: "Email",
                          labelStyle: GoogleFonts.orbitron(
                              color: Color(0xFF8AC5EC)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide(
                                color: Color(0xFF8AC5EC), width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      if (resetMsg != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: Text(
                            resetMsg!,
                            style: GoogleFonts.orbitron(
                              color: Color(0xFF8AC5EC),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: Text(
                        "Cancelar",
                        style: GoogleFonts.orbitron(color: Color(0xFF8AC5EC)),
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: resetLoading
                          ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF8AC5EC)),
                        ),
                      )
                          : Text(
                        "Enviar",
                        style: GoogleFonts.orbitron(color: Color(0xFF8AC5EC)),
                      ),
                      onPressed: resetLoading ? null : () async {
                        setStateDialog(() {
                          resetLoading = true;
                          resetMsg = null;
                        });
                        const String kResetRedirectUrl = 'https://tertulianonews.github.io/bubbleschain/reset-password';
                        try {
                          await Supabase.instance.client.auth
                              .resetPasswordForEmail(
                            emailCtrl.text.trim(),
                            redirectTo: kResetRedirectUrl,
                          );
                          setStateDialog(() {
                            resetMsg =
                            "Email de redefinição enviado! Verifique sua caixa de entrada.";
                            resetLoading = false;
                          });
                        } catch (e) {
                          setStateDialog(() {
                            resetMsg = "Erro: ${e.toString().replaceAll(
                                RegExp(r'Exception:|SupabaseAuthException:'),
                                '').trim()}";
                            resetLoading = false;
                          });
                        }
                      },
                    ),
                  ],
                ),
          ),
    );
  }

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final res = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (res.session == null) {
        setState(() {
          _errorMsg = "Falha na autenticação. Verifique suas credenciais.";
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMsg = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = "Email ou senha inválidos";
        _isLoading = false;
      });
    }
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    // Validações básicas
    if (_nameController.text
        .trim()
        .isEmpty) {
      setState(() {
        _errorMsg = "Por favor, informe um nome público.";
        _isLoading = false;
      });
      return;
    }

    if (_emailController.text
        .trim()
        .isEmpty) {
      setState(() {
        _errorMsg = "Por favor, informe um email válido.";
        _isLoading = false;
      });
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() {
        _errorMsg = "A senha deve ter no mínimo 6 caracteres.";
        _isLoading = false;
      });
      return;
    }

    try {
      final res = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        emailRedirectTo: 'https://tertulianonews.github.io/bubbleschain/',
      );

      if (res.user != null) {
        // Inserir dados adicionais na tabela users
        try {
          await Supabase.instance.client.from('users').insert({
            'id': res.user!.id,
            'nickname': _nameController.text.trim(),
            'avatar_url': null,
            'is_live': false,
            'live_channel': null,
          });
        } catch (e) {
          print("[DEBUG] Erro ao inserir usuário na tabela: $e");
        }

        setState(() {
          _errorMsg =
          "✅ Cadastro realizado! Verifique seu email para ativação.";
          _isLoading = false;
        });

        // Limpar campos após sucesso
        _nameController.clear();
        _emailController.clear();
        _passwordController.clear();

        // Voltar para modo login após 3 segundos
        Timer(Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _mode = 0;
              _errorMsg = null;
            });
          }
        });
      } else {
        setState(() {
          _errorMsg = "Falha ao cadastrar. Tente novamente.";
          _isLoading = false;
        });
      }
    } catch (e) {
      String errorMessage = "Erro ao cadastrar";
      String errorStr = e.toString().toLowerCase();

      if (errorStr.contains('email') && errorStr.contains('already')) {
        errorMessage = "Este email já está cadastrado.";
      } else if (errorStr.contains('password')) {
        errorMessage = "Senha deve ter no mínimo 6 caracteres.";
      } else if (errorStr.contains('email')) {
        errorMessage = "Por favor, informe um email válido.";
      }

      setState(() {
        _errorMsg = errorMessage;
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color kBubblesBlue = Color(0xFF8AC5EC);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Animated particle system around the form
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _particleController,
            builder: (context, child) {
              return CustomPaint(
                painter: _LoginParticlesPainter(
                  animationTime: _particleController.value,
                ),
                size: const Size(450, 450),
              );
            },
          ),
        ),
        // Login form content atop particles
        Column(
          children: [
            if (_mode == 1)
            // Campo nome/nickname para cadastro
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.3), width: 1.5),
                    ),
                    child: TextField(
                      controller: _nameController,
                      enabled: !_isLoading,
                      style: GoogleFonts.orbitron(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                      cursorColor: kBubblesBlue,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.transparent,
                        labelText: "Nome público",
                        labelStyle: TextStyle(
                            color: Colors.white.withOpacity(0.8)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 22),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                ),
              ),
            if (_mode == 1)
              SizedBox(height: 12),
            // Email
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1.5),
                  ),
                  child: TextField(
                    controller: _emailController,
                    enabled: !_isLoading,
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    cursorColor: kBubblesBlue,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.transparent,
                      labelText: "Email",
                      labelStyle: TextStyle(
                          color: Colors.white.withOpacity(0.8)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 18),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Senha
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.3), width: 1.5),
                  ),
                  child: TextField(
                    controller: _passwordController,
                    enabled: !_isLoading,
                    obscureText: !_showPassword,
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    cursorColor: kBubblesBlue,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.transparent,
                      labelText: "Senha",
                      labelStyle: TextStyle(
                          color: Colors.white.withOpacity(0.8)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 18),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _showPassword ? Icons.visibility_off : Icons
                              .visibility,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        onPressed: () {
                          setState(() {
                            _showPassword = !_showPassword;
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (_mode == 0)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 0),
                child: Center(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: kBubblesBlue,
                      textStyle: GoogleFonts.orbitron(
                        decoration: TextDecoration.underline,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Text('Esqueceu a senha?'),
                    onPressed: _showForgotPasswordDialog,
                  ),
                ),
              ),
            // Mensagem de erro/feedback
            if (_errorMsg != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _errorMsg!.startsWith('✅')
                        ? Colors.green.withOpacity(0.1)
                        : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _errorMsg!.startsWith('✅')
                          ? Colors.green.withOpacity(0.3)
                          : Colors.red.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _errorMsg!,
                    style: TextStyle(
                      color: _errorMsg!.startsWith('✅')
                          ? Colors.green.shade300
                          : kBubblesBlue,
                      fontFamily: GoogleFonts
                          .orbitron()
                          .fontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Toggle (Entrar / Cadastro) após os campos
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_isLoading) return;
                      if (_mode == 0) {
                        // Executar login
                        _login();
                      } else {
                        // Mudar para modo login
                        setState(() {
                          _mode = 0;
                          _errorMsg = null;
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: _mode == 0
                            ? kBubblesBlue.withOpacity(0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _mode == 0 ? kBubblesBlue : Colors.transparent,
                          width: _mode == 0 ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: _isLoading && _mode == 0
                            ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                kBubblesBlue),
                            strokeWidth: 2.8,
                          ),
                        )
                            : Text(
                          "Entrar",
                          style: GoogleFonts.orbitron(
                            color: _mode == 0 ? kBubblesBlue : kBubblesBlue
                                .withOpacity(0.67),
                            fontWeight: _mode == 0
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 18,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 7),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      if (_isLoading) return;
                      if (_mode == 1) {
                        // Executar cadastro
                        _register();
                      } else {
                        // Mudar para modo cadastro
                        setState(() {
                          _mode = 1;
                          _errorMsg = null;
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 11),
                      decoration: BoxDecoration(
                        color: _mode == 1
                            ? kBubblesBlue.withOpacity(0.18)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _mode == 1 ? kBubblesBlue : Colors.transparent,
                          width: _mode == 1 ? 2 : 1,
                        ),
                      ),
                      child: Center(
                        child: _isLoading && _mode == 1
                            ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                kBubblesBlue),
                            strokeWidth: 2.8,
                          ),
                        )
                            : Text(
                          "Cadastrar",
                          style: GoogleFonts.orbitron(
                            color: _mode == 1 ? kBubblesBlue : kBubblesBlue
                                .withOpacity(0.67),
                            fontWeight: _mode == 1
                                ? FontWeight.bold
                                : FontWeight.w600,
                            fontSize: 18,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_mode == 0)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Não tem conta? ",
                      style: GoogleFonts.orbitron(
                        color: kBubblesBlue.withOpacity(0.75),
                        fontSize: 13,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _mode = 1;
                          _errorMsg = null;
                        });
                      },
                      child: Text(
                        "Cadastre-se",
                        style: GoogleFonts.orbitron(
                          fontWeight: FontWeight.bold,
                          color: kBubblesBlue,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (_mode == 1)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Já tem conta? ",
                      style: GoogleFonts.orbitron(
                        color: kBubblesBlue.withOpacity(0.75),
                        fontSize: 13,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _mode = 0;
                          _errorMsg = null;
                        });
                      },
                      child: Text(
                        "Entrar",
                        style: GoogleFonts.orbitron(
                          fontWeight: FontWeight.bold,
                          color: kBubblesBlue,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// Particle system painter for login form
class _LoginParticlesPainter extends CustomPainter {
  final double animationTime; // from 0.0 to 1.0 for animation cycle

  _LoginParticlesPainter({required this.animationTime});

  @override
  void paint(Canvas canvas, Size size) {
    // Use center as the center of the form
    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    // Calculate orbit radius - smaller for more subtle effect
    final double bigRadius = size.width * 0.42;

    final int numParticles = 18; // Reduced number of particles
    final double time = animationTime * 2 * pi;

    for (int i = 0; i < numParticles; i++) {
      // orbiting angle
      final double baseAngle = i * 2 * pi / numParticles;
      // Animate particles individually with varied speeds
      final double speed = 0.5 + 0.3 * sin(baseAngle * 1.8);
      final double angle = baseAngle + time * speed;

      // Subtle orbital variation
      double orbitR = bigRadius + 15 * sin(time + baseAngle * 1.5 + i);

      // Small particle size variation
      double scale = 0.8 + 0.4 * sin(time * 1.2 + i * 0.8);

      // Subtle vertical wobble
      double yWobble = 8 * sin(time + i * 0.7);

      // Color variation - more subtle
      double colorT = 0.3 + 0.4 * sin(angle + time * 0.8 + i * 0.6);
      final Color color = Color.lerp(
          const Color(0xFF8AC5EC), Colors.white, colorT)!;

      // Some particles use alternate color for variety
      final bool alt = i % 4 == 0;
      final Color finalColor = alt
          ? Color.lerp(
          const Color(0xFFB24BF3), color, 0.6 + 0.3 * sin(angle + i))!
          : color;

      // Particle center
      final double px = centerX + orbitR * cos(angle);
      final double py = centerY + orbitR * sin(angle) + yWobble;

      final double r = 3 + 2 * scale; // Much smaller particle radius

      // Soft glow - much more subtle
      final Paint glow = Paint()
        ..color = finalColor.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(Offset(px, py), r * 2.2, glow);

      // Main particle - small and subtle
      final Paint dot = Paint()
        ..color = finalColor.withOpacity(0.65 + 0.15 * scale)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(Offset(px, py), r, dot);

      // Tiny white highlight - much more subtle
      if (colorT > 0.7) {
        final Paint highlight = Paint()
          ..color = Colors.white.withOpacity(0.2 + 0.3 * (colorT - 0.7))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.5);
        canvas.drawCircle(Offset(px, py), r * 0.6, highlight);
      }
    }

    // Remove the orbital circle completely - it was too visible
    // No orbital circle drawing here anymore
  }

  @override
  bool shouldRepaint(covariant _LoginParticlesPainter oldDelegate) {
    return animationTime != oldDelegate.animationTime;
  }
}

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

  // New method to draw blockchain cube animations
  void _drawBlockchainCubes(Canvas canvas, UserBubble bubble, double left,
      double top, double drawSize, double opacity) {
    final double time = DateTime
        .now()
        .millisecondsSinceEpoch / 1000.0;
    final double centerX = left + drawSize / 2;
    final double centerY = top + drawSize / 2;
    final double orbitRadius = drawSize * 0.6;

    // Draw 6 rotating cubes around the bubble
    for (int i = 0; i < 6; i++) {
      final double angle = (time * 0.5 + i * pi / 3) % (2 * pi);
      final double cubeX = centerX + orbitRadius * cos(angle);
      final double cubeY = centerY + orbitRadius * sin(angle);
      final double cubeSize = drawSize * 0.08;

      // Cube rotation for 3D effect
      final double cubeRotation = time * 2.0 + i * 0.5;

      canvas.save();
      canvas.translate(cubeX, cubeY);
      canvas.rotate(cubeRotation);

      // Draw cube with 3D effect
      _drawBlockchainCube(canvas, cubeSize, opacity);

      canvas.restore();

      // Draw connection lines between cubes
      if (i < 5) {
        final double nextAngle = (time * 0.5 + (i + 1) * pi / 3) % (2 * pi);
        final double nextCubeX = centerX + orbitRadius * cos(nextAngle);
        final double nextCubeY = centerY + orbitRadius * sin(nextAngle);

        final Paint connectionPaint = Paint()
          ..color = Colors.cyanAccent.withOpacity(0.3 * opacity)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

        canvas.drawLine(
          Offset(cubeX, cubeY),
          Offset(nextCubeX, nextCubeY),
          connectionPaint,
        );
      }
    }

    // Connect last cube to first
    final double firstAngle = (time * 0.5) % (2 * pi);
    final double lastAngle = (time * 0.5 + 5 * pi / 3) % (2 * pi);
    final double firstCubeX = centerX + orbitRadius * cos(firstAngle);
    final double firstCubeY = centerY + orbitRadius * sin(firstAngle);
    final double lastCubeX = centerX + orbitRadius * cos(lastAngle);
    final double lastCubeY = centerY + orbitRadius * sin(lastAngle);

    final Paint connectionPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.3 * opacity)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(lastCubeX, lastCubeY),
      Offset(firstCubeX, firstCubeY),
      connectionPaint,
    );
  }

  // New method to draw Nubank special effects
  void _drawNubankSpecialEffect(Canvas canvas, UserBubble bubble, double left,
      double top, double drawSize, double opacity) {
    final double time = DateTime
        .now()
        .millisecondsSinceEpoch / 1000.0;
    final double centerX = left + drawSize / 2;
    final double centerY = top + drawSize / 2;

    // Nubank's signature purple gradient ring
    final Paint nubankRingPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Color(0xFF820AD1).withOpacity(opacity), // Nubank purple
          Color(0xFFB24BF3).withOpacity(opacity), // Lighter purple
          Color(0xFF6A0DAD).withOpacity(opacity), // Darker purple
          Color(0xFF820AD1).withOpacity(opacity), // Back to original
        ],
        startAngle: time * 0.8,
        endAngle: time * 0.8 + 6.283,
      ).createShader(Rect.fromCircle(
          center: Offset(centerX, centerY), radius: drawSize / 2))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    // Draw animated ring
    canvas.drawCircle(
        Offset(centerX, centerY), drawSize / 2 + 8, nubankRingPaint);

    // Purple glowing particles around Nubank bubble
    final int particleCount = 12;
    for (int i = 0; i < particleCount; i++) {
      final double angle = (time * 0.6 + i * 6.283 / particleCount) %
          (2 * 3.141592);
      final double orbitRadius = drawSize * (0.7 + 0.2 * sin(time * 1.5 + i));
      final double particleX = centerX + orbitRadius * cos(angle);
      final double particleY = centerY + orbitRadius * sin(angle);

      final double particleSize = 2.5 + 1.5 * sin(time * 2.0 + i * 0.5);

      // Gradient from purple to white
      final Paint particlePaint = Paint()
        ..color = Color.lerp(
            Color(0xFF820AD1),
            Colors.white,
            0.3 + 0.7 * sin(time * 1.8 + i * 0.3)
        )!.withOpacity(0.8 * opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0);

      canvas.drawCircle(
          Offset(particleX, particleY), particleSize, particlePaint);
    }

    // Nubank money symbol floating effect
    final double symbolTime = time * 0.4;
    final double symbolY = centerY + 15 * sin(symbolTime);
    final TextPainter moneySymbol = TextPainter(
      text: TextSpan(
        text: '💳',
        style: TextStyle(
          fontSize: drawSize * 0.25,
          shadows: [
            Shadow(
              blurRadius: 8,
              color: Color(0xFF820AD1).withOpacity(0.6 * opacity),
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    moneySymbol.layout();
    moneySymbol.paint(
        canvas,
        Offset(
            centerX - moneySymbol.width / 2, symbolY - moneySymbol.height / 2)
    );

    // Purple energy waves
    for (int wave = 0; wave < 3; wave++) {
      final double waveTime = time * (1.2 + wave * 0.3);
      final double waveRadius = (drawSize / 2) + (20 * (waveTime % 1.0));
      final Paint wavePaint = Paint()
        ..color = Color(0xFF820AD1).withOpacity(
            (1.0 - (waveTime % 1.0)) * 0.3 * opacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawCircle(Offset(centerX, centerY), waveRadius, wavePaint);
    }
  }

  // Method to draw individual blockchain cube with 3D effect
  void _drawBlockchainCube(Canvas canvas, double size, double opacity) {
    final double halfSize = size / 2;
    final double depth = size * 0.3;

    // Front face (main cube)
    final Paint frontPaint = Paint()
      ..color = Colors.lightBlueAccent.withOpacity(0.8 * opacity)
      ..style = PaintingStyle.fill;

    final Rect frontRect = Rect.fromCenter(
      center: Offset.zero,
      width: size,
      height: size,
    );

    canvas.drawRect(frontRect, frontPaint);

    // Top face (3D effect)
    final Paint topPaint = Paint()
      ..color = Colors.white.withOpacity(0.6 * opacity)
      ..style = PaintingStyle.fill;

    final Path topPath = Path();
    topPath.moveTo(-halfSize, -halfSize);
    topPath.lineTo(-halfSize + depth, -halfSize - depth);
    topPath.lineTo(halfSize + depth, -halfSize - depth);
    topPath.lineTo(halfSize, -halfSize);
    topPath.close();

    canvas.drawPath(topPath, topPaint);

    // Right face (3D effect)
    final Paint rightPaint = Paint()
      ..color = Colors.blueAccent.withOpacity(0.9 * opacity)
      ..style = PaintingStyle.fill;

    final Path rightPath = Path();
    rightPath.moveTo(halfSize, -halfSize);
    rightPath.lineTo(halfSize + depth, -halfSize - depth);
    rightPath.lineTo(halfSize + depth, halfSize - depth);
    rightPath.lineTo(halfSize, halfSize);
    rightPath.close();

    canvas.drawPath(rightPath, rightPaint);

    // Cube outline
    final Paint outlinePaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(0.9 * opacity)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(frontRect, outlinePaint);
    canvas.drawPath(topPath, outlinePaint);
    canvas.drawPath(rightPath, outlinePaint);

    // Add small glowing center dot (representing data/hash)
    final Paint centerPaint = Paint()
      ..color = Colors.yellowAccent.withOpacity(0.9 * opacity)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset.zero, size * 0.1, centerPaint);
  }

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
      final searchedId = searchedBubbleInstance?.id;
      if (searchedId != null) {
        bolhasParaDesenhar.addAll(bubbles.where((b) => b.id != searchedId));
        bolhasParaDesenhar.add(searchedBubbleInstance!);
      }
    } else {
      bolhasParaDesenhar.addAll(bubbles);
    }

    for (final bubble in bolhasParaDesenhar) {
      final bool isSpecial = bubble.id == 'game_bubble' ||
          bubble.id == 'terlinet_word' ||
          bubble.id == 'bitcoin_bubble' ||
          bubble.id == 'canais_bubble';
      double baseSize = isSpecial ? 60.0 : bubble.size;

      bool isThisTheSearchedBubble = isSearching &&
          searchedBubbleInstance != null &&
          bubble.id == searchedBubbleInstance?.id;

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

      // Draw Nubank bubble special effects
      // Check by id == 'nubank' or name contains 'nubank'
      final bool isNubankBubble = bubble.id == 'nubank' ||
          (bubble.isSocial && bubble.name.toLowerCase().contains('nubank')) ||
          (bubble.id != 'game_bubble' &&
              bubble.id != 'terlinet_word' &&
              bubble.id != 'canais_bubble' &&
              bubble.name.toLowerCase().contains('nubank'));

      if (isNubankBubble && opacity > 0.3) {
        _drawNubankSpecialEffect(canvas, bubble, left, top, drawSize, opacity);
      }

      // Draw blockchain cube animations for crypto-related bubbles
      final bool isCryptoBubble = bubble.id == 'bitcoin_bubble' ||
          (bubble.isSocial && bubble.name.toLowerCase().contains('bitcoin')) ||
          (bubble.id != 'game_bubble' && bubble.id != 'terlinet_word' &&
              bubble.id != 'canais_bubble' && bubble.id != 'game_bubble' &&
              bubble.name.toLowerCase().contains('bitcoin'));

      if (isCryptoBubble && opacity > 0.3) {
        _drawBlockchainCubes(canvas, bubble, left, top, drawSize, opacity);
      }

      if (isSpecial) {
        final List<Color> neonColors = [
          Colors.blueAccent, Colors.cyanAccent, Colors.limeAccent, Colors.greenAccent,
        ];
        final double anim = (DateTime
            .now()
            .millisecondsSinceEpoch % 2000) / 2000.0;
        final sweep = 6.283 * anim;

        // Cores especiais para a bolha CANAIS - tons mais esverdeados e neon
        if (bubble.id == 'canais_bubble') {
          final List<Color> canaisColors = [
            Colors.limeAccent,
            Colors.greenAccent,
            Colors.lightGreenAccent,
            Colors.green.shade300,
          ];
          final Rect gameRect = Rect.fromCircle(
              center: Offset(left + drawSize / 2, top + drawSize / 2),
              radius: drawSize / 2);
          final Paint gradPaint = Paint()
            ..shader = SweepGradient(
              center: FractionalOffset.center,
              colors: canaisColors,
              stops: [0.0, 0.25, 0.6, 1.0],
              startAngle: sweep,
              endAngle: sweep + 6.283,
            ).createShader(gameRect)
            ..style = PaintingStyle.stroke
            ..strokeWidth = drawSize * 0.08;

          canvas.drawCircle(
              Offset(left + drawSize / 2, top + drawSize / 2), drawSize / 2,
              gradPaint);

          final Paint glowPaint = Paint()
            ..color = Colors.limeAccent.withOpacity(
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
              ..color = Colors.lightGreenAccent.withOpacity(0.15 * opacity));
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
                ..color = Colors.limeAccent.withOpacity(0.15 * opacity)
                ..strokeWidth = 2.2,
            );
          }
        } else {
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
          // Desenha o anel apenas se NÃO for a bolha terlinet_word, bitcoin_bubble, canais_bubble
          if (bubble.id != 'terlinet_word' && bubble.id != 'bitcoin_bubble' &&
              bubble.id != 'canais_bubble') {
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
        }

        final String label = (bubble.id == 'game_bubble')
            ? 'GAME'
            : (bubble.id == 'bitcoin_bubble')
            ? '₿'
            : (bubble.id == 'canais_bubble')
            ? 'CANAIS'
            : 'TerlineT Word';
        final double fontSize = (bubble.id == 'game_bubble')
            ? drawSize * 0.31
            : (bubble.id == 'bitcoin_bubble')
            ? drawSize * 0.57
            : (bubble.id == 'canais_bubble')
            ? drawSize * 0.22
            : drawSize * 0.27;
        final double letterSpacing = (bubble.id == 'game_bubble')
            ? 3.1
            : 2.0;
        final TextPainter textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.w900,
              fontSize: fontSize,
              color: Colors.white.withOpacity(opacity),
              letterSpacing: letterSpacing,
              shadows: bubble.id == 'canais_bubble' ? [
                Shadow(
                  blurRadius: 10,
                  color: Colors.limeAccent.withOpacity(opacity),
                ),
                Shadow(
                  blurRadius: 20,
                  color: Colors.greenAccent.withOpacity(opacity),
                ),
              ] : [
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
      if (isSpecial) {
        if (bubble.isLive) {
          // Efeito pulsante para live
          final double pulseAnimation = 0.8 + 0.2 * (0.5 + 0.5 * sin(DateTime
              .now()
              .millisecondsSinceEpoch / 300));

          final liveIndicatorPaint = Paint()
            ..color = Colors.redAccent.withOpacity(pulseAnimation * opacity)
            ..style = PaintingStyle.fill;
          final liveIndicatorBorderPaint = Paint()
            ..color = Colors.white.withOpacity(0.9 * opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;
          final liveIndicatorRadius = drawSize * 0.1 * pulseAnimation;
          final liveIndicatorCenter = Offset(
              left + drawSize - (drawSize * 0.18), top + (drawSize * 0.18));

          // Halo ao redor do indicador
          final liveHaloPaint = Paint()
            ..color = Colors.redAccent.withOpacity(
                0.3 * pulseAnimation * opacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
          canvas.drawCircle(
              liveIndicatorCenter, liveIndicatorRadius * 1.8, liveHaloPaint);

          canvas.drawCircle(
              liveIndicatorCenter, liveIndicatorRadius, liveIndicatorPaint);
          canvas.drawCircle(liveIndicatorCenter, liveIndicatorRadius,
              liveIndicatorBorderPaint);

          // Texto "LIVE" pequeno opcional
          final liveTextPainter = TextPainter(
            text: TextSpan(
              text: 'LIVE',
              style: TextStyle(
                fontSize: drawSize * 0.08,
                fontWeight: FontWeight.w900,
                color: Colors.white.withOpacity(opacity),
                shadows: [
                  Shadow(
                    blurRadius: 2,
                    color: Colors.redAccent.withOpacity(opacity),
                  ),
                ],
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          liveTextPainter.layout(minWidth: 0, maxWidth: drawSize);
          liveTextPainter.paint(
            canvas,
            Offset(
              left + drawSize - (drawSize * 0.35),
              top + drawSize - (drawSize * 0.15),
            ),
          );
        }
      } else {
        if (bubble.isLive) {
          // Efeito pulsante para live
          final double pulseAnimation = 0.8 + 0.2 * (0.5 + 0.5 * sin(DateTime
              .now()
              .millisecondsSinceEpoch / 300));

          final liveIndicatorPaint = Paint()
            ..color = Colors.redAccent.withOpacity(pulseAnimation * opacity)
            ..style = PaintingStyle.fill;
          final liveIndicatorBorderPaint = Paint()
            ..color = Colors.white.withOpacity(0.9 * opacity)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;
          final liveIndicatorRadius = drawSize * 0.1 * pulseAnimation;
          final liveIndicatorCenter = Offset(
              left + drawSize - (drawSize * 0.18), top + (drawSize * 0.18));

          // Halo ao redor do indicador
          final liveHaloPaint = Paint()
            ..color = Colors.redAccent.withOpacity(
                0.3 * pulseAnimation * opacity)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
          canvas.drawCircle(
              liveIndicatorCenter, liveIndicatorRadius * 1.8, liveHaloPaint);

          canvas.drawCircle(
              liveIndicatorCenter, liveIndicatorRadius, liveIndicatorPaint);
          canvas.drawCircle(liveIndicatorCenter, liveIndicatorRadius,
              liveIndicatorBorderPaint);

          // Texto "LIVE" pequeno opcional
          final liveTextPainter = TextPainter(
            text: TextSpan(
              text: 'LIVE',
              style: TextStyle(
                fontSize: drawSize * 0.08,
                fontWeight: FontWeight.w900,
                color: Colors.white.withOpacity(opacity),
                shadows: [
                  Shadow(
                    blurRadius: 2,
                    color: Colors.redAccent.withOpacity(opacity),
                  ),
                ],
              ),
            ),
            textDirection: TextDirection.ltr,
          );
          liveTextPainter.layout(minWidth: 0, maxWidth: drawSize);
          liveTextPainter.paint(
            canvas,
            Offset(
              left + drawSize - (drawSize * 0.35),
              top + drawSize - (drawSize * 0.15),
            ),
          );
        }
      }

      if (bubble.avatarUrl.isNotEmpty && bubble.id != 'game_bubble' &&
          bubble.id != 'terlinet_word' &&
          bubble.id != 'bitcoin_bubble' &&
          bubble.id != 'canais_bubble') {
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

          // Remove white border around user bubbles
          // final borderPaint = Paint()
          //   ..color = Colors.white.withOpacity(0.82 * imageOpacity)
          //   ..style = PaintingStyle.stroke
          //   ..strokeWidth = 2.8;
          // canvas.drawCircle(
          //     Offset(left + drawSize / 2, top + drawSize / 2), drawSize / 2,
          //     borderPaint);
        } else {
          final avatarPaint = Paint()..color = Colors.grey.withOpacity(imageOpacity * 0.5);
          canvas.drawCircle(
              Offset(left + drawSize / 2, top + drawSize / 2), drawSize / 2,
              avatarPaint);
          // Remove white border around user bubbles without avatars
          // final borderPaint = Paint()
          //   ..color = Colors.white.withOpacity(0.82 * imageOpacity)
          //   ..style = PaintingStyle.stroke
          //   ..strokeWidth = 2.8;
          // canvas.drawCircle(
          //     Offset(left + drawSize / 2, top + drawSize / 2), drawSize / 2,
          //     borderPaint);
        }
      } else if (bubble.id != 'game_bubble' && bubble.id != 'terlinet_word' &&
          bubble.id != 'bitcoin_bubble' && bubble.id != 'canais_bubble') {
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
          bubble.id != 'terlinet_word' &&
          bubble.id != 'bitcoin_bubble' &&
          bubble.id != 'canais_bubble') {
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