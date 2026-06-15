import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/quiz_repository.dart';
import 'data/story_content.dart';
import 'features/app_feature.dart';
import 'features/feature_registry.dart';
import 'features/remote_quiz_repository.dart';
import 'features/quiz_prefetch_manager.dart';
import 'screens/story_buddy_screen.dart';
import 'services/tts_service.dart';
import 'state/story_buddy_controller.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final featureRegistry = await FeatureRegistry.load(
    defaultEnabled: {
      AppFeature.remoteQuizPrefetch: true,
      AppFeature.animatedSoundWaves: true,
      AppFeature.wrongAnswerShake: true,
      AppFeature.buddyMotionMagic: true,
    },
    initTasks: {
      AppFeature.remoteQuizPrefetch: () async {
        await const RemoteQuizRepository().loadQuestion();
      },
    },
  );
  await featureRegistry.initialize();

  final prefetchManager = QuizPrefetchManager(repo: featureRegistry.isEnabled(AppFeature.remoteQuizPrefetch) ? const RemoteQuizRepository() : const QuizRepository());

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<FeatureRegistry>.value(value: featureRegistry),
        // Provide a shared prefetch manager so features can warm the next quiz.
        Provider.value(value: prefetchManager),
        ChangeNotifierProvider<StoryBuddyController>(
          create: (_) => StoryBuddyController(
            tts: FlutterTtsService(),
            narration: StoryContent.narration,
            quizRepository: featureRegistry.isEnabled(AppFeature.remoteQuizPrefetch)
                ? const RemoteQuizRepository()
                : const QuizRepository(),
            prefetchManager: prefetchManager,
          )..loadQuiz(),
        ),
      ],
      child: const AIStoryBuddyApp(),
    ),
  );
}

class AIStoryBuddyApp extends StatelessWidget {
  const AIStoryBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Story Buddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const StoryBuddyScreen(),
    );
  }
}
