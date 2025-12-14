import 'package:flutter/material.dart';

/// Logo TerlineT no estilo destacado futurista (letras T maiores).
class TerlineTLogo extends StatelessWidget {
  final double width;

  const TerlineTLogo({this.width = 100, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Wrapper garante largura suficiente e centraliza o bloco, depois desloca visualmente
        SizedBox(
          width: width * 1.3,
          child: Align(
            alignment: Alignment.centerLeft,
            child: Transform.translate(
              offset: const Offset(-73, 0),
              // agora usa translate em vez de padding
              // valor negativo move para esquerda O LOGO TODO e não dá erro
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: "T",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF00CCFF),
                        letterSpacing: 16, // manter o espaçamento amplo
                      ),
                    ),
                    TextSpan(
                      text: "ERLINE",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF00CCFF),
                        letterSpacing: 16, // mesmo espaçamento para todo nome
                      ),
                    ),
                    TextSpan(
                      text: "T",
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF00CCFF),
                        letterSpacing: 16,
                      ),
                    ),
                  ],
                ),
                softWrap: false,
                overflow: TextOverflow.visible,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
