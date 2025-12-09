import 'package:flutter/material.dart';
import 'package:sehrimapp/services/token_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TokenWalletScreen extends StatefulWidget {
  const TokenWalletScreen({Key? key}) : super(key: key);

  @override
  State<TokenWalletScreen> createState() => _TokenWalletScreenState();
}

class _TokenWalletScreenState extends State<TokenWalletScreen> {
  final TokenService _tokenService = TokenService();
  int _tokens = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTokens();
  }

  Future<void> _loadTokens() async {
    final tokens = await _tokenService.getUserTokens();
    setState(() {
      _tokens = tokens;
      _loading = false;
    });
  }

  Future<void> _claimDailyBonus() async {
    try {
      await _tokenService.claimDailyBonus();
      await _loadTokens();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Günlük bonus alındı! +5 token')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }

  Future<void> _watchAd() async {
    try {
      await _tokenService.watchAd();
      await _loadTokens();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reklam izlendi! +3 token')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Token Cüzdanı'),
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Token Bakiyesi
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).primaryColor,
                        Theme.of(context).primaryColor.withOpacity(0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.monetization_on,
                        color: Colors.white,
                        size: 60,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Toplam Token',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_tokens',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Token Kazan Başlığı
                const Text(
                  'Token Kazan',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Günlük Bonus
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_today, color: Colors.blue),
                    title: const Text('Günlük Giriş Bonusu'),
                    subtitle: const Text('+5 token'),
                    trailing: ElevatedButton(
                      onPressed: _claimDailyBonus,
                      child: const Text('Al'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Reklam İzle
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.play_circle_filled, color: Colors.green),
                    title: const Text('Reklam İzle'),
                    subtitle: const Text('+3 token'),
                    trailing: ElevatedButton(
                      onPressed: _watchAd,
                      child: const Text('İzle'),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // İşlem Geçmişi
                const Text(
                  'Son İşlemler',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                _buildTransactionHistory(),
              ],
            ),
    );
  }

  Widget _buildTransactionHistory() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('token_transactions')
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final transactions = snapshot.data!.docs;

        if (transactions.isEmpty) {
          return const Center(
            child: Text('Henüz işlem yok'),
          );
        }

        return Column(
          children: transactions.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final type = data['type'];
            final amount = data['amount'];
            final reason = data['reason'];

            return Card(
              child: ListTile(
                leading: Icon(
                  type == 'earn' ? Icons.add_circle : Icons.remove_circle,
                  color: type == 'earn' ? Colors.green : Colors.red,
                ),
                title: Text(reason),
                trailing: Text(
                  '${type == 'earn' ? '+' : '-'}$amount',
                  style: TextStyle(
                    color: type == 'earn' ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}