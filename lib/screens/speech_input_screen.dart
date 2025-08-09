import 'package:flutter/material.dart';
import '../services/speech_service.dart';
import '../utils/assessment.dart';
import 'exercise_screen.dart';

class SpeechInputScreen extends StatefulWidget {
  const SpeechInputScreen({super.key});

  @override
  State<SpeechInputScreen> createState() => _SpeechInputScreenState();
}

class _SpeechInputScreenState extends State<SpeechInputScreen> {
  final SpeechService _speechService = SpeechService();

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

  AssessmentResult? _assessment; // set after user speaks

  @override
  void initState() {
    super.initState();

    _currentSentence = _sentences[_currentSound]!.first;

    _speechService.init(onResult: (text) {
      setState(() {
        _spokenText = text;
        _isListening = false;
      });

      // Run real assessment on the recognized text vs. the prompted sentence
      final result = assessRecording(
        promptedSentence: _currentSentence,
        recognizedText: text,
      );

      setState(() {
        _assessment = result;
        _currentSound = result.targetSound; // use the assessed target going forward
      });
    });
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
    // Shuffle a sentence for the CURRENT sound we plan to practice
    final list = List<String>.from(_sentences[_currentSound] ?? ['Practice makes perfect!']);
    list.shuffle();
    setState(() {
      _currentSentence = list.first;
      _assessment = null; // reset prior result when changing prompt
      _spokenText = '';
    });
  }

  Widget _buildAssessmentCard(AssessmentResult a) {
    String encour = "Good job!";
    if (a.accuracyPercent < 70) encour = "Nice try!";
    else if (a.accuracyPercent < 85) encour = "You're getting better!";

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('Accuracy: ${a.accuracyPercent}%',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(encour, style: const TextStyle(color: Colors.green, fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),
            Text('We’ll practice "${a.targetSound}" next.',
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ExerciseScreen(sound: a.targetSound),
                  ),
                );
              },
              child: const Text('Continue to practice'),
            ),
          ],
        ),
      ),
    );
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
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isListening ? null : _newSentence,
              child: const Text('New sentence'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _toggleListening,
              child: Text(_isListening ? 'Stop' : 'Start'),
            ),
            const SizedBox(height: 20),
            const Text('You said:', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              _spokenText.isEmpty ? '—' : _spokenText,
              style: const TextStyle(fontSize: 20, color: Colors.blueAccent),
              textAlign: TextAlign.center,
            ),
            if (_assessment != null) _buildAssessmentCard(_assessment!),
          ],
        ),
      ),
    );
  }
}
