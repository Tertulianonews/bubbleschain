import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';
import 'login_screen.dart'
    show QuantumAnimatedBackground; // Importa só o fundo animado

class TermsPrivacyScreen extends StatelessWidget {
  const TermsPrivacyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Termos de Uso e Política de Privacidade',
          style: GoogleFonts.orbitron(
              fontWeight: FontWeight.bold, fontSize: 19),
        ),
        backgroundColor: QuantumColors.black,
        iconTheme: const IconThemeData(color: QuantumColors.white),
        elevation: 2,
      ),
      backgroundColor: QuantumColors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Termos de Uso',
              style: GoogleFonts.orbitron(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: QuantumColors.neonGreen,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Ao criar uma conta, você concorda em utilizar o aplicativo de forma íntegra, respeitando outros usuários e as leis vigentes. Reservamo-nos o direito de suspender contas que violem nossos princípios, promovam conteúdos ilegais, discriminatórios, abusivos ou não autorizados. Você é responsável por suas informações publicadas e pelo conteúdo compartilhado em nossa plataforma. Este ambiente visa conectar pessoas buscando diálogo respeitoso e seguro.',
              style: GoogleFonts.orbitron(
                  fontSize: 15, color: QuantumColors.white.withOpacity(0.93)),
            ),
            const SizedBox(height: 28),
            Text(
              'Política de Privacidade',
              style: GoogleFonts.orbitron(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: QuantumColors.neonGreen,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Suas informações cadastradas são protegidas e utilizadas apenas para melhorar sua experiência, enviar notificações e garantir a segurança da comunidade. Não compartilhamos seus dados com terceiros sem autorização legal, exceto em casos previstos em lei. Utilizamos padrões avançados de segurança e criptografia, similares aos das principais redes sociais, priorizando sua privacidade e proteção dos seus dados.',
              style: GoogleFonts.orbitron(
                  fontSize: 15, color: QuantumColors.white.withOpacity(0.93)),
            ),
            const SizedBox(height: 24),
            Text(
              'Atualizações',
              style: GoogleFonts.orbitron(fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: QuantumColors.neonGreen),
            ),
            const SizedBox(height: 8),
            Text(
              'Os Termos de Uso e a Política de Privacidade podem ser atualizados a qualquer momento. Recomendamos que revise periodicamente estes documentos pelo app.',
              style: GoogleFonts.orbitron(
                  fontSize: 15, color: QuantumColors.white.withOpacity(0.89)),
            ),
          ],
        ),
      ),
    );
  }
}
