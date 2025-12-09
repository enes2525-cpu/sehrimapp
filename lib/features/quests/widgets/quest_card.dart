import 'package:flutter/material.dart';
import 'package:sehrimapp/data/models/daily_quest.dart';
import 'quest_progress_bar.dart';

class QuestCard extends StatelessWidget {
  final DailyQuest quest;
  final VoidCallback onTap;

  const QuestCard({
    super.key,
    required this.quest,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final progress = quest.currentProgress / quest.targetCount;

    return GestureDetector(
      onTap: quest.isComplete ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: quest.isComplete
              ? Colors.green.withOpacity(0.25)
              : const Color(0xFF1E1E2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: quest.isComplete ? Colors.greenAccent : Colors.white12,
            width: 1.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              quest.title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              quest.description,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),

            const SizedBox(height: 12),

            // Progress Bar
            QuestProgressBar(progress: progress),

            const SizedBox(height: 6),

            Text(
              "${quest.currentProgress}/${quest.targetCount} tamamlandı",
              style: const TextStyle(color: Colors.white60, fontSize: 13),
            ),

            const SizedBox(height: 8),

            Row(
              children: [
                Icon(Icons.bolt, color: Colors.amber, size: 20),
                Text(" +${quest.xpReward} XP  ",
                    style: const TextStyle(color: Colors.white)),

                if (quest.tokenReward > 0)
                  Row(
                    children: [
                      const Icon(Icons.circle, color: Colors.cyan, size: 16),
                      Text(" +${quest.tokenReward} Token",
                          style: const TextStyle(color: Colors.white)),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
