import 'package:flutter/material.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/half_donut_gauge.dart';
import '../utils/assessment.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import 'session_complete_screen.dart';

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

  // Short sentence templates include \$WORD and stay short
  final Map<String, List<String>> shortSentenceTpl = {
    'R': [
      'The \$WORD is ready.',
      'We found the \$WORD.',
      'See the \$WORD today.',
    ],
    'S': [
      'The \$WORD is shiny.',
      'I see the \$WORD.',
      'Small \$WORD here.',
    ],
    'Sh': [
      'The \$WORD is shiny.',
      'She has a \$WORD.',
      'Show the \$WORD.',
    ],
  };

  PromptKind kind = PromptKind.introSentence;
  String targetSound = 'R';
  String prompt = '';
  String lastWord = '';
  bool isListening = false;
  String heard = '';
  AssessmentResult? lastAssessment;

  // session scoring (aggregate shown on final page)
  final List<int> sessionScores = [];

  // We’ll do 2 pairs: [intro] → [word, short sentence] x2 → then user can tap Done
  int cyclesCompleted = 0; // counts completed pairs (word+short sentence)
  final int maxCycles = 2;

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
      sessionScores.add(result.accuracyPercent.round());
      isListening = false;
    });
  }

  void _toggleRecord() {
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

  bool get _justFinishedPair =>
      kind == PromptKind.shortSentence && lastAssessment != null;

  bool get _hasNextStep {
    // there is a "next" unless we have completed maxCycles AND we're at the end of a pair
    if (_justFinishedPair && cyclesCompleted >= maxCycles) return false;
    return true;
  }

  void _goNext() {
    // Decide next prompt based on last assessment (weakest sound)
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
        final tplList = shortSentenceTpl[targetSound] ?? ['Say \$WORD clearly.'];
        final tpl = _pickRandom(tplList);
        prompt = tpl.replaceAll('\$WORD', lastWord);
        break;

      case PromptKind.shortSentence:
        // Finished a pair
        cyclesCompleted += 1;

        if (cyclesCompleted >= maxCycles) {
          // We’re at the end of the planned session.
          // Do NOT auto-navigate. The "Done" button will take them to the final page.
          setState(() {
            // Keep the current prompt/results visible; buttons will show "Done".
          });
          return;
        }

        // Start a new cycle with a new word (may be different sound)
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

  void _goDone() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SessionCompleteScreen(scores: sessionScores),
      ),
    );
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
                IconButton(
                  tooltip: 'Hear it',
                  onPressed: _speakPrompt,
                  icon: const Icon(Icons.volume_up),
                ),

                const SizedBox(height: 12),

                // Transcript
                const Text('You said:', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 6),
                Text(
                  heard.isEmpty ? '—' : heard,
                  style: const TextStyle(fontSize: 20, color: Colors.blueAccent),
                  textAlign: TextAlign.center,
                ),

                // Accuracy as half-donut (no encouragement here)
                if (lastAssessment != null) ...[
                  const SizedBox(height: 18),
                  HalfDonutGauge(
                    percent: lastAssessment!.accuracyPercent,
                    size: 300,
                    thickness: 40,
                  ),
                ],

                // Encouragement ONLY after each pair
                if (_justFinishedPair && lastAssessment != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _encouragement(lastAssessment!.accuracyPercent),
                    style: const TextStyle(
                      color: Colors.green,
                      fontStyle: FontStyle.italic,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                const SizedBox(height: 28),

                // Bottom buttons: Repeat + Next/Done
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Repeat (or Stop while recording)
                    ElevatedButton.icon(
                      onPressed: _toggleRecord,
                      icon: Icon(isListening ? Icons.stop : Icons.replay, color: Colors.black),
                      label: Text(isListening ? 'Stop' : 'Repeat',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.black)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Next (or Done if session complete)
                    ElevatedButton.icon(
                      onPressed: lastAssessment == null
                          ? null
                          : (_hasNextStep ? _goNext : _goDone),
                      icon: Icon(_hasNextStep ? Icons.arrow_forward : Icons.check,
                          color: lastAssessment == null ? Colors.black45 : Colors.black),
                      label: Text(_hasNextStep ? 'Next' : 'Done',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: lastAssessment == null ? Colors.black45 : Colors.black,
                          )),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                    ),
                  ],
                ),
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
