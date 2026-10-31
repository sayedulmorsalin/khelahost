import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:khelahost/core/constants.dart';
import 'package:khelahost/core/theme.dart';
import 'package:khelahost/models/tournament_room.dart';
import 'package:khelahost/services/room_service.dart';
import 'package:khelahost/widgets/countdown_widget.dart';
import 'package:khelahost/widgets/player_list_tile.dart';
import 'package:khelahost/widgets/room_info_card.dart';

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
      duration: const Duration(milliseconds: 500),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        title: Text(
          'Close Tournament?',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          'This will permanently close the room for all registered players.',
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Close Room',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
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
          content: Text('${player.name} removed from room.'),
          backgroundColor: AppTheme.accentRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: StreamBuilder<TournamentRoom?>(
        stream: _service.streamRoom(widget.docId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 2.5,
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return _buildClosed();
          }
          final room = snapshot.data!;
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

    return SafeArea(
      child: Column(
        children: [
          // Header Bar
          FadeTransition(
            opacity: _headerAnim,
            child: _buildHeader(room, isHost),
          ),

          // Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Countdown
                  CountdownWidget(targetTime: room.startTime, room: room),
                  const SizedBox(height: 16),

                  // Room credentials pass
                  RoomInfoCard(
                    room: room,
                    isHost: isHost,
                    onEditCredentials:
                        isHost ? () => _showEditCredentialsSheet(room) : null,
                    onRevealNow:
                        isHost ? () => _revealCredentialsNow(room) : null,
                  ),
                  const SizedBox(height: 16),

                  // Tournament info metrics grid
                  _buildInfoGrid(room),
                  const SizedBox(height: 16),

                  // Prize pool card
                  if (room.prizePool != null && room.prizePool!.isNotEmpty) ...[
                    _buildPrizeCard(room),
                    const SizedBox(height: 16),
                  ],

                  // Rules card
                  if (room.rules != null && room.rules!.isNotEmpty) ...[
                    _buildRulesCard(room),
                    const SizedBox(height: 16),
                  ],

                  // Player list section
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
    );
  }

  Widget _buildHeader(TournamentRoom room, bool isHost) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.bgCard,
        border: Border(
          bottom: BorderSide(color: AppTheme.divider, width: 1),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cardBorderGold),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppTheme.textPrimary,
                size: 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          GameIconWidget(game: room.game, size: 40, borderRadius: 10),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        room.name,
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isHost) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppTheme.gold.withValues(alpha: 0.45),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'VIP HOST',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.goldLight,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  room.game,
                  style: GoogleFonts.inter(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _statusColor(room.status).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
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
                  room.status == 'started'
                      ? 'LIVE'
                      : (room.status == 'waiting' ? 'SCHEDULED' : 'CLOSED'),
                  style: GoogleFonts.plusJakartaSans(
                    color: _statusColor(room.status),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
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
            icon: Icons.people_alt_outlined,
            label: 'Capacity',
            value: '${room.players.length} / ${room.maxPlayers}',
            color: AppTheme.primaryLight,
          ),
          _Divider(),
          _InfoCell(
            icon: Icons.calendar_today_rounded,
            label: 'Match Date',
            value: DateFormat('MMM dd').format(room.startTime),
            color: AppTheme.accent,
          ),
          _Divider(),
          _InfoCell(
            icon: Icons.access_time_rounded,
            label: 'Kickoff',
            value: DateFormat('hh:mm a').format(room.startTime),
            color: AppTheme.accentGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildPrizeCard(TournamentRoom room) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1B2436),
            Color(0xFF0F1524),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppTheme.gold.withValues(alpha: 0.45),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.gold.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppTheme.goldGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.gold.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(Icons.workspace_premium_rounded,
                color: Color(0xFF0A0E18), size: 26),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'OFFICIAL PRIZE PURSE',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.goldMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                room.prizePool!,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.goldLight,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
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
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel_rounded,
                  color: AppTheme.primaryLight, size: 16),
              const SizedBox(width: 8),
              Text(
                'RULES & MATCH GUIDELINES',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            room.rules!,
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 13,
              height: 1.6,
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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.groups_rounded,
                    color: AppTheme.primaryLight, size: 18),
                const SizedBox(width: 8),
                Text(
                  'ROSTER',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${room.players.length} / ${room.maxPlayers} slots',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
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
            decoration: AppTheme.glassCard(borderRadius: 14),
            child: Column(
              children: [
                const Icon(Icons.person_add_rounded,
                    color: AppTheme.textMuted, size: 30),
                const SizedBox(height: 8),
                Text(
                  'No players joined yet.\nShare room to invite friends!',
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
                  isPlayerTheHost: e.value.uid == room.hostId,
                  onRemove: isHost && e.value.uid != uid
                      ? () => _removePlayer(room, e.value)
                      : null,
                ),
              ),
      ],
    );
  }

  Widget _buildHostControls(TournamentRoom room) {
    return Column(
      children: [
        // Set / Edit Credentials button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showEditCredentialsSheet(room),
            icon: Icon(
              room.hasCredentials ? Icons.edit_rounded : Icons.vpn_key_rounded,
              size: 16,
            ),
            label: Text(
              room.hasCredentials
                  ? 'Edit Room ID & Password'
                  : 'Set Room ID & Password',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.accentGold,
              side: const BorderSide(color: AppTheme.accentGold, width: 1.2),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              textStyle: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _service.updateStatus(
                  room.id,
                  room.status == 'started' ? 'waiting' : 'started',
                ),
                icon: Icon(
                  room.status == 'started'
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  size: 18,
                ),
                label: Text(room.status == 'started'
                    ? 'Pause Match'
                    : 'Start Match'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _closeRoom(room),
                icon: const Icon(Icons.close_rounded, size: 16),
                label: const Text('Close Room'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.accentRed,
                  side: const BorderSide(color: AppTheme.accentRed, width: 1.2),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _revealCredentialsNow(TournamentRoom room) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        title: Text(
          'Reveal Credentials Now?',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          'This will immediately unlock the Room ID and Password for all participants.',
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Reveal Now',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) {
      await _service.revealCredentialsImmediately(room.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded,
                    color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text('Credentials revealed to all players!',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
              ],
            ),
            backgroundColor: AppTheme.accentGreen,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _showEditCredentialsSheet(TournamentRoom room) async {
    final roomIdCtrl = TextEditingController(text: room.roomId);
    final passwordCtrl = TextEditingController(text: room.roomPassword);
    bool obscurePassword = true;

    // Determine initial timer mode
    String timerMode = 'immediate';
    DateTime? customRevealTime;

    if (room.credentialsVisibleAt != null) {
      final diff = room.startTime.difference(room.credentialsVisibleAt!);
      if (diff.inMinutes == 15) {
        timerMode = '15min';
      } else if (diff.inMinutes == 30) {
        timerMode = '30min';
      } else {
        timerMode = 'custom';
        customRevealTime = room.credentialsVisibleAt;
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            decoration: const BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              border: Border(
                top: BorderSide(color: AppTheme.cardBorder, width: 1.5),
              ),
            ),
            padding: EdgeInsets.fromLTRB(
              20,
              16,
              20,
              MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.divider,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.vpn_key_rounded,
                            color: AppTheme.primaryLight, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Room Credentials & Timer',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Update in-game room credentials & automated reveal',
                              style: GoogleFonts.inter(
                                color: AppTheme.textMuted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Room ID field
                  TextField(
                    controller: roomIdCtrl,
                    style: GoogleFonts.inter(
                        color: AppTheme.textPrimary, fontSize: 14),
                    decoration: const InputDecoration(
                      labelText: 'In-Game Room ID',
                      hintText: 'Enter room ID',
                      prefixIcon: Icon(Icons.tag_rounded,
                          color: AppTheme.primaryLight, size: 20),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Password field
                  TextField(
                    controller: passwordCtrl,
                    obscureText: obscurePassword,
                    style: GoogleFonts.inter(
                        color: AppTheme.textPrimary, fontSize: 14),
                    decoration: InputDecoration(
                      labelText: 'Room Password',
                      hintText: 'Enter room password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded,
                          color: AppTheme.accentGold, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppTheme.textMuted,
                          size: 18,
                        ),
                        onPressed: () => setModalState(
                            () => obscurePassword = !obscurePassword),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'WHEN CAN PLAYERS VIEW THESE CREDENTIALS?',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 8),

                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTimerChip(
                        label: 'Immediately',
                        icon: Icons.flash_on_rounded,
                        selected: timerMode == 'immediate',
                        onTap: () =>
                            setModalState(() => timerMode = 'immediate'),
                      ),
                      _buildTimerChip(
                        label: '15m Before Start',
                        icon: Icons.timer_outlined,
                        selected: timerMode == '15min',
                        onTap: () =>
                            setModalState(() => timerMode = '15min'),
                      ),
                      _buildTimerChip(
                        label: '30m Before Start',
                        icon: Icons.timer_outlined,
                        selected: timerMode == '30min',
                        onTap: () =>
                            setModalState(() => timerMode = '30min'),
                      ),
                      _buildTimerChip(
                        label: 'Custom Timer',
                        icon: Icons.edit_calendar_rounded,
                        selected: timerMode == 'custom',
                        onTap: () async {
                          final now = DateTime.now();
                          final d = await showDatePicker(
                            context: ctx,
                            initialDate: room.startTime,
                            firstDate: now,
                            lastDate: now.add(const Duration(days: 30)),
                          );
                          if (d == null) return;
                          if (!ctx.mounted) return;
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.fromDateTime(
                              room.startTime
                                  .subtract(const Duration(minutes: 15)),
                            ),
                          );
                          if (t == null) return;
                          final picked = DateTime(
                              d.year, d.month, d.day, t.hour, t.minute);
                          setModalState(() {
                            customRevealTime = picked;
                            timerMode = 'custom';
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 22),

                  // Save button
                  ElevatedButton(
                    onPressed: () async {
                      final newRoomId = roomIdCtrl.text.trim();
                      final newPassword = passwordCtrl.text.trim();

                      DateTime? targetReveal;
                      if (timerMode == '15min') {
                        targetReveal = room.startTime
                            .subtract(const Duration(minutes: 15));
                      } else if (timerMode == '30min') {
                        targetReveal = room.startTime
                            .subtract(const Duration(minutes: 30));
                      } else if (timerMode == 'custom') {
                        targetReveal = customRevealTime;
                      }

                      Navigator.pop(ctx);

                      await _service.updateCredentials(
                        room.id,
                        roomId: newRoomId,
                        roomPassword: newPassword,
                        credentialsVisibleAt: targetReveal,
                        clearTimer: timerMode == 'immediate',
                      );

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: [
                                const Icon(Icons.check_circle_rounded,
                                    color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                    'Room credentials & reveal timer saved!',
                                    style: GoogleFonts.inter(
                                        fontWeight: FontWeight.w500)),
                              ],
                            ),
                            backgroundColor: AppTheme.accentGreen,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(16),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'Save Credentials',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimerChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.cardBorder,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? AppTheme.primaryLight : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: selected ? Colors.white : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClosed() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.accentRed.withValues(alpha: 0.12),
              ),
              child: const Icon(Icons.meeting_room_outlined,
                  color: AppTheme.accentRed, size: 44),
            ),
            const SizedBox(height: 18),
            Text(
              'Room Closed',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'This tournament room has concluded\nor was closed by the host.',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).popUntil((r) => r.isFirst),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                minimumSize: const Size(160, 44),
              ),
              child: const Text('Back to Home'),
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
                    'YOU ARE REGISTERED',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.accentGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    'Slot confirmed as "${player.name}"',
                    style: GoogleFonts.inter(
                        color: AppTheme.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => _removePlayer(room, player),
              child: Text(
                'Leave Slot',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.accentRed,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      onPressed: isFull ? null : () => _showJoinDialog(room),
      icon: Icon(isFull ? Icons.block_rounded : Icons.how_to_reg_rounded,
          size: 18),
      label: Text(isFull ? 'Slots Full' : 'Register for Tournament'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isFull ? AppTheme.bgSurface : AppTheme.primary,
        foregroundColor: isFull ? AppTheme.textMuted : Colors.white,
        minimumSize: const Size(double.infinity, 52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 15, fontWeight: FontWeight.w700),
      ),
    );
  }

  void _showJoinDialog(TournamentRoom room) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        title: Text(
          'Join ${room.name}',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your in-game nickname or gamer tag:',
              style: GoogleFonts.inter(
                  color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: nameCtrl,
              style: GoogleFonts.inter(
                  color: AppTheme.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                labelText: 'Gamer Tag / Display Name',
                hintText: 'e.g. ProGamer99',
                prefixIcon: Icon(Icons.sports_esports_rounded,
                    color: AppTheme.primaryLight, size: 20),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(ctx);

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
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text('Registered as "$name"!',
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    backgroundColor: AppTheme.accentGreen,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(16),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              minimumSize: const Size(110, 42),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Register',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
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
        return AppTheme.primaryLight;
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
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.inter(
              color: AppTheme.textMuted,
              fontSize: 10,
            ),
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
        height: 36,
        color: AppTheme.divider,
      );
}
