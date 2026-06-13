import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/story_content.dart';
import 'screens/story_buddy_screen.dart';
import 'services/tts_service.dart';
import 'state/story_buddy_controller.dart';
import 'theme/app_theme.dart';

void main() => runApp(const AIStoryBuddyApp());

class AIStoryBuddyApp extends StatelessWidget {
  const AIStoryBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<StoryBuddyController>(
      create: (_) => StoryBuddyController(
        tts: FlutterTtsService(),
        narration: StoryContent.narration,
      )..loadQuiz(),
      child: MaterialApp(
        title: 'AI Story Buddy',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const StoryBuddyScreen(),
      ),
    );
  }
}
