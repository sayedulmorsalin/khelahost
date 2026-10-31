import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:khelahost/core/theme.dart';
import 'package:khelahost/models/tournament_room.dart';

class PlayerListTile extends StatelessWidget {
  final Player player;
  final bool isHost;
  final bool isPlayerTheHost;
  final VoidCallback? onRemove;
  final int index;

  const PlayerListTile({
    super.key,
    required this.player,
    required this.index,
    this.isHost = false,
    this.isPlayerTheHost = false,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final avatarGradients = [
      const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF4F46E5)]),
      const LinearGradient(colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)]),
      const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
      const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
      const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFDB2777)]),
    ];
    final gradient = avatarGradients[index % avatarGradients.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPlayerTheHost ? AppTheme.cardBorderGold : AppTheme.cardBorder,
          width: isPlayerTheHost ? 1.3 : 1,
        ),
        boxShadow: isPlayerTheHost
            ? [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: isPlayerTheHost ? AppTheme.goldButtonGradient : gradient,
              boxShadow: isPlayerTheHost
                  ? [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              player.name.isNotEmpty ? player.name[0].toUpperCase() : '?',
              style: GoogleFonts.plusJakartaSans(
                color: isPlayerTheHost ? const Color(0xFF070A10) : Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Player info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        player.name,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isPlayerTheHost) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'HOST',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.accentGold,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Joined ${DateFormat('hh:mm a').format(player.joinedAt)}',
                  style: GoogleFonts.inter(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Slot Rank
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isPlayerTheHost
                    ? AppTheme.cardBorderGold
                    : AppTheme.divider,
              ),
            ),
            child: Text(
              '#${index + 1}',
              style: GoogleFonts.plusJakartaSans(
                color: isPlayerTheHost
                    ? AppTheme.primaryLight
                    : AppTheme.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Kick button (host only)
          if (isHost && onRemove != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.accentRed.withValues(alpha: 0.12),
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
