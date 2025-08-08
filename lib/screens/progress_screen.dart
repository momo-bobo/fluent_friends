import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'welcome_screen.dart';

class ProgressScreen extends StatelessWidget {
  final List<int> scores;
  final String sound;
  const ProgressScreen({super.key, required this.scores, required this.sound});

  String getEncouragement() {
    final avg = scores.reduce((a, b) => a + b) / scores.length;
    if (avg > 85) return "Excellent work!";
    if (avg > 70) return "You're improving nicely!";
    return "Great effort!";
    }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Progress')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text('Progress on "$sound" sound:', style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 24),
            Expanded(
              child: BarChart(
                BarChartData(
                  maxY: 100,
                  minY: 0,
                  alignment: BarChartAlignment.spaceAround,
                  barGroups: List.generate(scores.length, (i) => BarChartGroupData(
                    x: i,
                    barRods: [BarChartRodData(toY: scores[i].toDouble(), width: 20, borderRadius: BorderRadius.circular(6))],
                  )),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) => Text('Try ${v.toInt() + 1}'),
                    )),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, interval: 20)),
                  ),
                  gridData: FlGridData(show: true),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(getEncouragement(), style: const TextStyle(fontSize: 20, color: Colors.green, fontStyle: FontStyle.italic)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const WelcomeScreen()), (_) => false);
              },
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
