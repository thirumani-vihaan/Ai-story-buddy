import 'package:ai_story_buddy/data/quiz_repository.dart';
import 'package:ai_story_buddy/state/story_buddy_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fakes.dart';

void main() {
  StoryBuddyController build(FakeTtsService fake) => StoryBuddyController(
        tts: fake,
        narration: 'A short tale.',
        quizRepository: QuizRepository(bundle: FakeQuizBundle()),
      );

  test('starts idle with no quiz revealed', () {
    final c = build(FakeTtsService());
    addTearDown(c.dispose);
    expect(c.status, NarrationStatus.idle);
    expect(c.quizRevealed, isFalse);
  });

  test('completing the narration reveals the quiz', () async {
    final fake = FakeTtsService();
    final c = build(fake);
    addTearDown(c.dispose);

    await c.readStory();

    expect(fake.speakCalls, 1);
    expect(c.status, NarrationStatus.finished);
    expect(c.quizRevealed, isTrue);
  });

  test('stays in the reading state until narration completes', () async {
    final fake = FakeTtsService()..autoComplete = false;
    final c = build(fake);
    addTearDown(c.dispose);

    await c.readStory();
    expect(c.status, NarrationStatus.reading);
    expect(c.quizRevealed, isFalse);

    fake.finishNarration();
    expect(c.status, NarrationStatus.finished);
    expect(c.quizRevealed, isTrue);
  });

  test('progress sets the highlight range, completion clears it', () async {
    final fake = FakeTtsService()..autoComplete = false;
    final c = build(fake);
    addTearDown(c.dispose);

    await c.readStory();
    fake.emitProgress(2, 7);
    expect(c.highlightStart, 2);
    expect(c.highlightEnd, 7);

    fake.finishNarration();
    expect(c.highlightStart, 0);
    expect(c.highlightEnd, 0);
  });

  test('a failed speak returns to idle without revealing the quiz', () async {
    final fake = FakeTtsService()..speakResult = false;
    final c = build(fake);
    addTearDown(c.dispose);

    await c.readStory();

    expect(c.status, NarrationStatus.idle);
    expect(c.quizRevealed, isFalse);
  });

  test('wrong answer increments attempts and fires onWrong', () async {
    final fake = FakeTtsService();
    final c = build(fake);
    addTearDown(c.dispose);
    await c.loadQuiz();
    await c.readStory();

    var wrong = 0;
    var correct = 0;
    c.onWrong = () => wrong++;
    c.onCorrect = () => correct++;

    c.selectOption(0); // 'Red' - wrong (answer is 'Blue', index 2)
    expect(c.solved, isFalse);
    expect(c.wrongAttempts, 1);
    expect(c.lastWrongIndex, 0);
    expect(wrong, 1);

    c.selectOption(2); // 'Blue' - correct
    expect(c.solved, isTrue);
    expect(correct, 1);
  });

  test('playAgain resets both quiz and narration state', () async {
    final fake = FakeTtsService();
    final c = build(fake);
    addTearDown(c.dispose);
    await c.loadQuiz();
    await c.readStory();
    c.selectOption(2);
    expect(c.solved, isTrue);

    c.playAgain();

    expect(c.solved, isFalse);
    expect(c.quizRevealed, isFalse);
    expect(c.wrongAttempts, 0);
    expect(c.status, NarrationStatus.idle);
  });

  test('previewSeek moves the highlight without restarting audio', () {
    final fake = FakeTtsService();
    final c = StoryBuddyController(
      tts: fake,
      narration: 'alpha bravo charlie',
      quizRepository: QuizRepository(bundle: FakeQuizBundle()),
    );
    addTearDown(c.dispose);

    c.previewSeek(0);
    expect(fake.speakCalls, 0);
    expect(c.highlightStart, 0);
    expect(c.highlightEnd, 5); // "alpha"
  });

  test('seekTo resumes narration from the word at the position', () async {
    final fake = FakeTtsService()..autoComplete = false;
    final c = StoryBuddyController(
      tts: fake,
      narration: 'alpha bravo charlie delta',
      quizRepository: QuizRepository(bundle: FakeQuizBundle()),
    );
    addTearDown(c.dispose);

    await c.seekTo(0.5); // lands inside "charlie"
    expect(fake.lastSpokenText, 'charlie delta');
    expect(c.status, NarrationStatus.reading);

    // Progress offsets are now relative to the resumed substring.
    fake.emitProgress(0, 7); // "charlie"
    expect(c.highlightStart, 12);
    expect(c.highlightEnd, 19);
  });
}
