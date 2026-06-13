import 'dart:convert';

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

import '../models/quiz_question.dart';

/// Loads the quiz from a JSON asset, mimicking a call to our backend.
///
/// The [AssetBundle] is injectable so tests can supply a fake payload without
/// touching the global `rootBundle` (which other widgets, e.g. GoogleFonts,
/// also read).
class QuizRepository {
  const QuizRepository({this.assetPath = 'assets/quiz.json', this.bundle});

  final String assetPath;
  final AssetBundle? bundle;

  Future<QuizQuestion> loadQuestion() async {
    final raw = await (bundle ?? rootBundle).loadString(assetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return QuizQuestion.fromJson(json);
  }
}
