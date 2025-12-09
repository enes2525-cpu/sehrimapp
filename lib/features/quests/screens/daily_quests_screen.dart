import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sehrimapp/features/quests/providers/quest_provider.dart';
import 'package:sehrimapp/data/models/daily_quest.dart';
import 'package:sehrimapp/features/quests/widgets/quest_card.dart';
import 'package:sehrimapp/features/quests/widgets/quest_header.dart';

class DailyQuestsScreen extends StatelessWidget {
  const DailyQuestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => QuestProvider()..loadTodayQuests(),
      child: Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        body: SafeArea(
          child: Consumer<QuestProvider>(
            builder: (context, provider, _) {
              final DailyQuestSet? questSet = provider.todayQuests;
              final quests = questSet?.quests ?? [];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  QuestHeader(questSet: questSet),

                  const SizedBox(height: 10),

                  Expanded(
                    child: quests.isEmpty
                        ? const Center(
                            child: Text(
                              "Görevler yükleniyor...",
                              style: TextStyle(color: Colors.white),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: quests.length,
                            itemBuilder: (context, index) {
                              final quest = quests[index];

                              return QuestCard(
                                quest: quest,
                                onTap: () {
                                  provider.updateDailyQuest(quest.type);
                                },
                              );
                            },
                          ),
                  ),

                  if (questSet?.allCompleted == true)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00FFA3), Color(0xFF00D4FF)],
                        ),
                      ),
                      child: const Text(
                        "🎉 Tüm görevler tamamlandı! ŞA Kodunu kullanabilirsin!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
