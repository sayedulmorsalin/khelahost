import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khelahost/core/theme.dart';
import 'package:khelahost/models/tournament_room.dart';

class CountdownWidget extends StatefulWidget {
  final DateTime targetTime;
  final TournamentRoom room;

  const CountdownWidget({
    super.key,
    required this.targetTime,
    required this.room,
  });

  @override
  State<CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<CountdownWidget> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final diff = widget.targetTime.difference(now);
    setState(() {
      _remaining = diff.isNegative ? Duration.zero : diff;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _isStarted => _remaining == Duration.zero;

  String _pad(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final days = _remaining.inDays;
    final hours = _remaining.inHours % 24;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;

    return Container(
      decoration: AppTheme.glassCard(
        borderColor:
            _isStarted ? AppTheme.accentGreen : AppTheme.cardBorderGold,
        borderRadius: 20,
        isGold: !_isStarted,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      child: Column(
        children: [
          // Header Status Strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color:
                          _isStarted ? AppTheme.accentGreen : AppTheme.accentGold,
                      boxShadow: [
                        BoxShadow(
                          color: (_isStarted
                                  ? AppTheme.accentGreen
                                  : AppTheme.accentGold)
                              .withValues(alpha: 0.6),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isStarted ? 'MATCH IN PROGRESS' : 'MATCH COUNTDOWN',
                    style: GoogleFonts.plusJakartaSans(
                      color: _isStarted
                          ? AppTheme.accentGreen
                          : AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (_isStarted
                          ? AppTheme.accentGreen
                          : AppTheme.primary)
                      .withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _isStarted ? 'LIVE' : 'UPCOMING',
                  style: GoogleFonts.plusJakartaSans(
                    color: _isStarted
                        ? AppTheme.accentGreen
                        : AppTheme.primaryLight,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          if (_isStarted)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.sports_esports_rounded,
                      color: AppTheme.accentGreen, size: 28),
                  const SizedBox(width: 10),
                  Text(
                    'Match Has Commenced',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            )
          else
            // 4 Balanced Digital Segments
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _TimeUnit(value: _pad(days), label: 'DAYS'),
                _TimeSeparator(),
                _TimeUnit(value: _pad(hours), label: 'HOURS'),
                _TimeSeparator(),
                _TimeUnit(value: _pad(minutes), label: 'MINUTES'),
                _TimeSeparator(),
                _TimeUnit(value: _pad(seconds), label: 'SECONDS', isHighlight: true),
              ],
            ),
        ],
      ),
    );
  }
}

class _TimeUnit extends StatelessWidget {
  final String value;
  final String label;
  final bool isHighlight;

  const _TimeUnit({
    required this.value,
    required this.label,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 58,
          height: 52,
          decoration: BoxDecoration(
            color: AppTheme.bgSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isHighlight ? AppTheme.primary : AppTheme.cardBorderGold,
              width: 1.2,
            ),
            boxShadow: isHighlight
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: isHighlight ? AppTheme.primary : AppTheme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textMuted,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}

class _TimeSeparator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 18),
      child: Text(
        ':',
        style: GoogleFonts.plusJakartaSans(
          color: AppTheme.textMuted,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
