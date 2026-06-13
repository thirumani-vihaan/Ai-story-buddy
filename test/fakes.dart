import 'package:ai_story_buddy/services/tts_service.dart';
import 'package:flutter/services.dart';

/// The quiz payload used in tests (mirrors assets/quiz.json).
const String kQuizJson =
    '{"question":"What colour was Pip the Robot\'s lost gear?",'
    '"options":["Red","Green","Blue","Yellow"],"answer":"Blue"}';

/// An [AssetBundle] that returns a fixed quiz payload. Using a fresh instance
/// per test keeps quiz loading off the global `rootBundle`, which otherwise
/// gets into a bad state across multiple widget tests in one file.
class FakeQuizBundle extends AssetBundle {
  FakeQuizBundle([this.json = kQuizJson]);

  final String json;

  @override
  Future<String> loadString(String key, {bool cache = true}) async => json;

  @override
  Future<ByteData> load(String key) => throw UnimplementedError();
}

/// A controllable [TtsService]. By default `speak` fires the start handler then
/// the completion handler, mimicking a full narration. Set [speakResult] false
/// to simulate failure, or [autoComplete] false to hold in the reading state
/// and drive [finishNarration] / [emitProgress] manually.
class FakeTtsService implements TtsService {
  void Function()? _onStart;
  void Function()? _onComplete;
  void Function()? _onCancel;
  void Function(String message)? _onError;
  void Function(int start, int end)? _onProgress;

  bool speakResult = true;
  bool autoComplete = true;
  int speakCalls = 0;
  int stopCalls = 0;
  String? lastSpokenText;
  TtsVoice? lastSetVoice;

  /// Voices the fake engine reports (a natural Google voice + a Microsoft one).
  List<TtsVoice> availableVoices = const [
    TtsVoice(name: 'Google US English', locale: 'en-US'),
    TtsVoice(name: 'Microsoft David', locale: 'en-US'),
  ];

  @override
  set onStart(void Function() handler) => _onStart = handler;
  @override
  set onComplete(void Function() handler) => _onComplete = handler;
  @override
  set onCancel(void Function() handler) => _onCancel = handler;
  @override
  set onError(void Function(String message) handler) => _onError = handler;
  @override
  set onProgress(void Function(int start, int end) handler) =>
      _onProgress = handler;

  @override
  Future<List<TtsVoice>> voices() async => availableVoices;

  @override
  Future<void> setVoice(TtsVoice voice) async => lastSetVoice = voice;

  void finishNarration() => _onComplete?.call();
  void failNarration(String message) => _onError?.call(message);
  void emitProgress(int start, int end) => _onProgress?.call(start, end);

  @override
  Future<bool> speak(String text) async {
    speakCalls++;
    lastSpokenText = text;
    if (!speakResult) return false;
    _onStart?.call();
    if (autoComplete) _onComplete?.call();
    return true;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    _onCancel?.call();
  }

  @override
  void dispose() {}
}
