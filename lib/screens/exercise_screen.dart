import 'package:flutter/material.dart';
import '../widgets/animated_diagram.dart';
import '../widgets/score_indicator.dart';
import '../widgets/encouragement_text.dart';
import 'progress_screen.dart';

class ExerciseScreen extends StatefulWidget {
  final String sound;
  const ExerciseScreen({super.key, required this.sound});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  int attempt = 0;
  final List<int> scores = [];

  void _simulate() {
    if (attempt >= 3) return;
    final score = 60 + attempt * 10; // 60, 70, 80
    scores.add(score);
    setState(() => attempt++);

    if (attempt == 3) {
      Future.delayed(const Duration(seconds: 1), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ProgressScreen(scores: scores, sound: widget.sound),
          ),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRemaining = attempt < 3;
    return Scaffold(
      appBar: AppBar(title: Text('Practice: "${widget.sound}"')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Let’s practice the sound:', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            Text(
              '"${widget.sound}"',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.orange),
            ),
            const SizedBox(height: 24),
            AnimatedDiagram(sound: widget.sound),
            const SizedBox(height: 24),
            hasRemaining
                ? ElevatedButton(onPressed: _simulate, child: Text('Try ${attempt + 1}'))
                : const CircularProgressIndicator(),
            const SizedBox(height: 16),
            if (scores.isNotEmpty) ScoreIndicator(score: scores.last),
            if (scores.isNotEmpty) EncouragementText(score: scores.last),
          ],
        ),
      ),
    );
  }
}
