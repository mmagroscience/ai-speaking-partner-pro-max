import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

class TtsService {
  final FlutterTts _tts = FlutterTts();
  bool _ready = false;
  bool _speaking = false;
  bool _banglaAvailable = false;

  VoidCallback? onStart;
  VoidCallback? onComplete;
  ValueChanged<String>? onProgress;

  bool get isSpeaking => _speaking;
  bool get banglaAvailable => _banglaAvailable;

  Future<void> init() async {
    if (_ready) return;
    _ready = true;
    try {
      await _tts.setSpeechRate(0.46);
      await _tts.setPitch(1.0);
      await _tts.setVolume(1.0);
      await _tts.awaitSpeakCompletion(false);
      _tts.setStartHandler(() {
        _speaking = true;
        onStart?.call();
      });
      _tts.setCompletionHandler(() {
        _speaking = false;
        onComplete?.call();
      });
      _tts.setCancelHandler(() {
        _speaking = false;
        onComplete?.call();
      });
      _tts.setErrorHandler((message) {
        _speaking = false;
        if (kDebugMode) debugPrint('TTS error: $message');
        onComplete?.call();
      });
      _tts.setProgressHandler((text, start, end, word) {
        onProgress?.call(word);
      });
      _banglaAvailable = await _tts.isLanguageAvailable('bn-BD');
    } catch (e) {
      if (kDebugMode) debugPrint('TTS init failed: $e');
    }
  }

  Future<void> speak(String text, {bool bangla = false}) async {
    if (text.trim().isEmpty) return;
    await init();
    try {
      await _tts.stop();
      if (bangla && _banglaAvailable) {
        await _tts.setLanguage('bn-BD');
      } else {
        await _tts.setLanguage('en-US');
      }
      await _tts.speak(text);
    } catch (e) {
      _speaking = false;
      if (kDebugMode) debugPrint('TTS speak failed: $e');
      onComplete?.call();
    }
  }

  Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _speaking = false;
  }

  Future<void> dispose() async {
    await stop();
  }
}
