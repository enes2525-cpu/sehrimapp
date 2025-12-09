import 'package:flutter/material.dart';

class BlockedUsersScreen extends StatelessWidget {
  const BlockedUsersScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Engellenen Kullanıcılar")),
      body: const Center(
        child: Text("Engellenen kullanıcılar ekranı yakında aktif olacak."),
      ),
    );
  }
}
