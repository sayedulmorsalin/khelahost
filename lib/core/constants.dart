import 'package:flutter/material.dart';

class AppConstants {
  static const List<String> games = [
    'PUBG Mobile',
    'Free Fire',
    'eFootball',
    'Call of Duty Mobile',
    'Valorant Mobile',
    'Mobile Legends',
    'Clash Royale',
    'Clash of Clans',
  ];

  static const List<int> playerCounts = [10, 25, 50, 100];

  // Real mobile app icon asset paths
  static const Map<String, String> gameAssetIcons = {
    'PUBG Mobile': 'assets/games/pubg_mobile.png',
    'Free Fire': 'assets/games/free_fire.png',
    'eFootball': 'assets/games/efootball.png',
    'Call of Duty Mobile': 'assets/games/cod_mobile.png',
    'Valorant Mobile': 'assets/games/valorant_mobile.png',
    'Mobile Legends': 'assets/games/mobile_legends.png',
    'Clash Royale': 'assets/games/clash_royale.png',
    'Clash of Clans': 'assets/games/clash_of_clans.png',
  };

  // Fallback emojis if ever needed
  static const Map<String, String> gameIcons = {
    'PUBG Mobile': '🎯',
    'Free Fire': '🔥',
    'eFootball': '⚽',
    'Call of Duty Mobile': '💥',
    'Valorant Mobile': '⚡',
    'Mobile Legends': '⚔️',
    'Clash Royale': '👑',
    'Clash of Clans': '🏰',
  };
}

/// Reusable widget to display real game mobile app icons cleanly with premium elevation
class GameIconWidget extends StatelessWidget {
  final String game;
  final double size;
  final double borderRadius;
  final bool showBorder;

  const GameIconWidget({
    super.key,
    required this.game,
    this.size = 28,
    this.borderRadius = 8,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    final assetPath = AppConstants.gameAssetIcons[game];
    Widget icon;
    if (assetPath != null) {
      icon = ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _fallback(),
        ),
      );
    } else {
      icon = _fallback();
    }

    if (!showBorder) return icon;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      child: icon,
    );
  }

  Widget _fallback() {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFF162032),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Text(
        AppConstants.gameIcons[game] ?? '🎮',
        style: TextStyle(fontSize: size * 0.52),
      ),
    );
  }
}
