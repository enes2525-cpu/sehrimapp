import 'package:flutter/material.dart';

class QuickMessageWidget extends StatelessWidget {
  final Function(String message) onMessageSelected;

  const QuickMessageWidget({
    Key? key,
    required this.onMessageSelected,
  }) : super(key: key);

  static const List<Map<String, dynamic>> quickMessages = [
    {
      'icon': Icons.question_answer,
      'text': 'Merhaba, bu ürün hala satışta mı?',
      'label': 'Satışta mı?',
    },
    {
      'icon': Icons.local_shipping,
      'text': 'Kargo ile gönderim yapıyor musunuz?',
      'label': 'Kargo?',
    },
    {
      'icon': Icons.attach_money,
      'text': 'Son fiyatınız ne olur?',
      'label': 'Son fiyat?',
    },
    {
      'icon': Icons.handshake,
      'text': 'Elden teslim yapabilir miyiz?',
      'label': 'Elden teslim?',
    },
    {
      'icon': Icons.swap_horiz,
      'text': 'Takas kabul ediyor musunuz?',
      'label': 'Takas?',
    },
    {
      'icon': Icons.photo_camera,
      'text': 'Daha fazla fotoğraf paylaşabilir misiniz?',
      'label': 'Fotoğraf?',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: quickMessages.length,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemBuilder: (context, index) {
          final message = quickMessages[index];
          return _buildQuickMessageCard(
            icon: message['icon'],
            label: message['label'],
            onTap: () => onMessageSelected(message['text']),
          );
        },
      ),
    );
  }

  Widget _buildQuickMessageCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.blue[700], size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Hizli mesaj bottom sheet
class QuickMessageBottomSheet extends StatelessWidget {
  final Function(String message) onMessageSelected;

  const QuickMessageBottomSheet({
    Key? key,
    required this.onMessageSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Hızlı Mesajlar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...QuickMessageWidget.quickMessages.map((message) {
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.blue[50],
                child: Icon(message['icon'], color: Colors.blue[700], size: 20),
              ),
              title: Text(message['text']),
              onTap: () {
                Navigator.pop(context);
                onMessageSelected(message['text']);
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// Helper function
void showQuickMessages(
  BuildContext context, {
  required Function(String message) onMessageSelected,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => QuickMessageBottomSheet(
      onMessageSelected: onMessageSelected,
    ),
  );
}
