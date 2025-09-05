import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'channels_screen.dart';
import 'create_channel_screen.dart';
import '../widgets/live_video_widget.dart';

// Modelo para posts do canal
class ChannelPost {
  final String id;
  final String channelId;
  final String authorId;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final int likesCount;
  final int commentsCount;
  final bool isLiked;

  ChannelPost({
    required this.id,
    required this.channelId,
    required this.authorId,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.likesCount,
    required this.commentsCount,
    required this.isLiked,
  });

  factory ChannelPost.fromMap(Map<String, dynamic> map, bool isLiked) {
    return ChannelPost(
      id: map['id'] ?? '',
      channelId: map['channel_id'] ?? '',
      authorId: map['author_id'] ?? '',
      authorName: map['author_name'] ?? 'Usuário',
      authorAvatar: map['author_avatar'],
      content: map['content'] ?? '',
      imageUrl: map['image_url'],
      createdAt: DateTime.parse(
          map['created_at'] ?? DateTime.now().toIso8601String()),
      likesCount: map['likes_count'] ?? 0,
      commentsCount: map['comments_count'] ?? 0,
      isLiked: isLiked,
    );
  }
}

class ChannelViewScreen extends StatefulWidget {
  final Channel channel;

  const ChannelViewScreen({super.key, required this.channel});

  @override
  State<ChannelViewScreen> createState() => _ChannelViewScreenState();
}

class _ChannelViewScreenState extends State<ChannelViewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<ChannelPost> posts = [];
  bool isLoadingPosts = false;
  String currentUserId = '';
  bool isOwner = false;

  // Dados atualizados do canal
  late Channel currentChannel;

  // Controllers para criar post
  final TextEditingController _postController = TextEditingController();
  XFile? _selectedPostImage;
  Uint8List? _selectedPostImageBytes;
  bool isCreatingPost = false;
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    final user = Supabase.instance.client.auth.currentUser;
    currentUserId = user?.id ?? '';

    // Inicializar com os dados do canal passados
    currentChannel = widget.channel;
    isOwner = currentUserId == currentChannel.ownerId;

    _loadChannelData();
    _loadPosts();
  }

  // Método para carregar dados atualizados do canal
  Future<void> _loadChannelData() async {
    try {
      final response = await Supabase.instance.client
          .rpc('get_channels_with_info', params: {
        'user_id_param': currentUserId.isNotEmpty ? currentUserId : null,
      });

      final channelData = (response as List).firstWhere(
            (data) => data['id'] == widget.channel.id,
        orElse: () => null,
      );

      if (channelData != null && mounted) {
        setState(() {
          currentChannel = Channel.fromMap(
            Map<String, dynamic>.from(channelData),
            channelData['is_subscribed'] == true,
          );
        });
      }
    } catch (e) {
      print('[DEBUG] Erro ao carregar dados do canal: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _postController.dispose();
    super.dispose();
  }

  Future<void> _loadPosts() async {
    setState(() {
      isLoadingPosts = true;
    });

    try {
      // Buscar posts do canal com informações do autor
      final postsResponse = await Supabase.instance.client
          .from('channel_posts')
          .select('''
            id, channel_id, author_id, content, image_url, created_at, likes_count, comments_count,
            users:author_id (nickname, avatar_url)
          ''')
          .eq('channel_id', currentChannel.id)
          .order('created_at', ascending: false);

      // Buscar posts que o usuário curtiu
      Set<String> likedPostIds = {};
      if (currentUserId.isNotEmpty) {
        final likesResponse = await Supabase.instance.client
            .from('post_likes')
            .select('post_id')
            .eq('user_id', currentUserId);

        likedPostIds = likesResponse
            .map<String>((like) => like['post_id'] as String)
            .toSet();
      }

      if (mounted) {
        setState(() {
          posts = postsResponse.map<ChannelPost>((postData) {
            final userData = postData['users'] as Map<String, dynamic>?;
            final postMap = Map<String, dynamic>.from(postData);
            postMap['author_name'] = userData?['nickname'] ?? 'Usuário';
            postMap['author_avatar'] = userData?['avatar_url'];

            return ChannelPost.fromMap(
                postMap,
                likedPostIds.contains(postData['id'])
            );
          }).toList();
          isLoadingPosts = false;
        });
      }
    } catch (e) {
      print('[DEBUG] Erro ao carregar posts: $e');
      if (mounted) {
        setState(() {
          isLoadingPosts = false;
        });
      }
    }
  }

  Future<void> _createPost() async {
    if (_postController.text
        .trim()
        .isEmpty && _selectedPostImage == null) return;
    if (currentUserId.isEmpty) return;

    setState(() {
      isCreatingPost = true;
    });

    try {
      String? imageUrl;

      // Upload da imagem se selecionada
      if (_selectedPostImage != null) {
        final bytes = await _selectedPostImage!.readAsBytes();
        final fileExtension = _selectedPostImage!
            .path
            .split('.')
            .last
            .toLowerCase();
        final fileName = '${DateTime
            .now()
            .millisecondsSinceEpoch}_$currentUserId.$fileExtension';

        await Supabase.instance.client.storage
            .from('channel_images')
            .uploadBinary('posts/$fileName', bytes);

        imageUrl = Supabase.instance.client.storage
            .from('channel_images')
            .getPublicUrl('posts/$fileName');
      }

      // Criar post
      await Supabase.instance.client.from('channel_posts').insert({
        'channel_id': currentChannel.id,
        'author_id': currentUserId,
        'content': _postController.text.trim(),
        'image_url': imageUrl,
        'created_at': DateTime.now().toIso8601String(),
        'likes_count': 0,
        'comments_count': 0,
      });

      // Limpar campos
      _postController.clear();
      setState(() {
        _selectedPostImage = null;
        _selectedPostImageBytes = null;
      });

      // Recarregar posts
      await _loadPosts();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post criado com sucesso!'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('[DEBUG] Erro ao criar post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar post: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isCreatingPost = false;
        });
      }
    }
  }

  Future<void> _pickPostImage() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        // Ler bytes para compatibilidade com web
        final bytes = await pickedFile.readAsBytes();

        setState(() {
          _selectedPostImage = pickedFile;
          _selectedPostImageBytes = bytes;
        });
      }
    } catch (e) {
      print('[DEBUG] Erro ao selecionar imagem: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao selecionar imagem: $e')),
      );
    }
  }

  Future<void> _togglePostLike(ChannelPost post) async {
    if (currentUserId.isEmpty) return;

    try {
      if (post.isLiked) {
        // Remover curtida
        await Supabase.instance.client
            .from('post_likes')
            .delete()
            .eq('user_id', currentUserId)
            .eq('post_id', post.id);

        // Decrementar contador
        await Supabase.instance.client
            .from('channel_posts')
            .update({'likes_count': post.likesCount - 1})
            .eq('id', post.id);
      } else {
        // Adicionar curtida
        await Supabase.instance.client
            .from('post_likes')
            .insert({
          'user_id': currentUserId,
          'post_id': post.id,
          'liked_at': DateTime.now().toIso8601String(),
        });

        // Incrementar contador
        await Supabase.instance.client
            .from('channel_posts')
            .update({'likes_count': post.likesCount + 1})
            .eq('id', post.id);
      }

      // Recarregar posts
      await _loadPosts();
    } catch (e) {
      print('[DEBUG] Erro ao curtir/descurtir post: $e');
    }
  }

  void _startLive() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LiveVideoWidget(
              channelName: 'live_${currentChannel.id}',
              userId: currentUserId,
              isHost: true,
            ),
      ),
    ).then((_) {
      // Recarregar dados do canal após terminar live
      setState(() {});
    });
  }

  void _editChannel() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CreateChannelScreen(editingChannel: currentChannel),
      ),
    ).then((result) {
      if (result == true) {
        // Canal foi editado, voltar para lista de canais
        Navigator.pop(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 250,
              floating: false,
              pinned: true,
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Banner do canal
                    if (currentChannel.bannerUrl != null)
                      Image.network(
                        currentChannel.bannerUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.blue.withOpacity(0.5),
                                  Colors.purple.withOpacity(0.5),
                                  Colors.pink.withOpacity(0.5),
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    else
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.withOpacity(0.5),
                              Colors.purple.withOpacity(0.5),
                              Colors.pink.withOpacity(0.5),
                            ],
                          ),
                        ),
                      ),

                    // Overlay escuro
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.7),
                          ],
                        ),
                      ),
                    ),

                    // Informações do canal
                    Positioned(
                      bottom: 20,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: [
                          // Avatar do canal
                          CircleAvatar(
                            radius: 35,
                            backgroundColor: Colors.cyanAccent,
                            backgroundImage: currentChannel.imageUrl != null
                                ? NetworkImage(currentChannel.imageUrl!)
                                : null,
                            child: currentChannel.imageUrl == null
                                ? Text(
                              currentChannel.name.isNotEmpty
                                  ? currentChannel.name[0].toUpperCase()
                                  : 'C',
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            )
                                : null,
                          ),

                          const SizedBox(width: 16),

                          // Nome e estatísticas
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currentChannel.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${currentChannel
                                      .subscriberCount} seguidores',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 16,
                                  ),
                                ),
                                if (currentChannel.isLive)
                                  Container(
                                    margin: const EdgeInsets.only(top: 8),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.circle, color: Colors.white,
                                            size: 8),
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
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                if (isOwner)
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    color: Colors.grey[900],
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editChannel();
                          break;
                        case 'live':
                          _startLive();
                          break;
                      }
                    },
                    itemBuilder: (context) =>
                    [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.white),
                            SizedBox(width: 8),
                            Text('Editar Canal',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'live',
                        child: Row(
                          children: [
                            Icon(Icons.live_tv, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Iniciar Live',
                                style: TextStyle(color: Colors.white)),
                          ],
                        ),
                      ),
                    ],
                  ),
              ],
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.cyanAccent,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                tabs: const [
                  Tab(text: 'POSTS'),
                  Tab(text: 'SOBRE'),
                  Tab(text: 'LIVE'),
                ],
              ),
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            // Aba POSTS
            _buildPostsTab(),

            // Aba SOBRE
            _buildAboutTab(),

            // Aba LIVE
            _buildLiveTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsTab() {
    return Column(
      children: [
        // Campo para criar post (só para donos do canal ou usuários logados)
        if (currentUserId.isNotEmpty)
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _postController,
                  style: const TextStyle(color: Colors.white),
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: 'Compartilhe algo com seus seguidores...',
                    hintStyle: TextStyle(color: Colors.white60),
                    border: InputBorder.none,
                  ),
                ),

                if (_selectedPostImage != null) ...[
                  const SizedBox(height: 12),
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: _selectedPostImageBytes != null
                            ? Image.memory(
                          _selectedPostImageBytes!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                            : (!kIsWeb && _selectedPostImage != null)
                            ? Image.file(
                          File(_selectedPostImage!.path),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                            : Container(
                          height: 200,
                          width: double.infinity,
                          color: Colors.grey,
                          child: const Center(
                            child: Icon(
                                Icons.image, size: 50, color: Colors.white),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPostImage = null;
                              _selectedPostImageBytes = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                                Icons.close, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      onPressed: _pickPostImage,
                      icon: const Icon(Icons.image, color: Colors.cyanAccent),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: isCreatingPost ? null : _createPost,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                      ),
                      child: isCreatingPost
                          ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                          : const Text('POSTAR'),
                    ),
                  ],
                ),
              ],
            ),
          ),

        // Lista de posts
        Expanded(
          child: isLoadingPosts
              ? const Center(
            child: CircularProgressIndicator(color: Colors.cyanAccent),
          )
              : posts.isEmpty
              ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.post_add, size: 80, color: Colors.white30),
                const SizedBox(height: 16),
                const Text(
                  'Nenhum post ainda',
                  style: TextStyle(color: Colors.white60, fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seja o primeiro a compartilhar algo!',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 14),
                ),
              ],
            ),
          )
              : RefreshIndicator(
            color: Colors.cyanAccent,
            onRefresh: _loadPosts,
            child: ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return _buildPostCard(post);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostCard(ChannelPost post) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do post (autor e data)
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.cyanAccent,
                backgroundImage: post.authorAvatar != null
                    ? NetworkImage(post.authorAvatar!)
                    : null,
                child: post.authorAvatar == null
                    ? Text(
                  post.authorName.isNotEmpty
                      ? post.authorName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _formatDate(post.createdAt),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Conteúdo do post
          if (post.content.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              post.content,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],

          // Imagem do post
          if (post.imageUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                post.imageUrl!,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.white10,
                    child: const Center(
                      child: Icon(Icons.broken_image, color: Colors.white30),
                    ),
                  );
                },
              ),
            ),
          ],

          // Ações do post (curtir, comentar)
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: () => _togglePostLike(post),
                child: Row(
                  children: [
                    Icon(
                      post.isLiked ? Icons.favorite : Icons.favorite_border,
                      color: post.isLiked ? Colors.red : Colors.white60,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${post.likesCount}',
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  const Icon(
                      Icons.comment_outlined, color: Colors.white60, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${post.commentsCount}',
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAboutTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Descrição
          if (currentChannel.description.isNotEmpty) ...[
            const Text(
              'Descrição',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              currentChannel.description,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Estatísticas
          const Text(
            'Estatísticas',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                _buildStatRow(
                    'Seguidores', '${currentChannel.subscriberCount}'),
                const Divider(color: Colors.white24),
                _buildStatRow('Posts', '${posts.length}'),
                const Divider(color: Colors.white24),
                _buildStatRow(
                    'Criado em', _formatDate(currentChannel.createdAt)),
                const Divider(color: Colors.white24),
                _buildStatRow(
                    'Proprietário', currentChannel.ownerName),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (currentChannel.isLive) ...[
            const Icon(Icons.live_tv, size: 80, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Este canal está ao vivo!',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        LiveVideoWidget(
                          channelName: currentChannel.liveChannelName ??
                              'live_${currentChannel.id}',
                          userId: currentUserId,
                          isHost: isOwner,
                        ),
                  ),
                );
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('ASSISTIR LIVE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 16),
              ),
            ),
          ] else
            ...[
              const Icon(Icons.tv_off, size: 80, color: Colors.white30),
              const SizedBox(height: 16),
              const Text(
                'Nenhuma live ativa',
                style: TextStyle(color: Colors.white60, fontSize: 18),
              ),
              if (isOwner) ...[
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _startLive,
                  icon: const Icon(Icons.live_tv),
                  label: const Text('INICIAR LIVE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 16),
                  ),
                ),
              ],
            ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d atrás';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h atrás';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m atrás';
    } else {
      return 'Agora';
    }
  }
}