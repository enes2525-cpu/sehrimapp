import 'package:flutter/material.dart';

class QuestProgressBar extends StatelessWidget {
  final double progress; // 0.0 – 1.0 arası

  const QuestProgressBar({super.key, required this.progress});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 6,
        backgroundColor: Colors.grey.withOpacity(0.3),
        valueColor: AlwaysStoppedAnimation<Color>(
          progress >= 1.0 ? Colors.greenAccent : Colors.amberAccent,
        ),
      ),
    );
  }
}
