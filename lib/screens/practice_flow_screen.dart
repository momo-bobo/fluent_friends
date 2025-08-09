import 'package:flutter/material.dart';
import '../widgets/home_app_bar.dart';
import '../utils/assessment.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import 'progress_screen.dart';

enum PromptKind { introSentence, word, shortSentence }

class PracticeFlowScreen extends StatefulWidget {
  const PracticeFlowScreen({super.key});

  @override
  State<PracticeFlowScreen> createState() => _PracticeFlowScreenState();
}

class _PracticeFlowScreenState extends State<PracticeFlowScreen> {
  final SpeechService _speech = SpeechService();
  final TtsService _tts = TtsService();

  // Banks
  final Map<String, List<String>> introSentences = {
    'R': [
      'The red rabbit ran rapidly.',
      'Rachel rode the roller coaster.',
      'Rain rushed down the river.',
    ],
    'S': [
      'Sally sells seashells by the seashore.',
      'Seven snakes slither silently.',
      'Sam saw seven seagulls.',
    ],
    'Sh': [
      'The ship sails in the shining sun.',
      'She shouted to her friends.',
      'Shiny shoes should stay clean.',
    ],
  };

  final Map<String, List<String>> wordsBySound = {
    'R': ['rabbit', 'river', 'rocket', 'ring', 'red'],
    'S': ['sun', 'sand', 'sock', 'soup', 'seal'],
    'Sh': ['ship', 'shoe', 'shell', 'shark', 'shadow'],
  };

  // Short sentence templates include $WORD and stay short
  final Map<String, List<String>> shortSentenceTpl = {
    'R': [
      'The $WORD is ready.',
      'We found the $WORD.',
      'See the $WORD today.',
    ],
    'S': [
      'The $WORD is shiny.',
      'I see the $WORD.',
      'Small $WORD here.',
    ],
    'Sh': [
      'The $WORD is shiny.',
      'She has a $WORD.',
      'Show the $WORD.',
    ],
  };

  PromptKind kind = PromptKind.introSentence;
  String targetSound = 'R';
  String prompt = '';
  String lastWord = '';
  bool isListening = false;
  String heard = '';
  AssessmentResult? lastAssessment;

  // We’ll do 2 cycles: [intro] → [word, short sentence] x2 → progress
  int cyclesCompleted = 0;
  final int maxCycles = 2;
  final List<int> scores = [];

  @override
  void initState() {
    super.initState();
    _tts.init();
    _speech.init(onResult: _onHeard);

    // Pick a random intro sentence across sounds for variety
    final sounds = introSentences.keys.toList()..shuffle();
    targetSound = sounds.first;
    final list = List<String>.from(introSentences[targetSound]!)..shuffle();
    prompt = list.first;
  }

  void _onHeard(String text) {
    final result = assessRecording(promptedSentence: prompt, recognizedText: text);
    setState(() {
      heard = text;
      lastAssessment = result;
      scores.add(result.accuracyPercent.round());
      isListening = false;
    });
  }

  void _toggle() {
    if (isListening) {
      _speech.stop();
      setState(() => isListening = false);
    } else {
      setState(() {
        heard = '';
        lastAssessment = null;
        isListening = true;
      });
      _speech.start();
    }
  }

  void _speakPrompt() => _tts.speak(prompt);

  void _nextStep() {
    // Decide next prompt based on last assessment
    if (lastAssessment != null) {
      targetSound = lastAssessment!.targetSound;
    }

    switch (kind) {
      case PromptKind.introSentence:
        // Move to word for the chosen weak sound
        kind = PromptKind.word;
        lastWord = _pickRandom(wordsBySound[targetSound] ?? ['practice']);
        prompt = lastWord;
        break;

      case PromptKind.word:
        // Use a short sentence template that includes the word
        kind = PromptKind.shortSentence;
        final tplList = shortSentenceTpl[targetSound] ?? ['Say $WORD clearly.'];
        final tpl = _pickRandom(tplList);
        prompt = tpl.replaceAll('\$WORD', lastWord);
        break;

      case PromptKind.shortSentence:
        cyclesCompleted += 1;
        if (cyclesCompleted >= maxCycles) {
          // Done → progress
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ProgressScreen(scores: scores, sound: targetSound),
            ),
          );
          return;
        }
        // Start a new cycle: new word (may update targetSound from last assessment)
        kind = PromptKind.word;
        lastWord = _pickRandom(wordsBySound[targetSound] ?? ['practice']);
        prompt = lastWord;
        break;
    }

    setState(() {
      heard = '';
      lastAssessment = null;
    });
  }

  String _title() {
    switch (kind) {
      case PromptKind.introSentence:
        return 'Say This Sentence';
      case PromptKind.word:
        return 'Say This Word';
      case PromptKind.shortSentence:
        return 'Say This Short Sentence';
    }
  }

  String _pickRandom(List<String> list) {
    final copy = List<String>.from(list)..shuffle();
    return copy.first;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: HomeAppBar(title: _title()),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 8),
                Text(
                  '"$prompt"',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Hear it',
                      onPressed: _speakPrompt,
                      icon: const Icon(Icons.volume_up),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                ElevatedButton(
                  onPressed: _toggle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Colors.black, width: 2),
                    ),
                  ),
                  child: Text(isListening ? 'Stop' : 'Start'),
                ),

                const SizedBox(height: 16),
                const Text('You said:', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 6),
                Text(
                  heard.isEmpty ? '—' : heard,
                  style: const TextStyle(fontSize: 20, color: Colors.blueAccent),
                  textAlign: TextAlign.center,
                ),

                if (lastAssessment != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Accuracy: ${lastAssessment!.accuracyPercent.toStringAsFixed(0)}%',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _encouragement(lastAssessment!.accuracyPercent),
                    style: const TextStyle(color: Colors.green, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton(
                        onPressed: _nextStep,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                          side: const BorderSide(color: Colors.black, width: 2),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Next', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _encouragement(double avg) {
    if (avg < 25) return "Good start!";
    if (avg < 50) return "Keep going!";
    if (avg < 75) return "Nice progress!";
    if (avg < 90) return "Great job!";
    return "Fantastic!";
  }
}
