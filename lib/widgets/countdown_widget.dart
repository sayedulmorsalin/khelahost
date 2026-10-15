import 'dart:math';
import 'package:flutter/material.dart';
import 'package:khelahost/core/theme.dart';
import 'package:khelahost/models/tournament_room.dart';

/// Animated countdown timer that displays days, hours, minutes, seconds
/// with a pulsing ring and color transitions.
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

class _CountdownWidgetState extends State<CountdownWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _ringController;
  late Animation<double> _pulseAnimation;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    _pulseAnimation =
        Tween<double>(begin: 0.95, end: 1.05).animate(_pulseController);
    _updateRemaining();
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final diff = widget.targetTime.difference(now);
    if (mounted) {
      setState(() => _remaining = diff.isNegative ? Duration.zero : diff);
      if (!diff.isNegative) {
        Future.delayed(const Duration(seconds: 1), _updateRemaining);
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _ringController.dispose();
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

    // Total seconds for ring progress (cap at 24h display)
    final totalSeconds = widget.targetTime.difference(DateTime.now()).inSeconds;
    final progress = totalSeconds > 0
        ? 1 - (_remaining.inSeconds / totalSeconds).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      decoration: AppTheme.glassCard(
        borderColor: _isStarted ? AppTheme.accentGreen : AppTheme.primary,
        borderRadius: 20,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isStarted ? AppTheme.accentGreen : AppTheme.accent,
                  boxShadow: [
                    BoxShadow(
                      color: (_isStarted
                              ? AppTheme.accentGreen
                              : AppTheme.accent)
                          .withValues(alpha: 0.8),
                      blurRadius: 8,
                      spreadRadius: 2,
                    )
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _isStarted ? 'GAME STARTED!' : 'STARTS IN',
                style: TextStyle(
                  color: _isStarted ? AppTheme.accentGreen : AppTheme.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isStarted)
            ScaleTransition(
              scale: _pulseAnimation,
              child: Text(
                '🎮 GAME ON!',
                style: TextStyle(
                  color: AppTheme.accentGreen,
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                ),
              ),
            )
          else ...[
            // Animated ring
            SizedBox(
              width: 120,
              height: 120,
              child: AnimatedBuilder(
                animation: _ringController,
                builder: (ctx, child) => CustomPaint(
                  painter: _RingPainter(progress: progress),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _pad(hours),
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        Text(
                          'HRS',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Days / Minutes / Seconds row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TimeBox(value: _pad(days), label: 'DAYS'),
                _Separator(),
                _TimeBox(value: _pad(minutes), label: 'MIN'),
                _Separator(),
                _TimeBox(value: _pad(seconds), label: 'SEC'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  final String value;
  final String label;
  const _TimeBox({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 56,
          decoration: BoxDecoration(
            color: AppTheme.bgSurface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.primary.withValues(alpha: 0.3)),
          ),
          alignment: Alignment.center,
          child: Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 10,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }
}

class _Separator extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Text(
        ':',
        style: TextStyle(
          color: AppTheme.primary,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      );
}

class _RingPainter extends CustomPainter {
  final double progress;
  _RingPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background ring
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = AppTheme.divider
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );

    // Progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..shader = const LinearGradient(
          colors: [AppTheme.primary, AppTheme.accent],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
