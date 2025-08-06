import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme.dart';
import 'package:google_fonts/google_fonts.dart';

class QuantumColors {
  static const neonBlue = Color(0xFF64B5F6); // Azul vivo
  static const blueLight = Color(0xFF90CAF9); // Azul claro
  static const blueVeryLight = Color(
      0xFFE3F2FD); // Azul muito claro quase branco
  static const black = Color(0xFF000000);
}

LinearGradient quantumGradient = const LinearGradient(
  colors: [
    QuantumColors.neonBlue,
    QuantumColors.blueLight,
    Colors.white,
    QuantumColors.blueVeryLight
  ],
  stops: [0.0, 0.35, 0.8, 1.0],
);

LinearGradient quantumButtonGradient = const LinearGradient(
  colors: [
    QuantumColors.neonBlue,
    QuantumColors.blueLight,
    Colors.white,
  ],
  stops: [0.0, 0.55, 1.0],
);

BoxDecoration quantumGlass({required double radius}) {
  return BoxDecoration(
    color: Colors.white.withOpacity(0.75),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: QuantumColors.blueLight, width: 1.5),
  );
}

class QuantumAnimatedBackground extends StatefulWidget {
  const QuantumAnimatedBackground({super.key});

  @override
  State<QuantumAnimatedBackground> createState() =>
      _QuantumAnimatedBackgroundState();
}

class _QuantumAnimatedBackgroundState extends State<QuantumAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller =
    AnimationController(vsync: this, duration: const Duration(seconds: 14))
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, __) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color.lerp(QuantumColors.neonBlue, QuantumColors.blueLight,
                    _controller.value)!,
                Color.lerp(Colors.white, QuantumColors.blueVeryLight,
                    1 - _controller.value)!,
                Color.lerp(QuantumColors.neonBlue, QuantumColors.blueLight,
                    _controller.value / 2)!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      },
    );
  }
}

const Color kBubblesBlue = Color(0xFF8AC5EC);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _email = TextEditingController();
  final _pwd = TextEditingController();
  final _pwdRepeat = TextEditingController();
  bool isLoading = false;
  String? errorMsg;
  String? infoMsg;
  bool _showPassword = false;
  bool _showRepeatPassword = false;

  Future<void> _register() async {
    setState(() {
      isLoading = true;
      errorMsg = null;
      infoMsg = null;
    });
    if (_pwd.text.trim() != _pwdRepeat.text.trim()) {
      setState(() {
        errorMsg = 'As senhas não coincidem.';
        isLoading = false;
      });
      return;
    }
    if (_pwd.text
        .trim()
        .length < 6) {
      setState(() {
        errorMsg = 'A senha deve ter no mínimo 6 caracteres.';
        isLoading = false;
      });
      return;
    }
    try {
      final resp = await Supabase.instance.client.auth.signUp(
        email: _email.text.trim(),
        password: _pwd.text.trim(),
      );
      setState(() {
        infoMsg = 'Quase lá! Confira seu e-mail para ativar sua conta.';
      });
    } catch (e) {
      setState(() {
        errorMsg = 'Erro no cadastro: $e';
      });
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const QuantumAnimatedBackground(),
          Center(
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 390),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("CADASTRO",
                          style: GoogleFonts.orbitron(
                            color: kBubblesBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 32,
                            letterSpacing: 2.5,
                            shadows: [
                              Shadow(blurRadius: 12,
                                  color: kBubblesBlue,
                                  offset: Offset(0, 0)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                            child: Container(
                              decoration: quantumGlass(radius: 18),
                              child: TextField(
                                controller: _email,
                                style: GoogleFonts.orbitron(color: kBubblesBlue,
                                    fontWeight: FontWeight.w600),
                                cursorColor: kBubblesBlue,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  labelText: "Email",
                                  labelStyle: TextStyle(color: kBubblesBlue),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 22),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                            child: Container(
                              decoration: quantumGlass(radius: 18),
                              child: TextField(
                                controller: _pwd,
                                obscureText: !_showPassword,
                                style: GoogleFonts.orbitron(color: kBubblesBlue,
                                    fontWeight: FontWeight.w600),
                                cursorColor: kBubblesBlue,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  labelText: "Senha",
                                  labelStyle: TextStyle(color: kBubblesBlue),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 22),
                                  suffixIcon: IconButton(
                                    icon: Icon(_showPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                        color: kBubblesBlue),
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
                        const SizedBox(height: 18),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
                            child: Container(
                              decoration: quantumGlass(radius: 18),
                              child: TextField(
                                controller: _pwdRepeat,
                                obscureText: !_showRepeatPassword,
                                style: GoogleFonts.orbitron(color: kBubblesBlue,
                                    fontWeight: FontWeight.w600),
                                cursorColor: kBubblesBlue,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  labelText: "Repetir senha",
                                  labelStyle: TextStyle(color: kBubblesBlue),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 22),
                                  suffixIcon: IconButton(
                                    icon: Icon(_showRepeatPassword ? Icons
                                        .visibility_off : Icons.visibility,
                                        color: kBubblesBlue),
                                    onPressed: () {
                                      setState(() {
                                        _showRepeatPassword =
                                        !_showRepeatPassword;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (errorMsg != null) Padding(
                          padding: const EdgeInsets.only(top: 13),
                          child: Text(
                              errorMsg!, style: TextStyle(
                              color: kBubblesBlue, fontFamily: GoogleFonts
                              .orbitron()
                              .fontFamily)),
                        ),
                        if (infoMsg != null) Padding(
                          padding: const EdgeInsets.only(top: 13),
                          child: Text(
                              infoMsg!, style: TextStyle(
                              color: kBubblesBlue, fontFamily: GoogleFonts
                              .orbitron()
                              .fontFamily)),
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          onPressed: isLoading ? null : _register,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kBubblesBlue,
                            backgroundColor: QuantumColors.blueVeryLight,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            side: BorderSide(
                                color: kBubblesBlue, width: 1.7),
                            elevation: 0,
                            fixedSize: const Size(180, 40),
                            textStyle: GoogleFonts.orbitron(
                                fontWeight: FontWeight.bold, fontSize: 16,
                                color: kBubblesBlue),
                          ),
                          child: isLoading
                              ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  kBubblesBlue),
                              strokeWidth: 2.8,
                            ),
                          )
                              : const Text("CADASTRAR"),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: kBubblesBlue,
                            backgroundColor: QuantumColors.blueVeryLight,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            side: BorderSide(
                                color: kBubblesBlue, width: 1.7),
                            elevation: 0,
                            fixedSize: const Size(180, 40),
                            textStyle: GoogleFonts.orbitron(
                                fontWeight: FontWeight.bold, fontSize: 16,
                                color: kBubblesBlue),
                          ),
                          child: const Text("Voltar"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 24,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text.rich(
                    TextSpan(
                      text: 'Ao continuar, você concorda com nossos ',
                      style: GoogleFonts.orbitron(
                        color: kBubblesBlue,
                        fontWeight: FontWeight.w400,
                        fontSize: 11,
                      ),
                      children: [
                        TextSpan(
                          text: 'Termos de Uso e Política de Privacidade',
                          style: GoogleFonts.orbitron(
                            color: kBubblesBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 6),
                  Text(
                    'TerlineT 2025 - Conectando pessoas',
                    style: GoogleFonts.orbitron(
                      color: kBubblesBlue,
                      fontWeight: FontWeight.w400,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
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
