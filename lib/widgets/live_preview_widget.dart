import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LivePreviewWidget extends StatefulWidget {
  final String userId;
  final String channelName;
  final double size;
  final bool isOwn;

  const LivePreviewWidget({
    Key? key,
    required this.userId,
    required this.channelName,
    required this.size,
    required this.isOwn,
  }) : super(key: key);

  @override
  State<LivePreviewWidget> createState() => _LivePreviewWidgetState();
}

class _LivePreviewWidgetState extends State<LivePreviewWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _waveController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;
  late Animation<double> _glowAnimation;

  // Câmera para preview próprio
  CameraController? _cameraController;
  bool _isCameraInitialized = false;

  // Para viewers - mostrar frame real da live
  String? _currentFrameUrl;
  Timer? _previewTimer;
  final String _bucketName = 'live_frames';

  @override
  void initState() {
    super.initState();

    // Controlador principal para pulso
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Controlador para ondas de transmissão
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    // Animação de pulso suave
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Animação de ondas concêntricas
    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeOut,
    ));

    // Animação de brilho pulsante
    _glowAnimation = Tween<double>(
      begin: 0.5,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Iniciar todas as animações
    _pulseController.repeat(reverse: true);
    _waveController.repeat();

    // Inicializar conteúdo baseado no tipo de usuário
    if (widget.isOwn) {
      _initializeCamera();
    } else {
      _startPreviewFrameViewing();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final status = await Permission.camera.request();
      if (status != PermissionStatus.granted) return;

      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      final frontCamera = cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        frontCamera,
        ResolutionPreset.low,
        enableAudio: false, // Só preview, sem áudio
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _cameraController!.initialize();

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('[DEBUG] Erro ao inicializar câmera para preview: $e');
    }
  }

  /// Iniciar visualização de frames para preview (VIEWER)
  void _startPreviewFrameViewing() {
    if (widget.isOwn) return;

    _previewTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      try {
        final fileName = 'live_${widget.channelName}.jpg';
        final url = Supabase.instance.client.storage
            .from(_bucketName)
            .getPublicUrl(fileName);
        final urlWithTimestamp = '$url?t=${DateTime.now().millisecondsSinceEpoch}';

        if (mounted) {
          setState(() {
            _currentFrameUrl = urlWithTimestamp;
          });
        }
      } catch (e) {
        // Silently fail for preview
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _waveController.dispose();
    _cameraController?.dispose();
    _previewTimer?.cancel();
    super.dispose();
  }

  Widget _buildLiveIndicator() {
    return AnimatedBuilder(
      animation: Listenable.merge([_pulseController, _waveController]),
      builder: (context, child) {
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
              // Ícone de transmissão ao vivo
              Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(_glowAnimation.value),
                        blurRadius: 3,
                        spreadRadius: 0.5,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 5),
              // Texto AO VIVO
              const Text(
                'AO VIVO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Conteúdo principal da bolha
          Container(
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: widget.isOwn
                  ? _buildCameraPreview()
                  : _buildFramePreview(),
            ),
          ),

          // Indicador de LIVE posicionado no topo da bolha
          Positioned(
            top: -5,
            child: _buildLiveIndicator(),
          ),
        ],
      ),
    );
  }

  /// Widget para preview da própria câmera
  Widget _buildCameraPreview() {
    if (!_isCameraInitialized || _cameraController == null) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF2196F3),
              Color(0xFF1976D2),
            ],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.camera_alt,
            color: Colors.white,
            size: 32,
          ),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: _cameraController!.value.aspectRatio,
      child: CameraPreview(_cameraController!),
    );
  }

  /// Widget para preview dos frames (viewers)
  Widget _buildFramePreview() {
    if (_currentFrameUrl == null) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF9C27B0),
              Color(0xFF673AB7),
            ],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.live_tv,
            color: Colors.white,
            size: 32,
          ),
        ),
      );
    }

    return Image.network(
      _currentFrameUrl!,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFFF5722),
                Color(0xFFE64A19),
              ],
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 32,
            ),
          ),
        );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF607D8B),
                Color(0xFF455A64),
              ],
            ),
          ),
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2,
            ),
          ),
        );
      },
    );
  }
}