import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:khelahost/core/theme.dart';
import 'package:khelahost/models/tournament_room.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

class RoomInfoCard extends StatelessWidget {
  final TournamentRoom room;
  final bool showShare;

  const RoomInfoCard({super.key, required this.room, this.showShare = true});

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
    final dateStr = DateFormat('MMM dd, yyyy – hh:mm a').format(room.startTime);
    Share.share(
      '🎮 Join my ${room.game} Tournament!\n\n'
      '🏆 Tournament: ${room.name}\n'
      '🚪 Room ID: ${room.roomId}\n'
      '🔑 Password: ${room.roomPassword}\n'
      '🕐 Starts: $dateStr\n'
      '💰 Prize: ${room.prizePool?.isNotEmpty == true ? room.prizePool : "TBD"}\n\n'
      'Use KhelaHost app to join!',
      subject: 'KhelaHost Tournament Invite',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.glassCard(
        borderColor: AppTheme.accent,
        borderRadius: 20,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.meeting_room_rounded,
                  color: AppTheme.accent, size: 18),
              const SizedBox(width: 8),
              Text(
                'ROOM CREDENTIALS',
                style: TextStyle(
                  color: AppTheme.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Room ID Row
          _CredRow(
            label: 'Room ID',
            value: room.roomId,
            icon: Icons.tag_rounded,
            color: AppTheme.primaryLight,
            onCopy: () => _copy(context, room.roomId, 'Room ID'),
          ),
          const SizedBox(height: 12),

          // Password Row
          _CredRow(
            label: 'Password',
            value: room.roomPassword,
            icon: Icons.lock_rounded,
            color: AppTheme.accentGold,
            onCopy: () => _copy(context, room.roomPassword, 'Password'),
          ),

          if (showShare) ...[
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
      ),
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
    _obscure = widget.label == 'Password';
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
                  style: TextStyle(
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
          if (widget.label == 'Password')
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
