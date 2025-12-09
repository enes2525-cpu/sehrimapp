import 'package:flutter/material.dart';

class ShLogo extends StatelessWidget {
  final double size;
  const ShLogo({super.key, this.size = 180});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // LOGO GÖRSELİ
        SizedBox(
          height: size,
          child: Image.asset(
            "assets/logo/sehrim_logo.png",
            fit: BoxFit.contain,
          ),
        ),

        const SizedBox(height: 12),

        // Uygulama Adı
        Text(
          "ŞehrimApp",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF00AEEF),
            shadows: [
              Shadow(
                color: const Color(0xFF00AEEF).withOpacity(0.5),
                blurRadius: 20,
              )
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Açıklama
        Text(
          "Şehrindeki işletmeler, kampanyalar ve fırsatlar",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white.withOpacity(0.75),
          ),
        ),
      ],
    );
  }
}
