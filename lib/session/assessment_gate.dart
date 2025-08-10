import '../content/content_bank_repository.dart';
import '../content/models.dart';

/// Session-only gate: runs the assessment story at most once per app run.
/// No persistent storage or external dependencies, so it's CI-safe.
class AssessmentGateResult {
  final bool shouldRunAssessment;
  final AssessmentStory? story;
  AssessmentGateResult(this.shouldRunAssessment, this.story);
}

class AssessmentGate {
  static bool _ranThisSession = false;

  static Future<AssessmentGateResult> decide({String locale = 'en'}) async {
    if (_ranThisSession) {
      return AssessmentGateResult(false, null);
    }

    final story = await ContentBankRepository.instance.getFirstAssessment(locale: locale);

    if (story == null || story.sentences.isEmpty) {
      // No assessment content available; skip gracefully.
      return AssessmentGateResult(false, null);
    }

    return AssessmentGateResult(true, story);
  }

  static void markDoneNow() {
    _ranThisSession = true;
  }

  /// For testing or debugging you can reset the gate.
  static void resetForDebug() {
    _ranThisSession = false;
  }
}
