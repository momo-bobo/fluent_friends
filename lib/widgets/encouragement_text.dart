import 'package:flutter/material.dart';

class EncouragementText extends StatelessWidget {
  final int score;
  const EncouragementText({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    String message = "Good job!";
    if (score < 70) message = "Nice try!";
    else if (score < 85) message = "You're getting better!";
    return Padding(
      padding: const EdgeInsets.only(top: 12.0),
      child: Text(message, style: const TextStyle(fontSize: 18, fontStyle: FontStyle.italic, color: Colors.green)),
    );
  }
}
