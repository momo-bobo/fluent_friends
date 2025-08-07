import 'package:speech_to_text/speech_to_text.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  late Function(String) _onResult;

  void init({required Function(String) onResult}) async {
    _onResult = onResult;
    await _speech.initialize();
  }

  void start() async {
    await _speech.listen(onResult: (result) {
      _onResult(result.recognizedWords);
    });
  }

  void stop() {
    _speech.stop();
  }
}