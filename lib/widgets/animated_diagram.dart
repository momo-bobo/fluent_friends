import 'package:flutter/material.dart';

class AnimatedDiagram extends StatelessWidget {
  final String sound;
  const AnimatedDiagram({super.key, required this.sound});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 150, width: 150,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('👄\nMouth Diagram\n[$sound]', textAlign: TextAlign.center, style: const TextStyle(fontSize: 18)),
    );
  }
}
