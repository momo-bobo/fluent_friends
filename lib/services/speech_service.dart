export 'speech_service_stub.dart'
  if (dart.library.html) 'speech_service_web.dart'
  if (dart.library.io) 'speech_service_mobile.dart';