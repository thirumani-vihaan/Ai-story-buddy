import 'package:flutter/foundation.dart';

/// A single multiple-choice quiz question.
///
/// Built to be **data-driven**: [QuizQuestion.fromJson] parses the exact shape
/// our backend sends (`question`, `options`, `answer`). The number of [options]
/// is whatever the payload contains (3, 4 or 5), so the renderer flexes without
/// any code changes.
@immutable
class QuizQuestion {
  const QuizQuestion({
    required this.prompt,
    required this.options,
    required this.correctIndex,
  });

  /// Parses a backend payload such as:
  /// ```json
  /// {
  ///   "question": "What colour was Pip the Robot's lost gear?",
  ///   "options": ["Red", "Green", "Blue", "Yellow"],
  ///   "answer": "Blue"
  /// }
  /// ```
  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final prompt = json['question'] as String?;
    final rawOptions = json['options'] as List<dynamic>?;
    final answer = json['answer'] as String?;

    if (prompt == null || rawOptions == null || answer == null) {
      throw const FormatException(
          'Quiz JSON must contain "question", "options" and "answer".');
    }

    final options = rawOptions.map((dynamic o) => o.toString()).toList();
    final correctIndex = options.indexOf(answer);
    if (correctIndex < 0) {
      throw FormatException('Answer "$answer" is not one of the options.');
    }

    return QuizQuestion(
      prompt: prompt,
      options: options,
      correctIndex: correctIndex,
    );
  }

  final String prompt;
  final List<String> options;
  final int correctIndex;

  String get correctAnswer => options[correctIndex];

  bool isCorrect(int index) => index == correctIndex;
}
