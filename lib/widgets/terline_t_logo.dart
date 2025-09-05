import 'package:flutter/material.dart';

/// Logo TerlineT no estilo destacado futurista (letras T maiores).
class TerlineTLogo extends StatelessWidget {
  final bool showUnderline;
  final double width;

  const TerlineTLogo({this.showUnderline = true, this.width = 220, super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: "TERLINET".split("").map((letter) {
            final isT = letter == 'T';
            return Text(
              letter,
              style: TextStyle(
                fontSize: isT ? 36 : 26,
                fontWeight: isT ? FontWeight.w900 : FontWeight.bold,
                color: const Color(0xFF00CCFF),
              ),
            );
          }).toList(),
        ),
        if (showUnderline) ...[
          const SizedBox(height: 8),
          Container(
            width: width,
            height: 4,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF00CCFF).withOpacity(0.0),
                  const Color(0xFF00CCFF).withOpacity(0.3),
                  const Color(0xFF00CCFF).withOpacity(0.8),
                  const Color(0xFF00CCFF).withOpacity(1.0),
                  const Color(0xFF00CCFF).withOpacity(0.8),
                  const Color(0xFF00CCFF).withOpacity(0.3),
                  const Color(0xFF00CCFF).withOpacity(0.0),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ]
      ],
    );
  }
}
