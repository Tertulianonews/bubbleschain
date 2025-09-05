import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'channels_screen.dart';

class CreateChannelScreen extends StatefulWidget {
  final Channel? editingChannel; // null = criar novo, não null = editar existente

  const CreateChannelScreen({super.key, this.editingChannel});

  @override
  State<CreateChannelScreen> createState() => _CreateChannelScreenState();
}

class _CreateChannelScreenState extends State<CreateChannelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  bool _isLoading = false;
  String currentUserId = '';

  // Imagens
  XFile? _selectedImage;
  XFile? _selectedBanner;
  Uint8List? _selectedImageBytes;
  Uint8List? _selectedBannerBytes;
  String? _currentImageUrl;
  String? _currentBannerUrl;

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();

    final user = Supabase.instance.client.auth.currentUser;
    currentUserId = user?.id ?? '';

    // Se estiver editando, preencher campos
    if (widget.editingChannel != null) {
      _nameController.text = widget.editingChannel!.name;
      _descriptionController.text = widget.editingChannel!.description;
      _currentImageUrl = widget.editingChannel!.imageUrl;
      _currentBannerUrl = widget.editingChannel!.bannerUrl;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage({required bool isBanner}) async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: isBanner ? 1200 : 500,
        maxHeight: isBanner ? 600 : 500,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        // Para web, precisamos ler os bytes
        final bytes = await pickedFile.readAsBytes();

        setState(() {
          if (isBanner) {
            _selectedBanner = pickedFile;
            _selectedBannerBytes = bytes;
          } else {
            _selectedImage = pickedFile;
            _selectedImageBytes = bytes;
          }
        });
      }
    } catch (e) {
      print('[DEBUG] Erro ao selecionar imagem: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao selecionar imagem: $e')),
        );
      }
    }
  }

  // Widget para mostrar imagem que funciona em todas as plataformas
  Widget _buildImageWidget({
    required Uint8List? bytes,
    required XFile? file,
    required String? networkUrl,
    required double width,
    required double height,
    required Widget fallback,
  }) {
    // Se temos bytes (web ou mobile após seleção), usar Memory
    if (bytes != null) {
      return Image.memory(
        bytes,
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    }

    // Se não é web e temos arquivo, usar File
    if (!kIsWeb && file != null) {
      return Image.file(
        File(file.path),
        width: width,
        height: height,
        fit: BoxFit.cover,
      );
    }

    // Se temos URL da rede, usar Network
    if (networkUrl != null && networkUrl.isNotEmpty) {
      return Image.network(
        networkUrl,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback,
      );
    }

    // Fallback padrão
    return fallback;
  }

  Future<String?> _uploadImage(XFile imageFile, String folder) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final fileExtension = imageFile.path
          .split('.')
          .last
          .toLowerCase();
      final fileName = '${DateTime
          .now()
          .millisecondsSinceEpoch}_$currentUserId.$fileExtension';

      await Supabase.instance.client.storage
          .from('channel_images')
          .uploadBinary('$folder/$fileName', bytes);

      final publicUrl = Supabase.instance.client.storage
          .from('channel_images')
          .getPublicUrl('$folder/$fileName');

      return publicUrl;
    } catch (e) {
      print('[DEBUG] Erro ao fazer upload da imagem: $e');
      return null;
    }
  }

  Future<void> _saveChannel() async {
    if (!_formKey.currentState!.validate()) return;
    if (currentUserId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Usuário não autenticado')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String? imageUrl = _currentImageUrl;
      String? bannerUrl = _currentBannerUrl;

      // Upload da imagem do canal se selecionada
      if (_selectedImage != null) {
        imageUrl = await _uploadImage(_selectedImage!, 'avatars');
        if (imageUrl == null) {
          throw Exception('Erro ao fazer upload da imagem do canal');
        }
      }

      // Upload do banner se selecionado
      if (_selectedBanner != null) {
        bannerUrl = await _uploadImage(_selectedBanner!, 'banners');
        if (bannerUrl == null) {
          throw Exception('Erro ao fazer upload do banner');
        }
      }

      final channelData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'owner_id': currentUserId,
        'image_url': imageUrl,
        'banner_url': bannerUrl,
        'subscriber_count': widget.editingChannel?.subscriberCount ?? 0,
        'is_live': widget.editingChannel?.isLive ?? false,
        'live_channel_name': widget.editingChannel?.liveChannelName,
      };

      if (widget.editingChannel != null) {
        // Atualizar canal existente
        await Supabase.instance.client
            .from('channels')
            .update(channelData)
            .eq('id', widget.editingChannel!.id);
      } else {
        // Criar novo canal
        channelData['created_at'] = DateTime.now().toIso8601String();
        await Supabase.instance.client
            .from('channels')
            .insert(channelData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.editingChannel != null
                ? 'Canal atualizado com sucesso!'
                : 'Canal criado com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Retornar true para indicar sucesso
      }
    } catch (e) {
      print('[DEBUG] Erro ao salvar canal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar canal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingChannel != null;

    return Scaffold(
      // Previne redimensionamento quando teclado aparece
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          isEditing ? 'EDITAR CANAL' : 'CRIAR CANAL',
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.cyanAccent,
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveChannel,
              child: Text(
                isEditing ? 'SALVAR' : 'CRIAR',
                style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        // Garantir que o conteúdo fique dentro da área segura
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Banner do canal
              GestureDetector(
                onTap: () => _pickImage(isBanner: true),
                child: Container(
                  height: 150,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Stack(
                    children: [
                      // Mostrar banner com widget multi-plataforma
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: _buildImageWidget(
                          bytes: _selectedBannerBytes,
                          file: _selectedBanner,
                          networkUrl: _currentBannerUrl,
                          width: double.infinity,
                          height: 150,
                          fallback: Container(), // Container vazio como fallback
                        ),
                      ),

                      // Overlay com ícone e texto
                      Container(
                        width: double.infinity,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add_photo_alternate,
                              size: 40,
                              color: Colors.white70,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Adicionar Banner',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '1200x600 recomendado',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Avatar do canal e informações básicas
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar do canal
                  GestureDetector(
                    onTap: () => _pickImage(isBanner: false),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.cyanAccent,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child: ClipOval(
                        child: _buildImageWidget(
                          bytes: _selectedImageBytes,
                          file: _selectedImage,
                          networkUrl: _currentImageUrl,
                          width: 80,
                          height: 80,
                          fallback: const Icon(
                            Icons.add_a_photo,
                            size: 30,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Campos de texto
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nome do canal
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            labelText: 'Nome do Canal',
                            labelStyle: TextStyle(color: Colors.white70),
                            hintText: 'Ex: Gaming Channel',
                            hintStyle: TextStyle(color: Colors.white54),
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.white24),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.cyanAccent),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderSide: BorderSide(color: Colors.red),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value
                                .trim()
                                .isEmpty) {
                              return 'Nome do canal é obrigatório';
                            }
                            if (value
                                .trim()
                                .length < 3) {
                              return 'Nome deve ter pelo menos 3 caracteres';
                            }
                            if (value
                                .trim()
                                .length > 50) {
                              return 'Nome não pode ter mais de 50 caracteres';
                            }
                            return null;
                          },
                          maxLength: 50,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Descrição do canal
              TextFormField(
                controller: _descriptionController,
                style: const TextStyle(color: Colors.white),
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                  labelStyle: TextStyle(color: Colors.white70),
                  hintText: 'Descreva seu canal, que tipo de conteúdo você vai postar...',
                  hintStyle: TextStyle(color: Colors.white54),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyanAccent),
                  ),
                  alignLabelWithHint: true,
                ),
                validator: (value) {
                  if (value != null && value
                      .trim()
                      .length > 500) {
                    return 'Descrição não pode ter mais de 500 caracteres';
                  }
                  return null;
                },
                maxLength: 500,
              ),

              const SizedBox(height: 32),

              // Dicas de criação de canal
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Dicas para seu canal',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildTip('• Escolha um nome único e fácil de lembrar'),
                    _buildTip(
                        '• Use uma imagem de perfil clara e profissional'),
                    _buildTip(
                        '• Escreva uma descrição que explique seu conteúdo'),
                    _buildTip(
                        '• Banner atrativo ajuda a ganhar mais seguidores'),
                    _buildTip('• Você pode fazer lives diretamente do canal'),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Botão de criar/salvar
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChannel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black,
                    ),
                  )
                      : Text(
                    isEditing ? 'SALVAR ALTERAÇÕES' : 'CRIAR CANAL',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTip(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 14,
        ),
      ),
    );
  }
}