import 'package:flutter/material.dart';

class ViewHistoryScreen extends StatelessWidget {
  const ViewHistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Geçmiş")),
      body: const Center(
        child: Text("Geçmiş ekranı yakında aktif olacak."),
      ),
    );
  }
}
