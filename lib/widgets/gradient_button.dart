import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final VoidCallback onTap;
  final String title;
  final Gradient gradient;
  final bool isLoading;
  final TextStyle? font;
  final bool neon;

  const GradientButton({
    super.key,
    required this.onTap,
    required this.title,
    required this.gradient,
    this.isLoading = false,
    this.font,
    this.neon = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: neon ? [
            BoxShadow(color: Colors.greenAccent.withOpacity(0.45),
                blurRadius: 20,
                spreadRadius: 2)
          ] : [],
          border: Border.all(color: Colors.white.withOpacity(0.3), width: 2),
        ),
        child: Center(
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.black)
              : Text(
            title,
            style: font ?? const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
              fontSize: 18,
            ),
          ),
        ),
      ),
    );
  }
}
