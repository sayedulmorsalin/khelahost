import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:khelahost/core/constants.dart';
import 'package:khelahost/core/theme.dart';
import 'package:khelahost/models/tournament_room.dart';
import 'package:khelahost/screens/host_screen.dart';
import 'package:khelahost/screens/room_screen.dart';
import 'package:khelahost/services/room_service.dart';

class MyTournamentsScreen extends StatefulWidget {
  const MyTournamentsScreen({super.key});

  @override
  State<MyTournamentsScreen> createState() => _MyTournamentsScreenState();
}

class _MyTournamentsScreenState extends State<MyTournamentsScreen> {
  String _activeTab = 'All';

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        backgroundColor: AppTheme.bgDeep,
        body: SafeArea(
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
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please sign in with an email account to view and manage your tournaments.',
                    style: GoogleFonts.inter(
                        color: AppTheme.textSecondary, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Back to Home'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final service = RoomService();

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.cardBorder, width: 1.2),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppTheme.textPrimary,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Tournaments',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Manage your hosted rooms & credentials',
                          style: GoogleFonts.inter(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HostScreen()),
                      );
                    },
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_rounded,
                          color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),

            // User Profile Card
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: AppTheme.glassCard(
                  borderColor: AppTheme.primary,
                  borderRadius: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppTheme.primaryGradient,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (user.displayName?.isNotEmpty == true
                                ? user.displayName![0]
                                : user.email?[0] ?? 'H')
                            .toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.displayName?.isNotEmpty == true
                                ? user.displayName!
                                : 'Tournament Host',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            user.email ?? 'Verified Account',
                            style: GoogleFonts.inter(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGreen.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'HOST',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.accentGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Filter Tabs: All / Active / Finished
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: ['All', 'Active', 'Completed', 'Closed'].map((tab) {
                  final isSelected = _activeTab == tab;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      showCheckmark: false,
                      label: Text(
                        tab == 'All'
                            ? 'All Rooms'
                            : (tab == 'Active'
                                ? 'Active'
                                : (tab == 'Completed'
                                    ? 'Completed'
                                    : 'Closed')),
                        style: GoogleFonts.plusJakartaSans(
                          color:
                              isSelected ? Colors.white : AppTheme.textSecondary,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      backgroundColor: AppTheme.bgCard,
                      selectedColor: AppTheme.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 2),
                      side: BorderSide(
                        color: isSelected
                            ? AppTheme.primary
                            : AppTheme.cardBorder,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      onSelected: (_) => setState(() => _activeTab = tab),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 6),

            // Room list
            Expanded(
              child: StreamBuilder<List<TournamentRoom>>(
                stream: service.streamAllHostRooms(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                        strokeWidth: 2.5,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading rooms: ${snapshot.error}',
                        style: const TextStyle(color: AppTheme.accentRed),
                      ),
                    );
                  }

                  final allRooms = snapshot.data ?? [];
                  final rooms = allRooms.where((room) {
                    if (_activeTab == 'Active') {
                      return room.status == 'waiting' || room.status == 'started';
                    }
                    if (_activeTab == 'Completed') {
                      return room.status == 'completed';
                    }
                    if (_activeTab == 'Closed') {
                      return room.status == 'closed';
                    }
                    return true;
                  }).toList();

                  if (rooms.isEmpty) {
                    return _buildEmptyState(context);
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    physics: const BouncingScrollPhysics(),
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
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.emoji_events_outlined,
                  color: AppTheme.primaryLight, size: 48),
            ),
            const SizedBox(height: 18),
            Text(
              _activeTab == 'All'
                  ? 'No Tournaments Hosted Yet'
                  : 'No $_activeTab Tournaments',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _activeTab == 'All'
                  ? 'Create your first gaming match room and invite players with automated passwords.'
                  : 'You have no $_activeTab tournaments in your list.',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HostScreen()),
                );
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Host Tournament'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size(180, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
    final isClosed = room.status == 'closed';
    final isCompleted = room.status == 'completed';
    final isStarted = room.status == 'started';
    final startTimeStr =
        DateFormat('EEE, MMM dd • hh:mm a').format(room.startTime);
    final statusColor = isClosed
        ? AppTheme.accentRed
        : isCompleted
            ? AppTheme.gold
            : isStarted
                ? AppTheme.accentGreen
                : AppTheme.goldLight;
    final statusLabel = isClosed
        ? 'CLOSED'
        : isCompleted
            ? 'COMPLETED'
            : (isStarted ? 'LIVE NOW' : 'WAITING');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassCard(
        borderColor: statusColor,
        isGold: isStarted || !isClosed,
        borderRadius: 18,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RoomScreen(docId: room.id, isHost: true),
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
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSurface,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GameIconWidget(game: room.game, size: 22, borderRadius: 5),
                          const SizedBox(width: 7),
                          Text(
                            room.game,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    // Status tag
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: statusColor,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            statusLabel,
                            style: GoogleFonts.plusJakartaSans(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
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
                  style: GoogleFonts.plusJakartaSans(
                    color: isClosed
                        ? AppTheme.textMuted
                        : AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
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

                const SizedBox(height: 12),
                const Divider(color: AppTheme.divider, height: 1),
                const SizedBox(height: 10),

                Row(
                  children: [
                    // Players
                    _SmallBadge(
                      icon: Icons.people_rounded,
                      label:
                          '${room.players.length}/${room.maxPlayers} players',
                      color: AppTheme.primaryLight,
                    ),
                    const SizedBox(width: 8),

                    // Credentials status
                    if (!room.hasCredentials)
                      const _SmallBadge(
                        icon: Icons.key_off_rounded,
                        label: 'ID/Pass Pending',
                        color: AppTheme.accentGold,
                      )
                    else if (room.credentialsVisibleAt != null &&
                        room.credentialsVisibleAt!.isAfter(DateTime.now()))
                      _SmallBadge(
                        icon: Icons.timer_outlined,
                        label:
                            'Unlocks ${DateFormat('hh:mm a').format(room.credentialsVisibleAt!)}',
                        color: AppTheme.accentGold,
                      )
                    else
                      const _SmallBadge(
                        icon: Icons.key_rounded,
                        label: 'ID/Pass Ready',
                        color: AppTheme.accentGreen,
                      ),

                    const Spacer(),

                    Row(
                      children: [
                        Text(
                          isCompleted
                              ? 'Claims & Payout'
                              : (!isClosed ? 'Manage' : 'View'),
                          style: GoogleFonts.plusJakartaSans(
                            color: isCompleted
                                ? AppTheme.goldLight
                                : (!isClosed
                                    ? AppTheme.primaryLight
                                    : AppTheme.textMuted),
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: isCompleted
                              ? AppTheme.goldLight
                              : (!isClosed
                                  ? AppTheme.primaryLight
                                  : AppTheme.textMuted),
                          size: 13,
                        ),
                      ],
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

  const _SmallBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
}
