import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';

class LiveVideoWidget extends StatefulWidget {
  final String channelName;
  final String userId;
  final bool isHost; // true para quem está transmitindo, false para viewers

  const LiveVideoWidget({
    Key? key,
    required this.channelName,
    required this.userId,
    this.isHost = true,
  }) : super(key: key);

  @override
  State<LiveVideoWidget> createState() => _LiveVideoWidgetState();
}

class _LiveVideoWidgetState extends State<LiveVideoWidget> {
  bool _isLive = false;
  int _viewerCount = 0;
  bool _cameraEnabled = true;
  bool _micEnabled = true;

  // Variáveis da câmera
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  String? _cameraError;

  // Streaming de frames
  Timer? _frameTimer;
  Timer? _viewerTimer;
  String? _currentFrameUrl;
  final String _bucketName = 'live_frames';

  @override
  void initState() {
    super.initState();
    if (widget.isHost) {
      _initializeCamera();
    } else {
      // Se for viewer, entrar automaticamente no canal
      _joinChannel();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      // Solicitar permissões
      final cameraStatus = await Permission.camera.status;
      final micStatus = await Permission.microphone.status;

      if (!cameraStatus.isGranted) {
        final result = await Permission.camera.request();
        if (!result.isGranted) {
          setState(() {
            _cameraError = 'Permissão de câmera negada';
          });
          return;
        }
      }

      if (!micStatus.isGranted) {
        await Permission.microphone.request();
      }

      // Obter câmeras disponíveis
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _cameraError = 'Nenhuma câmera encontrada';
        });
        return;
      }

      // Inicializar controlador da câmera (frontal se disponível)
      final frontCamera = _cameras!.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low, // Usar resolução baixa para melhor performance
        enableAudio: true,
        imageFormatGroup: ImageFormatGroup.jpeg, // Formato JPEG otimizado
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _cameraError = 'Erro ao inicializar câmera: $e';
      });
    }
  }

  Future<void> _joinChannel() async {
    setState(() {
      _isLive = true;
    });

    // Atualizar status no Supabase
    if (widget.isHost) {
      await _updateLiveStatus(true);
      // Iniciar captura e upload de frames
      _startFrameStreaming();
    } else {
      // Iniciar download de frames para viewers
      _startFrameViewing();
    }

    // Simular contagem de viewers
    _startViewerSimulation();
  }

  /// Iniciar streaming de frames (HOST)
  void _startFrameStreaming() {
    if (!widget.isHost || _cameraController == null || !_isCameraInitialized)
      return;

    _frameTimer =
        Timer.periodic(const Duration(milliseconds: 400), (timer) async {
          if (!_isLive || !_cameraEnabled || _cameraController == null) return;

          try {
            // Capturar frame da câmera
            final XFile image = await _cameraController!.takePicture();
            final Uint8List bytes = await image.readAsBytes();

            // Nome do arquivo (sempre o mesmo para sobrescrever)
            final fileName = 'live_${widget.channelName}.jpg';

            // Upload para Supabase Storage (sobrescreve o anterior)
            await Supabase.instance.client.storage
                .from(_bucketName)
                .uploadBinary(
              fileName,
              bytes,
              fileOptions: const FileOptions(
                cacheControl: '0', // Não cachear
                upsert: true, // Sobrescrever sempre
              ),
            );

            debugPrint('[DEBUG] Frame enviado: $fileName');
          } catch (e) {
            debugPrint('[DEBUG] Erro ao capturar/enviar frame: $e');
          }
        });
  }

  /// Iniciar visualização de frames (VIEWER)
  void _startFrameViewing() {
    if (widget.isHost) return;

    _viewerTimer =
        Timer.periodic(const Duration(milliseconds: 600), (timer) async {
          if (!_isLive) return;

          try {
            // Nome do arquivo que o host está enviando
            final fileName = 'live_${widget.channelName}.jpg';

            // Obter URL pública do frame atual
            final url = Supabase.instance.client.storage
                .from(_bucketName)
                .getPublicUrl(fileName);

            // Adicionar timestamp para evitar cache
            final urlWithTimestamp = '$url?t=${DateTime
                .now()
                .millisecondsSinceEpoch}';

            if (mounted) {
              setState(() {
                _currentFrameUrl = urlWithTimestamp;
              });
            }

            debugPrint('[DEBUG] Frame atualizado para viewer: $fileName');
          } catch (e) {
            debugPrint('[DEBUG] Erro ao baixar frame: $e');
          }
        });
  }

  void _startViewerSimulation() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _isLive) {
        setState(() {
          _viewerCount += (1 + (DateTime
              .now()
              .millisecond % 3));
        });
        _startViewerSimulation();
      }
    });
  }

  Future<void> _leaveChannel() async {
    setState(() {
      _isLive = false;
      _viewerCount = 0;
      _currentFrameUrl = null;
    });

    // Parar timers
    _frameTimer?.cancel();
    _viewerTimer?.cancel();

    // Atualizar status no Supabase
    if (widget.isHost) {
      await _updateLiveStatus(false);
      // Limpar arquivo de frame do Storage
      await _cleanupLiveFrame();
    }
  }

  /// Limpar frame da live do Storage
  Future<void> _cleanupLiveFrame() async {
    try {
      final fileName = 'live_${widget.channelName}.jpg';
      await Supabase.instance.client.storage
          .from(_bucketName)
          .remove([fileName]);
      debugPrint('[DEBUG] Frame limpo do Storage: $fileName');
    } catch (e) {
      debugPrint('[DEBUG] Erro ao limpar frame: $e');
    }
  }

  Future<void> _updateLiveStatus(bool isLive) async {
    try {
      await Supabase.instance.client.from('users').update({
        'is_live': isLive,
        'live_channel': isLive ? widget.channelName : null,
        'live_started_at': isLive ? DateTime.now().toIso8601String() : null,
      }).eq('id', widget.userId);
    } catch (e) {
      debugPrint('Erro ao atualizar status live: $e');
    }
  }

  void _toggleCamera() {
    if (_cameraController != null && _isCameraInitialized) {
      setState(() {
        _cameraEnabled = !_cameraEnabled;
      });
    }
  }

  void _toggleMic() {
    setState(() {
      _micEnabled = !_micEnabled;
    });
  }

  @override
  void dispose() {
    // Parar timers
    _frameTimer?.cancel();
    _viewerTimer?.cancel();

    // Se for host, garantir que desmarca como live ao sair
    if (widget.isHost && _isLive) {
      _updateLiveStatus(false);
      _cleanupLiveFrame();
    }
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isHost ? 'Sua Live' : 'Assistindo Live'),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
        actions: [
          if (_isLive && widget.isHost)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, color: Colors.white, size: 8),
                    const SizedBox(width: 4),
                    Text('AO VIVO • $_viewerCount',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
        ],
      ),
      backgroundColor: Colors.black87,
      body: Stack(
        children: [
          Center(
            child: _renderVideo(),
          ),
          if (!_isLive)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.videocam, size: 80, color: Colors.white54),
                  const SizedBox(height: 20),
                  Text(
                    widget.isHost
                        ? _cameraError ?? (_isCameraInitialized
                        ? 'Toque para iniciar sua live'
                        : 'Inicializando câmera...')
                        : 'Aguardando transmissão...',
                    style: const TextStyle(color: Colors.white70, fontSize: 18),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  if (widget.isHost && _isCameraInitialized &&
                      _cameraError == null)
                    ElevatedButton.icon(
                      onPressed: _joinChannel,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Iniciar Live'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 30, vertical: 15),
                      ),
                    ),
                  if (_cameraError != null)
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _cameraError!,
                        style: const TextStyle(color: Colors.red, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          // Controles da live (só para host)
          if (_isLive && widget.isHost)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    heroTag: "camera",
                    onPressed: _toggleCamera,
                    backgroundColor: _cameraEnabled ? Colors.white : Colors.red,
                    child: Icon(
                      _cameraEnabled ? Icons.videocam : Icons.videocam_off,
                      color: _cameraEnabled ? Colors.black : Colors.white,
                    ),
                  ),
                  const SizedBox(width: 20),
                  FloatingActionButton(
                    heroTag: "mic",
                    onPressed: _toggleMic,
                    backgroundColor: _micEnabled ? Colors.white : Colors.red,
                    child: Icon(
                      _micEnabled ? Icons.mic : Icons.mic_off,
                      color: _micEnabled ? Colors.black : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      floatingActionButton: _isLive
          ? FloatingActionButton(
        onPressed: _leaveChannel,
        backgroundColor: Colors.red,
        child: const Icon(Icons.call_end, color: Colors.white),
      )
          : null,
    );
  }

  Widget _renderVideo() {
    if (_isLive) {
      if (widget.isHost && _isCameraInitialized && _cameraController != null &&
          _cameraEnabled) {
        // HOST: Mostrar feed real da câmera
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: CameraPreview(_cameraController!),
        );
      } else if (!widget.isHost && _currentFrameUrl != null) {
        // VIEWER: Mostrar frame atual do host
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.black,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              _currentFrameUrl!,
              fit: BoxFit.contain,
              // Manter proporção sem cortar
              width: double.infinity,
              height: double.infinity,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) {
                  return child;
                }
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 200),
                  child: child,
                );
              },
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 10),
                        Text(
                          'Carregando...',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.red.withOpacity(0.2),
                        Colors.orange.withOpacity(0.2),
                        Colors.yellow.withOpacity(0.2),
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.signal_wifi_connected_no_internet_4,
                            size: 60, color: Colors.white70),
                        SizedBox(height: 10),
                        Text(
                          'Reconectando...',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      } else {
        // Fallback: Camera desabilitada ou aguardando stream
        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.blue.withOpacity(0.3),
                Colors.purple.withOpacity(0.3),
                Colors.pink.withOpacity(0.3),
              ],
            ),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                        widget.isHost
                            ? (_cameraEnabled ? Icons.person : Icons
                            .videocam_off)
                            : Icons.refresh,
                        size: 120,
                        color: Colors.white70
                    ),
                    const SizedBox(height: 20),
                    Text(
                      widget.isHost
                          ? (_cameraEnabled
                          ? 'Você está ao vivo!'
                          : 'Câmera desabilitada')
                          : 'Carregando stream...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    if (widget.isHost)
                      Text(
                        '$_viewerCount pessoas assistindo',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 16),
                      ),
                  ],
                ),
              ),
              // Indicadores de status da câmera e microfone
              if (widget.isHost && _isLive)
                Positioned(
                  top: 20,
                  right: 20,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _cameraEnabled ? Icons.videocam : Icons.videocam_off,
                          color: _cameraEnabled ? Colors.green : Colors.red,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _micEnabled ? Icons.mic : Icons.mic_off,
                          color: _micEnabled ? Colors.green : Colors.red,
                          size: 20,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      }
    } else {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.videocam_off, size: 80, color: Colors.white54),
            SizedBox(height: 20),
            Text(
              'Live não iniciada',
              style: TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      );
    }
  }
}