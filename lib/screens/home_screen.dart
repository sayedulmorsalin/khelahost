import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:khelahost/core/constants.dart';
import 'package:khelahost/core/theme.dart';
import 'package:khelahost/models/tournament_room.dart';
import 'package:khelahost/screens/host_screen.dart';
import 'package:khelahost/screens/join_screen.dart';
import 'package:khelahost/screens/my_tournaments_screen.dart';
import 'package:khelahost/screens/room_screen.dart';
import 'package:khelahost/services/room_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RoomService _roomService = RoomService();

  PageRoute _slideRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (ctx, anim1, anim2) => page,
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (ctx, anim, secAnim, child) => SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.cardBorder, width: 1.0),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: AppTheme.primaryLight, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Host Account Required',
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'To host tournaments and manage room credentials, please sign in with an email account.\n\nGuest users can browse and participate in public tournaments.',
          style: GoogleFonts.inter(
            color: AppTheme.textSecondary,
            fontSize: 13,
            height: 1.45,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textMuted, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              minimumSize: const Size(140, 42),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Sign In / Register',
              style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showAccountMenu(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user == null || user.isAnonymous;
    final email = user?.email;
    final displayName = user?.displayName;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        decoration: const BoxDecoration(
          color: AppTheme.bgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          border: Border(
            top: BorderSide(color: AppTheme.cardBorder, width: 1.2),
            left: BorderSide(color: AppTheme.cardBorder, width: 1.2),
            right: BorderSide(color: AppTheme.cardBorder, width: 1.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isGuest
                        ? const Color(0xFF1E293B)
                        : AppTheme.primary,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    isGuest
                        ? 'G'
                        : ((displayName?.isNotEmpty == true
                                ? displayName![0]
                                : email?[0]) ??
                            'U')
                            .toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              isGuest
                                  ? 'Guest Player'
                                  : (displayName ?? 'Tournament Host'),
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isGuest
                                  ? AppTheme.bgSurface
                                  : AppTheme.accentGreen
                                      .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isGuest ? 'GUEST' : 'VERIFIED',
                              style: GoogleFonts.plusJakartaSans(
                                color: isGuest
                                    ? AppTheme.textSecondary
                                    : AppTheme.accentGreen,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isGuest
                            ? 'Limited access • Sign in to host'
                            : (email ?? 'Signed in account'),
                        style: GoogleFonts.inter(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Divider(color: AppTheme.divider),
            const SizedBox(height: 8),
            if (!isGuest)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.emoji_events_outlined,
                      color: AppTheme.primaryLight, size: 18),
                ),
                title: Text(
                  'My Hosted Tournaments',
                  style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textMuted, size: 18),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                      context, _slideRoute(const MyTournamentsScreen()));
                },
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isGuest ? AppTheme.primary : AppTheme.accentRed)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isGuest ? Icons.login_rounded : Icons.logout_rounded,
                  color: isGuest ? AppTheme.primaryLight : AppTheme.accentRed,
                  size: 18,
                ),
              ),
              title: Text(
                isGuest ? 'Sign In / Register Account' : 'Sign Out',
                style: GoogleFonts.plusJakartaSans(
                  color: isGuest ? AppTheme.textPrimary : AppTheme.accentRed,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: AppTheme.textMuted, size: 18),
              onTap: () async {
                Navigator.pop(ctx);
                await FirebaseAuth.instance.signOut();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isGuest = user == null || user.isAnonymous;
    final displayName = !isGuest
        ? (user.displayName?.isNotEmpty == true
            ? user.displayName!
            : (user.email?.split('@').first ?? 'Host'))
        : 'Guest';

    return Scaffold(
      backgroundColor: AppTheme.bgDeep,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Top App Bar
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    // Brand Logo Icon
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/icon/app_icon.png',
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Khela',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textPrimary,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                            Text(
                              'Host',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.primaryLight,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          'Tournament Platform',
                          style: GoogleFonts.inter(
                            color: AppTheme.textMuted,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // User Chip
                    GestureDetector(
                      onTap: () => _showAccountMenu(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppTheme.cardBorder, width: 1.0),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isGuest
                                    ? AppTheme.accentGold
                                    : AppTheme.accentGreen,
                              ),
                            ),
                            const SizedBox(width: 6),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 96),
                              child: Text(
                                displayName,
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: AppTheme.textMuted,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Hero Arena Banner
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    color: AppTheme.bgCard,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF162032),
                        Color(0xFF101725),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: AppTheme.cardBorder,
                      width: 1.0,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'TOURNAMENTS',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.primaryLight,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            const Spacer(),
                            const Icon(Icons.shield_outlined,
                                size: 16, color: AppTheme.textMuted),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Host & Join Mobile Matches',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Organize competitive tournaments with automated room password reveals, participant rosters, and match schedules.',
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                            height: 1.45,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _FeaturePill(
                                icon: Icons.schedule_rounded,
                                label: 'Scheduled Unlock'),
                            const SizedBox(width: 8),
                            _FeaturePill(
                                icon: Icons.verified_user_outlined,
                                label: 'Verified Hosts'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Quick Actions: Host & Explore Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Host Action Card
                    Expanded(
                      child: _ActionCard(
                        title: 'Host Match',
                        subtitle: 'Create room & password timer',
                        icon: Icons.add_circle_outline_rounded,
                        isPrimary: true,
                        onTap: () => _handleHostClick(context),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Explore Action Card
                    Expanded(
                      child: _ActionCard(
                        title: 'Explore Rooms',
                        subtitle: 'Browse tournaments & join',
                        icon: Icons.explore_outlined,
                        isPrimary: false,
                        onTap: () => Navigator.push(
                            context, _slideRoute(const JoinScreen())),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // My Tournaments Bar (if logged in email user)
            if (!isGuest)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.push(
                        context, _slideRoute(const MyTournamentsScreen())),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: AppTheme.glassCard(borderRadius: 14),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.emoji_events_outlined,
                                color: AppTheme.primaryLight, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Hosted Tournaments',
                                  style: GoogleFonts.plusJakartaSans(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  'Manage passwords, players & match status',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.textMuted,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppTheme.textMuted, size: 18),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Popular Esports Games Carousel
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Featured Games',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context, _slideRoute(const JoinScreen())),
                      child: Text(
                        'View All',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.primaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Real Game Icon Cards Carousel
            SliverToBoxAdapter(
              child: SizedBox(
                height: 102,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: AppConstants.games.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final game = AppConstants.games[index];
                    return _GameCategoryCard(
                      name: game,
                      onTap: () => Navigator.push(
                        context,
                        _slideRoute(JoinScreen(initialFilter: game)),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Live & Upcoming Tournaments Feed Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accentGreen,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Active Tournaments',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context, _slideRoute(const JoinScreen())),
                      child: Text(
                        'Explore',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.primaryLight,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Dynamic Stream of active public tournaments
            StreamBuilder<List<TournamentRoom>>(
              stream: _roomService.streamPublicRooms(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(28),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primary,
                          strokeWidth: 2.0,
                        ),
                      ),
                    ),
                  );
                }

                final rooms = snapshot.data ?? [];

                if (rooms.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 6),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AppTheme.glassCard(borderRadius: 16),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primary.withValues(alpha: 0.1),
                              ),
                              child: const Icon(Icons.sports_esports_outlined,
                                  color: AppTheme.primaryLight, size: 26),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              'No Active Tournaments',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Create the first match room and invite players!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                color: AppTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _handleHostClick(context),
                              icon: const Icon(Icons.add_rounded, size: 16),
                              label: const Text('Host Tournament'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primary,
                                minimumSize: const Size(160, 38),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final room = rooms[index];
                        return _LiveTournamentCard(
                          room: room,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    RoomScreen(docId: room.id, isHost: false),
                              ),
                            );
                          },
                        );
                      },
                      childCount: rooms.length > 5 ? 5 : rooms.length,
                    ),
                  ),
                );
              },
            ),

            // Footer statistics
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatItem(
                          title: '50K+',
                          subtitle: 'Players',
                          icon: Icons.people_outline_rounded),
                      Container(
                          width: 1, height: 28, color: AppTheme.divider),
                      _StatItem(
                          title: '1K+',
                          subtitle: 'Tournaments',
                          icon: Icons.emoji_events_outlined),
                      Container(
                          width: 1, height: 28, color: AppTheme.divider),
                      _StatItem(
                          title: '7+',
                          subtitle: 'Games',
                          icon: Icons.sports_esports_outlined),
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
}

class _FeaturePill extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeaturePill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: const Color(0xFF334155),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.primaryLight),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 124,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isPrimary ? AppTheme.primary : AppTheme.bgCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isPrimary ? AppTheme.primaryLight : AppTheme.cardBorder,
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isPrimary
                          ? Colors.white.withValues(alpha: 0.18)
                          : AppTheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: isPrimary ? Colors.white : AppTheme.primaryLight,
                      size: 20,
                    ),
                  ),
                  Icon(
                    Icons.arrow_outward_rounded,
                    size: 16,
                    color: isPrimary ? Colors.white70 : AppTheme.textMuted,
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: isPrimary
                          ? Colors.white.withValues(alpha: 0.8)
                          : AppTheme.textMuted,
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameCategoryCard extends StatelessWidget {
  final String name;
  final VoidCallback onTap;

  const _GameCategoryCard({
    required this.name,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 105,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.cardBorder, width: 1.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GameIconWidget(game: name, size: 42, borderRadius: 10),
              const SizedBox(height: 8),
              Text(
                name,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveTournamentCard extends StatelessWidget {
  final TournamentRoom room;
  final VoidCallback onTap;

  const _LiveTournamentCard({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isFull = room.players.length >= room.maxPlayers;
    final isStarted = room.status == 'started';
    final timeStr = DateFormat('hh:mm a • MMM dd').format(room.startTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.glassCard(
        borderColor: isStarted ? AppTheme.accentGreen : AppTheme.cardBorder,
        borderRadius: 14,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GameIconWidget(game: room.game, size: 22, borderRadius: 5),
                    const SizedBox(width: 8),
                    Text(
                      room.game,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: (isStarted
                                ? AppTheme.accentGreen
                                : (isFull
                                    ? AppTheme.accentRed
                                    : AppTheme.primary))
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        isStarted ? 'LIVE' : (isFull ? 'FULL' : 'OPEN'),
                        style: GoogleFonts.plusJakartaSans(
                          color: isStarted
                              ? AppTheme.accentGreen
                              : (isFull
                                  ? AppTheme.accentRed
                                  : AppTheme.primaryLight),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  room.name,
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule_rounded,
                        size: 13, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: GoogleFonts.inter(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.people_alt_outlined,
                        size: 13, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${room.players.length}/${room.maxPlayers}',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
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

class _StatItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _StatItem({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryLight),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                color: AppTheme.textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
