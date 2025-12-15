import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:audioplayers/audioplayers.dart'; // Adicionado para player de áudio
import 'create_channel_screen.dart';
import 'channel_view_screen_backup.dart';
import '../widgets/live_video_widget.dart';
import 'exchange_screen.dart';
import 'skydoge_blockchain_screen.dart'; // Import adicionado para Skydoge Blockchain

class Channel {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final String ownerName;
  final String? imageUrl;
  final String? bannerUrl;
  final int subscriberCount;
  final bool isLive;
  final String? liveChannelName;
  final DateTime createdAt;
  final bool isSubscribed;

  Channel({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.ownerName,
    this.imageUrl,
    this.bannerUrl,
    required this.subscriberCount,
    required this.isLive,
    this.liveChannelName,
    required this.createdAt,
    required this.isSubscribed,
  });

  factory Channel.fromMap(Map<String, dynamic> map, bool isSubscribed) {
    return Channel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      ownerId: map['owner_id'] ?? '',
      ownerName: map['owner_name'] ?? 'Usuário',
      imageUrl: map['image_url'],
      bannerUrl: map['banner_url'],
      subscriberCount: map['subscriber_count'] ?? 0,
      isLive: map['is_live'] == true,
      liveChannelName: map['live_channel_name'],
      createdAt: DateTime.parse(
          map['created_at'] ?? DateTime.now().toIso8601String()),
      isSubscribed: isSubscribed,
    );
  }
}

class ChannelsScreen extends StatefulWidget {
  const ChannelsScreen({super.key});

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen>
    with SingleTickerProviderStateMixin {

  List<Channel> channels = [];
  bool isLoading = true;
  String currentUserId = '';
  Timer? refreshTimer;

  late TabController _tabController;

  // Player de áudio para debug/teste
  final AudioPlayer _shootPlayer = AudioPlayer();

  // Filtros
  bool showOnlyLive = false;
  bool showOnlySubscribed = false;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    final user = Supabase.instance.client.auth.currentUser;
    currentUserId = user?.id ?? '';

    // Teste: tocar som assim que iniciar tela
    _shootPlayer.play(AssetSource('assets/short1.mp3'));

    _loadChannels();

    // Atualizar canais a cada 10 segundos para mostrar status de live atualizado
    refreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _loadChannels();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadChannels() async {
    try {
      // Usar a função SQL personalizada que já calcula tudo corretamente
      final response = await Supabase.instance.client
          .rpc('get_channels_with_info', params: {
        'user_id_param': currentUserId.isNotEmpty ? currentUserId : null,
      });

      if (mounted) {
        setState(() {
          channels = (response as List).map<Channel>((channelData) {
            return Channel.fromMap(
                Map<String, dynamic>.from(channelData),
                channelData['is_subscribed'] == true
            );
          }).toList();
          isLoading = false;
        });
      }
    } catch (e) {
      print('[DEBUG] Erro ao carregar canais: $e');
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  List<Channel> get filteredChannels {
    List<Channel> filtered = channels;

    // Filtrar por tab selecionada
    switch (_tabController.index) {
      case 0: // Todos
        break;
      case 1: // Seguindo
        filtered = filtered.where((c) => c.isSubscribed).toList();
        break;
      case 2: // Meus canais
        filtered = filtered.where((c) => c.ownerId == currentUserId).toList();
        break;
    }

    // Filtrar por pesquisa
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((c) =>
      c.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          c.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
          c.ownerName.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
    }

    // Filtrar por live
    if (showOnlyLive) {
      filtered = filtered.where((c) => c.isLive).toList();
    }

    // Ordenar: canais ao vivo primeiro, depois por data de criação
    filtered.sort((a, b) {
      if (a.isLive && !b.isLive) return -1;
      if (!a.isLive && b.isLive) return 1;
      return b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
  }

  Future<void> _toggleSubscription(Channel channel) async {
    if (currentUserId.isEmpty) return;

    try {
      if (channel.isSubscribed) {
        // Desinscrever
        await Supabase.instance.client
            .from('channel_subscriptions')
            .delete()
            .eq('user_id', currentUserId)
            .eq('channel_id', channel.id);
      } else {
        // Inscrever
        await Supabase.instance.client
            .from('channel_subscriptions')
            .insert({
          'user_id': currentUserId,
          'channel_id': channel.id,
          'subscribed_at': DateTime.now().toIso8601String(),
        });
      }

      // Recarregar canais
      await _loadChannels();
    } catch (e) {
      print('[DEBUG] Erro ao alterar inscrição: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao alterar inscrição: $e')),
      );
    }
  }

  void _openChannelView(Channel channel) {
    // Verificação e ação para EXCHANGE
    if (channel.id == 'exchange_bubble') {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ExchangeScreen(userId: currentUserId),
        ),
      ).then((_) {
        _loadChannels();
      });
      return;
    }

    // Verificação e ação para SKYDOGE BLOCKCHAIN (usando ID fixo ou nome do canal)
    if (channel.id == 'a0a0a0a0-b0b0-c0c0-d0d0-e0e0e0e0e0e0' ||
        channel.name.toLowerCase().contains('skydoge blockchain')) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const SkyDogeBlockchainScreen(),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChannelViewScreen(channel: channel),
      ),
    ).then((_) => _loadChannels());
  }

  void _openLiveStream(Channel channel) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LiveVideoWidget(
              channelName: channel.liveChannelName ?? 'live_${channel.id}',
              userId: currentUserId,
              isHost: channel.ownerId == currentUserId,
            ),
      ),
    );
  }

  void _createChannel() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateChannelScreen(),
      ),
    ).then((_) => _loadChannels());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Previne redimensionamento quando teclado aparece
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '💰',
              style: TextStyle(
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'CANAIS',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                letterSpacing: 2.0,
                fontSize: 18,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              showOnlyLive ? Icons.live_tv : Icons.live_tv_outlined,
              color: showOnlyLive ? Colors.red : Colors.white,
            ),
            onPressed: () {
              setState(() {
                showOnlyLive = !showOnlyLive;
              });
            },
            tooltip: 'Filtrar por canais ao vivo',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.cyanAccent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          onTap: (index) => setState(() {}),
          tabs: const [
            Tab(text: 'TODOS'),
            Tab(text: 'SEGUINDO'),
            Tab(text: 'MEUS'),
          ],
        ),
      ),
      body: SafeArea(
        // Garantir que o conteúdo fique dentro da área segura
        child: Column(
          children: [
            // Barra de pesquisa
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Pesquisar canais...',
                  hintStyle: const TextStyle(color: Colors.white60),
                  prefixIcon: const Icon(Icons.search, color: Colors.white60),
                  suffixIcon: searchQuery.isNotEmpty
                      ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white60),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        searchQuery = '';
                      });
                    },
                  )
                      : null,
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    searchQuery = value;
                  });
                },
              ),
            ),

            // Lista de canais
            Expanded(
              child: isLoading
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.cyanAccent),
                    SizedBox(height: 16),
                    Text(
                      'Carregando canais...',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              )
                  : filteredChannels.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.tv_off,
                      size: 80,
                      color: Colors.white30,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _tabController.index == 2
                          ? 'Você ainda não criou nenhum canal'
                          : searchQuery.isNotEmpty
                          ? 'Nenhum canal encontrado'
                          : 'Nenhum canal disponível',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 16,
                      ),
                    ),
                    if (_tabController.index == 2) ...[
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: _createChannel,
                        icon: const Icon(Icons.add),
                        label: const Text('Criar Meu Canal'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ],
                  ],
                ),
              )
                  : RefreshIndicator(
                color: Colors.cyanAccent,
                onRefresh: _loadChannels,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Calcular número de colunas baseado na largura da tela
                    int crossAxisCount = 1;
                    if (constraints.maxWidth >= 600)
                      crossAxisCount = 2; // Tablet pequeno
                    if (constraints.maxWidth >= 900)
                      crossAxisCount = 3; // Tablet grande
                    if (constraints.maxWidth >= 1200)
                      crossAxisCount = 4; // Desktop
                    if (constraints.maxWidth >= 1600)
                      crossAxisCount = 5; // Desktop grande

                    return GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.8, // Proporção dos cards
                      ),
                      itemCount: filteredChannels.length,
                      itemBuilder: (context, index) {
                        final channel = filteredChannels[index];
                        return _buildChannelCard(channel);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createChannel,
        backgroundColor: Colors.cyanAccent,
        foregroundColor: Colors.black,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildChannelCard(Channel channel) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: channel.isLive ? Colors.red : Colors.transparent,
          width: channel.isLive ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: () => _openChannelView(channel),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner/Imagem do canal
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16)),
                gradient: LinearGradient(
                  colors: [
                    Colors.blue.withOpacity(0.3),
                    Colors.purple.withOpacity(0.3),
                    Colors.pink.withOpacity(0.3),
                  ],
                ),
              ),
              child: Stack(
                children: [
                  if (channel.bannerUrl != null)
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16)),
                      child: Image.network(
                        channel.bannerUrl!,
                        width: double.infinity,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(); // Fallback para gradiente
                        },
                      ),
                    ),

                  // Indicador AO VIVO
                  if (channel.isLive)
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.5),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: Colors.white, size: 8),
                            SizedBox(width: 4),
                            Text(
                              'AO VIVO',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Botão play para live
                  if (channel.isLive)
                    Positioned.fill(
                      child: Center(
                        child: GestureDetector(
                          onTap: () => _openLiveStream(channel),
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.9),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Informações do canal
            Padding(
              padding: const EdgeInsets.all(12), // Reduzido de 16 para 12
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Avatar do canal
                      CircleAvatar(
                        radius: 18, // Reduzido de 20 para 18
                        backgroundColor: Colors.cyanAccent,
                        backgroundImage: channel.imageUrl != null
                            ? NetworkImage(channel.imageUrl!)
                            : null,
                        child: channel.imageUrl == null
                            ? Text(
                          channel.name.isNotEmpty
                              ? channel.name[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 14, // Reduzido de 16 para 14
                          ),
                        )
                            : null,
                      ),
                      const SizedBox(width: 12),

                      // Nome e estatísticas
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              channel.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  channel.ownerName,
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 14,
                                  ),
                                ),
                                const Text(
                                  ' • ',
                                  style: TextStyle(color: Colors.white60),
                                ),
                                Icon(
                                  Icons.people,
                                  size: 16,
                                  color: Colors.white60,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${channel.subscriberCount}',
                                  style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Botão de inscrição/desinscrição
                      if (channel.ownerId != currentUserId)
                        GestureDetector(
                          onTap: () => _toggleSubscription(channel),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: channel.isSubscribed
                                  ? Colors.white24
                                  : Colors.cyanAccent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              channel.isSubscribed ? 'SEGUINDO' : 'SEGUIR',
                              style: TextStyle(
                                color: channel.isSubscribed
                                    ? Colors.white
                                    : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Descrição
                  if (channel.description.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      channel.description,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}