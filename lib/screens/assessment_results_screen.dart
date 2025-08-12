import 'package:flutter/material.dart';
import '../models/assessment_outcome.dart';
import '../session/assessment_gate.dart';
import '../content/content_bank_repository.dart';
import 'practice_flow_screen.dart';
import 'welcome_screen.dart';

class AssessmentResultsScreen extends StatefulWidget {
  final AssessmentOutcome outcome;
  /// Number of total steps per sound block (e.g., 6 = 3 pairs).
  final int maxExercisesPerSound;

  const AssessmentResultsScreen({
    super.key,
    required this.outcome,
    this.maxExercisesPerSound = 6,
  });

  @override
  State<AssessmentResultsScreen> createState() => _AssessmentResultsScreenState();
}

class _AssessmentResultsScreenState extends State<AssessmentResultsScreen> {
  late final List<_SoundStat> _top3; // filtered + ranked (max 3)
  final Set<String> _completed = {}; // sounds finished by the child
  bool _allDone = false;

  @override
  void initState() {
    super.initState();
    _top3 = _computeTop3(widget.outcome);
  }

  /// Build top-3 by frequency (desc), then avg score (asc),
  /// but **exclude** any sound that was 100% on all its occurrences.
  List<_SoundStat> _computeTop3(AssessmentOutcome outcome) {
    final counts = <String, int>{};
    final sums = <String, int>{};
    final anyBelow100 = <String, bool>{};

    final n = outcome.suggestedSounds.length;
    for (int i = 0; i < n; i++) {
      final s = outcome.suggestedSounds[i];
      final score = (i < outcome.perSentenceScores.length)
          ? outcome.perSentenceScores[i]
          : 0;
      counts[s] = (counts[s] ?? 0) + 1;
      sums[s] = (sums[s] ?? 0) + score;
      if (score < 100) anyBelow100[s] = true;
    }

    final stats = counts.keys
        .where((s) => anyBelow100[s] == true) // drop all-100% sounds
        .map((s) {
          final c = counts[s]!;
          final avg = c == 0 ? 0.0 : (sums[s]! / c);
          return _SoundStat(sound: s, count: c, avgScore: avg);
        })
        .toList();

    stats.sort((a, b) {
      final byCount = b.count.compareTo(a.count); // more occurrences first
      if (byCount != 0) return byCount;
      return a.avgScore.compareTo(b.avgScore);    // then lower avg first
    });

    return stats.take(3).toList();
  }

  Future<void> _practiceSound(String sound) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PracticeFlowScreen(
          mode: PracticeFlowMode.standard,
          initialTargetSound: sound,
          exercisesTarget: widget.maxExercisesPerSound,
          onSessionComplete: () {
            // block finished
          },
        ),
      ),
    );

    setState(() {
      _completed.add(sound);
      if (_completed.length >= _top3.length && _top3.isNotEmpty) {
        // All chosen sounds done — show final CTA instead of auto re-assessing.
        _allDone = true;
      }
    });
  }

  Future<void> _rerunAssessment() async {
    final bank = ContentBankRepository.instance;

    // TODO: when you add rotation support, switch to bank.getNextAssessment(locale: 'en')
    final story = await bank.getFirstAssessment(locale: 'en');
    if (!mounted) return;

    if (story == null || story.sentences.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No assessment story available.')),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PracticeFlowScreen(
          items: story.sentences,
          mode: PracticeFlowMode.assessment,
          onAssessmentComplete: (outcome) {
            AssessmentGate.markDoneNow();
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => AssessmentResultsScreen(
                  outcome: outcome,
                  maxExercisesPerSound: widget.maxExercisesPerSound,
                ),
              ),
            );
          },
          onSessionComplete: () {
            AssessmentGate.markDoneNow();
          },
        ),
      ),
    );
  }

  void _goDone() {
    // Same idea as clicking X: end the flow and return to the welcome/home.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    // If all suggested sounds were perfect (100%), offer to re-assess.
    if (_top3.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white, elevation: 0,
          title: const Text('Great job today!', style: TextStyle(color: Colors.black)),
          iconTheme: const IconThemeData(color: Colors.black),
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'You spoke very smoothly today, good job!\nWould you like to do another assessment?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _rerunAssessment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      minimumSize: const Size(200, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.black, width: 2),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Do another assessment'),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _goDone,
                    child: const Text('Done', style: TextStyle(color: Colors.black)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // Otherwise, show top sounds to practice next
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: const Text('Great job today!', style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Let’s focus on these sounds next:',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: _top3.map((st) {
                    final done = _completed.contains(st.sound);
                    return _SoundCard(
                      stat: st,
                      done: done,
                      onTap: done ? null : () => _practiceSound(st.sound),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // If all done, show final CTA section
                if (_allDone) ...[
                  const Text(
                    'Nice work! You finished all the practice for these sounds.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: _rerunAssessment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(160, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.black, width: 2),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Practice more'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _goDone,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                          minimumSize: const Size(120, 48),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: const BorderSide(color: Colors.black, width: 2),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Done'),
                      ),
                    ],
                  ),
                ],

                if (!_allDone && _completed.isNotEmpty)
                  const Text(
                    'Pick another sound to practice!',
                    style: TextStyle(fontSize: 16),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SoundStat {
  final String sound;
  final int count;
  final double avgScore;
  _SoundStat({required this.sound, required this.count, required this.avgScore});
}

class _SoundCard extends StatelessWidget {
  final _SoundStat stat;
  final bool done;
  final VoidCallback? onTap;
  const _SoundCard({required this.stat, required this.done, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '/${stat.sound}/',
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'seen ${stat.count}× · avg ${stat.avgScore.round()}%',
            style: const TextStyle(fontSize: 14, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: done ? Colors.black45 : Colors.black,
              minimumSize: const Size(160, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: done ? Colors.black26 : Colors.black, width: 2),
              ),
              elevation: 0,
            ),
            child: Text(done ? 'Done' : 'Practice'),
          ),
        ],
      ),
    );
  }
}
