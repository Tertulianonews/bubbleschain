import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:intl/intl.dart';

class ChatScreen extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;

  const ChatScreen(
      {super.key, required this.otherUserId, required this.otherUserName, this.otherUserAvatar});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  late final String myUserId;

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    myUserId = user?.id ?? '';
    _marcarMensagensComoLidas();
  }

  Future<void> _sendMsg() async {
    final txt = _controller.text.trim();
    if (txt.isEmpty || myUserId.isEmpty) return;
    _controller.clear();
    await Supabase.instance.client.from('messages').insert({
      'sender_id': myUserId,
      'receiver_id': widget.otherUserId,
      'text': txt,
      'created_at': DateTime.now().toIso8601String(),
      'was_read': false,
    });
    // Após enviar, marcar como lidas todas mensagens recebidas do outro usuário
    await Supabase.instance.client
        .from('messages')
        .update({'was_read': true})
        .eq('receiver_id', myUserId)
        .eq('sender_id', widget.otherUserId)
        .eq('was_read', false);
  }

  Stream<List<Map<String, dynamic>>> _messagesStream() {
    final stream = Supabase.instance.client
        .from('messages')
        .stream(primaryKey: ['id']);
    return stream.map((msgs) =>
    msgs.where((msg) =>
    (msg['sender_id'] == myUserId &&
        msg['receiver_id'] == widget.otherUserId) ||
        (msg['sender_id'] == widget.otherUserId &&
            msg['receiver_id'] == myUserId)
    ).toList()
      ..sort((a, b) => a['created_at'].compareTo(b['created_at']))
    );
  }

  Future<void> _marcarMensagensComoLidas() async {
    if (myUserId.isEmpty) return;
    await Supabase.instance.client
        .from('messages')
        .update({'was_read': true})
        .eq('receiver_id', myUserId)
        .eq('sender_id', widget.otherUserId)
        .eq('was_read', false);
  }

  Future<void> _sendAttachment() async {
    final picker = ImagePicker();
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Text('🖼️', style: TextStyle(fontSize: 26)),
                title: const Text('Foto'),
                onTap: () async {
                  Navigator.pop(context);
                  final img = await picker.pickImage(
                      source: ImageSource.gallery, imageQuality: 90);
                  if (img != null) await _uploadAndSend(img, 'image');
                },
              ),
              ListTile(
                leading: const Text('🎬', style: TextStyle(fontSize: 26)),
                title: const Text('Vídeo'),
                onTap: () async {
                  Navigator.pop(context);
                  final vid = await picker.pickVideo(
                      source: ImageSource.gallery);
                  if (vid != null) await _uploadAndSend(vid, 'video');
                },
              ),
              ListTile(
                leading: const Text('🎵', style: TextStyle(fontSize: 26)),
                title: const Text('Áudio'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await FilePicker.platform.pickFiles(
                      type: FileType.audio);
                  if (result != null && result.files.isNotEmpty) {
                    await _uploadAndSend(
                        File(result.files.single.path!), 'audio');
                  }
                },
              ),
              ListTile(
                leading: const Text('📄', style: TextStyle(fontSize: 26)),
                title: const Text('Documento'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await FilePicker.platform.pickFiles(
                      type: FileType.any);
                  if (result != null && result.files.isNotEmpty) {
                    await _uploadAndSend(
                        File(result.files.single.path!), 'doc');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _uploadAndSend(dynamic picked, String tipo) async {
    String ext = '';
    String fileName = '';
    List<int> bytes = [];
    if (picked is XFile) {
      fileName = '${tipo}_${myUserId}_${DateTime
          .now()
          .millisecondsSinceEpoch}.${picked.name
          .split('.')
          .last}';
      bytes = await picked.readAsBytes();
      ext = picked.name
          .split('.')
          .last;
    } else if (picked is File) {
      fileName = '${tipo}_${myUserId}_${DateTime
          .now()
          .millisecondsSinceEpoch}.${picked.path
          .split('.')
          .last}';
      bytes = await picked.readAsBytes();
      ext = picked.path
          .split('.')
          .last;
    }
    final storage = Supabase.instance.client.storage;
    final bucket = 'chatfilesanexos';
    await storage.from(bucket).uploadBinary(
        fileName, Uint8List.fromList(bytes),
        fileOptions: const FileOptions(upsert: true));
    final publicUrl = storage.from(bucket).getPublicUrl(fileName);
    String conteudo = '';
    switch (tipo) {
      case 'image':
        conteudo = '[img]$publicUrl';
        break;
      case 'video':
        conteudo = '[video]$publicUrl';
        break;
      case 'audio':
        conteudo = '[audio]$publicUrl';
        break;
      case 'doc':
        conteudo = '[doc]$publicUrl';
        break;
      default:
        conteudo = '[file]$publicUrl';
    }
    await Supabase.instance.client.from('messages').insert({
      'sender_id': myUserId,
      'receiver_id': widget.otherUserId,
      'text': conteudo,
      'created_at': DateTime.now().toIso8601String(),
      'was_read': false,
    });
    // Após envio, marcar como lidas todas mensagens recebidas do outro usuário
    await Supabase.instance.client
        .from('messages')
        .update({'was_read': true})
        .eq('receiver_id', myUserId)
        .eq('sender_id', widget.otherUserId)
        .eq('was_read', false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black87,
        elevation: 0,
        leading: IconButton(
          icon: const Text('👈', style: TextStyle(fontSize: 28)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 21,
              backgroundColor: Colors.grey.shade300,
              backgroundImage: widget.otherUserAvatar != null &&
                  widget.otherUserAvatar!.isNotEmpty
                  ? NetworkImage(widget.otherUserAvatar!)
                  : null,
              child: (widget.otherUserAvatar == null ||
                  widget.otherUserAvatar!.isEmpty)
                  ? Text(widget.otherUserName.isNotEmpty
                  ? widget.otherUserName[0]
                  : '?',
                  style: const TextStyle(fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87))
                  : null,
            ),
            const SizedBox(width: 12),
            Flexible(child: Text(widget.otherUserName,
                style: const TextStyle(fontWeight: FontWeight.bold)))
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _messagesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (ctx, i) {
                    final msg = messages[messages.length - i - 1];
                    final bool mine = msg['sender_id'] == myUserId;
                    return Align(
                      alignment: mine ? Alignment.centerRight : Alignment
                          .centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 3),
                        padding: const EdgeInsets.symmetric(horizontal: 16,
                            vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery
                            .of(context)
                            .size
                            .width * 0.7),
                        decoration: BoxDecoration(
                          color: mine ? const Color(0xFF00FFC8) : Colors.white
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Column(
                          crossAxisAlignment: mine
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            ((msg['text'] ?? '').startsWith('[img]'))
                                ? GestureDetector(
                              onTap: () {
                                showDialog(
                                  context: context,
                                  builder: (_) =>
                                      Dialog(
                                        backgroundColor: Colors.transparent,
                                        child: InteractiveViewer(
                                          child: Image.network(
                                              msg['text'].substring(5)),
                                        ),
                                      ),
                                );
                              },
                              child: Image.network(
                                msg['text'].substring(5),
                                width: 210,
                                height: 210,
                                fit: BoxFit.cover,
                              ),
                            )
                                : ((msg['text'] ?? '').startsWith('[video]'))
                                ? InkWell(
                              onTap: () async {
                                final url = msg['text'].substring(7);
                                await launchUrl(Uri.parse(url));
                              },
                              child: Row(children: [
                                Text('🎬', style: TextStyle(
                                    fontSize: 20, color: Colors.amber)),
                                Text(' Ver vídeo',
                                    style: TextStyle(color: Colors.amber))
                              ]),
                            )
                                : ((msg['text'] ?? '').startsWith('[audio]'))
                                ? InkWell(
                              onTap: () async {
                                final url = msg['text'].substring(7);
                                await launchUrl(Uri.parse(url));
                              },
                              child: Row(children: [
                                Text('🎵', style: TextStyle(
                                    fontSize: 20, color: Colors.deepPurple)),
                                Text(' Ouvir áudio',
                                    style: TextStyle(color: Colors.deepPurple))
                              ]),
                            )
                                : ((msg['text'] ?? '').startsWith('[doc]'))
                                ? InkWell(
                              onTap: () async {
                                final url = msg['text'].substring(5);
                                await launchUrl(Uri.parse(url));
                              },
                              child: Row(children: [
                                Text('📄', style: TextStyle(
                                    fontSize: 20, color: Colors.blueAccent)),
                                Text(' Ver documento',
                                    style: TextStyle(color: Colors.blueAccent))
                              ]),
                            )
                                : (RegExp(r'https?://').hasMatch(
                                msg['text'] ?? ''))
                                ? SizedBox(
                              width: 240,
                              child: AnyLinkPreview(
                                link: msg['text'],
                                displayDirection: UIDirection
                                    .uiDirectionHorizontal,
                                showMultimedia: true,
                                errorWidget: Text(msg['text'] ?? ''),
                              ),
                            )
                                : Text(
                              msg['text'] ?? '',
                              style: TextStyle(
                                  color: mine ? Colors.black : Colors.white),
                            ),
                            if (msg['created_at'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  DateTime.tryParse(msg['created_at']) != null
                                      ? DateFormat('HH:mm').format(
                                      DateTime.parse(msg['created_at']))
                                      : '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 18),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Mensagem...',
                        fillColor: Colors.white.withOpacity(0.09),
                        filled: true,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                      ),
                      onSubmitted: (_) => _sendMsg(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  CircleAvatar(
                    backgroundColor: const Color(0xFF00FFC8),
                    child: IconButton(
                      icon: const Text('🚀', style: TextStyle(fontSize: 22)),
                      onPressed: _sendMsg,
                    ),
                  ),
                  const SizedBox(width: 6),
                  CircleAvatar(
                    backgroundColor: Colors.blueGrey.shade800,
                    child: IconButton(
                      icon: const Text('📎',
                          style: TextStyle(fontSize: 22, color: Colors.white)),
                      onPressed: _sendAttachment,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
