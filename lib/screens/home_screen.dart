import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khelahost/core/theme.dart';
import 'package:khelahost/screens/host_screen.dart';
import 'package:khelahost/screens/join_screen.dart';
import 'package:khelahost/screens/my_tournaments_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgController;
  late AnimationController _floatController;
  late Animation<double> _floatAnimation;
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnimation =
        Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOut),
    );
    final rng = Random();
    _particles = List.generate(
      20,
      (_) => _Particle(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        size: rng.nextDouble() * 3 + 1,
        speed: rng.nextDouble() * 0.002 + 0.001,
        opacity: rng.nextDouble() * 0.5 + 0.1,
      ),
    );
  }

  @override
  void dispose() {
    _bgController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedBuilder(
        animation: _bgController,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF070B14),
                  Color.lerp(
                    const Color(0xFF0F1629),
                    const Color(0xFF1A0A2E),
                    _bgController.value,
                  )!,
                  const Color(0xFF070B14),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: child,
          );
        },
        child: Stack(
          children: [
            // Particles
            ...List.generate(
              _particles.length,
              (i) => _ParticleWidget(particle: _particles[i]),
            ),

            // Glow orb top-right
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primary.withValues(alpha: 0.25),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Glow orb bottom-left
            Positioned(
              bottom: -60,
              left: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.accent.withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          // Top bar: account info + logout
                          _buildTopBar(context),
                          const SizedBox(height: 16),

                          // App Logo / Header
                          AnimatedBuilder(
                            animation: _floatAnimation,
                            builder: (_, child) => Transform.translate(
                              offset: Offset(0, _floatAnimation.value),
                              child: Column(
                                children: [
                                  // Logo icon
                                  Container(
                                    width: 96,
                                    height: 96,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primary
                                              .withValues(alpha: 0.55),
                                          blurRadius: 30,
                                          spreadRadius: 2,
                                        ),
                                        BoxShadow(
                                          color: AppTheme.accent
                                              .withValues(alpha: 0.3),
                                          blurRadius: 20,
                                          spreadRadius: -4,
                                        ),
                                      ],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(24),
                                      child: Image.asset(
                                        'assets/icon/app_icon.png',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'KHELA HOST',
                                    style: GoogleFonts.rajdhani(
                                      color: AppTheme.textPrimary,
                                      fontSize: 38,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Host & Join Mobile Game Tournaments',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.textSecondary,
                                      fontSize: 13,
                                      letterSpacing: 0.5,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Stats row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _StatBadge(
                                  icon: Icons.people_rounded,
                                  label: 'Players',
                                  value: '50K+'),
                              const SizedBox(width: 16),
                              _StatBadge(
                                  icon: Icons.emoji_events_rounded,
                                  label: 'Tournaments',
                                  value: '1K+'),
                              const SizedBox(width: 16),
                              _StatBadge(
                                  icon: Icons.gamepad_rounded,
                                  label: 'Games',
                                  value: '7+'),
                            ],
                          ),

                          const SizedBox(height: 28),

                          // HOST BUTTON
                          _GlowButton(
                            label: 'HOST A TOURNAMENT',
                            icon: Icons.add_circle_rounded,
                            gradient: AppTheme.primaryGradient,
                            glowColor: AppTheme.primary,
                            onTap: () => _handleHostClick(context),
                          ),

                          const SizedBox(height: 14),

                          // MY TOURNAMENTS (email users only)
                          StreamBuilder<User?>(
                            stream: FirebaseAuth.instance.authStateChanges(),
                            builder: (ctx, snap) {
                              final user = snap.data;
                              final isEmailUser =
                                  user != null && !user.isAnonymous;
                              if (!isEmailUser) return const SizedBox.shrink();
                              return Column(
                                children: [
                                  const SizedBox(height: 14),
                                  _GlowButton(
                                    label: 'MY TOURNAMENTS',
                                    icon: Icons.emoji_events_rounded,
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF059669),
                                        Color(0xFF047857)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    glowColor: AppTheme.accentGreen,
                                    onTap: () => Navigator.push(
                                      context,
                                      _slideRoute(
                                          const MyTournamentsScreen()),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 14),

                          // JOIN / EXPLORE BUTTON
                          _GlowButton(
                            label: 'EXPLORE TOURNAMENTS',
                            icon: Icons.explore_rounded,
                            gradient: AppTheme.accentGradient,
                            glowColor: AppTheme.accent,
                            onTap: () => Navigator.push(
                              context,
                              _slideRoute(const JoinScreen()),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Games row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: ['\ud83c\udfaf', '\ud83d\udd25', '\ud83d\udca5', '\u26a1', '\u2694\ufe0f']
                                .map((e) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      child: Text(e,
                                          style: const TextStyle(fontSize: 20)),
                                    ))
                                .toList(),
                          ),

                          const SizedBox(height: 10),

                          Text(
                            'PUBG · Free Fire · COD Mobile · Valorant',
                            style: GoogleFonts.inter(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              letterSpacing: 1,
                            ),
                          ),

                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleHostClick(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      _showAccountRequiredDialog(context);
    } else {
      Navigator.push(context, _slideRoute(const HostScreen()));
    }
  }

  void _showAccountRequiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.lock_person_rounded,
                color: AppTheme.primaryLight, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'ACCOUNT REQUIRED',
                style: GoogleFonts.rajdhani(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'To host a tournament and manage your room credentials anytime, you must create or sign into an account.\n\nGuest users cannot host tournaments.',
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // Sign out guest user so AuthGate redirects to AuthScreen
              await FirebaseAuth.instance.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('SIGN IN / REGISTER'),
          ),
        ],
      ),
    );
  }

  PageRoute _slideRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (ctx, anim1, anim2) => page,
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (ctx, anim, secAnim, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
          child: child,
        ),
      );

  Widget _buildTopBar(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user == null || user.isAnonymous;
    final String displayName;
    if (!isGuest) {
      final dn = user.displayName;
      final em = user.email;
      displayName = (dn != null && dn.isNotEmpty) ? dn : (em ?? 'Host');
    } else {
      displayName = 'Guest';
    }
    return Row(
      children: [
        // Account pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.divider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isGuest ? Icons.person_outline_rounded : Icons.verified_rounded,
                size: 14,
                color: isGuest ? AppTheme.textMuted : AppTheme.accentGreen,
              ),
              const SizedBox(width: 6),
              Text(
                displayName,
                style: GoogleFonts.inter(
                  color: isGuest ? AppTheme.textMuted : AppTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),

        const Spacer(),

        // Sign out / Sign in button
        GestureDetector(
          onTap: () async {
            if (isGuest) {
              // Sign out anonymous → goes to AuthScreen via AuthGate
              await FirebaseAuth.instance.signOut();
            } else {
              // Confirm sign out for email users
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppTheme.bgCard,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: Text('Sign Out?',
                      style: GoogleFonts.rajdhani(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.w700)),
                  content: Text('You will need to sign in again to manage your tournaments.',
                      style: GoogleFonts.inter(
                          color: AppTheme.textSecondary, fontSize: 13)),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel',
                          style: TextStyle(color: AppTheme.textMuted)),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Sign Out',
                          style: TextStyle(color: AppTheme.accentRed)),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await FirebaseAuth.instance.signOut();
              }
            }
          },
          child: Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.divider),
            ),
            child: Icon(
              isGuest ? Icons.login_rounded : Icons.logout_rounded,
              size: 18,
              color: isGuest ? AppTheme.accent : AppTheme.textMuted,
            ),
          ),
        ),
      ],
    );
  }
}


class _GlowButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final Color glowColor;
  final VoidCallback onTap;

  const _GlowButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.glowColor,
    required this.onTap,
  });

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          height: 60,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor.withValues(alpha: _pressed ? 0.2 : 0.45),
                blurRadius: _pressed ? 12 : 24,
                spreadRadius: -4,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: Colors.white, size: 22),
              const SizedBox(width: 10),
              Text(
                widget.label,
                style: GoogleFonts.rajdhani(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatBadge(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: AppTheme.glassCard(borderRadius: 12),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.accent, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: AppTheme.textPrimary,
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

// Particle system
class _Particle {
  double x, y, size, speed, opacity;
  _Particle(
      {required this.x,
      required this.y,
      required this.size,
      required this.speed,
      required this.opacity});
}

class _ParticleWidget extends StatefulWidget {
  final _Particle particle;
  const _ParticleWidget({required this.particle});

  @override
  State<_ParticleWidget> createState() => _ParticleWidgetState();
}

class _ParticleWidgetState extends State<_ParticleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(seconds: (1 / widget.particle.speed).round()),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0, end: 1).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return AnimatedBuilder(
      animation: _anim,
      builder: (ctx, child) => Positioned(
        left: widget.particle.x * size.width,
        top: (widget.particle.y + _anim.value * 0.05) * size.height,
        child: Opacity(
          opacity: widget.particle.opacity,
          child: Container(
            width: widget.particle.size,
            height: widget.particle.size,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accent,
            ),
          ),
        ),
      ),
    );
  }
}
