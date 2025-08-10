import 'package:flutter/material.dart';
import '../session/assessment_gate.dart';
import '../screens/practice_flow_screen.dart';

/// Call this from any "Start" / "Practice" button.
/// It launches the assessment story if available; otherwise runs your normal flow.
Future<void> startPracticeFlow(BuildContext context) async {
  final gate = await AssessmentGate.decide();

  if (!context.mounted) return;

  if (gate.shouldRunAssessment && gate.story != null && gate.story!.sentences.isNotEmpty) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PracticeFlowScreen(
        items: gate.story!.sentences,
        mode: PracticeFlowMode.assessment,
        onSessionComplete: () {
          AssessmentGate.markDoneNow();
        },
      ),
    ));
  } else {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const PracticeFlowScreen(
        mode: PracticeFlowMode.standard,
      ),
    ));
  }
}
