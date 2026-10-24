import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:khelahost/core/constants.dart';
import 'package:khelahost/core/theme.dart';
import 'package:khelahost/models/tournament_room.dart';
import 'package:khelahost/screens/room_screen.dart';
import 'package:khelahost/services/room_service.dart';
import 'package:intl/intl.dart';

class JoinScreen extends StatefulWidget {
  const JoinScreen({super.key});

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _service = RoomService();
  String _selectedFilter = 'All';
  String _searchQuery = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['All', ...AppConstants.games];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              // App Bar
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PUBLIC TOURNAMENTS',
                            style: GoogleFonts.rajdhani(
                              color: AppTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            'Explore active rooms & get ID & Password',
                            style: GoogleFonts.inter(
                                color: AppTheme.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),

              // Filter Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: categories.map((cat) {
                    final selected = _selectedFilter == cat;
                    final icon = AppConstants.gameIcons[cat] ?? '⚔️';
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: selected,
                        showCheckmark: false,
                        label: Text(
                          cat == 'All' ? 'All' : '$icon  $cat',
                          style: GoogleFonts.rajdhani(
                            color: selected
                                ? Colors.white
                                : AppTheme.textSecondary,
                            fontWeight:
                                selected ? FontWeight.w700 : FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        backgroundColor: AppTheme.bgCard,
                        selectedColor: AppTheme.primary,
                        side: BorderSide(
                          color: selected ? AppTheme.primary : AppTheme.divider,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        onSelected: (_) => setState(() => _selectedFilter = cat),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // Tournament List
              Expanded(
                child: StreamBuilder<List<TournamentRoom>>(
                  stream: _service.streamPublicRooms(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppTheme.primary),
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
                  color: AppTheme.primaryLight, size: 48),
            ),
            const SizedBox(height: 16),
            Text(
              'No Tournaments Found',
              style: GoogleFonts.rajdhani(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedFilter != 'All'
                  ? 'Try clearing filters or search query.'
                  : 'There are no active public tournaments hosted right now.\nBe the first to host one!',
              style: GoogleFonts.inter(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
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
    final gameIcon = AppConstants.gameIcons[room.game] ?? '🎮';
    final isFull = room.players.length >= room.maxPlayers;
    final isStarted = room.status == 'started';
    final startTimeStr =
        DateFormat('EEE, MMM dd • hh:mm a').format(room.startTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: AppTheme.glassCard(
        borderColor: isStarted
            ? AppTheme.accentGreen
            : (isFull ? AppTheme.accentRed : AppTheme.primary),
        borderRadius: 16,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => RoomScreen(docId: room.id, isHost: false),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Game badge + Status tag
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(gameIcon, style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            room.game,
                            style: GoogleFonts.rajdhani(
                              color: AppTheme.primaryLight,
                              fontWeight: FontWeight.w700,
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
                                    : AppTheme.accent))
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (isStarted
                                  ? AppTheme.accentGreen
                                  : (isFull
                                      ? AppTheme.accentRed
                                      : AppTheme.accent))
                              .withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        isStarted
                            ? 'LIVE NOW'
                            : (isFull ? 'FULL' : 'WAITING'),
                        style: TextStyle(
                          color: isStarted
                              ? AppTheme.accentGreen
                              : (isFull
                                  ? AppTheme.accentRed
                                  : AppTheme.accent),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Tournament Title
                Text(
                  room.name,
                  style: GoogleFonts.rajdhani(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
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

                // Specs bar: Players count + Prize pool
                Row(
                  children: [
                    // Players count badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.bgSurface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.divider),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_rounded,
                              color: isFull
                                  ? AppTheme.accentRed
                                  : AppTheme.accent,
                              size: 14),
                          const SizedBox(width: 6),
                          Text(
                            '${room.players.length}/${room.maxPlayers}',
                            style: GoogleFonts.rajdhani(
                              color: isFull
                                  ? AppTheme.accentRed
                                  : AppTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (room.prizePool != null &&
                        room.prizePool!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      // Prize pool badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: AppTheme.accentGold.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.monetization_on_rounded,
                                color: AppTheme.accentGold, size: 14),
                            const SizedBox(width: 6),
                            Text(
                              room.prizePool!,
                              style: GoogleFonts.rajdhani(
                                color: AppTheme.accentGold,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Action text
                    Row(
                      children: [
                        Text(
                          !room.hasCredentials
                              ? 'JOIN ROOM'
                              : (room.credentialsVisibleAt != null &&
                                      room.credentialsVisibleAt!
                                          .isAfter(DateTime.now())
                                  ? 'ID LOCKED'
                                  : 'GET ID & PASS'),
                          style: GoogleFonts.rajdhani(
                            color: !room.hasCredentials ||
                                    (room.credentialsVisibleAt != null &&
                                        room.credentialsVisibleAt!
                                            .isAfter(DateTime.now()))
                                ? AppTheme.accentGold
                                : AppTheme.accent,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: !room.hasCredentials ||
                                  (room.credentialsVisibleAt != null &&
                                      room.credentialsVisibleAt!
                                          .isAfter(DateTime.now()))
                              ? AppTheme.accentGold
                              : AppTheme.accent,
                          size: 12,
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
