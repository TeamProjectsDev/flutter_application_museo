import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../providers/collection_provider.dart';

class RankInfo {
  final String title;
  final Color color;
  final IconData icon;
  final int nextTierAt;

  RankInfo(this.title, this.color, this.icon, this.nextTierAt);
}

RankInfo _calculateRank(int count) {
  if (count == 0) {
    return RankInfo('rank_visitor'.tr(), Colors.grey, Icons.directions_walk, 1);
  } else if (count >= 1 && count <= 2) {
    return RankInfo(
      'rank_explorer'.tr(),
      const Color(0xFFCD7F32),
      Icons.explore,
      3,
    ); // Bronce
  } else if (count >= 3 && count <= 5) {
    return RankInfo(
      'rank_academic'.tr(),
      const Color(0xFFC0C0C0),
      Icons.school,
      6,
    ); // Plata
  } else {
    return RankInfo(
      'rank_curator'.tr(),
      const Color(0xFFFFD700),
      Icons.military_tech,
      999,
    ); // Oro
  }
}

class RankBadgeWidget extends ConsumerWidget {
  const RankBadgeWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Forzar reconstrucción por idioma
    final collectionState = ref.watch(collectionProvider);
    final count = collectionState.unlockedItems.length;
    final rank = _calculateRank(count);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: rank.color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rank.color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            backgroundColor: rank.color,
            foregroundColor: Colors.white,
            radius: 20,
            child: Icon(rank.icon, size: 24),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'auth_rank'.tr(args: [rank.title]),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                rank.nextTierAt == 999
                    ? 'auth_max_rank'.tr()
                    : 'auth_pieces_visited'.tr(
                        args: [count.toString(), rank.nextTierAt.toString()],
                      ),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
