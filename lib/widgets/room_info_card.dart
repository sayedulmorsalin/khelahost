import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:khelahost/core/theme.dart';
import 'package:khelahost/models/tournament_room.dart';
import 'package:share_plus/share_plus.dart';

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
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text('$label copied to clipboard',
                style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
          ],
        ),
        backgroundColor: AppTheme.accentGreen,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
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
            : (isLocked ? AppTheme.accentGold : AppTheme.cardBorder),
        borderRadius: 20,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top title row with optional Host Edit button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: (!hasCredentials || isLocked
                          ? AppTheme.accentGold
                          : AppTheme.primary)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  !hasCredentials
                      ? Icons.pending_actions_rounded
                      : (isLocked
                          ? Icons.lock_clock_rounded
                          : Icons.vpn_key_rounded),
                  color: !hasCredentials || isLocked
                      ? AppTheme.accentGold
                      : AppTheme.primaryLight,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'ROOM CREDENTIALS',
                style: GoogleFonts.plusJakartaSans(
                  color: !hasCredentials || isLocked
                      ? AppTheme.accentGold
                      : AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              if (isHost && widget.onEditCredentials != null)
                GestureDetector(
                  onTap: widget.onEditCredentials,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppTheme.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.edit_rounded,
                            color: AppTheme.primaryLight, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          hasCredentials ? 'Edit' : 'Set Now',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.primaryLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
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
            _buildPendingCredentialsCard(isHost),
          ] else if (isLocked && !isHost) ...[
            _buildLockedCountdownCard(),
          ] else ...[
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
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.accentGold.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentGold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.key_off_rounded,
                  color: AppTheme.accentGold, size: 24),
            ),
            const SizedBox(height: 10),
            Text(
              'Room ID & Password Not Set',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'You chose to set credentials later. Players see them as pending until you add them.',
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
                icon: const Icon(Icons.add_moderator_rounded, size: 16),
                label: const Text('Set In-Game Room Details'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(200, 42),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.hourglass_top_rounded,
                color: AppTheme.accentGold, size: 24),
          ),
          const SizedBox(height: 10),
          Text(
            'Credentials Pending',
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.accentGold,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'The tournament host will set the in-game Room ID and Password before match kickoff.',
            style: GoogleFonts.inter(
              color: AppTheme.textSecondary,
              fontSize: 12,
              height: 1.4,
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentGold.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_rounded,
                    color: AppTheme.accentGold, size: 18),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Credentials Auto-Unlock Timer',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.accentGold,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    'Protected until host scheduled reveal time',
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

          // Digital Timer display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDigitalBox(hours.toString().padLeft(2, '0'), 'HOURS'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(':',
                    style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.accentGold,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
              ),
              _buildDigitalBox(minutes.toString().padLeft(2, '0'), 'MINS'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(':',
                    style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.accentGold,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
              ),
              _buildDigitalBox(seconds.toString().padLeft(2, '0'), 'SECS'),
            ],
          ),

          const SizedBox(height: 12),
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

  Widget _buildDigitalBox(String value, String label) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 44,
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppTheme.accentGold.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.accentGold,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
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
        // Host notice if credentials are locked for players
        if (isHost && isLocked) ...[
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.accentGold.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer_outlined,
                    color: AppTheme.accentGold, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hidden from players until $revealTimeStr',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.accentGold,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        'Only you can view this right now.',
                        style: GoogleFonts.inter(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
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
                    child: Text(
                      'Reveal Now',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ] else if (isHost && !isLocked && room.hasCredentials) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppTheme.accentGreen.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: AppTheme.accentGreen, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Visible to all registered players',
                  style: GoogleFonts.inter(
                    color: AppTheme.accentGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],

        // Room ID Row
        _CredRow(
          label: 'In-Game Room ID',
          value: room.roomId.isNotEmpty ? room.roomId : 'Not set',
          icon: Icons.tag_rounded,
          accentColor: AppTheme.primaryLight,
          onCopy: room.roomId.isNotEmpty
              ? () => _copy(context, room.roomId, 'Room ID')
              : () {},
        ),
        const SizedBox(height: 10),

        // Password Row
        _CredRow(
          label: 'Room Password',
          value: room.roomPassword.isNotEmpty ? room.roomPassword : 'None',
          icon: Icons.lock_outline_rounded,
          accentColor: AppTheme.accentGold,
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
              icon: const Icon(Icons.share_outlined, size: 18),
              label: const Text('Share Room Details'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textPrimary,
                side: const BorderSide(color: AppTheme.cardBorder, width: 1.2),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
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
  final Color accentColor;
  final VoidCallback onCopy;

  const _CredRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
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
    _obscure = widget.label.contains('Password') && widget.value != 'None';
  }

  @override
  Widget build(BuildContext context) {
    final isPassword = widget.label.contains('Password');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: widget.accentColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.icon, color: widget.accentColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.label,
                  style: GoogleFonts.inter(
                    color: AppTheme.textMuted,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _obscure ? '••••••••' : widget.value,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          if (isPassword && widget.value != 'None')
            IconButton(
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: AppTheme.textMuted,
                size: 18,
              ),
              onPressed: () => setState(() => _obscure = !_obscure),
            ),
          IconButton(
            icon: const Icon(Icons.copy_rounded,
                color: AppTheme.primaryLight, size: 18),
            onPressed: widget.onCopy,
            tooltip: 'Copy',
          ),
        ],
      ),
    );
  }
}
