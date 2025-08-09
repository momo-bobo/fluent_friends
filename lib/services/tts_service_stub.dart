class TtsService {
  Future<void> init() async {}
  Future<void> speak(String text) async {}
  Future<void> stop() async {}

  // New API:
  Future<List<String>> listVoices() async => <String>[];
  Future<bool> setPreferredVoice(String name) async => false;
}
