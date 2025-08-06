import 'package:flutter/material.dart';

class PepeLogo extends StatelessWidget {
  final double size;

  const PepeLogo({super.key, this.size = 80});

  @override
  Widget build(BuildContext context) {
    return Text('🫧', style: TextStyle(fontSize: size));
  }
}
