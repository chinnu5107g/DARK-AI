import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/dark_theme.dart';

class VoiceVisualizer extends StatefulWidget {
  final bool isListening;
  final bool isSpeaking;
  final Color color;
  final int barCount;

  const VoiceVisualizer({
    Key? key,
    this.isListening = false,
    this.isSpeaking = false,
    this.color = DarkTheme.primaryCyan,
    this.barCount = 18,
  }) : super(key: key);

  @override
  State<VoiceVisualizer> createState() => _VoiceVisualizerState();
}

class _VoiceVisualizerState extends State<VoiceVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final active = widget.isListening || widget.isSpeaking;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(widget.barCount, (index) {
            final double phase = (index / widget.barCount) * 2 * math.pi;
            final double animVal = math.sin(_controller.value * 2 * math.pi + phase).abs();
            final double height = active ? (8.0 + animVal * 28.0) : 4.0;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              width: 3.5,
              height: height,
              decoration: BoxDecoration(
                color: active ? widget.color : DarkTheme.textSecondary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: widget.color.withOpacity(0.4),
                          blurRadius: 4,
                          spreadRadius: 1,
                        )
                      ]
                    : null,
              ),
            );
          }),
        );
      },
    );
  }
}
