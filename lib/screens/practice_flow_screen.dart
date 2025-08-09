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

  // Content banks (will move to JSON later)
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

  // Short sentence templates include \$WORD
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

  // Session scoring (aggregate shown on final page)
  final List<int> sessionScores = [];

  // 2 pairs by default: [intro] → [word + short sentence] x2 → user taps Done
  int cyclesCompleted = 0;
  final int maxCycles = 2;

  // Layout constants so nothing jumps
  static const double _donutSize = 150; // smaller
  static const double _donutHeight = _donutSize / 2; // half circle
  static const double _transcriptHeight = 56; // fixed-height placeholder

  // 🔊 Autoplay TTS (sticky)
  bool _autoplayTts = true;

  bool _didKickoff = false; // ensure first auto-kickoff happens once

  @override
  void initState() {
    super.initState();
    _tts.init();
    _speech.init(onResult: _onHeard);

    // Pick a random intro sentence across sounds
    final sounds = introSentences.keys.toList()..shuffle();
    targetSound = sounds.first;
    final list = List<String>.from(introSentences[targetSound]!)..shuffle();
    prompt = list.first;

    // Auto-play prompt then auto-start practice on first load
    WidgetsBinding.instance.addPostFrameCallback((_) => _kickoffIfNeeded());
  }

  Future<void> _kickoffIfNeeded() async {
    if (_didKickoff) return;
    _didKickoff = true;

    if (_autoplayTts) {
      await _tts.stop();
      // IMPORTANT: wait for TTS to finish before recording
      await _tts.speakAndWait(prompt);
    }
    setState(() => isListening = true);
    _speech.start();
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
          setState(() {}); // end of session planned; show Done (X) only
          return;
        }

        // Next cycle
        kind = PromptKind.word;
        lastWord = _pickRandom(wordsBySound[targetSound] ?? ['practice']);
        prompt = lastWord;
        break;
    }

    // Reset UI for next prompt
    setState(() {
      heard = '';
      lastAssessment = null;
      isListening = false;
    });

    // 🔊 Auto-play then auto-start recording (Practice)
    if (_autoplayTts) {
      await _tts.stop();
      await _tts.speakAndWait(prompt);
    }
    setState(() => isListening = true);
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

  // 🔊 Voice chooser (AppBar "Voice…")
  Future<void> _pickVoice() async {
    final voices = await _tts.listVoices();
    if (!mounted) return;

    String? selected;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choose a voice'),
        content: SizedBox(
          width: 400,
          height: 300,
          child: ListView.builder(
            itemCount: voices.length,
            itemBuilder: (context, i) {
              final name = voices[i];
              final isSelected = selected == name;
              return ListTile(
                title: Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.black87,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                onTap: () {
                  selected = name;
                  Navigator.of(context).pop();
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );

    if (selected != null) {
      await _tts.setPreferredVoice(selected!);
      if (_autoplayTts) {
        _speakPrompt();
      }
    }
  }

  // Speaker On/Off icons (selected has black border; unselected has none)
  Widget _speakerToggleIcons() {
    Widget _iconSel({
      required bool selected,
      required IconData icon,
      required VoidCallback onTap,
    }) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected ? Colors.black : Colors.transparent, // only selected outlined
              width: 3,
            ),
          ),
          child: Icon(
            icon,
            color: selected ? Colors.black : Colors.black45,
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _iconSel(
          selected: _autoplayTts,
          icon: Icons.volume_up_outlined,
          onTap: () => setState(() => _autoplayTts = true),
        ),
        const SizedBox(width: 12),
        _iconSel(
          selected: !_autoplayTts,
          icon: Icons.volume_off_outlined,
          onTap: () => setState(() => _autoplayTts = false),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      // Top-left Home, top-right Voice… then Done (X)
      appBar: HomeAppBar(
        title: _title(),
        actions: [
          TextButton(
            onPressed: _pickVoice,
            child: const Text('Voice…', style: TextStyle(color: Colors.black)),
          ),
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

                // Speaker On/Off (icons only)
                _speakerToggleIcons(),

                // Transcript placeholder (fixed height)
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
                   
