import 'package:flutter/material.dart';
import '../widgets/animated_diagram.dart';
import '../widgets/score_indicator.dart';
import '../widgets/encouragement_text.dart';
import '../widgets/centered_page.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../utils/assessment.dart';
import 'progress_screen.dart';

class ExerciseScreen extends StatefulWidget {
  final String sound; // 'R', 'S', 'Sh'
  const ExerciseScreen({super.key, required this.sound});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  final SpeechService _speechService = SpeechService();
  final TtsService _tts = TtsService();

  // Practice prompts per sound. Tweak/add as needed.
  final Map<String, List<String>> _prompts = {
    'R': ['rabbit', 'river', 'rocket', 'red rock', 'run rapidly', 'round ring'],
    'S': ['sun', 'sand', 'seven snakes', 'see the sea', 'sweet soup', 'silly socks'],
    'Sh': ['ship', 'shoe', 'shiny shell', 'short shadow', 'sheep in the shed', 'show the shape'],
  };

  int attempt = 0;
  final List<int> scores = [];

  String _currentPrompt = '';
  String _spokenText = '';
  bool _isListening = false;
  AssessmentResult? _assessment;

  @override
  void initState() {
    super.initState();

    // Initialize first prompt for this sound
    final list = _prompts[widget.sound] ?? const ['Practice makes perfect!'];
    _currentPrompt = list.first;

    // Init TTS
    _tts.init();

    // Init speech recognition and score each attempt
    _speechService.init(onResult: (text) {
      final result = assessRecording(
        promptedSentence: _currentPrompt,
        recognizedText: text,
      );
      setState(() {
        _spokenText = text;
        _assessment = result;
        scores.add(result.accuracyPercent.round());
        attempt++;
        _isListening = false;
      });

      if (attempt >= 3) {
        // Let them see the last feedback briefly, then go to progress
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted) return;
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ProgressScreen(scores: scores, sound: widget.sound),
            ),
          );
        });
      }
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

  void _newPrompt() {
    if (_isListening) return;
    final list = List<String>.from(_prompts[widget.sound] ?? const ['Practice makes perfect!'])..shuffle();
    setState(() {
      _currentPrompt = list.first;
      _spokenText = '';
      _assessment = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasRemaining = attempt < 3;

    return CenteredPage(
      title: 'Practice: "${widget.sound}"',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Try saying:', style: TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            '"$_currentPrompt"',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),

          // 🔊 Hear it + New prompt row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: 'Hear it',
                onPressed: () => _tts.speak(_currentPrompt),
                icon: const Icon(Icons.volume_up),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _newPrompt,
                child: const Text('New word/phrase'),
              ),
            ],
          ),

          const SizedBox(height: 12),
          AnimatedDiagram(sound: widget.sound),
          const SizedBox(height: 12),

          if (hasRemaining)
            ElevatedButton(
              onPressed: _toggleListening,
              child: Text(_isListening ? 'Stop' : 'Try ${attempt + 1}'),
            )
          else
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: CircularProgressIndicator(),
            ),

          const SizedBox(height: 16),
          const Text('You said:', style: TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            _spokenText.isEmpty ? '—' : _spokenText,
            style: const TextStyle(fontSize: 20, color: Colors.blueAccent),
            textAlign: TextAlign.center,
          ),

          if (_assessment != null) ...[
            const SizedBox(height: 16),
            ScoreIndicator(score: _assessment!.accuracyPercent.round()),
            EncouragementText(score: _assessment!.accuracyPercent.round()),
          ],

          const SizedBox(height: 8),
          Text('Attempts: $attempt / 3', style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }
}
