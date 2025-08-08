import 'package:flutter/material.dart';

class ScoreIndicator extends StatelessWidget {
  final int score;
  const ScoreIndicator({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Accuracy: $score%', style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 8),
        LinearProgressIndicator(value: score / 100, minHeight: 10),
      ],
    );
  }
}
