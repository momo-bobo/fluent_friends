import 'package:flutter/material.dart';
import '../widgets/centered_page.dart';
import 'speech_input_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CenteredPage(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Fluent Friends', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(
            'Practice speaking with friendly, positive feedback.',
            style: Theme.of(context).textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // Cute emoji mascot placeholder
          const Text('🗣️', style: TextStyle(fontSize: 64)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SpeechInputScreen()));
            },
            child: const Text('Start Speaking Practice'),
          ),
          const SizedBox(height: 12),
          Text(
            'No login required • Kid-friendly UI • Encouraging feedback',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
