import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../widgets/gradient_button.dart';
import '../widgets/pepe_logo.dart';
import 'home_screen.dart';
import '../theme.dart';
import 'package:google_fonts/google_fonts.dart';
import 'register_screen.dart'; // Import the RegisterScreen
import 'profile_setup_screen.dart'; // Import the ProfileSetupScreen
import 'terms_privacy_screen.dart'; // IMPORT NECESSÁRIO

import 'dart:math';

class QuantumColors {
  static const neonBlue = Color(0xFF64B5F6); // Azul vivo
  static const blueLight = Color(0xFF90CAF9); // Azul claro
  static const blueVeryLight = Color(
      0xFFE3F2FD); // Azul muito claro quase branco
  static const neonGreen = Color(0xFFA5D6A7); // Não será mais usado
  static const neonYellow = Color(0xFFFFF59D); // Não será mais usado
  static const neonPurple = Color(0xFFCE93D8); // Não será mais usado
  static const neonPink = Color(0xFFF8BBD0); // Não será mais usado
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

BoxDecoration quantumGlass({required double radius}) {
  return BoxDecoration(
    color: Colors.white.withOpacity(0.75),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: QuantumColors.blueLight, width: 1.5),
  );
}

LinearGradient quantumButtonGradient = const LinearGradient(
  colors: [
    QuantumColors.neonBlue,
    QuantumColors.blueLight,
    Colors.white,
  ],
  stops: [0.0, 0.55, 1.0],
);

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
                Color.lerp(QuantumColors.neonBlue, QuantumColors.neonBlue,
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _pwd = TextEditingController();
  bool isLoading = false;
  String? errorMsg;
  bool _showPassword = false;
  String? resetMsg;
  bool _resetLoading = false;

  Future<void> _login() async {
    setState(() => isLoading = true);
    errorMsg = null;
    try {
      final resp = await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _pwd.text.trim(),
      );
      if (resp.user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  ProfileSetupScreen(userIdOverride: resp.user!.id)),
        );
      }
    } catch (e) {
      setState(() => errorMsg = "Falha no login: $e");
    }
    setState(() => isLoading = false);
  }

  void _showForgotPwdDialog(BuildContext ctx, Color accentBlue) async {
    final TextEditingController emailCtrl = TextEditingController(
        text: _email.text);
    setState(() {
      resetMsg = null;
      _resetLoading = false;
    });
    await showDialog(
      context: ctx,
      builder: (context) =>
          StatefulBuilder(
            builder: (context, setStateDialog) =>
                AlertDialog(
                  title: Text("Recuperar senha", style: GoogleFonts.orbitron(
                      fontWeight: FontWeight.bold, color: accentBlue)),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Informe seu e-mail cadastrado para receber o link de redefinição de senha.',
                          style: GoogleFonts.orbitron(fontSize: 13)),
                      const SizedBox(height: 15),
                      TextField(
                        controller: emailCtrl,
                        decoration: InputDecoration(
                          labelText: "Email",
                          labelStyle: GoogleFonts.orbitron(color: accentBlue),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      if (resetMsg != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 15),
                          child: Text(resetMsg!, style: GoogleFonts.orbitron(
                              color: accentBlue,
                              fontWeight: FontWeight.bold
                          )),
                        ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: Text("Cancelar",
                          style: GoogleFonts.orbitron(color: accentBlue)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    TextButton(
                      child: _resetLoading
                          ? SizedBox(width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  accentBlue)))
                          : Text("Enviar",
                          style: GoogleFonts.orbitron(color: accentBlue)),
                      onPressed: _resetLoading ? null : () async {
                        setStateDialog(() {
                          _resetLoading = true;
                          resetMsg = null;
                        });
                        const String kResetRedirectUrl = 'https://tertulianonews.github.io/bubbleschain/reset-password';
                        try {
                          print('RESET TO: $kResetRedirectUrl');
                          await Supabase.instance.client.auth
                              .resetPasswordForEmail(
                            emailCtrl.text.trim(),
                            redirectTo: kResetRedirectUrl,
                          );
                          setState(() =>
                          resetMsg =
                          "Email de redefinição enviado! Verifique sua caixa de entrada.");
                          setStateDialog(() => _resetLoading = false);
                        } catch (e) {
                          setState(() =>
                          resetMsg = ("Erro: " + (e
                              .toString()
                              .replaceAll(
                              RegExp(r'Exception:|SupabaseAuthException:'), '')
                              .trim())));
                          setStateDialog(() => _resetLoading = false);
                        }
                      },
                    ),
                  ],
                ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color kBubblesBlue = Color(0xFF8AC5EC);
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
                        ShaderMask(
                          shaderCallback: (rect) =>
                              quantumGradient.createShader(rect),
                          child: const PepeLogo(size: 80),
                        ),
                        const SizedBox(height: 24),
                        Text("Bubbles",
                          style: GoogleFonts.orbitron(
                            color: kBubblesBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 34,
                            letterSpacing: 3,
                            shadows: [
                              Shadow(blurRadius: 12,
                                  color: kBubblesBlue,
                                  offset: Offset(0, 0)),
                              Shadow(blurRadius: 24,
                                  color: kBubblesBlue,
                                  offset: Offset(0, 2)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Email
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                                sigmaX: 7, sigmaY: 7),
                            child: Container(
                              decoration: quantumGlass(radius: 18),
                              child: TextField(
                                controller: _email,
                                style: GoogleFonts.orbitron(
                                    color: kBubblesBlue,
                                    fontWeight: FontWeight.w600),
                                cursorColor: kBubblesBlue,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  labelText: "Email",
                                  labelStyle: TextStyle(
                                      color: kBubblesBlue),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 22),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        // Senha
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(
                                sigmaX: 7, sigmaY: 7),
                            child: Container(
                              decoration: quantumGlass(radius: 18),
                              child: TextField(
                                controller: _pwd,
                                obscureText: !_showPassword,
                                style: GoogleFonts.orbitron(
                                    color: kBubblesBlue,
                                    fontWeight: FontWeight.w600),
                                cursorColor: kBubblesBlue,
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: Colors.transparent,
                                  labelText: "Senha",
                                  labelStyle: TextStyle(
                                      color: kBubblesBlue),
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 22),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                        _showPassword
                                            ? Icons.visibility_off
                                            : Icons
                                            .visibility,
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
                        // Link esqueci senha
                        Padding(
                          padding: const EdgeInsets.only(
                              top: 7, bottom: 0),
                          child: Center(
                            child: TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: kBubblesBlue,
                                textStyle: GoogleFonts.orbitron(
                                  decoration: TextDecoration.underline,
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: const Text('Esqueceu a senha?'),
                              onPressed: () {
                                _showForgotPwdDialog(
                                    context, kBubblesBlue);
                              },
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
                        const SizedBox(height: 28),
                        OutlinedButton(
                          onPressed: isLoading ? null : _login,
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
                              : const Text("ENTRAR"),
                        ),
                        const SizedBox(height: 7),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(
                                builder: (_) => const RegisterScreen()));
                          },
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
                          child: const Text("Cadastre-se"),
                        ),
                        const SizedBox(height: 7),
                        OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TermsPrivacyScreen(),
                              ),
                            );
                          },
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
                          child: const Text("Políticas"),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 10,
            child: Center(
              child: Text(
                'TerlineT 2025 - Conectando pessoas',
                style: GoogleFonts.orbitron(
                  color: Color(0xFF185886),
                  fontWeight: FontWeight.w400,
                  fontSize: 12,
                  letterSpacing: 1.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
