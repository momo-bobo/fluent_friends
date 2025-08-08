@JS()
library web_speech_bridge;

import 'package:js/js.dart';

@JS('startRecognition')
external void startRecognition(String callbackFunctionName);

@JS('onResultFromSpeech')
external set onResultFromSpeech(Function(String) f);
