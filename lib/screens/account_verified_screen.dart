import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/pepe_logo.dart';

class AccountVerifiedScreen extends StatelessWidget {
  const AccountVerifiedScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: 390),
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.81),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(blurRadius: 36, color: Colors.blue.withOpacity(0.1))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const PepeLogo(size: 62),
              SizedBox(height: 16),
              Text("Conta verificada!",
                  style: GoogleFonts.orbitron(fontSize: 23,
                      color: Color(0xFF185886),
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text(
                "Seu e-mail foi confirmado com sucesso.\nAgora você pode acessar todos os recursos do Bubbles Chat.",
                style: GoogleFonts.orbitron(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF8AC5EC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                    textStyle: GoogleFonts.orbitron(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                onPressed: () =>
                    Navigator.of(context).pushReplacementNamed('/'),
                child: Text("Ir para o login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
