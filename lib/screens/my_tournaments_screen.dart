import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khelahost/core/constants.dart';
import 'package:khelahost/core/theme.dart';
import 'package:khelahost/models/tournament_room.dart';
import 'package:khelahost/screens/room_screen.dart';
import 'package:khelahost/services/room_service.dart';
import 'package:intl/intl.dart';

class MyTournamentsScreen extends StatelessWidget {
  const MyTournamentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline_rounded,
                        color: AppTheme.accentGold, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      'Account Required',
                      style: GoogleFonts.rajdhani(
                        color: AppTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please sign in with an email account to view your hosted tournaments.',
                      style: GoogleFonts.inter(
                          color: AppTheme.textSecondary, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('GO BACK'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final service = RoomService();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppTheme.textPrimary, size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'MY TOURNAMENTS',
                            style: GoogleFonts.rajdhani(
                              color: AppTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            'Manage your hosted rooms',
                            style: GoogleFonts.inter(
                                color: AppTheme.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // User info chip
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: AppTheme.glassCard(
                      borderColor: AppTheme.primary, borderRadius: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shield_rounded,
                            color: AppTheme.primaryLight, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName?.isNotEmpty == true
                                  ? user.displayName!
                                  : 'Host',
                              style: GoogleFonts.rajdhani(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              user.email ?? 'Guest',
                              style: GoogleFonts.inter(
                                  color: AppTheme.textMuted, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color:
                                  AppTheme.accentGreen.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          'HOST',
                          style: GoogleFonts.rajdhani(
                            color: AppTheme.accentGreen,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Room list
              Expanded(
                child: StreamBuilder<List<TournamentRoom>>(
                  stream: service.streamAllHostRooms(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                            color: AppTheme.primary),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.accentRed
                                      .withValues(alpha: 0.15),
                                ),
                                child: const Icon(
                                  Icons.error_outline_rounded,
                                  color: AppTheme.accentRed,
                                  size: 48,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Unable to load tournaments',
                                style: GoogleFonts.rajdhani(
                                  color: AppTheme.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                snapshot.error.toString(),
                                style: GoogleFonts.inter(
                                  color: AppTheme.textMuted,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 20),
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const MyTournamentsScreen(),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.refresh_rounded,
                                    size: 18),
                                label: const Text('RETRY'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppTheme.accent,
                                  side:
                                      const BorderSide(color: AppTheme.accent),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final rooms = snapshot.data ?? [];

                    if (rooms.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      itemCount: rooms.length,
                      itemBuilder: (context, index) =>
                          _HostRoomCard(room: rooms[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.emoji_events_outlined,
                  color: AppTheme.primaryLight, size: 52),
            ),
            const SizedBox(height: 20),
            Text(
              'No Tournaments Yet',
              style: GoogleFonts.rajdhani(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'You haven\'t hosted any tournaments.\nTap "Host a Tournament" to get started!',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('GO BACK'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.accent),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: GoogleFonts.rajdhani(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HostRoomCard extends StatelessWidget {
  final TournamentRoom room;
  const _HostRoomCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final gameIcon = AppConstants.gameIcons[room.game] ?? '🎮';
    final isClosed = room.status == 'closed';
    final isStarted = room.status == 'started';
    final startTimeStr =
        DateFormat('EEE, MMM dd • hh:mm a').format(room.startTime);
    final statusColor = isClosed
        ? AppTheme.accentRed
        : isStarted
            ? AppTheme.accentGreen
            : AppTheme.accent;
    final statusLabel =
        isClosed ? 'CLOSED' : isStarted ? 'LIVE' : 'WAITING';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassCard(
        borderColor: statusColor,
        borderRadius: 16,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    RoomScreen(docId: room.id, isHost: true),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Game badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(gameIcon,
                              style: const TextStyle(fontSize: 13)),
                          const SizedBox(width: 6),
                          Text(
                            room.game,
                            style: GoogleFonts.rajdhani(
                              color: AppTheme.primaryLight,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Status
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: statusColor.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                                shape: BoxShape.circle, color: statusColor),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            statusLabel,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Text(
                  room.name,
                  style: GoogleFonts.rajdhani(
                    color: isClosed
                        ? AppTheme.textMuted
                        : AppTheme.textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        color: AppTheme.textMuted, size: 13),
                    const SizedBox(width: 5),
                    Text(
                      startTimeStr,
                      style: GoogleFonts.inter(
                          color: AppTheme.textSecondary, fontSize: 11),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    // Players
                    _SmallBadge(
                      icon: Icons.people_rounded,
                      label:
                          '${room.players.length}/${room.maxPlayers} players',
                      color: AppTheme.accent,
                    ),
                    if (room.prizePool?.isNotEmpty == true) ...[
                      const SizedBox(width: 8),
                      _SmallBadge(
                        icon: Icons.monetization_on_rounded,
                        label: room.prizePool!,
                        color: AppTheme.accentGold,
                      ),
                    ],
                    const Spacer(),
                    if (!isClosed)
                      Row(
                        children: [
                          Text(
                            'MANAGE',
                            style: GoogleFonts.rajdhani(
                              color: AppTheme.primaryLight,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_ios_rounded,
                              color: AppTheme.primaryLight, size: 11),
                        ],
                      )
                    else
                      Text(
                        'VIEW DETAILS',
                        style: GoogleFonts.rajdhani(
                          color: AppTheme.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          letterSpacing: 1,
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SmallBadge(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.rajdhani(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700),
            ),
          ],
        ),
      );
}
