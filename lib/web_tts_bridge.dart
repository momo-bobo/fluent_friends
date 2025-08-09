@JS()
library web_tts_bridge;

import 'package:js/js.dart';

@JS('speakText')
external void speakText(String text);

@JS('stopSpeaking')
external void stopSpeaking();

// NEW: returns a JS Promise
@JS('speakTextAndWait')
external Object speakTextAndWait(String text);

// already have these if you added voice picking:
@JS('getVoiceNames')
external List<dynamic> getVoiceNames();

@JS('setPreferredVoiceByName')
external bool setPreferredVoiceByName(String name);
