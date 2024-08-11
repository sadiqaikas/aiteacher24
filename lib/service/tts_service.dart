import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _flutterTts = FlutterTts();
  TtsService() {
    _initializeTts();
  }
  void _initializeTts() {
    _flutterTts.setStartHandler(() {
      print("Playing");
    });

    _flutterTts.setCompletionHandler(() {
      print("TTS completed");
    });

    _flutterTts.setErrorHandler((msg) {
      print("TTS Error: $msg");
    });

    _flutterTts.awaitSpeakCompletion(true);
  }

  Future<void> speak(String text) async {
    await _flutterTts.stop(); // Ensure any previous speech is stopped
    await Future.delayed(
        const Duration(milliseconds: 500)); // Allow time for TTS to reset
    await _flutterTts.speak(text);
  }

  Future<void> stop() async {
    await _flutterTts.stop();
  }

  void setCompletionHandler(Function() handler) {
    _flutterTts.setCompletionHandler(handler);
  }
}
