import 'package:flutter/material.dart';
import '../services/speech_service.dart';
import 'exercise_screen.dart';

class SpeechInputScreen extends StatefulWidget {
  const SpeechInputScreen({super.key});
  @override
  State<SpeechInputScreen> createState() => _SpeechInputScreenState();
}

class _SpeechInputScreenState extends State<SpeechInputScreen> {
  final SpeechService _speechService = SpeechService();
  String _spokenText = '';
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speechService.init(onResult: (text) {
      setState(() {
        _spokenText = text;
        _isListening = false;
      });
      final sound = _analyze(_spokenText);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ExerciseScreen(sound: sound)),
      );
    });
  }

  String _analyze(String input) {
    if (input.toLowerCase().contains('r')) return 'R';
    if (input.toLowerCase().contains('s')) return 'S';
    return 'Sh';
  }

  void _toggle() {
    if (_isListening) {
      _speechService.stop();
      setState(() => _isListening = false);
    } else {
      _speechService.start();
      setState(() => _isListening = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Say This Sentence')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('Please say:', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 8),
            const Text(
              '"The red rabbit ran rapidly."',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _toggle,
              child: Text(_isListening ? 'Stop' : 'Start'),
            ),
            const SizedBox(height: 16),
            const Text('You said:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              _spokenText,
              style: const TextStyle(fontSize: 20, color: Colors.blueAccent),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
