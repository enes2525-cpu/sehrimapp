import 'package:flutter/material.dart';

class BadgeWidget extends StatelessWidget {
  final String badgeType;
  final bool compact;

  const BadgeWidget({
    Key? key,
    required this.badgeType,
    this.compact = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final badgeInfo = _getBadgeInfo(badgeType);

    if (compact) {
      return Tooltip(
        message: badgeInfo['label']!,
        child: Icon(
          badgeInfo['icon'] as IconData,
          size: 16,
          color: badgeInfo['color'] as Color,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (badgeInfo['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (badgeInfo['color'] as Color).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeInfo['icon'] as IconData,
            size: 14,
            color: badgeInfo['color'] as Color,
          ),
          const SizedBox(width: 4),
          Text(
            badgeInfo['label']!,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: badgeInfo['color'] as Color,
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getBadgeInfo(String type) {
    switch (type) {
      case 'fast_reply':
        return {
          'label': 'Hızlı Cevap',
          'icon': Icons.flash_on,
          'color': Colors.orange,
        };
      case 'trusted_seller':
        return {
          'label': 'Güvenilir',
          'icon': Icons.verified,
          'color': Colors.green,
        };
      case 'popular':
        return {
          'label': 'Popüler',
          'icon': Icons.star,
          'color': Colors.amber,
        };
      case 'new_seller':
        return {
          'label': 'Yeni',
          'icon': Icons.new_releases,
          'color': Colors.blue,
        };
      default:
        return {
          'label': type,
          'icon': Icons.badge,
          'color': Colors.grey,
        };
    }
  }
}

// Çoklu rozet gösterimi
class BadgeList extends StatelessWidget {
  final List<String> badges;
  final int maxShow;

  const BadgeList({
    Key? key,
    required this.badges,
    this.maxShow = 3,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) return const SizedBox.shrink();

    final displayBadges = badges.take(maxShow).toList();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: displayBadges
          .map((badge) => BadgeWidget(badgeType: badge))
          .toList(),
    );
  }
}
