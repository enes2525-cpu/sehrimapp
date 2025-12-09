import 'package:flutter/material.dart';
import 'package:sehrimapp/data/models/daily_quest.dart';

class QuestHeader extends StatelessWidget {
  final DailyQuestSet? questSet;

  const QuestHeader({super.key, this.questSet});

  @override
  Widget build(BuildContext context) {
    final completed = questSet?.completedCount ?? 0;
    final total = questSet?.totalCount ?? 1;

    final double progress = completed / total;

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Günlük Görevler",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.white12,
            color: Colors.greenAccent,
            minHeight: 8,
          ),
          const SizedBox(height: 8),
          Text(
            "$completed / $total görev tamamlandı",
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
