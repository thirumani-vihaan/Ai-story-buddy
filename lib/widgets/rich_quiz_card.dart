import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'dart:math' as math;
import 'package:vibration/vibration.dart';

import '../models/quiz_question.dart';
// Theme and buttons are intentionally lightweight here; avoid extra deps.

/// Polished, animated quiz card inspired by external repos. Designed to be
/// drop-in for `QuizQuestion` and optionally more lively than the default.
class RichQuizCard extends StatefulWidget {
  const RichQuizCard({super.key, required this.quiz, this.onSelect});

  final QuizQuestion quiz;
  final ValueChanged<int>? onSelect;

  @override
  State<RichQuizCard> createState() => _RichQuizCardState();
}

class _RichQuizCardState extends State<RichQuizCard> with SingleTickerProviderStateMixin {
  String? _selectedAnswer;
  bool _showSuccess = false;
  late ConfettiController _confettiController;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _handleAnswer(String answer) async {
    if (_selectedAnswer != null) return;

    setState(() => _selectedAnswer = answer);

    final index = widget.quiz.options.indexOf(answer);
    final isCorrect = widget.quiz.isCorrect(index);

    if (!isCorrect) {
      _triggerWrongAnswer();
    } else {
      await _triggerCorrectAnswer();
    }

    widget.onSelect?.call(index);
  }

  void _triggerWrongAnswer() {
    _shakeController.forward(from: 0);
    _hapticFeedback();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _selectedAnswer = null;
        });
      }
    });
  }

  Future<void> _triggerCorrectAnswer() async {
    _confettiController.play();
    setState(() => _showSuccess = true);
    await Future.delayed(const Duration(milliseconds: 100));
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(pattern: [0, 50, 50, 50]);
    }
  }

  Future<void> _hapticFeedback() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quiz = widget.quiz;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, _) {
            final shakeOffset = _shakeController.isAnimating
                ? math.sin(_shakeAnimation.value * math.pi * 8) * 10
                : 0.0;
            return Transform.translate(
              offset: Offset(shakeOffset, 0),
              child: _buildQuizCard(quiz),
            );
          },
        ),
        Positioned(
          top: -10,
          left: MediaQuery.of(context).size.width / 2 - 50,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            colors: const [
              Color(0xFF8B5CF6),
              Color(0xFFF97316),
              Color(0xFFFCD34D),
              Color(0xFF34D399),
            ],
            numberOfParticles: 30,
            gravity: 0.3,
          ),
        ),
      ],
    );
  }

  Widget _buildQuizCard(QuizQuestion quiz) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            Color(0xFFFFF7ED),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFB923C).withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: _selectedAnswer != null && !_isSelectedCorrect()
            ? Border.all(color: Colors.red.shade300, width: 3)
            : Border.all(color: Colors.white.withOpacity(0.5), width: 2),
      ),
      child: _showSuccess ? _buildSuccessContent() : _buildQuizContent(quiz),
    );
  }

  bool _isSelectedCorrect() {
    if (_selectedAnswer == null) return false;
    final idx = widget.quiz.options.indexOf(_selectedAnswer!);
    return widget.quiz.isCorrect(idx);
  }

  Widget _buildQuizContent(QuizQuestion quiz) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFFFB923C).withOpacity(0.2),
                const Color(0xFFFCD34D).withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.quiz_rounded,
            color: Color(0xFFF97316),
            size: 28,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Quiz Time!',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF9333EA),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            quiz.prompt,
            style: const TextStyle(
              fontSize: 20,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 22),
        ...quiz.options.map((option) => _buildOptionButton(option, quiz)),
      ],
    );
  }

  Widget _buildOptionButton(String option, QuizQuestion quiz) {
    final isSelected = _selectedAnswer == option;
    final idx = quiz.options.indexOf(option);
    final isCorrect = isSelected && quiz.isCorrect(idx);
    final isWrong = isSelected && !quiz.isCorrect(idx);

    Color bgColor = const Color(0xFFF5F3FF);
    Color borderColor = Colors.transparent;
    Color textColor = const Color(0xFF5B21B6);

    if (isSelected) {
      if (isCorrect) {
        bgColor = const Color(0xFFD1FAE5);
        borderColor = const Color(0xFF34D399);
        textColor = const Color(0xFF065F46);
      } else if (isWrong) {
        bgColor = const Color(0xFFFEE2E2);
        borderColor = const Color(0xFFEF4444);
        textColor = const Color(0xFF991B1B);
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: isSelected ? 2 : 0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _selectedAnswer == null ? () => _handleAnswer(option) : null,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
              child: Text(
                option,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: const [
        Icon(
          Icons.verified_rounded,
          color: Color(0xFF34D399),
          size: 64,
        ),
        SizedBox(height: 16),
        Text(
          'Awesome!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Color(0xFF34D399),
          ),
        ),
        SizedBox(height: 8),
        Text(
          'You helped Pip!',
          style: TextStyle(
            fontSize: 18,
            color: Color(0xFF059669),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
