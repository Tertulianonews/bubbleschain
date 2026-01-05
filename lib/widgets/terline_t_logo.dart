import 'dart:math';
import 'package:flutter/material.dart';

/// Representa uma partícula flutuante com física de movimento e colisão
class FloatingParticle {
  double x;
  double y;
  double velocityX;
  double velocityY;
  double size;
  final double mass;
  
  FloatingParticle({
    required this.x,
    required this.y,
    required this.velocityX,
    required this.velocityY,
    required this.size,
    required this.mass,
  });
}

/// Logo TerlineT no estilo destacado futurista (letras T maiores)
/// com partículas em movimento orgânico simulando um anel de asteroides.
class TerlineTLogo extends StatefulWidget {
  final double width;

  const TerlineTLogo({this.width = 300, super.key});

  @override
  State<TerlineTLogo> createState() => _TerlineTLogoState();
}

class _TerlineTLogoState extends State<TerlineTLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<FloatingParticle> _floatingParticles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    
    // Inicializar partículas flutuantes
    _initFloatingParticles();
  }
  
  /// Inicializa as partículas flutuantes com posições e velocidades aleatórias
  void _initFloatingParticles() {
    final random = Random();
    _floatingParticles = List.generate(200, (i) { // Aumentado para 200
      // Posição inicial em um círculo externo
      final angle = random.nextDouble() * 2 * pi;
      final distance = widget.width * 0.85 + random.nextDouble() * (widget.width * 0.15);
      
      final centerX = widget.width / 2;
      final centerY = widget.width / 2;
      
      final x = centerX + cos(angle) * distance;
      final y = centerY + sin(angle) * distance;
      
      // Velocidade com mais variação aleatória
      final angleToCenter = atan2(centerY - y, centerX - x);
      final angleVariation = (random.nextDouble() - 0.5) * 0.8; // Adiciona variação angular
      final finalAngle = angleToCenter + angleVariation;
      final speed = 1.2 + random.nextDouble() * 1.5; // Velocidade bem aumentada (era 0.6-1.5, agora 1.2-2.7)
      
      return FloatingParticle(
        x: x,
        y: y,
        velocityX: cos(finalAngle) * speed,
        velocityY: sin(finalAngle) * speed,
        size: widget.width * 0.004 + random.nextDouble() * (widget.width * 0.008), // Tamanho micro (era 0.012-0.037, agora 0.004-0.012)
        mass: 0.8 + random.nextDouble() * 0.4,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.width,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          // Atualizar física das partículas flutuantes
          _updateFloatingParticles();
          
          return Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Partículas do anel de asteroides
              ..._buildAsteroidRing(),
              // Logo principal
              _buildLogo(),
              // Partículas flutuantes com colisão (por cima)
              ..._buildFloatingParticles(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLogo() {
    return Center(
      child: OverflowBox(
        maxWidth: double.infinity,
        child: Transform.translate(
          offset: const Offset(0, 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                "T",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF00CCFF),
                ),
              ),
              const SizedBox(width: 4),
              Transform.translate(
                offset: const Offset(0, -5),
                child: Text(
                  "ERLINE",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00CCFF),
                    letterSpacing: 14,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                "T",
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF00CCFF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Atualiza a física das partículas flutuantes (movimento e colisões)
  void _updateFloatingParticles() {
    final centerX = widget.width / 2;
    final centerY = widget.width / 2;
    final ringRadius = widget.width * 0.48;
    final ringThickness = widget.width * 0.1;
    
    for (var particle in _floatingParticles) {
      // Atualizar posição baseada na velocidade
      particle.x += particle.velocityX;
      particle.y += particle.velocityY;
      
      // Calcular distância do centro
      final dx = particle.x - centerX;
      final dy = particle.y - centerY;
      final distanceFromCenter = sqrt(dx * dx + dy * dy);
      
      // Verificar colisão com o anel de asteroides
      final distanceFromRing = (distanceFromCenter - ringRadius).abs();
      
      if (distanceFromRing < ringThickness && distanceFromCenter > ringRadius * 0.8) {
        // Partícula colidiu com o anel - calcular ricochete
        final angle = atan2(dy, dx);
        
        // Calcular vetor normal da superfície do anel
        final normalX = cos(angle);
        final normalY = sin(angle);
        
        // Calcular velocidade em relação à normal
        final dotProduct = particle.velocityX * normalX + particle.velocityY * normalY;
        
        // Reflexão da velocidade (ricochete) com coeficiente de restituição
        final restitution = 0.8;
        particle.velocityX = particle.velocityX - 2 * dotProduct * normalX * restitution;
        particle.velocityY = particle.velocityY - 2 * dotProduct * normalY * restitution;
        
        // Adicionar pequena perturbação aleatória para variação
        final random = Random();
        particle.velocityX += (random.nextDouble() - 0.5) * 0.1;
        particle.velocityY += (random.nextDouble() - 0.5) * 0.1;
        
        // Empurrar partícula para fora da zona de colisão
        final pushDistance = ringThickness * 1.2;
        if (distanceFromCenter < ringRadius) {
          particle.x = centerX + normalX * (ringRadius - pushDistance);
          particle.y = centerY + normalY * (ringRadius - pushDistance);
        } else {
          particle.x = centerX + normalX * (ringRadius + pushDistance);
          particle.y = centerY + normalY * (ringRadius + pushDistance);
        }
      }
      
      // Reposicionar partícula se sair muito da tela ou entrar no anel
      if (particle.x < -widget.width * 0.5 || particle.x > widget.width * 1.5 ||
          particle.y < -widget.width * 0.5 || particle.y > widget.width * 1.5 ||
          distanceFromCenter < ringRadius * 0.7) {
        // Reposicionar em um círculo externo em direção aleatória
        final random = Random();
        final angle = random.nextDouble() * 2 * pi;
        final distance = widget.width * 0.85 + random.nextDouble() * (widget.width * 0.15);
        
        particle.x = centerX + cos(angle) * distance;
        particle.y = centerY + sin(angle) * distance;
        
        // Nova velocidade com variação aleatória
        final angleToCenter = atan2(centerY - particle.y, centerX - particle.x);
        final angleVariation = (random.nextDouble() - 0.5) * 0.8;
        final finalAngle = angleToCenter + angleVariation;
        final speed = 1.2 + random.nextDouble() * 1.5; // Velocidade aumentada
        particle.velocityX = cos(finalAngle) * speed;
        particle.velocityY = sin(finalAngle) * speed;
      }
      
      // Adicionar pequena força aleatória para movimento mais orgânico
      final random = Random();
      if (random.nextDouble() < 0.08) { // 8% de chance a cada frame (era 5%)
        particle.velocityX += (random.nextDouble() - 0.5) * 0.3;
        particle.velocityY += (random.nextDouble() - 0.5) * 0.3;
      }
      
      // Limitar velocidade máxima
      final speed = sqrt(particle.velocityX * particle.velocityX + 
                        particle.velocityY * particle.velocityY);
      if (speed > 3.0) { // Aumentado para 3.0 (era 2.0)
        particle.velocityX = (particle.velocityX / speed) * 3.0;
        particle.velocityY = (particle.velocityY / speed) * 3.0;
      }
    }
  }
  
  /// Renderiza as partículas flutuantes
  List<Widget> _buildFloatingParticles() {
    final List<Widget> particles = [];
    final animation = _controller.value * 2 * pi;
    
    for (int i = 0; i < _floatingParticles.length; i++) {
      final particle = _floatingParticles[i];
      
      particles.add(
        Positioned(
          left: particle.x - particle.size / 2,
          top: particle.y - particle.size / 2,
          child: Transform.scale(
            scale: 1.0 + sin(animation * 2 + i) * 0.15,
            child: Opacity(
              opacity: (0.85 + 0.15 * sin(animation * 3 + i)).clamp(0.6, 1.0),
              child: Container(
                width: particle.size,
                height: particle.size,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700), // Cor dourada
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD700).withOpacity(0.8),
                      blurRadius: widget.width * 0.03,
                      spreadRadius: widget.width * 0.01,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: widget.width * 0.015,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return particles;
  }

  /// Cria partículas com movimento orbital circular (anel de asteroides)
  List<Widget> _buildAsteroidRing() {
    final random = Random(42);
    final List<Widget> particles = [];
    const int particleCount = 80;

    // Centro do anel
    final centerX = widget.width / 2;
    final centerY = widget.width / 2;

    // Raio do anel ao redor do texto TerlineT
    final baseOrbitRadius = widget.width * 0.48;

    for (int i = 0; i < particleCount; i++) {
      final baseAngle = (i / particleCount) * 2 * pi;
      final speed = 0.05 + random.nextDouble() * 0.10; // Velocidade reduzida (era 0.15-0.40, agora 0.05-0.15)

      // Tamanho das partículas
      final size = widget.width * 0.015 + random.nextDouble() * (widget.width * 0.025);

      // Variação no raio - apenas para FORA
      final orbitRadius = baseOrbitRadius +
          (sin(i * 0.5).abs() * (widget.width * 0.05)) +
          random.nextDouble() * (widget.width * 0.08);

      final baseOpacity = 0.8 + random.nextDouble() * 0.2;
      final verticalVariation = widget.width * 0.005 + random.nextDouble() * (widget.width * 0.01);
      final verticalSpeed = 0.1 + random.nextDouble() * 0.3;

      final animation = _controller.value * 2 * pi;
      final orbitalAngle = baseAngle + animation * speed;

      // Coordenadas na órbita circular
      final x = centerX + cos(orbitalAngle) * orbitRadius;
      final y = centerY +
          sin(orbitalAngle) * orbitRadius +
          sin(animation * verticalSpeed + i) * verticalVariation;

      final depthFactor = 0.8 + random.nextDouble() * 0.4;
      final finalSize = size * depthFactor;
      final finalOpacity = baseOpacity * depthFactor.clamp(0.7, 1.0);

      final isClusterLeader = random.nextDouble() < 0.35;

      particles.add(
        Positioned(
          left: x - finalSize / 2,
          top: y - finalSize / 2,
          child: Transform.scale(
            scale: 1.0 + sin(animation * 3 + i) * 0.2,
            child: Opacity(
              opacity: (finalOpacity * (0.9 + 0.1 * sin(animation * 2 + i))).clamp(0.4, 1.0),
              child: Container(
                width: finalSize,
                height: finalSize,
                decoration: BoxDecoration(
                  color: const Color(0xFF00CCFF),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00CCFF).withOpacity(isClusterLeader ? 0.95 : 0.7),
                      blurRadius: isClusterLeader ? widget.width * 0.04 : widget.width * 0.02,
                      spreadRadius: isClusterLeader ? widget.width * 0.015 : widget.width * 0.008,
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(isClusterLeader ? 0.4 : 0.2),
                      blurRadius: isClusterLeader ? widget.width * 0.02 : widget.width * 0.01,
                      spreadRadius: 0,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return particles;
  }
}
