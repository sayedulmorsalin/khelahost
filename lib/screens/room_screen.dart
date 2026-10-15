import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khelahost/core/constants.dart';
import 'package:khelahost/core/theme.dart';
import 'package:khelahost/models/tournament_room.dart';
import 'package:khelahost/services/room_service.dart';
import 'package:khelahost/widgets/countdown_widget.dart';
import 'package:khelahost/widgets/player_list_tile.dart';
import 'package:khelahost/widgets/room_info_card.dart';
import 'package:intl/intl.dart';

class RoomScreen extends StatefulWidget {
  final String docId;
  final bool isHost;

  const RoomScreen({super.key, required this.docId, required this.isHost});

  @override
  State<RoomScreen> createState() => _RoomScreenState();
}

class _RoomScreenState extends State<RoomScreen> with TickerProviderStateMixin {
  final _service = RoomService();
  late AnimationController _headerController;
  late Animation<double> _headerAnim;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _headerAnim = CurvedAnimation(
        parent: _headerController, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  Future<void> _closeRoom(TournamentRoom room) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Close Tournament?',
          style: GoogleFonts.rajdhani(
              color: AppTheme.textPrimary, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This will close the room for all participants.',
          style: GoogleFonts.inter(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Close Room',
                style: TextStyle(color: AppTheme.accentRed)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await _service.closeRoom(room.id);
      if (mounted) Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  Future<void> _removePlayer(TournamentRoom room, Player player) async {
    await _service.removePlayer(room.id, player);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${player.name} removed.'),
          backgroundColor: AppTheme.accentRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<TournamentRoom?>(
        stream: _service.streamRoom(widget.docId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return _buildClosed();
          }
          final room = snapshot.data!;
          // Derive host status dynamically so returning hosts are recognized
          final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
          final isHost = room.hostId == uid || widget.isHost;
          if (room.status == 'closed' && !isHost) {
            return _buildClosed();
          }
          return _buildRoom(room, isHost);
        },
      ),
    );
  }

  Widget _buildRoom(TournamentRoom room, bool isHost) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            FadeTransition(
              opacity: _headerAnim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.2),
                  end: Offset.zero,
                ).animate(_headerAnim),
                child: _buildHeader(room),
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),

                    // Countdown
                    CountdownWidget(targetTime: room.startTime, room: room),
                    const SizedBox(height: 16),

                    // Room credentials card
                    RoomInfoCard(room: room),
                    const SizedBox(height: 16),

                    // Tournament info grid
                    _buildInfoGrid(room),
                    const SizedBox(height: 16),

                    // Prize pool
                    if (room.prizePool != null && room.prizePool!.isNotEmpty)
                      _buildPrizeCard(room),

                    // Rules
                    if (room.rules != null && room.rules!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _buildRulesCard(room),
                    ],

                    const SizedBox(height: 16),

                    // Player list
                    _buildPlayerList(room, uid, isHost),

                    const SizedBox(height: 16),

                    // Participant Join / Status controls (for non-hosts)
                    if (!isHost) ...[
                      _buildParticipantControls(room, uid),
                      const SizedBox(height: 16),
                    ],

                    // Host controls
                    if (isHost) ...[
                      _buildHostControls(room),
                      const SizedBox(height: 16),
                    ],

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(TournamentRoom room) {
    final gameIcon = AppConstants.gameIcons[room.game] ?? '🎮';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.2),
            Colors.transparent,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border(
          bottom: BorderSide(color: AppTheme.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.divider),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppTheme.textPrimary, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Text(gameIcon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.name,
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  room.game,
                  style: GoogleFonts.inter(
                      color: AppTheme.textMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: _statusColor(room.status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _statusColor(room.status).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _statusColor(room.status),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  room.status.toUpperCase(),
                  style: TextStyle(
                    color: _statusColor(room.status),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoGrid(TournamentRoom room) {
    return Container(
      decoration: AppTheme.glassCard(borderRadius: 16),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _InfoCell(
            icon: Icons.people_rounded,
            label: 'Players',
            value: '${room.players.length}/${room.maxPlayers}',
            color: AppTheme.accent,
          ),
          _Divider(),
          _InfoCell(
            icon: Icons.calendar_today_rounded,
            label: 'Start Date',
            value: DateFormat('MMM dd').format(room.startTime),
            color: AppTheme.primaryLight,
          ),
          _Divider(),
          _InfoCell(
            icon: Icons.access_time_rounded,
            label: 'Start Time',
            value: DateFormat('hh:mm a').format(room.startTime),
            color: AppTheme.accentGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeCard(TournamentRoom room) {
    return Container(
      decoration: AppTheme.glassCard(
          borderColor: AppTheme.accentGold, borderRadius: 16),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.monetization_on_rounded,
                color: AppTheme.accentGold, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PRIZE POOL',
                style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 11,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                room.prizePool!,
                style: GoogleFonts.rajdhani(
                  color: AppTheme.accentGold,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRulesCard(TournamentRoom room) {
    return Container(
      decoration: AppTheme.glassCard(borderRadius: 16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.rule_rounded,
                  color: AppTheme.primary, size: 18),
              const SizedBox(width: 8),
              Text(
                'RULES & INFO',
                style: TextStyle(
                  color: AppTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            room.rules!,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerList(TournamentRoom room, String uid, bool isHost) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.people_rounded, color: AppTheme.accent, size: 18),
            const SizedBox(width: 8),
            Text(
              'PLAYERS  ',
              style: TextStyle(
                color: AppTheme.accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${room.players.length}',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (room.players.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: AppTheme.glassCard(borderRadius: 12),
            child: Column(
              children: [
                const Icon(Icons.person_add_rounded,
                    color: AppTheme.textMuted, size: 32),
                const SizedBox(height: 8),
                Text(
                  'No players yet\nShare the room to invite people!',
                  style: GoogleFonts.inter(
                      color: AppTheme.textMuted, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...room.players.asMap().entries.map(
                (e) => PlayerListTile(
                  player: e.value,
                  index: e.key,
                  isHost: isHost,
                  onRemove: isHost && e.value.uid != uid
                      ? () => _removePlayer(room, e.value)
                      : null,
                ),
              ),
      ],
    );
  }

  Widget _buildHostControls(TournamentRoom room) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _service.updateStatus(
              room.id,
              room.status == 'started' ? 'waiting' : 'started',
            ),
            icon: Icon(
              room.status == 'started'
                  ? Icons.pause_rounded
                  : Icons.play_arrow_rounded,
            ),
            label: Text(
                room.status == 'started' ? 'PAUSE GAME' : 'START GAME'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accentGreen,
              side: const BorderSide(color: AppTheme.accentGreen),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _closeRoom(room),
            icon: const Icon(Icons.close_rounded),
            label: const Text('CLOSE ROOM'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accentRed,
              side: const BorderSide(color: AppTheme.accentRed),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildClosed() {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentRed.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.meeting_room_outlined,
                  color: AppTheme.accentRed, size: 48),
            ),
            const SizedBox(height: 20),
            Text(
              'Room Closed',
              style: GoogleFonts.rajdhani(
                color: AppTheme.textPrimary,
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This tournament room no longer exists\nor has been closed by the host.',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            OutlinedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.accent),
                padding: const EdgeInsets.symmetric(
                    horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('GO HOME'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipantControls(TournamentRoom room, String uid) {
    final player = room.players.where((p) => p.uid == uid).firstOrNull;
    final isJoined = player != null;
    final isFull = room.players.length >= room.maxPlayers;

    if (isJoined) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: AppTheme.glassCard(
          borderColor: AppTheme.accentGreen,
          borderRadius: 16,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: AppTheme.accentGreen, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'YOU ARE REGISTERED!',
                    style: GoogleFonts.rajdhani(
                      color: AppTheme.accentGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    'Slot registered as "${player.name}"',
                    style: GoogleFonts.inter(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _removePlayer(room, player),
              child: const Text(
                'Leave Slot',
                style: TextStyle(color: AppTheme.accentRed, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: isFull ? null : () => _showJoinDialog(room),
      icon: Icon(isFull ? Icons.block_rounded : Icons.how_to_reg_rounded),
      label: Text(isFull ? 'SLOTS FULL' : 'REGISTER MY SLOT IN TOURNAMENT'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isFull ? AppTheme.bgSurface : AppTheme.accent,
        foregroundColor: isFull ? AppTheme.textMuted : Colors.white,
        minimumSize: const Size(double.infinity, 54),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.rajdhani(
            fontSize: 16, fontWeight: FontWeight.w800, letterSpacing: 1.5),
      ),
    );
  }

  void _showJoinDialog(TournamentRoom room) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Register for ${room.name}',
          style: GoogleFonts.rajdhani(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your in-game display name to join the player list:',
              style: GoogleFonts.inter(
                  color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.inter(color: AppTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Gamer Tag / Display Name',
                hintText: 'e.g. ProGamer99',
                prefixIcon: Icon(Icons.person_rounded, color: AppTheme.accent),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);

              // User is always authenticated via AuthGate
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) return;

              final player = Player(
                uid: uid,
                name: name,
                joinedAt: DateTime.now(),
              );

              await _service.joinRoom(room.id, player);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Registered as "$name"!'),
                    backgroundColor: AppTheme.accentGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              minimumSize: const Size(100, 44),
            ),
            child: const Text('Register'),
          ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'started':
        return AppTheme.accentGreen;
      case 'closed':
        return AppTheme.accentRed;
      default:
        return AppTheme.accent;
    }
  }
}

class _InfoCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _InfoCell({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: AppTheme.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 40,
        color: AppTheme.divider,
      );
}
