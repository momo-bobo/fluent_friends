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

  // 2 pairs by default: [intro] → [word + short sentence] x2 → user taps Done
  int cyclesCompleted = 0;
  final int maxCycles = 2;

  // Layout constants so nothing jumps
  static const double _donutSize = 150; // smaller
  static const double _donutHeight = _donutSize / 2; // half circle
  static const double _transcriptHeight = 56; // fixed-height placeholder

  // 🔊 Autoplay TTS setting (sticky)
  bool _autoplayTts = true;

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
    if (_justFinishedPair && cyclesCompleted >= maxCycles) return false;
    return true;
  }

  Future<void> _goNext() async {
    // Decide next prompt based on last assessment (weakest sound)
    if (lastAssessment != null) {
      targetSound = lastAssessment!.targetSound;
    }

    switch (kind) {
      case PromptKind.introSentence:
        kind = PromptKind.word;
        lastWord = _pickRandom(wordsBySound[targetSound] ?? ['practice']);
        prompt = lastWord;
        break;

      case PromptKind.word:
        kind = PromptKind.shortSentence;
        final tplList = shortSentenceTpl[targetSound] ?? ['Say \$WORD clearly.'];
        final tpl = _pickRandom(tplList);
        prompt = tpl.replaceAll('\$WORD', lastWord);
        break;

      case PromptKind.shortSentence:
        cyclesCompleted += 1;

        if (cyclesCompleted >= maxCycles) {
          // End of planned session. "Done" (X) will end session.
          setState(() {}); // keep results on screen
          return;
        }

        // Start a new cycle with a new word (may be different sound)
        kind = PromptKind.word;
        lastWord = _pickRandom(wordsBySound[targetSound] ?? ['practice']);
        prompt = lastWord;
        break;
    }

    // Reset UI for next prompt
    setState(() {
      heard = '';
      lastAssessment = null;
      isListening = false; // flip to true after (maybe) speaking
    });

    // 🔊 Autoplay: speak first, then auto-start practice
    if (_autoplayTts) {
      _speakPrompt();
      await Future.delayed(const Duration(milliseconds: 900));
    }

    setState(() {
      isListening = true;
    });
    _speech.start();
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

  Widget _autoplayToggle() {
    // Two outlined buttons: On / Off
    final onSelected = _autoplayTts;
    final offSelected = !_autoplayTts;

    OutlinedButton _btn({
      required bool selected,
      required IconData icon,
      required String label,
      required VoidCallback onPressed,
    }) {
      return OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: selected ? Colors.black : Colors.black45),
        label: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.black45,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          side: BorderSide(color: Colors.black, width: selected ? 3 : 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _btn(
          selected: onSelected,
          icon: Icons.volume_up_outlined,
          label: 'Speaker On',
          onPressed: () => setState(() => _autoplayTts = true),
        ),
        const SizedBox(width: 8),
        _btn(
          selected: offSelected,
          icon: Icons.volume_off_outlined,
          label: 'Speaker Off',
          onPressed: () => setState(() => _autoplayTts = false),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Top-left Home, top-right Done (X)
      appBar: HomeAppBar(
        title: _title(),
        actions: [
          IconButton(
            tooltip: 'Done',
            onPressed: _goDone,
            icon: const Icon(Icons.close_outlined, color: Colors.black),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Prompt
                const SizedBox(height: 8),
                Text(
                  '"$prompt"',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 10),
                // 🔊 Autoplay toggle (speaker on/off)
                _autoplayToggle(),

                // Transcript placeholder (no label, fixed height)
                const SizedBox(height: 16),
                SizedBox(
                  height: _transcriptHeight,
                  child: Center(
                    child: heard.isEmpty
                        ? const SizedBox.shrink()
                        : Text(
                            heard,
                            style: const TextStyle(
                              fontSize: 20,
                              color: Colors.blueAccent,
                            ),
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),

                // Half-donut placeholder (fixed height so layout doesn't jump)
                const SizedBox(height: 8),
                SizedBox(
                  height: _donutHeight,
                  child: lastAssessment == null
                      ? const SizedBox.shrink()
                      : HalfDonutGauge(
                          percent: lastAssessment!.accuracyPercent,
                          size: _donutSize,
                          thickness: 40,
                        ),
                ),

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

                // Bottom buttons: Practice + Next
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Practice (or Stop while recording)
                    ElevatedButton.icon(
                      onPressed: _toggleRecord,
                      icon: Icon(
                        isListening ? Icons.stop_outlined : Icons.play_arrow_outlined,
                        color: Colors.black,
                      ),
                      label: const Text(
                        'Practice',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                          fontSize: 20,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                        minimumSize: const Size(160, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: const BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Next (disabled until we have a result)
                    ElevatedButton.icon(
                      onPressed: lastAssessment == null ? null : _goNext,
                      icon: Icon(
                        Icons.arrow_forward_outlined,
                        color: lastAssessment == null ? Colors.black45 : Colors.black,
                      ),
                      label: Text(
                        'Next',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: lastAssessment == null ? Colors.black45 : Colors.black,
                          fontSize: 20,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
                        minimumSize: const Size(160, 56),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
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
