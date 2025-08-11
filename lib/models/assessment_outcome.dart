class AssessmentOutcome {
  final List<String> suggestedSounds;   // e.g., ["R", "S", "R", "L"]
  final List<int> perSentenceScores;    // 0..100 (same order as suggestedSounds)

  AssessmentOutcome({
    required this.suggestedSounds,
    required this.perSentenceScores,
  });
}
