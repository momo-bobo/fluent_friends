import 'dart:math';

class AssessmentResult {
  final double accuracyPercent; // 0..100
  final String targetSound; // 'R', 'S', or 'Sh'
  final Map<String, double> soundRatios; // heard/expected for each sound
  AssessmentResult({
    required this.accuracyPercent,
    required this.targetSound,
    required this.soundRatios,
  });
}

String _normalize(String s) {
  final lower = s.toLowerCase();
  // remove punctuation, keep letters and spaces
  final cleaned = lower.replaceAll(RegExp(r'[^a-z\s]'), ' ');
  // collapse whitespace
  return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
}

List<String> _tokenizeWords(String s) => _normalize(s).split(' ').where((w) => w.isNotEmpty).toList();

int _editDistance<T>(List<T> a, List<T> b) {
  final m = a.length, n = b.length;
  final dp = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));
  for (var i = 0; i <= m; i++) dp[i][0] = i;
  for (var j = 0; j <= n; j++) dp[0][j] = j;
  for (var i = 1; i <= m; i++) {
    for (var j = 1; j <= n; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      dp[i][j] = min(
        dp[i - 1][j] + 1, // deletion
        min(
          dp[i][j - 1] + 1, // insertion
          dp[i - 1][j - 1] + cost, // substitution
        ),
      );
    }
  }
  return dp[m][n];
}

/// Word Error Rate (WER) in 0..1 (0 = perfect, 1 = all wrong)
double _wordErrorRate(String reference, String hypothesis) {
  final ref = _tokenizeWords(reference);
  final hyp = _tokenizeWords(hypothesis);
  if (ref.isEmpty) return 0.0;
  final dist = _editDistance(ref, hyp);
  return dist / ref.length;
}

int _countOccurrences(String text, String pat) {
  final t = _normalize(text);
  var count = 0;
  var i = 0;
  while (true) {
    final idx = t.indexOf(pat, i);
    if (idx == -1) break;
    count++;
    i = idx + pat.length;
  }
  return count;
}

/// Returns 0..1 ratio of heard/expected for a given sound (R, S, Sh)
double _soundRatio(String expectedSentence, String heard, String sound) {
  final pattern = sound == 'Sh' ? 'sh' : sound.toLowerCase();
  final expected = _countOccurrences(expectedSentence, pattern);
  if (expected == 0) return 1.0; // no expectation => neutral
  final got = _countOccurrences(heard, pattern);
  return (got / expected).clamp(0.0, 1.0);
}

AssessmentResult assessRecording({
  required String promptedSentence,
  required String recognizedText,
}) {
  final wer = _wordErrorRate(promptedSentence, recognizedText); // 0..1
  final wordAcc = (1.0 - wer).clamp(0.0, 1.0);

  final ratios = <String, double>{
    'R': _soundRatio(promptedSentence, recognizedText, 'R'),
    'S': _soundRatio(promptedSentence, recognizedText, 'S'),
    'Sh': _soundRatio(promptedSentence, recognizedText, 'Sh'),
  };

  // Choose the sound with the LOWEST ratio (most missed) among those expected in the sentence.
  String target = 'R';
  double lowest = 2.0;
  for (final entry in ratios.entries) {
    final expectedInSentence = _countOccurrences(promptedSentence, entry.key.toLowerCase() == 'sh' ? 'sh' : entry.key.toLowerCase()) > 0;
    if (expectedInSentence && entry.value < lowest) {
      lowest = entry.value;
      target = entry.key;
    }
  }
  // If nothing expected, fallback to the sound with the lowest ratio anyway.
  if (lowest == 2.0) {
    final sorted = ratios.entries.toList()..sort((a, b) => a.value.compareTo(b.value));
    target = sorted.first.key;
  }

  // Blend word accuracy with sound ratio -> overall accuracy
  // Heavier weight on word correctness for friendliness
  final soundAcc = ratios[target];
  final overall = (0.7 * wordAcc + 0.3 * soundAcc).clamp(0.0, 1.0) * 100.0;

  return AssessmentResult(
    accuracyPercent: double.parse(overall.toStringAsFixed(1)),
    targetSound: target,
    soundRatios: ratios,
  );
}
