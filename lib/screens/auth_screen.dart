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
      duration: const Duration(milliseconds: 500),
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
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.inter(
                    color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.accentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
      backgroundColor: AppTheme.bgDeep,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
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
                    const SizedBox(height: 36),

                    // App Brand Header
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: AppTheme.primaryLight.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withValues(alpha: 0.35),
                                  blurRadius: 28,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/icon/app_icon.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'KHELA',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                'HOST',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.primary,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppTheme.cardBorderGold,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.workspace_premium_rounded,
                                    color: AppTheme.primary, size: 13),
                                const SizedBox(width: 5),
                                Text(
                                  'PREMIER VIP ESPORTS ARENA',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.primaryLight,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Auth Card
                    Container(
                      decoration: AppTheme.glassCard(
                        borderRadius: 24,
                        isGold: true,
                        borderColor: AppTheme.cardBorderGold,
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Mode toggle header
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppTheme.bgSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.cardBorderGold),
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

                          const SizedBox(height: 22),

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
                                        color: AppTheme.textPrimary,
                                        fontSize: 14),
                                    decoration: const InputDecoration(
                                      hintText: 'e.g. ProGamer99',
                                      prefixIcon: Icon(Icons.person_outline_rounded,
                                          color: AppTheme.primaryLight, size: 20),
                                    ),
                                    validator: (v) {
                                      if (!_isLogin &&
                                          (v == null || v.trim().isEmpty)) {
                                        return 'Please enter your display name';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                ],

                                // Email
                                _FieldLabel('Email Address'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _emailCtrl,
                                  keyboardType: TextInputType.emailAddress,
                                  style: GoogleFonts.inter(
                                      color: AppTheme.textPrimary, fontSize: 14),
                                  decoration: const InputDecoration(
                                    hintText: 'you@example.com',
                                    prefixIcon: Icon(Icons.email_outlined,
                                        color: AppTheme.primaryLight, size: 20),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Email is required';
                                    }
                                    if (!v.contains('@') || !v.contains('.')) {
                                      return 'Enter a valid email address';
                                    }
                                    return null;
                                  },
                                ),

                                const SizedBox(height: 16),

                                // Password
                                _FieldLabel('Password'),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _passwordCtrl,
                                  obscureText: _obscure,
                                  style: GoogleFonts.inter(
                                      color: AppTheme.textPrimary, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: _isLogin
                                        ? 'Your password'
                                        : 'Min. 6 characters',
                                    prefixIcon: const Icon(
                                        Icons.lock_outline_rounded,
                                        color: AppTheme.primaryLight,
                                        size: 20),
                                    suffixIcon: IconButton(
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                      icon: Icon(
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

                          const SizedBox(height: 22),

                          // Submit button
                          _loading
                              ? const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(
                                      color: AppTheme.primary,
                                      strokeWidth: 2.5,
                                    ),
                                  ),
                                )
                              : Container(
                                  width: double.infinity,
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.goldButtonGradient,
                                    borderRadius: BorderRadius.circular(14),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primary
                                            .withValues(alpha: 0.35),
                                        blurRadius: 16,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: _submit,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _isLogin
                                              ? Icons.login_rounded
                                              : Icons.workspace_premium_rounded,
                                          size: 19,
                                          color: const Color(0xFF070A10),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _isLogin
                                              ? 'Sign In to Arena'
                                              : 'Join VIP Arena',
                                          style: GoogleFonts.plusJakartaSans(
                                            color: const Color(0xFF070A10),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                            letterSpacing: 0.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Divider
                    Row(
                      children: [
                        const Expanded(child: Divider(color: AppTheme.divider)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          child: Text(
                            'OR',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: AppTheme.divider)),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Guest button
                    _loading
                        ? const SizedBox.shrink()
                        : OutlinedButton.icon(
                            onPressed: _continueAsGuest,
                            icon: const Icon(Icons.person_outline_rounded,
                                size: 18, color: AppTheme.primaryLight),
                            label: const Text('Continue as Guest'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.textPrimary,
                              side: const BorderSide(
                                  color: AppTheme.cardBorderGold, width: 1.2),
                              minimumSize: const Size(double.infinity, 50),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              textStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),

                    const SizedBox(height: 10),

                    Center(
                      child: Text(
                        'Guest players can explore rooms and participate in tournaments',
                        style: GoogleFonts.inter(
                          color: AppTheme.textMuted,
                          fontSize: 11,
                        ),
                        textAlign: TextAlign.center,
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
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          color: AppTheme.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: selected ? AppTheme.goldButtonGradient : null,
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppTheme.primary.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: selected ? const Color(0xFF070A10) : AppTheme.textMuted,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
