import 'package:flutter/material.dart';
import 'dart:math' as math;

class MagicEntryButton extends StatefulWidget {
  final VoidCallback onTap;
  const MagicEntryButton({super.key, required this.onTap});

  @override
  State<MagicEntryButton> createState() => _MagicEntryButtonState();
}

class _MagicEntryButtonState extends State<MagicEntryButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // ── THE REVOLVING ANIMATION ENGINE ──
    _controller = AnimationController(
      vsync: this, 
      duration: const Duration(seconds: 3)
    )..repeat(); // Loops forever
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(2.5), // This acts as the border width
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.3),
                  blurRadius: 12,
                  spreadRadius: 2,
                  offset: const Offset(0, 4),
                )
              ],
              // ── THE REVOLVING BORDER GRADIENT ──
              gradient: SweepGradient(
                colors: const [
                  Color(0xFFFFC300), // Yellow
                  Colors.pinkAccent, // Pink
                  Colors.deepPurpleAccent, // Purple
                  Color(0xFFFFC300), // Yellow (must match start to loop seamlessly)
                ],
                transform: GradientRotation(_controller.value * 2 * math.pi),
              ),
            ),
            child: child,
          );
        },
        // ── THE INNER JADE TO MANGO BUTTON ──
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [
                Color(0xFF3EB489), // Jade Green
                Color(0xFFFFC300), // Mango Yellow
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                "Magic Entry",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}