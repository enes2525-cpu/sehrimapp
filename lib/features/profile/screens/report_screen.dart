import 'package:flutter/material.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Rapor Et")),
      body: const Center(
        child: Text("Raporlama ekranı yakında aktif olacak."),
      ),
    );
  }
}
