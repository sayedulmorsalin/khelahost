import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khelahost/core/theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _loading = false;
  bool _obscure = true;

  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _displayNameCtrl.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() => _isLogin = !_isLogin);
    _animCtrl
      ..reset()
      ..forward();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final auth = FirebaseAuth.instance;
      if (_isLogin) {
        await auth.signInWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
      } else {
        final cred = await auth.createUserWithEmailAndPassword(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text.trim(),
        );
        final displayName = _displayNameCtrl.text.trim();
        if (displayName.isNotEmpty) {
          await cred.user?.updateDisplayName(displayName);
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(_friendlyError(e.code));
    } catch (e) {
      if (mounted) _showError('Something went wrong. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _continueAsGuest() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      if (mounted) _showError('Could not sign in as guest.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        backgroundColor: AppTheme.accentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with that email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 48),

                      // Logo
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
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
                                borderRadius: BorderRadius.circular(22),
                                child: Image.asset(
                                  'assets/icon/app_icon.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'KHELA HOST',
                              style: GoogleFonts.rajdhani(
                                color: AppTheme.textPrimary,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 4,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tournament Management Platform',
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 40),

                      // Mode toggle header
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: Row(
                          children: [
                            _ModeTab(
                              label: 'Sign In',
                              selected: _isLogin,
                              onTap: () {
                                if (!_isLogin) _toggleMode();
                              },
                            ),
                            _ModeTab(
                              label: 'Create Account',
                              selected: !_isLogin,
                              onTap: () {
                                if (_isLogin) _toggleMode();
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Form
                      Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Display name (sign up only)
                            if (!_isLogin) ...[
                              _FieldLabel('Display Name'),
                              const SizedBox(height: 6),
                              TextFormField(
                                controller: _displayNameCtrl,
                                style: GoogleFonts.inter(
                                    color: AppTheme.textPrimary),
                                decoration: const InputDecoration(
                                  hintText: 'e.g. ProGamer99',
                                  prefixIcon: Icon(Icons.person_rounded,
                                      color: AppTheme.primary, size: 20),
                                ),
                                validator: (v) {
                                  if (!_isLogin &&
                                      (v == null || v.trim().isEmpty)) {
                                    return 'Please enter your display name';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                            ],

                            // Email
                            _FieldLabel('Email Address'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.inter(
                                  color: AppTheme.textPrimary),
                              decoration: const InputDecoration(
                                hintText: 'you@example.com',
                                prefixIcon: Icon(Icons.email_rounded,
                                    color: AppTheme.primary, size: 20),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                if (!v.contains('@') || !v.contains('.')) {
                                  return 'Enter a valid email';
                                }
                                return null;
                              },
                            ),

                            const SizedBox(height: 18),

                            // Password
                            _FieldLabel('Password'),
                            const SizedBox(height: 6),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscure,
                              style: GoogleFonts.inter(
                                  color: AppTheme.textPrimary),
                              decoration: InputDecoration(
                                hintText:
                                    _isLogin ? 'Your password' : 'Min. 6 characters',
                                prefixIcon: const Icon(Icons.lock_rounded,
                                    color: AppTheme.primary, size: 20),
                                suffixIcon: GestureDetector(
                                  onTap: () =>
                                      setState(() => _obscure = !_obscure),
                                  child: Icon(
                                    _obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppTheme.textMuted,
                                    size: 20,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Password is required';
                                }
                                if (!_isLogin && v.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Submit button
                      _loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: AppTheme.primary),
                            )
                          : _GradientButton(
                              label: _isLogin ? 'SIGN IN' : 'CREATE ACCOUNT',
                              icon: _isLogin
                                  ? Icons.login_rounded
                                  : Icons.person_add_rounded,
                              gradient: AppTheme.primaryGradient,
                              glowColor: AppTheme.primary,
                              onTap: _submit,
                            ),

                      const SizedBox(height: 16),

                      // Divider
                      Row(
                        children: [
                          const Expanded(child: Divider(color: AppTheme.divider)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'OR',
                              style: GoogleFonts.inter(
                                  color: AppTheme.textMuted, fontSize: 12),
                            ),
                          ),
                          const Expanded(child: Divider(color: AppTheme.divider)),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Guest button
                      _loading
                          ? const SizedBox.shrink()
                          : OutlinedButton.icon(
                              onPressed: _continueAsGuest,
                              icon: const Icon(Icons.person_outline_rounded,
                                  size: 18),
                              label: const Text('CONTINUE AS GUEST'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppTheme.textSecondary,
                                side: const BorderSide(
                                    color: AppTheme.divider, width: 1.5),
                                minimumSize: const Size(double.infinity, 52),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                textStyle: GoogleFonts.rajdhani(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.5),
                              ),
                            ),

                      const SizedBox(height: 8),

                      Center(
                        child: Text(
                          'Guest accounts cannot manage tournaments',
                          style: GoogleFonts.inter(
                              color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ),

                      const Spacer(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Sub-widgets ─────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.inter(
          color: AppTheme.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      );
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: selected ? AppTheme.primaryGradient : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.rajdhani(
              color: selected ? Colors.white : AppTheme.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class _GradientButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final Color glowColor;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.glowColor,
    required this.onTap,
  });

  @override
  State<_GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<_GradientButton> {
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
          height: 56,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: widget.glowColor
                    .withValues(alpha: _pressed ? 0.2 : 0.45),
                blurRadius: _pressed ? 12 : 28,
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
