import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khelahost/core/theme.dart';

class ClaimWindowTimer extends StatefulWidget {
  final DateTime deadline;
  final VoidCallback? onExpired;
  final bool compact;

  const ClaimWindowTimer({
    super.key,
    required this.deadline,
    this.onExpired,
    this.compact = false,
  });

  @override
  State<ClaimWindowTimer> createState() => _ClaimWindowTimerState();
}

class _ClaimWindowTimerState extends State<ClaimWindowTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calcRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _calcRemaining();
    });
  }

  void _calcRemaining() {
    final diff = widget.deadline.difference(DateTime.now());
    if (diff.isNegative) {
      if (_remaining != Duration.zero) {
        setState(() => _remaining = Duration.zero);
        widget.onExpired?.call();
      }
    } else {
      setState(() => _remaining = diff);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final isExpired = _remaining == Duration.zero;
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    if (widget.compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: (isExpired ? AppTheme.accentRed : AppTheme.gold)
              .withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: (isExpired ? AppTheme.accentRed : AppTheme.gold)
                .withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isExpired ? Icons.timer_off_rounded : Icons.timer_rounded,
              size: 13,
              color: isExpired ? AppTheme.accentRed : AppTheme.accentGold,
            ),
            const SizedBox(width: 5),
            Text(
              isExpired
                  ? 'Closed'
                  : '${_pad(hours)}h ${_pad(minutes)}m ${_pad(seconds)}s',
              style: GoogleFonts.plusJakartaSans(
                color: isExpired ? AppTheme.accentRed : AppTheme.goldLight,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: (isExpired ? AppTheme.accentRed : AppTheme.gold)
            .withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isExpired ? AppTheme.accentRed : AppTheme.gold)
              .withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: (isExpired ? AppTheme.accentRed : AppTheme.gold)
                  .withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isExpired ? Icons.lock_clock_rounded : Icons.alarm_rounded,
              color: isExpired ? AppTheme.accentRed : AppTheme.gold,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isExpired ? 'DEADLINE EXPIRED' : '3-HOUR SUBMISSION WINDOW',
                style: GoogleFonts.plusJakartaSans(
                  color: isExpired ? AppTheme.accentRed : AppTheme.goldLight,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isExpired
                    ? 'Submissions are now closed'
                    : '${_pad(hours)}h ${_pad(minutes)}m ${_pad(seconds)}s remaining',
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

