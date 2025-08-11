import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../widgets/home_app_bar.dart';
import '../widgets/gauge_area.dart';
import '../widgets/counter_chip.dart';
import '../widgets/speaker_toggle.dart';

import '../utils/assessment.dart';
import '../services/speech_service.dart';
import '../services/tts_service.dart';
import '../services/tones_service.dart';

import 'session_complete_screen.dart';
import '../content/content_repository.dart';
import '../models/assessment_outcome.dart';

enum PracticeFlowMode { standard, assessment }
enum PromptKind { introSentence, word, shortSentence }

class PracticeFlowScreen extends StatefulWidget {
  final List<String>? items;                     // assessment sentences
  final PracticeFlowMode mode;                   // standard or assessment
  final VoidCallback? onSessionComplete;         // legacy hook
  final ValueChanged<AssessmentOutcome>? onAssessmentComplete;
  final String? initialTargetSound;              // seed standard mode
  final int? exercisesTarget;                    // total steps in focused block (e.g., 6)

  const PracticeFlowScreen({
    super.key,
    this.items,
    this.mode = PracticeFlowMode.standard,
    this.onSessionComplete,
    this.onAssessmentComplete,
    this.initialTargetSound,
    this.exercisesTarget,
  });

  @override
  State<PracticeFlowScreen> createState() => _PracticeFlowScreenState();
}

class _PracticeFlowScreenState extends State<PracticeFlowScreen> {
  final _speech = SpeechService();
  final _tts = TtsService();
  final _tones = TonesService();

  late ContentRepository _content;
  bool _loading = true;

  // flow state
  PromptKind _kind = PromptKind.introSentence;
  String _targetSound = 'R';
  String _prompt = '';
  String _lastWord = '';

  // io state
  bool _isListening = false;
  bool _autoplayTts = true;
  bool _didKickoff = false;
  double _micLevel = 0.0;

  // recognition + scoring
  String _heard = '';
  AssessmentResult? _lastAssessment;

  // session stats
  final List<int> _sessionScores = [];
  int _cyclesCompleted = 0;
  final int _maxCycles = 2; // ignored for focused blocks

  // assessment sequencing
  int _seqIndex = 0;
  final List<String> _assessmentSounds = [];
  final List<int> _assessmentScores = [];

  // focused block (counts EVERY Next)
  int _stepsCompleted = 0;

  bool get _isAssessment =>
      widget.mode == PracticeFlowMode.assessment &&
      (widget.items?.isNotEmpty ?? false);

  bool get _isFocusedBlock => !_isAssessment && (widget.exercisesTarget != null);

  static const double _donutSize = 150;

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
      _prompt = widget.items![_seqIndex];
      setState(() => _loading = false);
      WidgetsBinding.instance.addPostFrameCallback((_) => _kickoffIfNeeded());
      return;
    }

    _content = await ContentRepository.loadFromAssets();
    _targetSound = widget.initialTargetSound ?? _content.randomSoundKey();

    // Focused blocks start at a WORD (skip intro sentence)
    if (_isFocusedBlock) {
      _kind = PromptKind.word;
      _lastWord = _content.randomWord(_targetSound);
      _prompt = _lastWord;
      _stepsCompleted = 0;
      _cyclesCompleted = 0; // legacy gate off
    } else {
      _prompt = _content.randomIntroSentence(_targetSound);
    }

    setState(() => _loading = false);
    WidgetsBinding.instance.addPostFrameCallback((_) => _kickoffIfNeeded());
  }

  Future<void> _kickoffIfNeeded() async {
    if (_didKickoff || _loading) return;
    _didKickoff = true;

    if (_autoplayTts) {
      await _tts.stop();
      await _tts.speakAndWait(_prompt);
    }
    await _startListening();
  }

  Future<void> _startListening() async {
    setState(() {
      _heard = '';
      _lastAssessment = null;
      _isListening = true;
    });
    await _tones.playStartDing();
    if (kIsWeb) {
      await _tones.startMicLevelStream(
        onLevel: (lvl) => mounted ? setState(() => _micLevel = lvl.clamp(0.0, 1.0)) : null,
      );
    }
    _speech.start();
  }

  Future<void> _stopListening() async {
    _speech.stop();
    await _tones.playStopDing();
    if (kIsWeb) {
      await _tones.stopMicLevelStream();
      if (mounted) setState(() => _micLevel = 0.0);
    }
    if (mounted) setState(() => _isListening = false);
  }

  void _onHeard(String text) {
    final result = assessRecording(promptedSentence: _prompt, recognizedText: text);
    final score = result.accuracyPercent.round();

    setState(() {
      _heard = text;
      _lastAssessment = result;
      _sessionScores.add(score);
      if (_isAssessment) {
        _assessmentScores.add(score);
        if (result.targetSound.isNotEmpty) _assessmentSounds.add(result.targetSound);
      }
    });

    _stopListening();
  }

  Future<void> _goNext() async {
    // Assessment sequence
    if (_isAssessment) {
      final isLast = _seqIndex >= (widget.items!.length - 1);
      if (isLast) {
        final out = AssessmentOutcome(
          suggestedSounds: List<String>.from(_assessmentSounds),
          perSentenceScores: List<int>.from(_assessmentScores),
        );
        if (widget.onAssessmentComplete != null) {
          widget.onAssessmentComplete!(out);
          return;
        }
        widget.onSessionComplete?.call();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => SessionCompleteScreen(scores: _sessionScores)),
        );
        return;
      }

      setState(() {
        _seqIndex += 1;
        _prompt = widget.items![_seqIndex];
        _heard = '';
        _lastAssessment = null;
      });

      if (_autoplayTts) {
        await _tts.stop();
        await _tts.speakAndWait(_prompt);
      }
      await _startListening();
      return;
    }

    // Standard mode steering
    if (_lastAssessment != null) {
      final suggested = _lastAssessment!.targetSound;
      if (_content.hasSound(suggested)) _targetSound = suggested;
    }

    // Focused block: count EVERY Next and cap at exercisesTarget
    if (_isFocusedBlock && widget.exercisesTarget != null) {
      _stepsCompleted += 1;
      if (_stepsCompleted >= widget.exercisesTarget!) {
        widget.onSessionComplete?.call();
        if (!mounted) return;
        Navigator.pop(context); // back to results
        return;
      }
    }

    // Advance within pair flow
    switch (_kind) {
      case PromptKind.introSentence:
        _kind = PromptKind.word;
        _lastWord = _content.randomWord(_targetSound);
        _prompt = _lastWord;
        break;

      case PromptKind.word:
        _kind = PromptKind.shortSentence;
        _prompt = _content.shortSentenceWithWord(_targetSound, _lastWord);
        break;

      case PromptKind.shortSentence:
        if (!_isFocusedBlock) {
          _cyclesCompleted += 1;
          if (_cyclesCompleted >= _maxCycles) {
            setState(() {}); // Done (X) ends
            return;
          }
        }
        _kind = PromptKind.word;
        _lastWord = _content.randomWord(_targetSound);
        _prompt = _lastWord;
        break;
    }

    setState(() {
      _heard = '';
      _lastAssessment = null;
    });

    if (_autoplayTts) {
      await _tts.stop();
      await _tts.speakAndWait(_prompt);
    }
    await _startListening();
  }

  void _toggleRecord() => _isListening ? _stopListening() : _startListening();

  void _goDone() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => SessionCompleteScreen(scores: _sessionScores)),
    );
  }

  // UI bits
  String? _title() {
    if (_isAssessment) return 'Say This Sentence';
    switch (_kind) {
      case PromptKind.introSentence:
        return 'Say This Sentence';
      case PromptKind.word:
        return 'Say This Word';
      case PromptKind.shortSentence:
        return null;
    }
  }

  int? _counterNumber() {
    if (!_isFocusedBlock || widget.exercisesTarget == null) return null;
    final next = _stepsCompleted + 1;
    return next > widget.exercisesTarget! ? widget.exercisesTarget! : next;
  }

  bool get _justFinishedPair => _kind == PromptKind.shortSentence && _lastAssessment != null;

  String _encouragement(double avg) {
    if (avg < 25) return "Good start!";
    if (avg < 50) return "Keep going!";
    if (avg < 75) return "Nice progress!";
    if (avg < 90) return "Great job!";
    return "Fantastic!";
  }

  // Speaker toggle handler
  void _onSpeakerToggle(bool v) => setState(() => _autoplayTts = v);

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: HomeAppBar(
          title: 'Loading…',
          actions: const [
            TextButton(onPressed: null, child: Text('Voice…', style: TextStyle(color: Colors.black54))),
            IconButton(onPressed: null, icon: Icon(Icons.close_outlined, color: Colors.black54)),
          ],
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final counterN = _counterNumber();
    final counterT = widget.exercisesTarget;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: HomeAppBar(
        title: _title(),
        actions: [
          TextButton(
            onPressed: () async {
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
                        final sel = selected == name;
                        return ListTile(
                          title: Text(
                            name,
                            style: TextStyle(
                              color: sel ? Colors.black : Colors.black87,
                              fontWeight: sel ? FontWeight.w600 : FontWeight.w400,
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
                if (_autoplayTts) _tts.speak(_prompt);
              }
            },
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isFocusedBlock && counterN != null && counterT != null)
                  CounterChip(current: counterN, total: counterT),

                const SizedBox(height: 8),
                Text(
                  '"$_prompt"',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),

                SpeakerToggle(autoplay: _autoplayTts, onChanged: _onSpeakerToggle),

                const SizedBox(height: 16),
                SizedBox(
                  height: 56,
                  child: Center(
                    child: _heard.isEmpty
                        ? const SizedBox.shrink()
                        : Text(
                            _heard,
                            style: const TextStyle(fontSize: 20, color: Colors.blueAccent),
                            textAlign: TextAlign.center,
                          ),
                  ),
                ),

                const SizedBox(height: 8),
                Center(
                  child: GaugeArea(
                    isListening: _isListening,
                    micLevel: _micLevel,
                    percent: _lastAssessment?.accuracyPercent ?? 0,
                    showGauge: _lastAssessment != null,
                    size: _donutSize,
                    thickness: 40,
                  ),
                ),

                if (_justFinishedPair && _lastAssessment != null && !_isAssessment) ...[
                  const SizedBox(height: 10),
                  Text(
                    _encouragement(_lastAssessment!.accuracyPercent),
                    textAlign: TextAlign.center,
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
                        _isListening ? Icons.stop_outlined : Icons.play_arrow_outlined,
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
                      onPressed: _lastAssessment == null ? null : _goNext,
                      icon: Icon(
                        Icons.arrow_forward_outlined,
                        color: _lastAssessment == null ? Colors.black45 : Colors.black,
                      ),
                      label: Text(
                        'Next',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _lastAssessment == null ? Colors.black45 : Colors.black,
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
}
