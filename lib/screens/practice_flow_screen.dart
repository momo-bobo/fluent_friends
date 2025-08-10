import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../widgets/home_app_bar.dart';
import '../widgets/half_donut_gauge.dart';
import '../widgets/voice_wave.dart';
import '../utils/assessment.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../services/tones_service.dart';
import 'session_complete_screen.dart';
import '../content/content_repository.dart';

// NEW: optional flow mode to support assessment sequences
enum PracticeFlowMode { standard, assessment }

enum PromptKind { introSentence, word, shortSentence }

class PracticeFlowScreen extends StatefulWidget {
  // NEW: optional sequence (e.g., assessment story sentences)
  final List<String>? items;
  final PracticeFlowMode mode;
  final VoidCallback? onSessionComplete;

  const PracticeFlowScreen({
    super.key,
    this.items,
    this.mode = PracticeFlowMode.standard,
    this.onSessionComplete,
  });

  @override
  State<PracticeFlowScreen> createState() => _PracticeFlowScreenState();
}

class _PracticeFlowScreenState extends State<PracticeFlowScreen> {
  final SpeechService _speech = SpeechService();
  final TtsService _tts = TtsService();
  final TonesService _tones = TonesService();

  late ContentRepository _content;
  bool _loading = true;

  // For standard mode (existing behavior)
  PromptKind kind = PromptKind.introSentence;
  String targetSound = 'R';

  // Shared UI state
  String prompt = '';
  String lastWord = '';
  bool isListening = false;
  String heard = '';
  AssessmentResult? lastAssessment;

  final List<int> sessionScores = [];
  int cyclesCompleted = 0;
  final int maxCycles = 2;

  static const double _donutSize = 150;
  static const double _donutHeight = _donutSize / 2;
  static const double _transcriptHeight = 56;

  bool _autoplayTts = true;
  bool _didKickoff = false;

  // Mic level (currently not driving the painter; kept for future)
  double _micLevel = 0.0;

  // NEW: sequence index for assessment mode
  int _seqIndex = 0;

  bool get _isAssessment => widget.mode == PracticeFlowMode.assessment && (widget.items?.isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    await _tts.init();
    await _tones.init();
    _speech.init(onResult: _onHeard);

    if (_isAssessment) {
      // Assessment mode: no dependency on ContentRepository for items
      prompt = widget.items![_seqIndex];
      setState(() {
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _kickoffIfNeeded());
      return;
    }

    // Standard mode: load sounds content and proceed as before
    _content = await ContentRepository.loadFromAssets();

    // Choose starting sound/prompt from content
    targetSound = _content.randomSoundKey();
    prompt = _content.randomIntroSentence(targetSound);

    setState(() {
      _loading = false;
    });

    // Auto-play prompt then auto-start practice on first load
    WidgetsBinding.instance.addPostFrameCallback((_) => _kickoffIfNeeded());
  }

  Future<void> _kickoffIfNeeded() async {
    if (_didKickoff || _loading) return;
    _didKickoff = true;

    if (_autoplayTts) {
      await _tts.stop();
      await _tts.speakAndWait(prompt);
    }
    await _startListening();
  }

  Future<void> _startListening() async {
    setState(() {
      heard = '';
      lastAssessment = null;
      isListening = true;
    });
    await _tones.playStartDing();
    if (kIsWeb) {
      await _tones.startMicLevelStream(
        onLevel: (lvl) {
          if (!mounted) return;
          setState(() => _micLevel = lvl.clamp(0.0, 1.0));
        },
      );
    }
    _speech.start();
  }

  Future<void> _stopListening() async {
    _speech.stop();
    await _tones.playStopDing();
    if (kIsWeb) {
      await _tones.stopMicLevelStream();
      setState(() => _micLevel = 0.0);
    }
    setState(() => isListening = false);
  }

  void _onHeard(String text) {
    final result = assessRecording(promptedSentence: prompt, recognizedText: text);
    setState(() {
      heard = text;
      lastAssessment = result;
      sessionScores.add(result.accuracyPercent.round());
    });
    _stopListening();
  }

  void _toggleRecord() {
    if (isListening) {
      _stopListening();
    } else {
      _startListening();
    }
  }

  void _speakPrompt() => _tts.speak(prompt);

  bool get _justFinishedPair =>
      kind == PromptKind.shortSentence && lastAssessment != null;

  Future<void> _goNext() async {
    if (_isAssessment) {
      // Assessment mode: advance through provided items
      final isLast = _seqIndex >= (widget.items!.length - 1);
      if (isLast) {
        // session complete
        widget.onSessionComplete?.call();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SessionCompleteScreen(scores: sessionScores),
          ),
        );
        return;
      }

      setState(() {
        _seqIndex += 1;
        prompt = widget.items![_seqIndex];
        heard = '';
        lastAssessment = null;
      });

      if (_autoplayTts) {
        await _tts.stop();
        await _tts.speakAndWait(prompt);
      }
      await _startListening();
      return;
    }

    // -------- Standard mode (existing flow) --------
    // Choose next step informed by last assessment (weakest sound), fallback safe
    if (lastAssessment != null) {
      final suggested = lastAssessment!.targetSound;
      if (_content.hasSound(suggested)) {
        targetSound = suggested;
      }
    }

    switch (kind) {
      case PromptKind.introSentence:
        kind = PromptKind.word;
        lastWord = _content.randomWord(targetSound);
        prompt = lastWord;
        break;

      case PromptKind.word:
        kind = PromptKind.shortSentence;
        prompt = _content.shortSentenceWithWord(targetSound, lastWord);
        break;

      case PromptKind.shortSentence:
        cyclesCompleted += 1;
        if (cyclesCompleted >= maxCycles) {
          setState(() {}); // Planned end; Done (X) finishes session
          return;
        }
        kind = PromptKind.word;
        lastWord = _content.randomWord(targetSound);
        prompt = lastWord;
        break;
    }

    setState(() {
      heard = '';
      lastAssessment = null;
    });

    if (_autoplayTts) {
      await _tts.stop();
      await _tts.speakAndWait(prompt);
    }
    await _startListening();
  }

  void _goDone() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SessionCompleteScreen(scores: sessionScores),
      ),
    );
  }

  String? _title() {
    if (_isAssessment) return 'Say This Sentence';
    switch (kind) {
      case PromptKind.introSentence:
        return 'Say This Sentence';
      case PromptKind.word:
        return 'Say This Word';
      case PromptKind.shortSentence:
        return null; // no title for short sentence
    }
  }

  // Voice Picker (AppBar "Voice…")
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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
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

  // Speaker On/Off icons (selected has black border; unselected none)
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
              color: selected ? Colors.black : Colors.transparent,
              width: 3,
            ),
          ),
          child: Icon(icon, color: selected ? Colors.black : Colors.black45),
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
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: HomeAppBar(
          title: 'Loading…',
          actions: const [
            // Disabled while loading
            TextButton(onPressed: null, child: Text('Voice…', style: TextStyle(color: Colors.black54))),
            IconButton(
              tooltip: 'Done',
              onPressed: null,
              icon: Icon(Icons.close_outlined, color: Colors.black54),
            ),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

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
                const SizedBox(height: 8),
                Text(
                  '"$prompt"',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                _speakerToggleIcons(),

                const SizedBox(height: 16),
                SizedBox(
                  height: _transcriptHeight,
                  child: Center(
                    child: heard.isEmpty
                        ? const SizedBox.shrink()
                        : Text(
                            heard,
                            style: const TextStyle(fontSize: 20, color: Colors.blueAccent),
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),

                const SizedBox(height: 8),
                SizedBox(
                  height: _donutHeight,
                  child: isListening
                      ? VoiceWave(level: _micLevel)   // ← pass the live level; no const
                      : (lastAssessment == null
                          ? const SizedBox.shrink()
                          : HalfDonutGauge(
                              percent: lastAssessment!.accuracyPercent,
                              size: _donutSize,
                              thickness: 40,
                            )),
                ),

                if (_justFinishedPair && lastAssessment != null && !_isAssessment) ...[
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _toggleRecord,
                      icon: Icon(
                        isListening ? Icons.stop_outlined : Icons.play_arrow_outlined,
                        color: Colors.black,
                      ),
                      label: const Text(
                        'Practice',
                        style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 20),
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
    if (avg < 75) return "Nice!";
    if (avg < 90) return "Great job!";
    return "Fantastic!";
  }
}
