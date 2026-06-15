import 'package:flutter/foundation.dart';

import '../data/quiz_repository.dart';
import '../models/quiz_question.dart';
import '../services/tts_service.dart';

/// Lifecycle of the read-aloud narration.
enum NarrationStatus { idle, preparing, reading, finished }

/// Owns all of the screen's state: the narration lifecycle (including the
/// word-by-word highlight) and the quiz.
///
/// It is deliberately **platform-free** (only `foundation` + an injected
/// [TtsService]) so it can be driven by a fake in tests. Imperative UI feedback
/// (confetti, haptics) is delegated to the view via [onCorrect] / [onWrong].
class StoryBuddyController extends ChangeNotifier {
  StoryBuddyController({
    required this.tts,
    required this.narration,
    this.quizRepository = const QuizRepository(),
    this.prefetchManager,
  }) {
    tts
      ..onStart = _handleStarted
      ..onComplete = _handleCompleted
      ..onCancel = _handleCancelled
      ..onError = _handleError
      ..onProgress = _handleProgress;
  }

  final TtsService tts;

  /// The exact text spoken *and* displayed, so highlight offsets line up.
  final String narration;
  final QuizRepository quizRepository;
  final dynamic prefetchManager;

  // ---- Narration ----
  NarrationStatus _status = NarrationStatus.idle;
  NarrationStatus get status => _status;
  bool get isBusy =>
      _status == NarrationStatus.preparing ||
      _status == NarrationStatus.reading;

  // ---- Highlight (karaoke) + seeking ----
  int _highlightStart = 0;
  int _highlightEnd = 0;
  int get highlightStart => _highlightStart;
  int get highlightEnd => _highlightEnd;

  // Character offset where the current speak() began (for drag-to-seek), and
  // flags that suppress the cancel/progress handlers while we re-issue speech.
  int _baseOffset = 0;
  bool _seeking = false;
  bool _scrubbing = false;

  /// Whether narration is active — used to show the seek bar only after the
  /// first tap on "Read Me a Story".
  bool get isNarrating =>
      _status == NarrationStatus.preparing ||
      _status == NarrationStatus.reading;

  /// Current read position as a 0..1 fraction of the whole story.
  double get progress {
    final length = narration.length;
    if (length == 0) return 0;
    return (_highlightEnd / length).clamp(0.0, 1.0);
  }

  // ---- Quiz ----
  QuizQuestion? _quiz;
  QuizQuestion? get quiz => _quiz;
  bool get isQuizReady => _quiz != null;

  bool _quizLoadFailed = false;
  bool get quizLoadFailed => _quizLoadFailed;

  bool _quizRevealed = false;
  bool get quizRevealed => _quizRevealed;

  int? _selectedIndex;
  int? get selectedIndex => _selectedIndex;

  bool _solved = false;
  bool get solved => _solved;

  int _wrongAttempts = 0;
  int get wrongAttempts => _wrongAttempts;

  int? _lastWrongIndex;
  int? get lastWrongIndex => _lastWrongIndex;

  /// View hooks for imperative feedback (confetti + haptics).
  VoidCallback? onCorrect;
  VoidCallback? onWrong;

  /// Loads the question from JSON (our "backend"). Called once at startup.
  Future<void> loadQuiz() async {
    _quizLoadFailed = false;
    try {
      // If a prefetch manager has a ready value, use it; otherwise fetch.
      if (prefetchManager != null) {
        final next = await prefetchManager.consumePrefetch();
        if (next != null) {
          _quiz = next;
          notifyListeners();
          return;
        }
      }
      _quiz = await quizRepository.loadQuestion();
      notifyListeners();
    } catch (_) {
      _quizLoadFailed = true;
      notifyListeners();
      // Keep _quiz null; the story still works and the quiz just won't reveal.
    }
  }

  Future<void> retryQuiz() async {
    await loadQuiz();
  }

  Future<void> readStory() async {
    if (isBusy) return;
    _resetHighlight();
    _baseOffset = 0;
    _setStatus(NarrationStatus.preparing);
    final started = await tts.speak(narration);
    if (!started) {
      _handleError('Narration could not start.');
    }
  }

  Future<void> stopNarration() => tts.stop();

  // ---- Drag-to-seek (the playback bar) ----

  /// Called when the user starts dragging the bar: pause audio so it doesn't
  /// fight the preview highlight.
  void beginScrub() {
    _scrubbing = true;
    tts.stop(); // cancel handler is guarded while _scrubbing is true
  }

  /// Called continuously while dragging: move the highlight (and the text
  /// auto-scroll) to the dragged position, without restarting audio yet.
  void previewSeek(double fraction) {
    final length = narration.length;
    if (length == 0) return;
    final offset = (fraction.clamp(0.0, 1.0) * length).round();
    final range = _wordRangeAt(offset);
    _highlightStart = range.$1;
    _highlightEnd = range.$2;
    notifyListeners();
  }

  /// Called when the drag ends: resume narration from the chosen word so the
  /// voice and the highlight stay in sync.
  Future<void> seekTo(double fraction) async {
    final length = narration.length;
    if (length == 0) return;
    final offset = (fraction.clamp(0.0, 1.0) * length).round();
    final start = _wordRangeAt(offset).$1;
    _baseOffset = start;
    _highlightStart = start;
    _highlightEnd = start;
    _scrubbing = false;
    _seeking = true;
    _setStatus(NarrationStatus.reading); // optimistic; keeps Stop + the bar
    await tts.stop();
    // Browsers can drop a `speak()` issued immediately after `cancel()`, so
    // give the engine a moment before re-speaking from the new position.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await tts.speak(narration.substring(start));
    _seeking = false;
  }

  /// The [start, end) character range of the word at [offset].
  (int, int) _wordRangeAt(int offset) {
    final length = narration.length;
    if (length == 0) return (0, 0);
    var index = offset.clamp(0, length - 1);
    while (index < length - 1 && _isSpace(narration[index])) {
      index++;
    }
    var start = index;
    while (start > 0 && !_isSpace(narration[start - 1])) {
      start--;
    }
    var end = index + 1;
    while (end < length && !_isSpace(narration[end])) {
      end++;
    }
    return (start, end);
  }

  bool _isSpace(String ch) =>
      ch == ' ' || ch == '\n' || ch == '\t' || ch == '\r';

  void selectOption(int index) {
    if (_solved || _quiz == null) return;
    _selectedIndex = index;
    if (_quiz!.isCorrect(index)) {
      _solved = true;
      onCorrect?.call();
    } else {
      _wrongAttempts++;
      _lastWrongIndex = index;
      onWrong?.call();
    }
    notifyListeners();
  }

  /// Back to the story so the child can listen and play again.
  void playAgain() {
    _selectedIndex = null;
    _lastWrongIndex = null;
    _wrongAttempts = 0;
    _solved = false;
    _quizRevealed = false;
    _resetHighlight();
    _setStatus(NarrationStatus.idle);
  }

  /// Advance to the next story+quiz pair, preferring a prefetched payload
  /// when available so swaps feel instant.
  Future<void> loadNext() async {
    // Try consuming a background prefetch first.
    try {
      final next = await prefetchManager?.consumePrefetch();
      if (next != null) {
        _applyNextData(next);
        return;
      }
    } catch (_) {}

    // Fallback: fetch fresh from the repository.
    try {
      _quiz = null;
      notifyListeners();
      final data = await quizRepository.loadQuestion();
      _applyNextData(data);
    } catch (_) {
      _quizLoadFailed = true;
      notifyListeners();
    }
  }

  void _applyNextData(QuizQuestion data) {
    _quiz = data;
    _selectedIndex = null;
    _lastWrongIndex = null;
    _wrongAttempts = 0;
    _solved = false;
    _quizRevealed = false;
    _quizLoadFailed = false;
    notifyListeners();

    // Start prefetch for the following pair.
    try {
      prefetchManager?.startPrefetch();
    } catch (_) {}
  }

  // ---- TTS handlers ----
  void _handleStarted() {
    if (_status == NarrationStatus.preparing) {
      _setStatus(NarrationStatus.reading);
    }
  }

  void _handleProgress(int start, int end) {
    if (_scrubbing) return;
    _highlightStart = _baseOffset + start;
    _highlightEnd = _baseOffset + end;
    notifyListeners();
  }

  void _handleCompleted() {
    _resetHighlight();
    _setStatus(NarrationStatus.finished);
    if (!_quizRevealed) {
      _quizRevealed = true;
      notifyListeners();
      // Start prefetch for the following pair if available
      try {
        prefetchManager?.startPrefetch();
      } catch (_) {}
    }
  }

  void _handleCancelled() {
    if (_seeking || _scrubbing) return;
    _resetHighlight();
    if (!_quizRevealed) _setStatus(NarrationStatus.idle);
  }

  void _handleError(String message) {
    // Errors fired while we deliberately stop/seek are just cancellation
    // artifacts - ignore them. Any other error fails quietly back to idle
    // (no alarming message); the child can simply tap "Read Me a Story" again.
    if (_seeking || _scrubbing) return;
    debugPrint('TTS error: $message');
    _resetHighlight();
    if (!_quizRevealed) _setStatus(NarrationStatus.idle);
  }

  void _resetHighlight() {
    _highlightStart = 0;
    _highlightEnd = 0;
  }

  void _setStatus(NarrationStatus status) {
    _status = status;
    notifyListeners();
  }

  @override
  void dispose() {
    tts.dispose();
    super.dispose();
  }
}
