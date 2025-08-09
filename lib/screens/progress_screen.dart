import 'package:flutter/material.dart';
import '../widgets/half_donut_gauge.dart';
import 'welcome_screen.dart';

class ProgressScreen extends StatelessWidget {
  final List<int> scores; // 3 attempts
  final String sound;

  const ProgressScreen({super.key, required this.scores, required this.sound});

  double _avgScore() {
    if (scores.isEmpty) return 0;
    final total = scores.fold<int>(0, (a, b) => a + b);
    return total / scores.length;
  }

  String _encouragement(double avg) {
    // keep it simple with a few tasteful phrases
    if (avg < 25) return "Good start!";
    if (avg < 50) return "Keep going!";
    if (avg < 75) return "Nice progress!";
    if (avg < 90) return "Great job!";
    return "Fantastic!";
  }

  @override
  Widget build(BuildContext context) {
    final avg = _avgScore();

    return Scaffold(
      backgroundColor: Colors.white, // clean white
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Your Progress', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '“$sound” practice',
                  style: const TextStyle(fontSize: 18, color: Colors.black54),
                ),
                const SizedBox(height: 8),
                HalfDonutGauge(percent: avg, size: 280, thickness: 26),
                const SizedBox(height: 12),
                Text(
                  _encouragement(avg),
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.green,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
                      (_) => false,
                    );
                  },
                  child: const Text('Back to Home'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
