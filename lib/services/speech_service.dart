import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// A small wrapper around speech_to_text that never throws into the UI.
class SpeechService {
  final SpeechToText _speech = SpeechToText();
  bool _initialized = false;
  bool _available = false;
  String? _lastError;
  bool _cancelled = false;

  bool get isAvailable => _available;
  bool get isListening => _speech.isListening;
  String? get lastError => _lastError;

  Future<bool> initialize() async {
    if (_initialized) return _available;
    _initialized = true;
    try {
      _available = await _speech.initialize(
        onError: (error) {
          _lastError = error.errorMsg;
        },
        onStatus: (status) {
          if (kDebugMode) debugPrint('STT status: $status');
        },
        finalTimeout: const Duration(seconds: 3),
      );
    } catch (e) {
      _available = false;
      _lastError = e.toString();
    }
    return _available;
  }

  /// Listens once and returns the final transcript. Returns null when speech
  /// recognition is unavailable, the user cancels, or nothing was heard.
  Future<String?> listen({
    String localeId = 'en_US',
    Duration listenFor = const Duration(seconds: 30),
    Duration pauseFor = const Duration(seconds: 4),
    ValueChanged<String>? onPartial,
  }) async {
    _cancelled = false;
    final ok = await initialize();
    if (!ok) return null;

    final completer = Completer<String?>();
    var transcript = '';

    void finish(String? value) {
      if (!completer.isCompleted) completer.complete(value);
    }

    try {
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          transcript = result.recognizedWords.trim();
          onPartial?.call(transcript);
          if (result.finalResult) finish(transcript.isEmpty ? null : transcript);
        },
        listenOptions: SpeechListenOptions(
          partialResults: true,
          cancelOnError: false,
          listenFor: listenFor,
          pauseFor: pauseFor,
          localeId: localeId,
        ),
      );
    } catch (e) {
      _lastError = e.toString();
      return null;
    }

    final safety = Timer(listenFor + const Duration(seconds: 3), () async {
      if (completer.isCompleted) return;
      try {
        await _speech.stop();
      } catch (_) {}
      finish(transcript.isEmpty ? null : transcript);
    });

    final value = await completer.future;
    safety.cancel();
    if (_cancelled) return null;
    return value;
  }

  Future<void> stop() async {
    try {
      await _speech.stop();
    } catch (_) {}
  }

  Future<void> cancel() async {
    _cancelled = true;
    try {
      await _speech.cancel();
    } catch (_) {}
  }

  Future<void> dispose() async {
    await cancel();
  }
}
