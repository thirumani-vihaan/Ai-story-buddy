import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../data/story_content.dart';
import '../state/story_buddy_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/app_header.dart';
import '../widgets/buddy_avatar.dart';
import '../widgets/option_card.dart';
import '../widgets/primary_button.dart';

/// The whole experience on one screen. The layout is a fixed column —
/// Buddy on top, a flexible middle that swaps between the story and the quiz,
/// and a pinned action button — so the header, Buddy, story and button always
/// fit the viewport on phones, tablets and laptops. Long story/quiz content
/// scrolls *inside* the flexible middle rather than growing the page.
class StoryBuddyScreen extends StatefulWidget {
  const StoryBuddyScreen({super.key});

  @override
  State<StoryBuddyScreen> createState() => _StoryBuddyScreenState();
}

class _StoryBuddyScreenState extends State<StoryBuddyScreen> {
  final ConfettiController _confetti =
      ConfettiController(duration: const Duration(seconds: 1));
  StoryBuddyController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = context.read<StoryBuddyController>();
    if (!identical(controller, _controller)) {
      _controller = controller
        ..onCorrect = _celebrate
        ..onWrong = _nudge;
    }
  }

  void _celebrate() {
    HapticFeedback.heavyImpact();
    _confetti.play();
  }

  void _nudge() => HapticFeedback.mediumImpact();

  @override
  void dispose() {
    _confetti.dispose();
    super.dispose();
  }

  double _buddySize(double height) {
    if (height < 560) return 84;
    if (height < 700) return 112;
    if (height < 900) return 140;
    return 160;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final revealed =
        context.select<StoryBuddyController, bool>((c) => c.quizRevealed);

    return Scaffold(
      appBar: const AppHeader(),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _Buddy(size: _buddySize(size.height)),
                      const SizedBox(height: 14),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          switchInCurve: Curves.easeOut,
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 0.04),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                          child: revealed
                              ? const _QuizView(key: ValueKey('quiz'))
                              : const _StoryView(key: ValueKey('story')),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confetti,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                numberOfParticles: 26,
                minBlastForce: 8,
                maxBlastForce: 20,
                gravity: 0.25,
                emissionFrequency: 0.05,
                colors: const [
                  AppColors.primary,
                  AppColors.accent,
                  AppColors.success,
                  AppColors.gear,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Buddy extends StatelessWidget {
  const _Buddy({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final mood = context.select<StoryBuddyController, BuddyMood>((c) {
      if (c.solved) return BuddyMood.happy;
      if (c.status == NarrationStatus.preparing ||
          c.status == NarrationStatus.reading) {
        return BuddyMood.reading;
      }
      return BuddyMood.idle;
    });
    return Center(
      child: RepaintBoundary(child: BuddyAvatar(mood: mood, size: size)),
    );
  }
}

class _StoryView extends StatelessWidget {
  const _StoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<StoryBuddyController>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(child: _StoryCard()),
        const SizedBox(height: 10),
        if (c.isNarrating) ...[
          const _PlaybackBar(),
          const SizedBox(height: 6),
        ],
        const _ReadButton(),
      ],
    );
  }
}

/// The story card: a header, the title, and the read-aloud text in an internal
/// scroll view. While narrating, the current word is highlighted and the text
/// auto-scrolls to follow along.
class _StoryCard extends StatefulWidget {
  const _StoryCard();

  @override
  State<_StoryCard> createState() => _StoryCardState();
}

class _StoryCardState extends State<_StoryCard> {
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<StoryBuddyController>();
    final text = c.narration;
    final length = text.length;
    final start = c.highlightStart.clamp(0, length);
    final end = c.highlightEnd.clamp(start, length);

    if (c.status == NarrationStatus.reading && end > 0 && length > 0) {
      // Keep the spoken word in view (proportional, smooth auto-scroll).
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scroll.hasClients) return;
        final maxExtent = _scroll.position.maxScrollExtent;
        if (maxExtent <= 0) return;
        final target = (end / length) * maxExtent;
        if ((target - _scroll.offset).abs() > 6) {
          _scroll.animateTo(
            target,
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
          );
        }
      });
    } else if (c.status == NarrationStatus.preparing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients && _scroll.offset != 0) _scroll.jumpTo(0);
      });
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withValues(alpha: 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                'STORY TIME',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSoft,
                ),
              ),
              Spacer(),
              Icon(Icons.menu_book_rounded, size: 18, color: AppColors.textSoft),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            StoryContent.title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: SingleChildScrollView(
              controller: _scroll,
              child: _StoryBody(text: text, start: start, end: end),
            ),
          ),
        ],
      ),
    );
  }
}

class _StoryBody extends StatelessWidget {
  const _StoryBody({required this.text, required this.start, required this.end});

  final String text;
  final int start;
  final int end;

  @override
  Widget build(BuildContext context) {
    const base = TextStyle(fontSize: 17, height: 1.55, color: AppColors.textStrong);
    if (end <= start) {
      return Text(text, style: base);
    }
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(text: text.substring(0, start)),
          TextSpan(
            text: text.substring(start, end),
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
              backgroundColor: Color(0xFFFFE39A),
            ),
          ),
          TextSpan(text: text.substring(end)),
        ],
      ),
      style: base,
    );
  }
}

class _ReadButton extends StatelessWidget {
  const _ReadButton();

  @override
  Widget build(BuildContext context) {
    final c = context.watch<StoryBuddyController>();
    switch (c.status) {
      case NarrationStatus.preparing:
        return const PrimaryButton(
          label: 'Preparing the story…',
          onPressed: null,
          busy: true,
        );
      case NarrationStatus.reading:
        return PrimaryButton(
          label: 'Stop',
          icon: Icons.stop_rounded,
          color: AppColors.primaryDark,
          onPressed: c.stopNarration,
        );
      case NarrationStatus.idle:
      case NarrationStatus.finished:
        return PrimaryButton(
          label: 'Read Me a Story',
          icon: Icons.volume_up_rounded,
          onPressed: c.isQuizReady ? c.readStory : null,
        );
    }
  }
}

class _PlaybackBar extends StatefulWidget {
  const _PlaybackBar();

  @override
  State<_PlaybackBar> createState() => _PlaybackBarState();
}

class _PlaybackBarState extends State<_PlaybackBar> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    final c = context.watch<StoryBuddyController>();
    final double value = (_dragValue ?? c.progress).clamp(0.0, 1.0).toDouble();
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 6,
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.outline,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: 0.14),
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
      ),
      child: Slider(
        value: value,
        onChangeStart: (_) => context.read<StoryBuddyController>().beginScrub(),
        onChanged: (v) {
          setState(() => _dragValue = v);
          context.read<StoryBuddyController>().previewSeek(v);
        },
        onChangeEnd: (v) {
          setState(() => _dragValue = null);
          context.read<StoryBuddyController>().seekTo(v);
        },
      ),
    );
  }
}

class _QuizView extends StatelessWidget {
  const _QuizView({super.key});

  OptionState _stateFor(StoryBuddyController c, int index) {
    if (c.solved) {
      return index == c.quiz!.correctIndex
          ? OptionState.correct
          : OptionState.disabled;
    }
    return c.selectedIndex == index ? OptionState.wrong : OptionState.idle;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<StoryBuddyController>();
    final quiz = c.quiz;
    if (quiz == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'QUIZ TIME',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSoft,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  quiz.prompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textStrong,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 18),
                for (int i = 0; i < quiz.options.length; i++)
                  OptionCard(
                    label: quiz.options[i],
                    state: _stateFor(c, i),
                    shouldShake: !c.solved && c.lastWrongIndex == i,
                    shakeTick: c.wrongAttempts,
                    onTap: c.solved ? null : () => c.selectOption(i),
                  ),
                const SizedBox(height: 2),
                _Feedback(solved: c.solved, triedWrong: c.selectedIndex != null),
              ],
            ),
          ),
        ),
        if (c.solved) ...[
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Read it Again',
            icon: Icons.replay_rounded,
            color: AppColors.accent,
            foreground: AppColors.primaryDark,
            onPressed: c.playAgain,
          ),
        ],
      ],
    );
  }
}

class _Feedback extends StatelessWidget {
  const _Feedback({required this.solved, required this.triedWrong});

  final bool solved;
  final bool triedWrong;

  @override
  Widget build(BuildContext context) {
    if (solved) {
      return const Text(
        'Yay! You got it! 🎉',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.success,
          fontWeight: FontWeight.w700,
          fontSize: 16,
        ),
      );
    }
    if (triedWrong) {
      return const Text(
        "Oops! That's not it - give it another try 🙂",
        textAlign: TextAlign.center,
        style: TextStyle(color: AppColors.textSoft, fontSize: 15),
      );
    }
    return const SizedBox(height: 8);
  }
}
