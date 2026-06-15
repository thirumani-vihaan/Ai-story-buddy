import '../data/quiz_repository.dart';
import '../models/quiz_question.dart';

/// Lightweight manager that mirrors the prefetching strategy from external
/// repos: start a background fetch for the next `QuizQuestion` when the
/// current one is revealed so swaps to the following question feel instant.
class QuizPrefetchManager {
  QuizPrefetchManager({this.repo});

  final QuizRepository? repo;

  Future<QuizQuestion>? _prefetch;
  bool _isReady = false;
  bool get isNextReady => _isReady;

  /// Start a background fetch if one isn't already running.
  void startPrefetch() {
    if (_prefetch != null) return;
    final future = (repo ?? const QuizRepository()).loadQuestion();
    _prefetch = future;
    _isReady = false;
    future.then((_) {
      _isReady = true;
    }).catchError((_) {
      _isReady = false;
    });
  }

  /// Consume the prefetch if available; returns null if no prefetch started.
  Future<QuizQuestion?> consumePrefetch() async {
    final p = _prefetch;
    if (p == null) return null;
    try {
      final q = await p;
      return q;
    } catch (_) {
      return null;
    } finally {
      _prefetch = null;
    }
  }
}
