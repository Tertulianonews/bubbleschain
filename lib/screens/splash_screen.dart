import 'package:flutter/material.dart';
import 'terlinet_word_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'bubbles_home_screen.dart'; // Importa tela principal do app

/// SplashScreen com logo animado TerlineT
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )
      ..forward();

    // Timer para navegar após splash
    Future.delayed(const Duration(seconds: 2), () async {
      if (mounted) {
        // Sempre navegar para a tela de bolhas, que agora gerencia login/logout internamente
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BubblesHomeScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Fundo escuro/gradiente custom
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E14),
      body: Center(
        child: ScaleTransition(
          scale: Tween(begin: 0.7, end: 1.14).animate(
            CurvedAnimation(parent: _animController, curve: Curves.elasticOut),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo animado ou mascote exclusivo
              SizedBox(
                width: 120,
                height: 120,
                child: TerlineTWordScreen(), // Mostra o mascote principal
              ),
              const SizedBox(height: 20),
              Text(
                'Bem-vindo ao BubbleChain!',
                style: TextStyle(
                  color: Colors.blue[300],
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'tertulianonews.github.io/bubbleschain',
                style: TextStyle(
                  color: Colors.cyanAccent.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
