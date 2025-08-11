import 'package:flutter/material.dart';
import '../models/assessment_outcome.dart';
import '../session/assessment_gate.dart';
import '../content/content_bank_repository.dart';
import 'practice_flow_screen.dart';

class AssessmentResultsScreen extends StatefulWidget {
  final AssessmentOutcome outcome;
  final int maxExercisesPerSound;

  const AssessmentResultsScreen({
    super.key,
    required this.outcome,
    this.maxExercisesPerSound = 6,// 3 word + sentence pairs
  });

  @override
  State<AssessmentResultsScreen> createState() => _AssessmentResultsScreenState();
}

class _AssessmentResultsScreenState extends State<AssessmentResultsScreen> {
  late final List<_SoundStat> _top3;
  final Set<String> _completed = {};

  @override
  void initState() {
    super.initState();
    _top3 = _computeTop3(widget.outcome);
  }

  List<_SoundStat> _computeTop3(AssessmentOutcome outcome) {
    // frequency & avg score per suggested sound
    final counts = <String, int>{};
    final sums = <String, int>{};

    final n = outcome.suggestedSounds.length;
    for (int i = 0; i < n; i++) {
      final s = outcome.suggestedSounds[i];
      final score = (i < outcome.perSentenceScores.length) ? outcome.perSentenceScores[i] : 0;
      counts[s] = (counts[s] ?? 0) + 1;
      sums[s] = (sums[s] ?? 0) + score;
    }

    final stats = counts.keys.map((s) {
      final c = counts[s]!;
      final avg = (sums[s]! / c);
      return _SoundStat(sound: s, count: c, avgScore: avg);
    }).toList();

    stats.sort((a, b) {
      // most occurrences first (more “deficient”)
      final byCount = b.count.compareTo(a.count);
      if (byCount != 0) return byCount;
      // then lower average score first
      return a.avgScore.compareTo(b.avgScore);
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
            // one focused block finished
          },
        ),
      ),
    );
    setState(() {
      _completed.add(sound);
    });

    // If all three done, rerun assessment
    if (_completed.length >= _top3.length) {
      await _rerunAssessment();
    }
  }

  Future<void> _rerunAssessment() async {
    // Try to fetch a different story; fall back to the first
    final bank = ContentBankRepository.instance;
    final story = await bank.getFirstAssessment(locale: 'en'); // TODO: replace with "getAnother" if you add more
    if (!mounted) return;
    if (story == null || story.sentences.isEmpty) {
      // No story available; just pop back, or show a simple message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No more assessment stories available.')),
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
                builder: (_) => AssessmentResultsScreen(outcome: outcome),
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

  @override
  Widget build(BuildContext context) {
    // simple, clean layout; we’ll fancy it up later
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
                if (_completed.isNotEmpty && _completed.length < _top3.length)
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
          Text('/${stat.sound}/',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('seen ${stat.count}x · avg ${(stat.avgScore).round()}%',
              style: const TextStyle(fontSize: 14, color: Colors.black54)),
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
