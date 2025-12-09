import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sehrimapp/data/models/daily_quest.dart';
import 'package:sehrimapp/data/repositories/quest_repository.dart';

class QuestProvider extends ChangeNotifier {
  final QuestRepository _repo = QuestRepository();

  DailyQuestSet? todayQuests;
  bool isLoading = false;

  Future<void> loadTodayQuests() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    isLoading = true;
    notifyListeners();

    final result = await _repo.getTodayQuests(userId);
    if (result.isSuccess) {
      todayQuests = result.data;
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> updateDailyQuest(QuestType type) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final result = await _repo.updateQuestProgress(userId, type);
    if (result.isSuccess) {
      todayQuests = result.data;
      notifyListeners();
    }
  }
}
