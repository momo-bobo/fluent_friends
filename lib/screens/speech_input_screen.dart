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

  // Sentences grouped by target sound. Add/remove as you like.
  final Map<String, List<String>> _sentences = {
    'R': [
      'The red rabbit ran rapidly.',
      'Rachel rode the roller coaster.',
      'Rain rushed down the river.',
      'Rory raised the round rock.',
    ],
    'S': [
      'Sally sells seashells by the seashore.',
      'Seven snakes slither silently.',
      'Sam saw seven seagulls.',
      'Sunny skies make smiles.',
    ],
    'Sh': [
      'The ship sails in the shining sun.',
      'She shouted to her friends.',
      'Shiny shoes should stay clean.',
      'The shy shark swam shallowly.',
    ],
  };

  String _currentSound = 'R';
  late String _currentSentence;

  String _spokenText = '';
  bool _isListening = false;

  @override
  void initState() {
    super.initState();

    // Default UI sentence before any analysis.
    _currentSentence = _sentences[_currentSound]!.first;

    // Initialize speech service and set the callback.
    _speechService.init(onResult: (text) {
      setState(() {
        _spokenText = text;
        _isListening = false;
      });

      // Analyze and navigate to exercise for the detected sound.
      final sound = _analyze(text);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ExerciseScreen(sound: sound)),
      );
    });
  }

  // Super-simple heuristic. Replace with real phoneme analysis later.
  String _analyze(String input) {
    final lower = input.toLowerCase();
    if (lower.contains('sh')) return 'Sh';
    if (lower.contains('s')) return 'S';
    if (lower.contains('r')) return 'R';
    // Fallback: keep current sound
    return _currentSound;
  }

  void _toggleListening() {
    if (_isListening) {
      _speechService.stop();
      setState(() => _isListening = false);
    } else {
      _speechService.start();
      setState(() => _isListening = true);
    }
  }

  void _newSentence() {
    // Shuffle within the current sound’s list.
    final list = List<String>.from(_sentences[_currentSound]!);
    list.shuffle();
    setState(() {
      _currentSentence = list.first;
    });
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
            const SizedBox(height: 10),
            Text(
              '"$_currentSentence"',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _isListening ? null : _newSentence,
              child: const Text('New sentence'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _toggleListening,
              child: Text(_isListening ? 'Stop' : 'Start'),
            ),
            const SizedBox(height: 24),
            const Text('You said:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              _spokenText.isEmpty ? '—' : _spokenText,
              style: const TextStyle(fontSize: 20, color: Colors.blueAccent),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
