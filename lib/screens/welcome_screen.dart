import 'package:flutter/material.dart';
import 'practice_flow_screen.dart';
import '../session/assessment_gate.dart';
import 'assessment_results_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // clean background
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Welcome to Fluent Friends',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow, color: Colors.black),
              label: const Text(
                'Start',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Colors.black, width: 2),
                ),
                elevation: 0,
              ),
              onPressed: () async {
                final gate = await AssessmentGate.decide();

                if (!context.mounted) return;

                if (gate.shouldRunAssessment &&
                    gate.story != null &&
                    gate.story!.sentences.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PracticeFlowScreen(
                        items: gate.story!.sentences,
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
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PracticeFlowScreen(
                        mode: PracticeFlowMode.standard,
                      ),
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
