@JS()
library web_tts_bridge;

import 'package:js/js.dart';

@JS('speakText')
external void speakText(String text);

@JS('stopSpeaking')
external void stopSpeaking();

// New
@JS('getVoiceNames')
external List<dynamic> getVoiceNames();

@JS('setPreferredVoiceByName')
external bool setPreferredVoiceByName(String name);
