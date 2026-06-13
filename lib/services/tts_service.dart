import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';

/// A named voice exposed by the platform TTS engine.
class TtsVoice {
  const TtsVoice({required this.name, required this.locale});

  final String name;
  final String locale;
}

/// Abstraction over text-to-speech so the controller can be unit-tested with a
/// fake, and so we could swap in a remote engine later.
abstract class TtsService {
  /// Begins speaking [text]. Returns `true` if narration was started.
  Future<bool> speak(String text);

  /// Stops any in-progress narration (treated as a user cancel).
  Future<void> stop();

  /// The voices the engine offers (may be empty on platforms without metadata).
  Future<List<TtsVoice>> voices();

  /// Selects a specific engine [voice] for subsequent narration.
  Future<void> setVoice(TtsVoice voice);

  set onStart(void Function() handler);
  set onComplete(void Function() handler);
  set onCancel(void Function() handler);
  set onError(void Function(String message) handler);

  /// Fires as each word is spoken, with the [start]/[end] character offsets of
  /// that word within the spoken text (used to highlight the story).
  set onProgress(void Function(int start, int end) handler);

  void dispose();
}

/// [TtsService] backed by the device's native engine via `flutter_tts`.
class FlutterTtsService implements TtsService {
  FlutterTtsService([FlutterTts? tts]) : _tts = tts ?? FlutterTts();

  final FlutterTts _tts;
  bool _configured = false;

  @override
  set onStart(void Function() handler) => _tts.setStartHandler(handler);

  @override
  set onComplete(void Function() handler) => _tts.setCompletionHandler(handler);

  @override
  set onCancel(void Function() handler) => _tts.setCancelHandler(handler);

  @override
  set onError(void Function(String message) handler) =>
      _tts.setErrorHandler((dynamic message) => handler(message.toString()));

  @override
  set onProgress(void Function(int start, int end) handler) =>
      _tts.setProgressHandler(
        (String text, int start, int end, String word) => handler(start, end),
      );

  Future<void> _configure() async {
    if (_configured) return;
    // A natural, gentle, kid-friendly default.
    try {
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);
    } on MissingPluginException {
      // No platform support (e.g. tests).
    } on PlatformException {
      // Engine not ready - speak() will surface real failures.
    }
    _configured = true;
  }

  @override
  Future<List<TtsVoice>> voices() async {
    try {
      final raw = await _tts.getVoices;
      if (raw is List) {
        return raw
            .whereType<Map>()
            .map((m) => TtsVoice(
                  name: (m['name'] ?? '').toString(),
                  locale: (m['locale'] ?? '').toString(),
                ))
            .where((v) => v.name.isNotEmpty)
            .toList();
      }
    } on MissingPluginException {
      // No engine.
    } on PlatformException {
      // Ignore.
    }
    return const [];
  }

  @override
  Future<void> setVoice(TtsVoice voice) async {
    try {
      await _tts.setVoice({'name': voice.name, 'locale': voice.locale});
    } on MissingPluginException {
      // No engine.
    } on PlatformException {
      // Ignore.
    }
  }

  @override
  Future<bool> speak(String text) async {
    try {
      await _configure();
      await _tts.stop();
      final result = await _tts.speak(text);
      // flutter_tts returns 1 on success, 0 on failure (platform dependent).
      return result == 1 || result == null;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _tts.stop();
    } on MissingPluginException {
      // No engine available - nothing to stop.
    }
  }

  @override
  void dispose() {
    _tts.stop();
  }
}
