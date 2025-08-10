import 'package:flutter/material.dart';
import '../widgets/half_donut_gauge.dart';
import '../widgets/home_app_bar.dart';

class SessionCompleteScreen extends StatelessWidget {
  final List<int> scores; // all attempts this session
  const SessionCompleteScreen({super.key, required this.scores});

  double _avg() {
    if (scores.isEmpty) return 0;
    final total = scores.fold<int>(0, (a, b) => a + b);
    return total / scores.length;
  }

  @override
  Widget build(BuildContext context) {
    final avg = _avg();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const HomeAppBar(title: 'Home'),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HalfDonutGauge(percent: avg, size: 300, thickness: 80),
              const SizedBox(height: 20),
              const Text(
                'Good job today!\nSee you next time.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
