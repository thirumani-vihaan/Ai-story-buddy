import 'dart:convert';

import 'package:http/http.dart' as http;

import '../data/quiz_repository.dart';
import '../models/quiz_question.dart';

/// A drop-in replacement for [QuizRepository] that can fetch a quiz payload
/// from a backend and gracefully fall back to the local JSON asset.
class RemoteQuizRepository extends QuizRepository {
  const RemoteQuizRepository({this.apiBaseUrl, super.assetPath, super.bundle});

  final String? apiBaseUrl;

  @override
  Future<QuizQuestion> loadQuestion() async {
    if (apiBaseUrl != null && apiBaseUrl!.isNotEmpty) {
      try {
        final url = Uri.parse('$apiBaseUrl/api/story-quiz');
        final response = await http.get(url).timeout(const Duration(seconds: 8));
        if (response.statusCode == 200) {
          final json = jsonDecode(response.body) as Map<String, dynamic>;
          return QuizQuestion.fromJson(json);
        }
      } catch (_) {
        // Network or parsing failure; fall through to the local asset.
      }
    }
    return super.loadQuestion();
  }
}
