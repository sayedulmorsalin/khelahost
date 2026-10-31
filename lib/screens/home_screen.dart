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
                    // Brand Logo Icon with subtle gold ring
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppTheme.gold.withValues(alpha: 0.4),
                          width: 1.0,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/icon/app_icon.png',
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'KHELA',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            Text(
                              'HOST',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.gold,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.workspace_premium_rounded,
                              size: 11,
                              color: AppTheme.gold,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'VIP TOURNAMENT CLUB',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.goldMuted,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Spacer(),
                    // User Chip with luxury border
                    GestureDetector(
                      onTap: () => _showAccountMenu(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 11, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.bgCard,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isGuest
                                ? AppTheme.cardBorder
                                : AppTheme.gold.withValues(alpha: 0.35),
                            width: 1.0,
                          ),
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
                                  color: isGuest
                                      ? AppTheme.textPrimary
                                      : AppTheme.goldLight,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: isGuest
                                  ? AppTheme.textMuted
                                  : AppTheme.gold,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Luxury Executive VIP Arena Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 18),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: AppTheme.bgCard,
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF162034),
                        Color(0xFF0E1424),
                        Color(0xFF060910),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: AppTheme.gold.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.gold.withValues(alpha: 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                      const BoxShadow(
                        color: Color(0x60000000),
                        blurRadius: 20,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4.5),
                              decoration: BoxDecoration(
                                color: AppTheme.gold.withValues(alpha: 0.16),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppTheme.gold.withValues(alpha: 0.45),
                                  width: 0.9,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.workspace_premium_rounded,
                                      color: AppTheme.gold, size: 13),
                                  const SizedBox(width: 5),
                                  Text(
                                    'VIP ARENA PASS',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: AppTheme.goldLight,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'OFFICIAL ESPORTS',
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.goldMuted,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Executive Tournament Lounge',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Host exclusive tournament lobbies with automated room keys, verified host credentials, and real-time live participant tracking.',
                          style: GoogleFonts.inter(
                            color: AppTheme.textSecondary,
                            fontSize: 12.5,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: const [
                            _FeaturePill(
                                icon: Icons.vpn_key_rounded,
                                label: 'Automated Key Reveal'),
                            _FeaturePill(
                                icon: Icons.sports_esports_rounded,
                                label: '8 Official Titles'),
                            _FeaturePill(
                                icon: Icons.military_tech_rounded,
                                label: 'Verified VIP Hosts'),
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

            // Official Esports Titles Carousel
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.workspace_premium_rounded,
                            size: 16, color: AppTheme.gold),
                        const SizedBox(width: 8),
                        Text(
                          'Featured Titles',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context, _slideRoute(const JoinScreen())),
                      child: Text(
                        'View All',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.gold,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
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
                height: 126,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1524),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppTheme.cardBorderGold,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppTheme.gold),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.goldLight,
              fontSize: 11,
              fontWeight: FontWeight.w700,
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
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 130,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: isPrimary
                ? AppTheme.goldButtonGradient
                : const LinearGradient(
                    colors: [Color(0xFF131B2A), Color(0xFF070B13)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isPrimary
                  ? const Color(0xFFFFF1D0)
                  : AppTheme.cardBorderGold,
              width: 1.2,
            ),
            boxShadow: [
              if (isPrimary)
                BoxShadow(
                  color: AppTheme.gold.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                )
              else
                const BoxShadow(
                  color: Color(0x40000000),
                  blurRadius: 12,
                  offset: Offset(0, 4),
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
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: isPrimary
                          ? const Color(0xFF0A0E18)
                          : AppTheme.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isPrimary
                            ? AppTheme.gold
                            : AppTheme.gold.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      icon,
                      color: isPrimary ? AppTheme.gold : AppTheme.goldLight,
                      size: 20,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isPrimary
                          ? const Color(0xFF0A0E18).withValues(alpha: 0.85)
                          : AppTheme.bgSurface,
                      border: Border.all(
                        color: isPrimary
                            ? AppTheme.gold.withValues(alpha: 0.5)
                            : AppTheme.cardBorderGold,
                        width: 0.8,
                      ),
                    ),
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      size: 13,
                      color: isPrimary ? AppTheme.gold : AppTheme.goldLight,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      color: isPrimary ? const Color(0xFF070A10) : Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: isPrimary
                          ? const Color(0xFF2A2312)
                          : AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
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
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 112,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            gradient: const LinearGradient(
              colors: [Color(0xFF111726), Color(0xFF080C14)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppTheme.cardBorderGold,
              width: 1.0,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x35000000),
                blurRadius: 10,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GameIconWidget(game: name, size: 50, borderRadius: 12),
              const SizedBox(height: 8),
              Text(
                name,
                style: GoogleFonts.plusJakartaSans(
                  color: AppTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'PRO LEAGUE',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.gold,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
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
    final fillRatio = (room.players.length / room.maxPlayers).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassCard(
        borderColor: isStarted ? AppTheme.accentGreen : AppTheme.cardBorderGold,
        isGold: isStarted,
        borderRadius: 18,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GameIconWidget(game: room.game, size: 40, borderRadius: 10),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            room.name,
                            style: GoogleFonts.plusJakartaSans(
                              color: AppTheme.textPrimary,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Text(
                                room.game,
                                style: GoogleFonts.inter(
                                  color: AppTheme.goldLight,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'OFFICIAL LOBBY',
                                style: GoogleFonts.plusJakartaSans(
                                  color: AppTheme.textMuted,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: (isStarted
                                ? AppTheme.accentGreen
                                : (isFull
                                    ? AppTheme.accentRed
                                    : AppTheme.gold))
                            .withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (isStarted
                                  ? AppTheme.accentGreen
                                  : (isFull
                                      ? AppTheme.accentRed
                                      : AppTheme.gold))
                              .withValues(alpha: 0.35),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isStarted) ...[
                            Container(
                              width: 5,
                              height: 5,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.accentGreen,
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            isStarted ? 'LIVE' : (isFull ? 'FULL' : 'OPEN'),
                            style: GoogleFonts.plusJakartaSans(
                              color: isStarted
                                  ? AppTheme.accentGreen
                                  : (isFull
                                      ? AppTheme.accentRed
                                      : AppTheme.goldLight),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: fillRatio,
                    minHeight: 4,
                    backgroundColor: AppTheme.bgSurface,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isFull
                          ? AppTheme.accentRed
                          : (fillRatio > 0.8
                              ? AppTheme.gold
                              : AppTheme.goldDark),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        size: 13, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      timeStr,
                      style: GoogleFonts.inter(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                    if (room.prizePool != null && room.prizePool!.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppTheme.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                          border: Border.all(
                            color: AppTheme.gold.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.emoji_events_rounded,
                                color: AppTheme.gold, size: 12),
                            const SizedBox(width: 4),
                            Text(
                              room.prizePool!,
                              style: GoogleFonts.plusJakartaSans(
                                color: AppTheme.goldLight,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const Spacer(),
                    const Icon(Icons.people_alt_outlined,
                        size: 13, color: AppTheme.textMuted),
                    const SizedBox(width: 4),
                    Text(
                      '${room.players.length} / ${room.maxPlayers}',
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
