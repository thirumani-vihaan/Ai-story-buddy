import 'package:ai_story_buddy/data/quiz_repository.dart';
import 'package:ai_story_buddy/data/story_content.dart';
import 'package:ai_story_buddy/screens/story_buddy_screen.dart';
import 'package:ai_story_buddy/state/story_buddy_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'fakes.dart';

void main() {
  // Buddy's gear animation loops forever, so `pumpAndSettle` would never
  // return. Advance time with explicit pumps instead.
  Future<void> tick(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
  }

  Future<FakeTtsService> pumpApp(WidgetTester tester) async {
    final fake = FakeTtsService();
    final controller = StoryBuddyController(
      tts: fake,
      narration: 'A short tale.',
      quizRepository: QuizRepository(bundle: FakeQuizBundle()),
    );
    await controller.loadQuiz();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<StoryBuddyController>.value(
        value: controller,
        child: const MaterialApp(home: StoryBuddyScreen()),
      ),
    );
    await tester.pump();
    return fake;
  }

  Future<void> readStory(WidgetTester tester) async {
    await tester.tap(find.text('Read Me a Story'));
    await tick(tester);
  }

  testWidgets('shows the story title and the Read button', (tester) async {
    await pumpApp(tester);

    expect(find.text(StoryContent.title), findsOneWidget);
    expect(find.text('Read Me a Story'), findsOneWidget);
  });

  testWidgets('finishing narration reveals the data-driven quiz',
      (tester) async {
    await pumpApp(tester);
    await readStory(tester);

    expect(find.text("What colour was Pip the Robot's lost gear?"),
        findsOneWidget);
    for (final option in ['Red', 'Green', 'Blue', 'Yellow']) {
      expect(find.text(option), findsOneWidget);
    }
  });

  testWidgets('wrong answer nudges, correct answer celebrates',
      (tester) async {
    await pumpApp(tester);
    await readStory(tester);

    await tester.ensureVisible(find.text('Red'));
    await tester.tap(find.text('Red'));
    await tick(tester);
    expect(find.textContaining('another try'), findsOneWidget);
    expect(find.text('Read it Again'), findsNothing);

    await tester.ensureVisible(find.text('Blue'));
    await tester.tap(find.text('Blue'));
    await tick(tester);
    expect(find.text('Yay! You got it! 🎉'), findsOneWidget);
    expect(find.text('Read it Again'), findsOneWidget);
  });

  testWidgets('a failed read silently returns to the Read button',
      (tester) async {
    final fake = await pumpApp(tester);
    fake.speakResult = false;

    await tester.tap(find.text('Read Me a Story'));
    await tick(tester);

    // No error UI — the Read button is simply still there to try again.
    expect(find.text('Read Me a Story'), findsOneWidget);
    expect(find.textContaining('check your sound'), findsNothing);

    // Recover: a successful read reveals the quiz.
    fake.speakResult = true;
    await tester.tap(find.text('Read Me a Story'));
    await tick(tester);
    expect(find.text('Blue'), findsOneWidget);
  });

  testWidgets('the seek bar appears only after Read is tapped', (tester) async {
    final fake = await pumpApp(tester);
    fake.autoComplete = false; // hold in the reading state

    expect(find.byType(Slider), findsNothing);

    await tester.tap(find.text('Read Me a Story'));
    await tick(tester);

    expect(find.byType(Slider), findsOneWidget);
  });
}
