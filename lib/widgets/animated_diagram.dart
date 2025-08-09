import 'package:flutter/material.dart';

class AnimatedDiagram extends StatefulWidget {
  final String sound;
  const AnimatedDiagram({super.key, required this.sound});

  @override
  State<AnimatedDiagram> createState() => _AnimatedDiagramState();
}

class _AnimatedDiagramState extends State<AnimatedDiagram> with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.98, end: 1.02).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
      child: Container(
        height: 150, width: 150,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 6))],
        ),
        child: Text('👄\nMouth Diagram\n[${widget.sound}]', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
