import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart'; // Import the LoginScreen

class ProfileSetupScreen extends StatefulWidget {
  final String? userIdOverride;

  const ProfileSetupScreen({Key? key, this.userIdOverride}) : super(key: key);

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  String? avatarUrl;
  XFile? pickedImage;
  final _nickController = TextEditingController();
  bool isUploading = false;
  String? errorMsg;
  bool loadedProfile = false;
  late String userId;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    // Usa id real do supabase (ou override para debug/teste)
    userId = widget.userIdOverride ?? user?.id ?? '';
    _carregarPerfil();
  }

  Future<void> _carregarPerfil() async {
    if (userId.isEmpty) return;
    final response = await Supabase.instance.client
        .from('users')
        .select('nickname, avatar_url')
        .eq('id', userId)
        .maybeSingle();
    if (response != null) {
      if (response['nickname'] != null) {
        _nickController.text = response['nickname'];
      }
      if (response['avatar_url'] != null) {
        setState(() {
          avatarUrl = response['avatar_url'];
        });
      }
    }
    setState(() {
      loadedProfile = true;
    });
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 85);
    if (result == null) return;
    setState(() {
      pickedImage = result;
      isUploading = true;
      errorMsg = null;
    });
    try {
      final bytes = await result.readAsBytes();
      // Geração correta do fileName SEM barra
      final fileName = 'avatar_${userId}_${DateTime
          .now()
          .millisecondsSinceEpoch}.jpg';
      final storage = Supabase.instance.client.storage;
      await storage.from('avatars').uploadBinary(
          fileName, bytes, fileOptions: const FileOptions(upsert: true));
      final publicUrl = storage.from('avatars').getPublicUrl(fileName);
      setState(() => avatarUrl = publicUrl);
    } catch (e) {
      setState(() {
        errorMsg = 'Falha ao fazer upload: $e';
      });
    }
    setState(() {
      isUploading = false;
    });
  }

  Future<void> _salvarPerfil() async {
    if ((_nickController.text.trim()).isEmpty || avatarUrl == null) {
      setState(() {
        errorMsg = 'Preencha nome e foto!';
      });
      return;
    }
    try {
      await Supabase.instance.client.from('users').upsert({
        'id': userId,
        'nickname': _nickController.text.trim(),
        'avatar_url': avatarUrl
      });
      setState(() {
        errorMsg = null;
      });
      // Após salvar, navegue para home bubbles main
      Navigator.of(context).pushReplacementNamed('/bubbles');
    } catch (e) {
      setState(() {
        errorMsg = 'Erro ao salvar no banco: $e';
      });
    }
  }

  @override
  void dispose() {
    _nickController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
          icon: const Text('👈', style: TextStyle(fontSize: 28)),
          onPressed: () => Navigator.pop(context),
        )
            : null,
      ),
      body: loadedProfile ? Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: isUploading ? null : _pickAndUploadImage,
                child: avatarUrl != null
                    ? CircleAvatar(
                  radius: 75,
                  backgroundColor: Colors.indigo.shade100,
                  backgroundImage: NetworkImage(avatarUrl!),
                )
                    : pickedImage != null
                    ? FutureBuilder<Uint8List>(
                    future: pickedImage!.readAsBytes(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const CircleAvatar(
                          radius: 75, child: CircularProgressIndicator());
                      return CircleAvatar(
                        radius: 75,
                        backgroundColor: Colors.indigo.shade100,
                        backgroundImage: MemoryImage(snapshot.data!),
                      );
                    })
                    : const CircleAvatar(
                  radius: 75,
                  backgroundColor: Colors.indigoAccent,
                  child: Icon(Icons.camera_alt, size: 60, color: Colors.white),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: 220,
                child: TextField(
                  controller: _nickController,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                      hintText: 'Seu nome/apelido',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(16)))
                  ),
                ),
              ),
              const SizedBox(height: 14),
              if (errorMsg != null) Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                    errorMsg!, style: const TextStyle(color: Colors.redAccent)),
              ),
              ElevatedButton(
                onPressed: isUploading ? null : _salvarPerfil,
                child: isUploading
                    ? const CircularProgressIndicator()
                    : const Text('Salvar'),
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: Navigator.canPop(context) ? () =>
                    Navigator.pop(context) : null,
                child: const Text('Voltar para bolhas'),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (!mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                  );
                },
                child: const Text('🚪', style: TextStyle(fontSize: 38)),
              ),
            ],
          ),
        ),
      ) : const Center(child: CircularProgressIndicator()),
    );
  }
}
