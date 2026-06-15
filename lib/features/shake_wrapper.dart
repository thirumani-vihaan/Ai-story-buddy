import 'dart:math';

import 'package:flutter/material.dart';

/// A lightweight wrapper that plays a brief shake animation when a value changes.
class ShakeWrapper extends StatefulWidget {
  const ShakeWrapper({
    super.key,
    required this.child,
    required this.trigger,
    this.enabled = true,
  });

  final Widget child;
  final int trigger;
  final bool enabled;

  @override
  State<ShakeWrapper> createState() => _ShakeWrapperState();
}

class _ShakeWrapperState extends State<ShakeWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
  }

  @override
  void didUpdateWidget(covariant ShakeWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && widget.trigger != oldWidget.trigger) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = sin(_controller.value * pi * 4) * (1.0 - _controller.value);
        return Transform.translate(
          offset: Offset(progress * 10, 0),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
