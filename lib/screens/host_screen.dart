import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khelahost/core/constants.dart';
import 'package:khelahost/core/theme.dart';
import 'package:khelahost/models/tournament_room.dart';
import 'package:khelahost/screens/room_screen.dart';
import 'package:khelahost/services/room_service.dart';
import 'package:intl/intl.dart';

class HostScreen extends StatefulWidget {
  const HostScreen({super.key});

  @override
  State<HostScreen> createState() => _HostScreenState();
}

class _HostScreenState extends State<HostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _roomIdCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _prizeCtrl = TextEditingController();
  final _rulesCtrl = TextEditingController();
  final _playerNameCtrl = TextEditingController();

  String _selectedGame = AppConstants.games.first;
  int _maxPlayers = 100;
  DateTime? _startTime;
  bool _loading = false;
  bool _obscurePassword = true;

  final _service = RoomService();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roomIdCtrl.dispose();
    _passwordCtrl.dispose();
    _prizeCtrl.dispose();
    _rulesCtrl.dispose();
    _playerNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(hours: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primary,
            surface: AppTheme.bgCard,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.primary,
            surface: AppTheme.bgCard,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    setState(() {
      _startTime = DateTime(
        date.year, date.month, date.day, time.hour, time.minute,
      );
    });
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null) {
      _showError('Please set a game start time.');
      return;
    }
    if (_startTime!.isBefore(DateTime.now())) {
      _showError('Start time must be in the future.');
      return;
    }
    if (_playerNameCtrl.text.trim().isEmpty) {
      _showError('Please enter your display name.');
      return;
    }

    // Require non-guest account to host
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.isAnonymous) {
      _showAccountRequiredDialog();
      return;
    }
    final uid = user.uid;

    setState(() => _loading = true);
    try {
      final hostPlayer = Player(
        uid: uid,
        name: _playerNameCtrl.text.trim(),
        joinedAt: DateTime.now(),
      );

      final room = TournamentRoom(
        id: '',
        name: _nameCtrl.text.trim(),
        game: _selectedGame,
        roomId: _roomIdCtrl.text.trim(),
        roomPassword: _passwordCtrl.text.trim(),
        maxPlayers: _maxPlayers,
        prizePool: _prizeCtrl.text.trim().isEmpty ? null : _prizeCtrl.text.trim(),
        rules: _rulesCtrl.text.trim().isEmpty ? null : _rulesCtrl.text.trim(),
        startTime: _startTime!,
        createdAt: DateTime.now(),
        hostId: uid,
        players: [hostPlayer],
        status: 'waiting',
      );

      final created = await _service.createRoom(room);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => RoomScreen(docId: created.id, isHost: true),
        ),
      );
    } catch (e) {
      _showError('Failed to create room: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.accentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showAccountRequiredDialog() {
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
          'To host a tournament and manage your room credentials, you must create or sign into an account.\n\nGuest users cannot host tournaments.',
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
              Navigator.of(context).popUntil((r) => r.isFirst);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // App bar
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.divider),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            color: AppTheme.textPrimary, size: 18),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HOST TOURNAMENT',
                          style: GoogleFonts.rajdhani(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          'Set up your game room',
                          style: GoogleFonts.inter(
                              color: AppTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel('BASIC INFO'),
                        const SizedBox(height: 12),

                        // Display name
                        _buildField(
                          controller: _playerNameCtrl,
                          label: 'Your Display Name',
                          icon: Icons.person_rounded,
                          hint: 'How players will see you',
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter your name'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Tournament name
                        _buildField(
                          controller: _nameCtrl,
                          label: 'Tournament Name',
                          icon: Icons.emoji_events_rounded,
                          hint: 'e.g. Sunday Battle Royale',
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter tournament name'
                              : null,
                        ),
                        const SizedBox(height: 12),

                        // Game dropdown
                        _SectionLabel('SELECT GAME'),
                        const SizedBox(height: 12),
                        Container(
                          decoration: AppTheme.glassCard(borderRadius: 12),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedGame,
                              isExpanded: true,
                              dropdownColor: AppTheme.bgCard,
                              style: GoogleFonts.inter(
                                  color: AppTheme.textPrimary, fontSize: 15),
                              icon: const Icon(Icons.keyboard_arrow_down_rounded,
                                  color: AppTheme.primary),
                              items: AppConstants.games
                                  .map((g) => DropdownMenuItem(
                                        value: g,
                                        child: Row(
                                          children: [
                                            Text(
                                              AppConstants.gameIcons[g] ?? '🎮',
                                              style: const TextStyle(fontSize: 20),
                                            ),
                                            const SizedBox(width: 10),
                                            Text(g),
                                          ],
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _selectedGame = v!),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),
                        _SectionLabel('ROOM CREDENTIALS'),
                        const SizedBox(height: 12),

                        // Room ID
                        _buildField(
                          controller: _roomIdCtrl,
                          label: 'In-Game Room ID',
                          icon: Icons.tag_rounded,
                          hint: 'Enter your in-game room ID',
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Enter room ID' : null,
                        ),
                        const SizedBox(height: 12),

                        // Password
                        TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePassword,
                          style: GoogleFonts.inter(
                              color: AppTheme.textPrimary, fontSize: 15),
                          decoration: InputDecoration(
                            labelText: 'Room Password',
                            hintText: 'Enter room password',
                            prefixIcon: const Icon(Icons.lock_rounded,
                                color: AppTheme.accentGold, size: 20),
                            suffixIcon: IconButton(
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Enter room password'
                              : null,
                        ),

                        const SizedBox(height: 20),
                        _SectionLabel('TOURNAMENT DETAILS'),
                        const SizedBox(height: 12),

                        // Max players
                        Row(
                          children: [
                            Text(
                              'Max Players',
                              style: GoogleFonts.inter(
                                  color: AppTheme.textSecondary, fontSize: 14),
                            ),
                            const Spacer(),
                            ...AppConstants.playerCounts.map(
                              (count) => GestureDetector(
                                onTap: () =>
                                    setState(() => _maxPlayers = count),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: _maxPlayers == count
                                        ? AppTheme.primary
                                        : AppTheme.bgSurface,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: _maxPlayers == count
                                          ? AppTheme.primary
                                          : AppTheme.divider,
                                    ),
                                  ),
                                  child: Text(
                                    '$count',
                                    style: GoogleFonts.rajdhani(
                                      color: _maxPlayers == count
                                          ? Colors.white
                                          : AppTheme.textSecondary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Prize Pool
                        _buildField(
                          controller: _prizeCtrl,
                          label: 'Prize Pool (Optional)',
                          icon: Icons.monetization_on_rounded,
                          hint: 'e.g. ৳500 or "Custom skins"',
                          iconColor: AppTheme.accentGold,
                          required: false,
                        ),
                        const SizedBox(height: 12),

                        // Rules
                        TextFormField(
                          controller: _rulesCtrl,
                          maxLines: 4,
                          style: GoogleFonts.inter(
                              color: AppTheme.textPrimary, fontSize: 14),
                          decoration: const InputDecoration(
                            labelText: 'Rules & Description (Optional)',
                            hintText:
                                'Enter tournament rules, mode, map info...',
                            alignLabelWithHint: true,
                          ),
                        ),

                        const SizedBox(height: 20),
                        _SectionLabel('START TIME'),
                        const SizedBox(height: 12),

                        // Start time picker
                        GestureDetector(
                          onTap: _pickDateTime,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: AppTheme.glassCard(
                              borderColor: _startTime != null
                                  ? AppTheme.accentGreen
                                  : AppTheme.primary,
                              borderRadius: 12,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color:
                                        AppTheme.primary.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.access_time_rounded,
                                      color: AppTheme.primary, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Game Start Time',
                                        style: GoogleFonts.inter(
                                          color: AppTheme.textMuted,
                                          fontSize: 11,
                                          letterSpacing: 1,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _startTime == null
                                            ? 'Tap to set start time'
                                            : DateFormat('EEE, MMM dd  –  hh:mm a')
                                                .format(_startTime!),
                                        style: GoogleFonts.rajdhani(
                                          color: _startTime == null
                                              ? AppTheme.textSecondary
                                              : AppTheme.accentGreen,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Icon(
                                  Icons.edit_calendar_rounded,
                                  color: AppTheme.textMuted,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Create button
                        GestureDetector(
                          onTap: _loading ? null : _createRoom,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: _loading
                                  ? LinearGradient(colors: [
                                      AppTheme.primary.withValues(alpha: 0.5),
                                      AppTheme.primary.withValues(alpha: 0.3),
                                    ])
                                  : AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary
                                      .withValues(alpha: _loading ? 0.1 : 0.4),
                                  blurRadius: 24,
                                  spreadRadius: -4,
                                )
                              ],
                            ),
                            child: Center(
                              child: _loading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.rocket_launch_rounded,
                                            color: Colors.white, size: 22),
                                        const SizedBox(width: 10),
                                        Text(
                                          'CREATE ROOM',
                                          style: GoogleFonts.rajdhani(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 2,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    Color? iconColor,
    bool required = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: iconColor ?? AppTheme.primary, size: 20),
      ),
      validator: required
          ? (validator ??
              (v) => v == null || v.trim().isEmpty ? 'Required' : null)
          : null,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}
