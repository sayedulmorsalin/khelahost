import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khelahost/core/theme.dart';
import 'package:khelahost/models/tournament_room.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class RoomInfoCard extends StatefulWidget {
  final TournamentRoom room;
  final bool isHost;
  final bool showShare;
  final VoidCallback? onEditCredentials;
  final VoidCallback? onRevealNow;

  const RoomInfoCard({
    super.key,
    required this.room,
    this.isHost = false,
    this.showShare = true,
    this.onEditCredentials,
    this.onRevealNow,
  });

  @override
  State<RoomInfoCard> createState() => _RoomInfoCardState();
}

class _RoomInfoCardState extends State<RoomInfoCard> {
  Timer? _ticker;
  Duration _remainingToReveal = Duration.zero;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didUpdateWidget(covariant RoomInfoCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.room.credentialsVisibleAt !=
        widget.room.credentialsVisibleAt) {
      _startTimer();
    }
  }

  void _startTimer() {
    _ticker?.cancel();
    final revealTime = widget.room.credentialsVisibleAt;
    if (revealTime != null && revealTime.isAfter(DateTime.now())) {
      _updateRemaining();
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        _updateRemaining();
      });
    } else {
      _remainingToReveal = Duration.zero;
    }
  }

  void _updateRemaining() {
    final revealTime = widget.room.credentialsVisibleAt;
    if (revealTime == null) {
      _remainingToReveal = Duration.zero;
      return;
    }
    final diff = revealTime.difference(DateTime.now());
    if (diff.isNegative) {
      _ticker?.cancel();
      setState(() => _remainingToReveal = Duration.zero);
    } else {
      setState(() => _remainingToReveal = diff);
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  bool get _isLockedForPlayers {
    final revealTime = widget.room.credentialsVisibleAt;
    if (revealTime == null) return false;
    return DateTime.now().isBefore(revealTime);
  }

  void _copy(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied!'),
        backgroundColor: AppTheme.accentGreen,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _share(TournamentRoom room) {
    final dateStr =
        DateFormat('MMM dd, yyyy – hh:mm a').format(room.startTime);
    Share.share(
      '🎮 Join my ${room.game} Tournament!\n\n'
      '🏆 Tournament: ${room.name}\n'
      '🚪 Room ID: ${room.roomId.isNotEmpty ? room.roomId : "Pending"}\n'
      '🔑 Password: ${room.roomPassword.isNotEmpty ? room.roomPassword : "Pending"}\n'
      '🕐 Starts: $dateStr\n'
      '💰 Prize: ${room.prizePool?.isNotEmpty == true ? room.prizePool : "TBD"}\n\n'
      'Use KhelaHost app to join!',
      subject: 'KhelaHost Tournament Invite',
    );
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final isHost = widget.isHost;
    final hasCredentials = room.hasCredentials;
    final isLocked = _isLockedForPlayers;

    return Container(
      decoration: AppTheme.glassCard(
        borderColor: !hasCredentials
            ? AppTheme.accentGold
            : (isLocked ? AppTheme.accentGold : AppTheme.accent),
        borderRadius: 20,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top title row with optional Host Edit button
          Row(
            children: [
              Icon(
                !hasCredentials
                    ? Icons.pending_actions_rounded
                    : (isLocked
                        ? Icons.lock_clock_rounded
                        : Icons.meeting_room_rounded),
                color: !hasCredentials || isLocked
                    ? AppTheme.accentGold
                    : AppTheme.accent,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'ROOM CREDENTIALS',
                style: TextStyle(
                  color: !hasCredentials || isLocked
                      ? AppTheme.accentGold
                      : AppTheme.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const Spacer(),
              if (isHost && widget.onEditCredentials != null)
                GestureDetector(
                  onTap: widget.onEditCredentials,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppTheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_rounded,
                            color: AppTheme.primaryLight, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          hasCredentials ? 'EDIT' : 'SET NOW',
                          style: GoogleFonts.rajdhani(
                            color: AppTheme.primaryLight,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Content variations
          if (!hasCredentials) ...[
            // Credentials have not been set yet
            _buildPendingCredentialsCard(isHost),
          ] else if (isLocked && !isHost) ...[
            // Non-host player viewing credentials that are scheduled with timer
            _buildLockedCountdownCard(),
          ] else ...[
            // Revealed credentials (or host view with timer banner)
            _buildRevealedCredentials(room, isHost, isLocked),
          ],
        ],
      ),
    );
  }

  Widget _buildPendingCredentialsCard(bool isHost) {
    if (isHost) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: AppTheme.accentGold.withValues(alpha: 0.3), width: 1),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.key_off_rounded,
                  color: AppTheme.accentGold, size: 28),
            ),
            const SizedBox(height: 10),
            Text(
              'ROOM ID & PASSWORD NOT SET',
              style: GoogleFonts.rajdhani(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You chose to give credentials later. Registered players see them as pending until you add them.',
              style: GoogleFonts.inter(
                color: AppTheme.textMuted,
                fontSize: 12,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            if (widget.onEditCredentials != null)
              ElevatedButton.icon(
                onPressed: widget.onEditCredentials,
                icon: const Icon(Icons.add_moderator_rounded, size: 18),
                label: const Text('SET ROOM ID & PASSWORD'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  textStyle: GoogleFonts.rajdhani(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.accentGold.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hourglass_top_rounded,
                color: AppTheme.accentGold, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            'CREDENTIALS PENDING',
            style: GoogleFonts.rajdhani(
              color: AppTheme.accentGold,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'The tournament host has not set the in-game Room ID and Password yet.\nThey will appear here before the match begins!',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLockedCountdownCard() {
    final hours = _remainingToReveal.inHours;
    final minutes = _remainingToReveal.inMinutes % 60;
    final seconds = _remainingToReveal.inSeconds % 60;
    final revealTimeStr = widget.room.credentialsVisibleAt != null
        ? DateFormat('hh:mm a, MMM dd')
            .format(widget.room.credentialsVisibleAt!)
        : '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.35),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded,
                    color: AppTheme.accentGold, size: 22),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ROOM ID & PASSWORD LOCKED',
                    style: GoogleFonts.rajdhani(
                      color: AppTheme.accentGold,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'Host set a timer to reveal credentials',
                    style: GoogleFonts.inter(
                      color: AppTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ticker display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeUnit(
                  hours.toString().padLeft(2, '0'), 'HOURS'),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(':',
                    style: TextStyle(
                        color: AppTheme.accentGold,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
              ),
              _buildTimeUnit(
                  minutes.toString().padLeft(2, '0'), 'MINS'),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text(':',
                    style: TextStyle(
                        color: AppTheme.accentGold,
                        fontSize: 22,
                        fontWeight: FontWeight.w800)),
              ),
              _buildTimeUnit(
                  seconds.toString().padLeft(2, '0'), 'SECS'),
            ],
          ),

          const SizedBox(height: 14),
          if (revealTimeStr.isNotEmpty)
            Text(
              'Unlocks automatically at $revealTimeStr',
              style: GoogleFonts.inter(
                color: AppTheme.textMuted,
                fontSize: 11,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: AppTheme.accentGold.withValues(alpha: 0.3)),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: GoogleFonts.rajdhani(
              color: AppTheme.accentGold,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            color: AppTheme.textMuted,
            fontSize: 9,
            letterSpacing: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildRevealedCredentials(
      TournamentRoom room, bool isHost, bool isLocked) {
    final revealTimeStr = room.credentialsVisibleAt != null
        ? DateFormat('hh:mm a, MMM dd').format(room.credentialsVisibleAt!)
        : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Host Timer notice banner if credentials are locked for players
        if (isHost && isLocked) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: AppTheme.accentGold.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined,
                    color: AppTheme.accentGold, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HIDDEN FROM PLAYERS UNTIL $revealTimeStr',
                        style: GoogleFonts.rajdhani(
                          color: AppTheme.accentGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        'You can view them, but players cannot until the timer ends.',
                        style: GoogleFonts.inter(
                            color: AppTheme.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                if (widget.onRevealNow != null)
                  TextButton(
                    onPressed: widget.onRevealNow,
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.accentGreen,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('REVEAL NOW',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
          ),
        ] else if (isHost && !isLocked && room.hasCredentials) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppTheme.accentGreen.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.visibility_rounded,
                    color: AppTheme.accentGreen, size: 14),
                const SizedBox(width: 6),
                Text(
                  'Visible to all registered tournament players',
                  style: GoogleFonts.inter(
                      color: AppTheme.accentGreen, fontSize: 11),
                ),
              ],
            ),
          ),
        ],

        // Room ID Row
        _CredRow(
          label: 'Room ID',
          value: room.roomId.isNotEmpty ? room.roomId : 'Not set',
          icon: Icons.tag_rounded,
          color: AppTheme.primaryLight,
          onCopy: room.roomId.isNotEmpty
              ? () => _copy(context, room.roomId, 'Room ID')
              : () {},
        ),
        const SizedBox(height: 12),

        // Password Row
        _CredRow(
          label: 'Password',
          value: room.roomPassword.isNotEmpty ? room.roomPassword : 'None',
          icon: Icons.lock_rounded,
          color: AppTheme.accentGold,
          onCopy: room.roomPassword.isNotEmpty
              ? () => _copy(context, room.roomPassword, 'Password')
              : () {},
        ),

        if (widget.showShare) ...[
          const SizedBox(height: 16),
          const Divider(color: AppTheme.divider),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _share(room),
              icon: const Icon(Icons.share_rounded, size: 18),
              label: const Text('SHARE ROOM'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.accent,
                side: const BorderSide(color: AppTheme.accent),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CredRow extends StatefulWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback onCopy;

  const _CredRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onCopy,
  });

  @override
  State<_CredRow> createState() => _CredRowState();
}

class _CredRowState extends State<_CredRow> {
  bool _obscure = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.label == 'Password' && widget.value != 'None';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: widget.color.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        children: [
          Icon(widget.icon, color: widget.color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: const TextStyle(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _obscure ? '•' * widget.value.length : widget.value,
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
          if (widget.label == 'Password' && widget.value != 'None')
            GestureDetector(
              onTap: () => setState(() => _obscure = !_obscure),
              child: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppTheme.textMuted,
                size: 20,
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: widget.onCopy,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: widget.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.copy_rounded, color: widget.color, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}
