import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:khelahost/core/constants.dart';
import 'package:khelahost/core/theme.dart';
import 'package:khelahost/models/tournament_room.dart';
import 'package:khelahost/screens/room_screen.dart';
import 'package:khelahost/services/room_service.dart';

class JoinScreen extends StatefulWidget {
  final String? initialFilter;

  const JoinScreen({super.key, this.initialFilter});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final RoomService _service = RoomService();
  late String _selectedFilter;
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter ?? 'All';
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ...AppConstants.games];

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: SafeArea(
        child: Column(
          children: [
            // Header Bar
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
                        border: Border.all(color: AppTheme.cardBorder, width: 1.2),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppTheme.textPrimary,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Public Tournaments',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        Text(
                          'Explore active rooms & grab room keys',
                          style: GoogleFonts.inter(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                style: GoogleFonts.inter(
                    color: AppTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search tournament name or game...',
                  prefixIcon: const Icon(Icons.search_rounded,
                      color: AppTheme.textMuted, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded,
                              color: AppTheme.textMuted, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),

            // Filter Chips
            SizedBox(
              height: 52,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                physics: const BouncingScrollPhysics(),
                itemCount: categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final selected = _selectedFilter == cat;

                  return FilterChip(
                    selected: selected,
                    showCheckmark: false,
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (cat == 'All') ...[
                          Icon(
                            Icons.grid_view_rounded,
                            size: 14,
                            color: selected
                                ? const Color(0xFF070A10)
                                : AppTheme.goldLight,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'All Games',
                            style: GoogleFonts.plusJakartaSans(
                              color: selected
                                  ? const Color(0xFF070A10)
                                  : AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ] else ...[
                          GameIconWidget(game: cat, size: 18, borderRadius: 4),
                          const SizedBox(width: 7),
                          Text(
                            cat,
                            style: GoogleFonts.plusJakartaSans(
                              color: selected
                                  ? const Color(0xFF070A10)
                                  : AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                    backgroundColor: AppTheme.bgCard,
                    selectedColor: AppTheme.gold,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 2),
                    side: BorderSide(
                      color: selected
                          ? AppTheme.gold
                          : AppTheme.cardBorderGold,
                      width: 1.2,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    onSelected: (_) => setState(() => _selectedFilter = cat),
                  );
                },
              ),
            ),

            const SizedBox(height: 4),

            // Tournament List
            Expanded(
              child: StreamBuilder<List<TournamentRoom>>(
                stream: _service.streamPublicRooms(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primary,
                        strokeWidth: 2.5,
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Error loading tournaments: ${snapshot.error}',
                        style: const TextStyle(color: AppTheme.accentRed),
                      ),
                    );
                  }

                  final allRooms = snapshot.data ?? [];

                  // Apply filter & search
                  final filteredRooms = allRooms.where((room) {
                    final matchesFilter = _selectedFilter == 'All' ||
                        room.game == _selectedFilter;
                    final matchesSearch = _searchQuery.isEmpty ||
                        room.name
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ||
                        room.game
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase()) ||
                        room.roomId
                            .toLowerCase()
                            .contains(_searchQuery.toLowerCase());
                    return matchesFilter && matchesSearch;
                  }).toList();

                  if (filteredRooms.isEmpty) {
                    return _buildEmptyState();
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    physics: const BouncingScrollPhysics(),
                    itemCount: filteredRooms.length,
                    itemBuilder: (context, index) {
                      return _TournamentCard(room: filteredRooms[index]);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primary.withValues(alpha: 0.1),
              ),
              child: const Icon(Icons.sports_esports_outlined,
                  color: AppTheme.primaryLight, size: 44),
            ),
            const SizedBox(height: 16),
            Text(
              'No Tournaments Found',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'All'
                  ? 'No matching tournaments for your search or filter.'
                  : 'There are no active public tournaments right now.\nBe the first to host one!',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 13,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isNotEmpty || _selectedFilter != 'All') ...[
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _selectedFilter = 'All';
                    _searchQuery = '';
                    _searchCtrl.clear();
                  });
                },
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(140, 40),
                ),
                child: const Text('Reset Filters'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TournamentCard extends StatelessWidget {
  final TournamentRoom room;

  const _TournamentCard({required this.room});

  @override
  Widget build(BuildContext context) {
    final isFull = room.players.length >= room.maxPlayers;
    final isStarted = room.status == 'started';
    final startTimeStr =
        DateFormat('EEE, MMM dd • hh:mm a').format(room.startTime);
    final fillRatio = (room.players.length / room.maxPlayers).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppTheme.glassCard(
        borderColor: isStarted ? AppTheme.accentGreen : AppTheme.cardBorderGold,
        isGold: isStarted,
        borderRadius: 18,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RoomScreen(docId: room.id, isHost: false),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Game badge + Status tag
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          GameIconWidget(game: room.game, size: 22, borderRadius: 5),
                          const SizedBox(width: 8),
                          Text(
                            room.game,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: (isStarted
                                ? AppTheme.accentGreen
                                : (isFull
                                    ? AppTheme.accentRed
                                    : AppTheme.primary))
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isStarted) ...[
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.accentGreen,
                              ),
                            ),
                            const SizedBox(width: 5),
                          ],
                          Text(
                            isStarted
                                ? 'LIVE NOW'
                                : (isFull ? 'FULL' : 'REGISTERING'),
                            style: GoogleFonts.plusJakartaSans(
                              color: isStarted
                                  ? AppTheme.accentGreen
                                  : (isFull
                                      ? AppTheme.accentRed
                                      : AppTheme.primaryLight),
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Tournament Title
                Text(
                  room.name,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 6),

                // Start Time
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        color: AppTheme.textMuted, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      startTimeStr,
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Player capacity progress bar
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Participants',
                          style: GoogleFonts.inter(
                            color: AppTheme.textMuted,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          '${room.players.length} / ${room.maxPlayers} players',
                          style: GoogleFonts.plusJakartaSans(
                            color: isFull
                                ? AppTheme.accentRed
                                : AppTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: fillRatio,
                        minHeight: 5,
                        backgroundColor: AppTheme.bgSurface,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          isFull
                              ? AppTheme.accentRed
                              : (fillRatio > 0.8
                                  ? AppTheme.accentGold
                                  : AppTheme.primary),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(color: AppTheme.divider, height: 1),
                const SizedBox(height: 12),

                // Bottom row: Prize / Credentials status & Enter button
                Row(
                  children: [
                    if (room.prizePool != null &&
                        room.prizePool!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.emoji_events_rounded,
                                color: AppTheme.accentGold, size: 13),
                            const SizedBox(width: 5),
                            Text(
                              room.prizePool!,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.accentGold,
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],

                    // Credentials lock chip
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSurface,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            !room.hasCredentials
                                ? Icons.schedule_rounded
                                : (room.credentialsVisibleAt != null &&
                                        room.credentialsVisibleAt!
                                            .isAfter(DateTime.now())
                                    ? Icons.lock_clock_rounded
                                    : Icons.key_rounded),
                            size: 13,
                            color: !room.hasCredentials ||
                                    (room.credentialsVisibleAt != null &&
                                        room.credentialsVisibleAt!
                                            .isAfter(DateTime.now()))
                                ? AppTheme.accentGold
                                : AppTheme.accentGreen,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            !room.hasCredentials
                                ? 'ID Pending'
                                : (room.credentialsVisibleAt != null &&
                                        room.credentialsVisibleAt!
                                            .isAfter(DateTime.now())
                                    ? 'ID Locked'
                                    : 'ID Ready'),
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    // Enter Room Action Pill
                    Row(
                      children: [
                        Text(
                          'Enter Arena',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.gold,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppTheme.gold,
                          size: 14,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
