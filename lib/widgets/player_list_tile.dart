import 'package:flutter/material.dart';
import 'package:khelahost/core/theme.dart';
import 'package:khelahost/models/tournament_room.dart';
import 'package:intl/intl.dart';

class PlayerListTile extends StatelessWidget {
  final Player player;
  final bool isHost;
  final VoidCallback? onRemove;
  final int index;

  const PlayerListTile({
    super.key,
    required this.player,
    required this.index,
    this.isHost = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final colors = [
      AppTheme.primary,
      AppTheme.accent,
      AppTheme.accentGreen,
      AppTheme.accentGold,
      AppTheme.primaryLight,
    ];
    final color = colors[index % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha: 0.6)],
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              player.name.isNotEmpty
                  ? player.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.name,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'Joined ${DateFormat('hh:mm a').format(player.joinedAt)}',
                  style: TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border:
                  Border.all(color: color.withValues(alpha: 0.3), width: 1),
            ),
            child: Text(
              '#${index + 1}',
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (isHost && onRemove != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.accentRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.close_rounded,
                    color: AppTheme.accentRed, size: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
