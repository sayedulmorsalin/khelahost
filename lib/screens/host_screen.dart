import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:khelahost/core/constants.dart';
import 'package:khelahost/core/theme.dart';
import 'package:khelahost/models/tournament_room.dart';
import 'package:khelahost/screens/room_screen.dart';
import 'package:khelahost/services/room_service.dart';

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
  final _maxPlayersCtrl = TextEditingController(text: '100');

  String _selectedGame = AppConstants.games.first;
  int _maxPlayers = 100;
  DateTime? _startTime;
  bool _loading = false;
  bool _obscurePassword = true;

  // Room ID & password options
  bool _giveCredentialsLater = false;
  String _revealTimerMode = 'immediate'; // 'immediate', '15min', '30min', 'custom'
  DateTime? _customRevealTime;

  final _service = RoomService();

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.displayName != null && user.displayName!.isNotEmpty) {
      _playerNameCtrl.text = user.displayName!;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roomIdCtrl.dispose();
    _passwordCtrl.dispose();
    _prizeCtrl.dispose();
    _rulesCtrl.dispose();
    _playerNameCtrl.dispose();
    _maxPlayersCtrl.dispose();
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

  Future<void> _pickCustomRevealTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _startTime ?? now.add(const Duration(minutes: 30)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.accent,
            surface: AppTheme.bgCard,
          ),
        ),
        child: child!,
      ),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(
          _startTime?.subtract(const Duration(minutes: 15)) ??
              now.add(const Duration(minutes: 30))),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppTheme.accent,
            surface: AppTheme.bgCard,
          ),
        ),
        child: child!,
      ),
    );
    if (time == null || !mounted) return;

    final picked = DateTime(
      date.year, date.month, date.day, time.hour, time.minute,
    );
    if (picked.isBefore(DateTime.now())) {
      _showError('Reveal time must be in the future.');
      return;
    }
    if (_startTime != null && picked.isAfter(_startTime!)) {
      _showError('Reveal time cannot be after the match start time.');
      return;
    }

    setState(() {
      _customRevealTime = picked;
      _revealTimerMode = 'custom';
    });
  }

  DateTime? get _calculatedCredentialsRevealTime {
    if (_revealTimerMode == '15min') {
      if (_startTime == null) return null;
      return _startTime!.subtract(const Duration(minutes: 15));
    }
    if (_revealTimerMode == '30min') {
      if (_startTime == null) return null;
      return _startTime!.subtract(const Duration(minutes: 30));
    }
    if (_revealTimerMode == 'custom') {
      return _customRevealTime;
    }
    return null;
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startTime == null) {
      _showError('Please set a match kickoff time.');
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

    final typedPlayers = int.tryParse(_maxPlayersCtrl.text.trim());
    if (typedPlayers == null || typedPlayers < 2 || typedPlayers > 100) {
      _showError('Max players must be a number between 2 and 100.');
      return;
    }

    if (!_giveCredentialsLater) {
      if (_roomIdCtrl.text.trim().isEmpty) {
        _showError('Please enter in-game room ID or check "Give Later".');
        return;
      }
      if (_passwordCtrl.text.trim().isEmpty) {
        _showError('Please enter room password or check "Give Later".');
        return;
      }
    }

    if (_revealTimerMode == 'custom' && _customRevealTime == null) {
      _showError('Please pick a custom time for revealing room credentials.');
      return;
    }

    final revealTime = _calculatedCredentialsRevealTime;

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
        roomId: _giveCredentialsLater ? '' : _roomIdCtrl.text.trim(),
        roomPassword: _giveCredentialsLater ? '' : _passwordCtrl.text.trim(),
        maxPlayers: typedPlayers,
        prizePool: _prizeCtrl.text.trim().isEmpty ? null : _prizeCtrl.text.trim(),
        rules: _rulesCtrl.text.trim().isEmpty ? null : _rulesCtrl.text.trim(),
        startTime: _startTime!,
        createdAt: DateTime.now(),
        hostId: uid,
        players: [hostPlayer],
        status: 'waiting',
        credentialsVisibleAt: revealTime,
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
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                msg,
                style: GoogleFonts.inter(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.accentRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showAccountRequiredDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        title: Text(
          'Account Required',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        content: Text(
          'To host a tournament and manage your room credentials, you must sign into an account.\n\nGuest users cannot host tournaments.',
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.plusJakartaSans(color: AppTheme.textMuted)),
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
            child: Text(
              'Sign In / Register',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            // App Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: AppTheme.cardBorder, width: 1.2),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppTheme.textPrimary,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Host Tournament',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Set up your game match room',
                        style: GoogleFonts.inter(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
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
                physics: const BouncingScrollPhysics(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),

                      // Section 1: Basic Info
                      _buildSectionCard(
                        title: 'MATCH INFORMATION',
                        icon: Icons.sports_esports_rounded,
                        children: [
                          _buildField(
                            controller: _playerNameCtrl,
                            label: 'Your Host Display Name',
                            icon: Icons.person_outline_rounded,
                            hint: 'How players will see the host',
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Enter your host name'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          _buildField(
                            controller: _nameCtrl,
                            label: 'Tournament / Room Name',
                            icon: Icons.emoji_events_outlined,
                            hint: 'e.g. Sunday Night Battle Royale',
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Enter tournament title'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Esports Title / Game',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textSecondary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            decoration: BoxDecoration(
                              color: AppTheme.bgSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedGame,
                                isExpanded: true,
                                dropdownColor: AppTheme.bgCard,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                icon: const Icon(
                                    Icons.keyboard_arrow_down_rounded,
                                    color: AppTheme.primaryLight),
                                items: AppConstants.games
                                    .map(
                                      (g) => DropdownMenuItem(
                                        value: g,
                                        child: Row(
                                          children: [
                                            GameIconWidget(
                                              game: g,
                                              size: 24,
                                              borderRadius: 5,
                                            ),
                                            const SizedBox(width: 10),
                                            Text(g),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedGame = v!),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Section 2: Kickoff Time
                      _buildSectionCard(
                        title: 'SCHEDULE & KICKOFF',
                        icon: Icons.access_time_rounded,
                        children: [
                          GestureDetector(
                            onTap: _pickDateTime,
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.bgSurface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: _startTime != null
                                      ? AppTheme.accentGreen
                                      : AppTheme.divider,
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: (_startTime != null
                                              ? AppTheme.accentGreen
                                              : AppTheme.primary)
                                          .withValues(alpha: 0.15),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: Icon(
                                      Icons.calendar_today_rounded,
                                      color: _startTime != null
                                          ? AppTheme.accentGreen
                                          : AppTheme.primaryLight,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Match Kickoff Time',
                                          style: GoogleFonts.inter(
                                            color: AppTheme.textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _startTime == null
                                              ? 'Tap to select match date & time'
                                              : DateFormat(
                                                      'EEE, MMM dd  •  hh:mm a')
                                                  .format(_startTime!),
                                          style:
                                              GoogleFonts.plusJakartaSans(
                                            color: _startTime == null
                                                ? AppTheme.textSecondary
                                                : AppTheme.textPrimary,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.edit_calendar_rounded,
                                    color: AppTheme.textMuted,
                                    size: 18,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Section 3: Room Credentials & Security
                      _buildSectionCard(
                        title: 'ROOM CREDENTIALS & SECURITY',
                        icon: Icons.vpn_key_rounded,
                        children: [
                          // Give Later Toggle
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: AppTheme.bgSurface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.divider),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Set Room ID & Password Later',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: AppTheme.textPrimary,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        'Provide credentials closer to match kickoff',
                                        style: GoogleFonts.inter(
                                          color: AppTheme.textMuted,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch.adaptive(
                                  value: _giveCredentialsLater,
                                  activeTrackColor: AppTheme.primary,
                                  onChanged: (val) {
                                    setState(
                                        () => _giveCredentialsLater = val);
                                  },
                                ),
                              ],
                            ),
                          ),

                          if (_giveCredentialsLater) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    AppTheme.accentGold.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: AppTheme.accentGold
                                        .withValues(alpha: 0.25)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(Icons.info_outline_rounded,
                                      color: AppTheme.accentGold, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Room credentials will show as "Pending" for participants. You can set them anytime before the match starts from your room screen.',
                                      style: GoogleFonts.inter(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 14),
                            _buildField(
                              controller: _roomIdCtrl,
                              label: 'In-Game Room ID',
                              icon: Icons.tag_rounded,
                              hint: 'Enter your in-game room ID',
                              validator: (v) {
                                if (_giveCredentialsLater) return null;
                                return v == null || v.trim().isEmpty
                                    ? 'Enter room ID or check "Set Later"'
                                    : null;
                              },
                            ),
                            const SizedBox(height: 14),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              style: GoogleFonts.inter(
                                  color: AppTheme.textPrimary, fontSize: 14),
                              decoration: InputDecoration(
                                labelText: 'Room Password',
                                hintText: 'Enter room password',
                                prefixIcon: const Icon(
                                    Icons.lock_outline_rounded,
                                    color: AppTheme.accentGold,
                                    size: 20),
                                suffixIcon: IconButton(
                                  onPressed: () => setState(() =>
                                      _obscurePassword = !_obscurePassword),
                                  icon: Icon(
                                    _obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ),
                              validator: (v) {
                                if (_giveCredentialsLater) return null;
                                return v == null || v.trim().isEmpty
                                    ? 'Enter room password or check "Set Later"'
                                    : null;
                              },
                            ),
                          ],

                          const SizedBox(height: 16),
                          Text(
                            'CREDENTIALS REVEAL TIMER',
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Choose when registered players can view the credentials:',
                            style: GoogleFonts.inter(
                                color: AppTheme.textSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 10),

                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildTimerChip(
                                label: 'Immediately',
                                icon: Icons.flash_on_rounded,
                                selected: _revealTimerMode == 'immediate',
                                onTap: () => setState(
                                    () => _revealTimerMode = 'immediate'),
                              ),
                              _buildTimerChip(
                                label: '15m Before Start',
                                icon: Icons.timer_outlined,
                                selected: _revealTimerMode == '15min',
                                onTap: () {
                                  if (_startTime == null) {
                                    _showError(
                                        'Please set match start time above first.');
                                    return;
                                  }
                                  setState(() => _revealTimerMode = '15min');
                                },
                              ),
                              _buildTimerChip(
                                label: '30m Before Start',
                                icon: Icons.timer_outlined,
                                selected: _revealTimerMode == '30min',
                                onTap: () {
                                  if (_startTime == null) {
                                    _showError(
                                        'Please set match start time above first.');
                                    return;
                                  }
                                  setState(() => _revealTimerMode = '30min');
                                },
                              ),
                              _buildTimerChip(
                                label: 'Custom Timer',
                                icon: Icons.edit_calendar_rounded,
                                selected: _revealTimerMode == 'custom',
                                onTap: _pickCustomRevealTime,
                              ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.bgSurface,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: _revealTimerMode == 'immediate'
                                    ? AppTheme.accentGreen
                                        .withValues(alpha: 0.3)
                                    : AppTheme.accentGold
                                        .withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _revealTimerMode == 'immediate'
                                      ? Icons.visibility_rounded
                                      : Icons.lock_clock_rounded,
                                  color: _revealTimerMode == 'immediate'
                                      ? AppTheme.accentGreen
                                      : AppTheme.accentGold,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _getTimerExplanation(),
                                    style: GoogleFonts.inter(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Section 4: Capacity & Rewards
                      _buildSectionCard(
                        title: 'CAPACITY & REWARDS',
                        icon: Icons.military_tech_rounded,
                        children: [
                          TextFormField(
                            controller: _maxPlayersCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(3),
                            ],
                            style: GoogleFonts.inter(
                                color: AppTheme.textPrimary, fontSize: 14),
                            decoration: const InputDecoration(
                              labelText: 'Max Players (2 - 100)',
                              hintText: 'e.g. 100, 50, 32',
                              prefixIcon: Icon(Icons.people_alt_outlined,
                                  color: AppTheme.primaryLight, size: 20),
                            ),
                            onChanged: (val) {
                              final count = int.tryParse(val.trim());
                              if (count != null) {
                                setState(() => _maxPlayers = count);
                              }
                            },
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Enter max players';
                              }
                              final val = int.tryParse(v.trim());
                              if (val == null) return 'Enter a valid number';
                              if (val < 2) return 'Minimum 2 players required';
                              if (val > 100) return 'Max players cannot exceed 100';
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Text(
                                'Quick Capacity:',
                                style: GoogleFonts.inter(
                                    color: AppTheme.textMuted, fontSize: 12),
                              ),
                              const Spacer(),
                              ...[16, 32, 50, 100].map((count) {
                                final isSelected = _maxPlayers == count &&
                                    _maxPlayersCtrl.text == '$count';
                                return GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _maxPlayers = count;
                                      _maxPlayersCtrl.text = '$count';
                                    });
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.primary
                                          : AppTheme.bgSurface,
                                      borderRadius:
                                          BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected
                                            ? AppTheme.primary
                                            : AppTheme.divider,
                                      ),
                                    ),
                                    child: Text(
                                      '$count',
                                      style: GoogleFonts.plusJakartaSans(
                                        color: isSelected
                                            ? Colors.white
                                            : AppTheme.textSecondary,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildField(
                            controller: _prizeCtrl,
                            label: 'Prize Pool (Optional)',
                            icon: Icons.emoji_events_outlined,
                            hint: 'e.g. ৳1,000 or "Season Pass"',
                            iconColor: AppTheme.accentGold,
                            required: false,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _rulesCtrl,
                            maxLines: 3,
                            style: GoogleFonts.inter(
                                color: AppTheme.textPrimary, fontSize: 14),
                            decoration: const InputDecoration(
                              labelText: 'Rules & Guidelines (Optional)',
                              hintText:
                                  'Enter tournament format, map, weapon bans...',
                              alignLabelWithHint: true,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Submit Button
                      ElevatedButton(
                        onPressed: _loading ? null : _createRoom,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          minimumSize: const Size(double.infinity, 54),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.rocket_launch_rounded,
                                      size: 18),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Create Tournament Room',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: AppTheme.glassCard(borderRadius: 18),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.primaryLight, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
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
      style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon:
            Icon(icon, color: iconColor ?? AppTheme.primaryLight, size: 20),
      ),
      validator: required
          ? (validator ??
              (v) => v == null || v.trim().isEmpty ? 'Required' : null)
          : null,
    );
  }

  String _getTimerExplanation() {
    if (_revealTimerMode == 'immediate') {
      return 'Room credentials will be visible to registered players as soon as they are saved.';
    }
    if (_revealTimerMode == '15min') {
      if (_startTime == null) {
        return 'Will reveal 15 min before match kickoff.';
      }
      final t = _startTime!.subtract(const Duration(minutes: 15));
      return 'Hidden until 15m before match: ${DateFormat('hh:mm a, MMM dd').format(t)}';
    }
    if (_revealTimerMode == '30min') {
      if (_startTime == null) {
        return 'Will reveal 30 min before match kickoff.';
      }
      final t = _startTime!.subtract(const Duration(minutes: 30));
      return 'Hidden until 30m before match: ${DateFormat('hh:mm a, MMM dd').format(t)}';
    }
    if (_revealTimerMode == 'custom') {
      if (_customRevealTime == null) {
        return 'Tap "Custom Timer" to pick release date & time.';
      }
      return 'Hidden until: ${DateFormat('hh:mm a, MMM dd').format(_customRevealTime!)}';
    }
    return '';
  }

  Widget _buildTimerChip({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.primary.withValues(alpha: 0.15)
              : AppTheme.bgSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppTheme.primary : AppTheme.divider,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: selected ? AppTheme.primaryLight : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: selected ? Colors.white : AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
