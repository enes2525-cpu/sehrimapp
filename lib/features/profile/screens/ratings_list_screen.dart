import 'package:flutter/material.dart';

class RatingsListScreen extends StatelessWidget {
  const RatingsListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Puanlarım")),
      body: const Center(
        child: Text("Puan listesi yakında aktif olacak."),
      ),
    );
  }
}
