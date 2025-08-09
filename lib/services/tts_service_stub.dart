class TtsService {
  Future<void> init() async {}
  Future<void> speak(String text) async {}
  Future<void> stop() async {}

  Future<void> speakAndWait(String text) async {} // NEW

  Future<List<String>> listVoices() async => <String>[];
  Future<bool> setPreferredVoice(String name) async => false;
}
