import 'package:flutter/material.dart';
import 'package:sehrimapp/services/block_service.dart';
import 'package:sehrimapp/services/auth_service.dart';
import 'package:intl/intl.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userId = AuthService.currentUserId;

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Engellenenler')),
        body: const Center(child: Text('Giriş yapmalısınız')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Engellenen Kullanıcılar'),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: BlockService.getBlockedUsers(userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.block,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Engellenmiş kullanıcı yok',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Engellediğiniz kullanıcılar burada görünür',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }

          final blockedUsers = snapshot.data!;
          return ListView.separated(
            itemCount: blockedUsers.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final user = blockedUsers[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user['photoUrl'] != null
                      ? NetworkImage(user['photoUrl'])
                      : null,
                  child: user['photoUrl'] == null
                      ? Text(user['name'][0].toUpperCase())
                      : null,
                ),
                title: Text(user['name']),
                subtitle: user['blockedAt'] != null
                    ? Text(
                        'Engellendi: ${DateFormat('dd MMM yyyy').format(user['blockedAt'])}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      )
                    : null,
                trailing: OutlinedButton(
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Engeli Kaldır'),
                        content: Text('${user['name']} engelini kaldırmak istediğinize emin misiniz?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('İptal'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Engeli Kaldır'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await BlockService.unblockUser(
                        blockerId: userId,
                        blockedId: user['id'],
                      );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${user['name']} engeli kaldırıldı'),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Engeli Kaldır'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
