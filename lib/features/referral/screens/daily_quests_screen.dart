import 'package:flutter/material.dart';
import 'package:sehrimapp/data/models/user_model.dart';
import 'package:sehrimapp/services/auth_service.dart';
import 'package:sehrimapp/services/firestore_service.dart';
import 'package:sehrimapp/services/level_service.dart';
import 'package:sehrimapp/data/repositories/user_repository.dart';

class DailyQuestsScreen extends StatefulWidget {
  const DailyQuestsScreen({Key? key}) : super(key: key);

  @override
  State<DailyQuestsScreen> createState() => _DailyQuestsScreenState();
}

class _DailyQuestsScreenState extends State<DailyQuestsScreen> {
  UserModel? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final userId = AuthService.currentUserId;
    if (userId == null) {
      setState(() => _loading = false);
      return;
    }

    // Günlük reset kontrolü
    await UserRepository().resetDailyTasksIfNeeded(userId);

    final user = await FirestoreService.getUser(userId);

    if (mounted) {
      setState(() {
        _user = user;
        _loading = false;
      });
    }
  }

  Future<void> _completeTask(int xpReward, int tokenReward) async {
    final userId = AuthService.currentUserId;
    if (userId == null || _user == null) return;

    if (_user!.dailyTaskProgress >= 20) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tüm günlük görevleri tamamladınız!")),
      );
      return;
    }

    // 1) Firestore’da progress artır
    await UserRepository().incrementDailyTask(userId);

    // 2) XP ver
    await LevelService.addXp(userId, xpReward);

    // 3) Token ver
    await FirestoreService.updateUserTokens(userId, tokenReward);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("+$xpReward XP, +$tokenReward Token kazandın!")),
    );

    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_user == null) {
      return const Scaffold(
        body: Center(child: Text("Giriş gerekli.")),
      );
    }

    final user = _user!;
    final progress = user.dailyTaskProgress.clamp(0, 20);

    return Scaffold(
      appBar: AppBar(title: const Text("Günlük Görevler")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProgress(progress),
            const SizedBox(height: 20),
            Expanded(child: _buildTaskList(user)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress(int progress) {
    return Column(
      children: [
        Text(
          "Günlük İlerleme: $progress / 20",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        LinearProgressIndicator(
          value: progress / 20,
          minHeight: 10,
          backgroundColor: Colors.grey.shade300,
          valueColor: AlwaysStoppedAnimation(Colors.greenAccent),
        ),
      ],
    );
  }

  Widget _buildTaskList(UserModel user) {
    final tasks = [
      {
        "title": "Bugün 1 ilan görüntüle",
        "progressCheck": user.totalAdViews > 0,
        "xp": 25,
        "token": 5,
      },
      {
        "title": "Profiline göz at",
        "progressCheck": user.profileViews > 0,
        "xp": 20,
        "token": 5,
      },
      {
        "title": "1 kullanıcıyı takip et",
        "progressCheck": user.followingCount > 0,
        "xp": 30,
        "token": 8,
      },
    ];

    return ListView.builder(
      itemCount: tasks.length,
      itemBuilder: (_, i) {
        final t = tasks[i];
        final done = t["progressCheck"] as bool;

        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: Icon(
              done ? Icons.check_circle : Icons.circle_outlined,
              color: done ? Colors.green : Colors.grey,
            ),
            title: Text(t["title"].toString()),
            trailing: ElevatedButton(
              onPressed: done
                  ? () => _completeTask(t["xp"] as int, t["token"] as int)
                  : null,
              child: const Text("Tamamla"),
            ),
          ),
        );
      },
    );
  }
}
