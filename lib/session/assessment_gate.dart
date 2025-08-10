import 'package:flutter/foundation.dart'; // for debugPrint
import '../content/content_bank_repository.dart';
import '../content/models.dart';

/// Simple session-only gate: runs the assessment once per app session.
/// No persistent storage to keep CI simple.
class AssessmentGateResult {
  final bool shouldRunAssessment;
  final AssessmentStory? story;
  AssessmentGateResult(this.shouldRunAssessment, this.story);
}

class AssessmentGate {
  static bool _ranThisSession = false;

  static Future<AssessmentGateResult> decide({String locale = 'en'}) async {
    if (_ranThisSession) {
      debugPrint('[AssessmentGate] Already ran this session; skipping.');
      return AssessmentGateResult(false, null);
    }

    debugPrint('[AssessmentGate] Deciding …');
    final story =
        await ContentBankRepository.instance.getFirstAssessment(locale: locale);

    if (story == null || story.sentences.isEmpty) {
      debugPrint('[AssessmentGate] No story available; using standard flow.');
      return AssessmentGateResult(false, null);
    }

    debugPrint('[AssessmentGate] Story found; will run assessment.');
    return AssessmentGateResult(true, story);
  }

  static void markDoneNow() {
    _ranThisSession = true;
    debugPrint('[AssessmentGate] Marked as done for this session.');
  }

  static void resetForDebug() {
    _ranThisSession = false;
    debugPrint('[AssessmentGate] Reset for debug.');
  }
}
