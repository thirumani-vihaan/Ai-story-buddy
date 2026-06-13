import 'package:ai_story_buddy/models/quiz_question.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuizQuestion.fromJson', () {
    test('parses the brief\'s payload and resolves the answer index', () {
      final q = QuizQuestion.fromJson(const {
        'question': "What colour was Pip the Robot's lost gear?",
        'options': ['Red', 'Green', 'Blue', 'Yellow'],
        'answer': 'Blue',
      });

      expect(q.prompt, "What colour was Pip the Robot's lost gear?");
      expect(q.options, ['Red', 'Green', 'Blue', 'Yellow']);
      expect(q.correctIndex, 2);
      expect(q.correctAnswer, 'Blue');
      expect(q.isCorrect(2), isTrue);
      expect(q.isCorrect(0), isFalse);
    });

    test('renders a different question with a different option count (3)', () {
      final q = QuizQuestion.fromJson(const {
        'question': 'Where did Pip lose his gear?',
        'options': ['The City', 'The Whispering Woods', 'The Sea'],
        'answer': 'The Whispering Woods',
      });

      expect(q.options.length, 3);
      expect(q.correctIndex, 1);
    });

    test('handles five options without code changes', () {
      final q = QuizQuestion.fromJson(const {
        'question': 'Pick five',
        'options': ['A', 'B', 'C', 'D', 'E'],
        'answer': 'E',
      });

      expect(q.options.length, 5);
      expect(q.correctAnswer, 'E');
    });

    test('throws when the answer is not among the options', () {
      expect(
        () => QuizQuestion.fromJson(const {
          'question': 'Q',
          'options': ['A', 'B'],
          'answer': 'Z',
        }),
        throwsFormatException,
      );
    });

    test('throws when a required key is missing', () {
      expect(
        () => QuizQuestion.fromJson(const {
          'question': 'Q',
          'options': ['A', 'B'],
        }),
        throwsFormatException,
      );
    });
  });
}
