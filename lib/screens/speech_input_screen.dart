import 'package:flutter/material.dart';
import '../widgets/centered_page.dart';
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
    'R': ['The red rabbit ran rapidly.', 'Rachel rode the roller coaster.', 'Rain rushed down the river.'],
    'S': ['Sally sells seashells by the seashore.', 'Seven snakes slither silently.', 'Sam saw seven seagulls.'],
    'Sh': ['The ship sails in the shining sun.', 'She shouted to her friends.', 'Shiny shoes should stay clean.'],
  };

  String _currentSound = 'R';
  late String _currentSentence;

  String _spokenText = '';
  bool _isListening = false;
  AssessmentResult? _assessment;

  @override
  void initState() {
    super.initState();
    _currentSentence = _sentences[_currentSound]!.first;

    _speechService.init(onResult: (text) {
      final result = assessRecording(promptedSentence: _currentSentence, recognizedText: text);
      setState(() {
        _spokenText = text;
        _assessment = result;
        _currentSound = result.targetSound;
        _isListening = false;
      });
    });
  }

  void _toggleListening() {
    if (_isListening) {
      _speechService.stop();
      setState(() => _isListening = false);
    } else {
      setState(() {
        _spokenText = '';
        _assessment = null;
        _isListening = true;
      });
      _speechService.start();
    }
  }

  void _newSentence() {
    if (_isListening) return;
    final list = List<String>.from(_sentences[_currentSound] ?? ['Practice makes perfect!'])..shuffle();
    setState(() {
      _currentSentence = list.first;
      _spokenText = '';
      _assessment = null;
    });
  }

  Widget _assessmentCard(AssessmentResult a) {
    String encour = "Good job!";
    if (a.accuracyPercent < 70) encour = "Nice try!";
    else if (a.accuracyPercent < 85) encour = "You're getting better!";
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        children: [
          Text('Accuracy: ${a.accuracyPercent}%', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(encour, style: const TextStyle(color: Colors.green, fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => ExerciseScreen(sound: a.targetSound)));
            },
            child: Text('Practice "${a.targetSound}"'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CenteredPage(
      title: 'Say This Sentence',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Please say:', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            '"$_currentSentence"',
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          TextButton(onPressed: _newSentence, child: const Text('New sentence')),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: _toggleListening,
            child: Text(_isListening ? 'Stop' : 'Start'),
          ),
          const SizedBox(height: 16),
          const Text('You said:', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            _spokenText.isEmpty ? '—' : _spokenText,
            style: const TextStyle(fontSize: 20, color: Colors.blueAccent),
            textAlign: TextAlign.center,
          ),
          if (_assessment != null) _assessmentCard(_assessment!),
        ],
      ),
    );
  }
}
