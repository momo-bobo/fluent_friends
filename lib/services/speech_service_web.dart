import 'dart:js' as js;
import '../web_speech_bridge.dart';

class SpeechService {
  late Function(String) _onResult;

  void init({required Function(String) onResult}) {
    _onResult = onResult;
    js.context['onResultFromSpeech'] = (String result) {
      _onResult(result);
    };
  }

  void start() {
    startRecognition('onResultFromSpeech');
  }

  void stop() {}
}
