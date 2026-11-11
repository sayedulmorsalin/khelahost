import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:khelahost/core/theme.dart';
import 'package:khelahost/models/tournament_room.dart';
import 'package:khelahost/models/winner_claim.dart';
import 'package:khelahost/services/room_service.dart';
import 'package:khelahost/widgets/claim_window_timer.dart';
import 'package:khelahost/widgets/image_viewer_dialog.dart';
import 'package:khelahost/widgets/winner_claim_dialog.dart';

class WinnerClaimsSection extends StatelessWidget {
  final TournamentRoom room;
  final String uid;
  final bool isHost;

  const WinnerClaimsSection({
    super.key,
    required this.room,
    required this.uid,
    required this.isHost,
  });

  @override
  Widget build(BuildContext context) {
    final service = RoomService();

    if (isHost) {
      // Host view: Stream all claims for this room
      return StreamBuilder<List<WinnerClaim>>(
        stream: service.streamWinnerClaims(room.id),
        builder: (context, snapshot) {
          final claims = snapshot.data ?? [];
          return _HostClaimsView(
            room: room,
            claims: claims,
            isLoading: snapshot.connectionState == ConnectionState.waiting,
          );
        },
      );
    } else {
      // Participant view: Stream user's claim
      return StreamBuilder<WinnerClaim?>(
        stream: service.streamPlayerClaim(room.id, uid),
        builder: (context, snapshot) {
          final claim = snapshot.data;
          final isRegistered = room.players.any((p) => p.uid == uid);
          final player =
              room.players.where((p) => p.uid == uid).firstOrNull;
          final playerName = player?.name ?? 'Player';

          return _ParticipantClaimView(
            room: room,
            uid: uid,
            playerName: playerName,
            isRegistered: isRegistered,
            claim: claim,
          );
        },
      );
    }
  }
}

class _HostClaimsView extends StatelessWidget {
  final TournamentRoom room;
  final List<WinnerClaim> claims;
  final bool isLoading;

  const _HostClaimsView({
    required this.room,
    required this.claims,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.emoji_events_rounded,
                color: AppTheme.gold, size: 20),
            const SizedBox(width: 8),
            Text(
              'WINNER CLAIMS & PAYOUTS',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: claims.isNotEmpty
                    ? AppTheme.gold.withValues(alpha: 0.15)
                    : AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: claims.isNotEmpty
                      ? AppTheme.gold.withValues(alpha: 0.4)
                      : AppTheme.cardBorder,
                ),
              ),
              child: Text(
                '${claims.length} submitted',
                style: GoogleFonts.plusJakartaSans(
                  color: claims.isNotEmpty ? AppTheme.goldLight : AppTheme.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (room.isCompleted && room.claimDeadline != null) ...[
          const SizedBox(height: 10),
          ClaimWindowTimer(deadline: room.claimDeadline!),
        ],
        const SizedBox(height: 12),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(
                color: AppTheme.primary,
                strokeWidth: 2,
              ),
            ),
          )
        else if (claims.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: AppTheme.glassCard(borderRadius: 14),
            child: Column(
              children: [
                const Icon(Icons.inbox_rounded,
                    color: AppTheme.textMuted, size: 32),
                const SizedBox(height: 8),
                Text(
                  'No winner claims submitted yet',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'When players finish the match, they can submit their victory screenshots and payout numbers here for you to verify.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppTheme.textMuted,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          )
        else
          ...claims.map((claim) => _ClaimCardForHost(room: room, claim: claim)),
      ],
    );
  }
}

class _ClaimCardForHost extends StatelessWidget {
  final TournamentRoom room;
  final WinnerClaim claim;

  const _ClaimCardForHost({
    required this.room,
    required this.claim,
  });

  void _showApproveDialog(BuildContext context) {
    final commentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        title: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppTheme.accentGreen, size: 22),
            const SizedBox(width: 8),
            Text(
              'Approve & Mark Paid',
              style: GoogleFonts.plusJakartaSans(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 17,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pay prize to ${claim.playerName} via ${claim.paymentMethod}:',
              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_android_rounded,
                      color: AppTheme.primaryLight, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    claim.phoneNumber,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: claim.phoneNumber));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Phone number copied!'),
                          behavior: SnackBarBehavior.floating,
                          duration: Duration(seconds: 1),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: commentCtrl,
              style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Transaction ID / Note (Optional)',
                hintText: 'e.g. TrxID: 9X38174 sent via bKash',
              ),
            ),
          ],
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
              await RoomService().updateClaimStatus(
                room.id,
                claim.playerUid,
                'approved',
                hostComment: commentCtrl.text.trim().isNotEmpty
                    ? commentCtrl.text.trim()
                    : null,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Claim for ${claim.playerName} approved!'),
                    backgroundColor: AppTheme.accentGreen,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Confirm Paid'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final commentCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppTheme.cardBorder),
        ),
        title: Text(
          'Reject Claim?',
          style: GoogleFonts.plusJakartaSans(
            color: AppTheme.accentRed,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter reason for rejection so the player knows what went wrong:',
              style: GoogleFonts.inter(color: AppTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: commentCtrl,
              style: GoogleFonts.inter(color: AppTheme.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                labelText: 'Reason (Optional)',
                hintText: 'e.g. Screenshot does not match room or score',
              ),
            ),
          ],
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
              await RoomService().updateClaimStatus(
                room.id,
                claim.playerUid,
                'rejected',
                hostComment: commentCtrl.text.trim().isNotEmpty
                    ? commentCtrl.text.trim()
                    : null,
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Claim for ${claim.playerName} rejected.'),
                    backgroundColor: AppTheme.accentRed,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentRed,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Reject Claim'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = claim.isApproved
        ? AppTheme.accentGreen
        : (claim.isRejected ? AppTheme.accentRed : AppTheme.gold);
    final statusText = claim.isApproved
        ? 'APPROVED & PAID'
        : (claim.isRejected ? 'REJECTED' : 'PENDING REVIEW');
    final formattedTime =
        DateFormat('MMM dd • hh:mm a').format(claim.submittedAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AppTheme.glassCard(
        borderColor: statusColor.withValues(alpha: 0.6),
        borderRadius: 16,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Player name & Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded,
                    color: AppTheme.primaryLight, size: 16),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      claim.playerName,
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Submitted $formattedTime',
                      style: GoogleFonts.inter(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.plusJakartaSans(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Screenshot section header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.image_rounded,
                      size: 14, color: AppTheme.primaryLight),
                  const SizedBox(width: 6),
                  Text(
                    'VICTORY SCREENSHOT',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () => ImageViewerDialog.show(
                  context,
                  claim.screenshotUrl,
                  title: '${claim.playerName}\'s Victory Proof',
                ),
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.fullscreen_rounded,
                          color: AppTheme.goldLight, size: 15),
                      const SizedBox(width: 4),
                      Text(
                        'View Fullscreen',
                        style: GoogleFonts.plusJakartaSans(
                          color: AppTheme.goldLight,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Screenshot thumbnail with click to zoom
          GestureDetector(
            onTap: () => ImageViewerDialog.show(
              context,
              claim.screenshotUrl,
              title: '${claim.playerName}\'s Victory Proof',
            ),
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.black,
                border: Border.all(color: AppTheme.cardBorder),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      claim.screenshotUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (ctx, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: AppTheme.bgSurface,
                          child: const Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.primaryLight,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (ctx, err, stack) => const Center(
                        child: Icon(Icons.broken_image_rounded,
                            color: AppTheme.textMuted),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.zoom_in_rounded,
                                color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Tap to expand / zoom',
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Payment Phone Number Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    claim.paymentMethod.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.goldLight,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: SelectableText(
                    claim.phoneNumber,
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: claim.phoneNumber));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Copied ${claim.phoneNumber}'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 1),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.copy_rounded,
                            color: AppTheme.primaryLight, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          'Copy',
                          style: GoogleFonts.inter(
                            color: AppTheme.primaryLight,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (claim.note != null && claim.note!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: AppTheme.textMuted, size: 14),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    claim.note!,
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],

          if (claim.hostComment != null && claim.hostComment!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Host note: ${claim.hostComment!}',
                style: GoogleFonts.inter(
                  color: statusColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],

          // Actions
          if (claim.isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showRejectDialog(context),
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Reject'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.accentRed,
                      side: const BorderSide(color: AppTheme.accentRed),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () => _showApproveDialog(context),
                    icon: const Icon(Icons.check_circle_rounded, size: 16),
                    label: const Text('Approve & Pay'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accentGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ParticipantClaimView extends StatelessWidget {
  final TournamentRoom room;
  final String uid;
  final String playerName;
  final bool isRegistered;
  final WinnerClaim? claim;

  const _ParticipantClaimView({
    required this.room,
    required this.uid,
    required this.playerName,
    required this.isRegistered,
    required this.claim,
  });

  @override
  Widget build(BuildContext context) {
    if (!isRegistered) {
      return const SizedBox.shrink();
    }

    // If player already submitted a claim
    if (claim != null) {
      final statusColor = claim!.isApproved
          ? AppTheme.accentGreen
          : (claim!.isRejected ? AppTheme.accentRed : AppTheme.gold);
      final statusText = claim!.isApproved
          ? 'APPROVED & PAID'
          : (claim!.isRejected ? 'REJECTED' : 'PENDING REVIEW');

      return Container(
        decoration: AppTheme.glassCard(
          borderColor: statusColor.withValues(alpha: 0.6),
          borderRadius: 16,
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.emoji_events_rounded,
                    color: AppTheme.gold, size: 20),
                const SizedBox(width: 8),
                Text(
                  'YOUR PRIZE CLAIM',
                  style: GoogleFonts.plusJakartaSans(
                    color: AppTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    statusText,
                    style: GoogleFonts.plusJakartaSans(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Screenshot preview
            GestureDetector(
              onTap: () => ImageViewerDialog.show(
                context,
                claim!.screenshotUrl,
                title: 'Your Victory Proof',
              ),
              child: Container(
                height: 130,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.black,
                  border: Border.all(color: AppTheme.cardBorder),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        claim!.screenshotUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const Center(
                          child: Icon(Icons.broken_image_rounded,
                              color: AppTheme.textMuted),
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.zoom_in_rounded,
                                  color: Colors.white, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'View Full Screenshot',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),

            // Phone and payment method info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.bgSurface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone_android_rounded,
                      color: AppTheme.primaryLight, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    '${claim!.paymentMethod}: ${claim!.phoneNumber}',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            if (claim!.hostComment != null &&
                claim!.hostComment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Host note: ${claim!.hostComment!}',
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            if (!claim!.isApproved) ...[
              const SizedBox(height: 12),
              if (room.isClaimWindowExpired)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.bgSurface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_clock_rounded,
                          size: 14, color: AppTheme.textMuted),
                      const SizedBox(width: 6),
                      Text(
                        '3-Hour submission deadline ended. Under host review.',
                        style: GoogleFonts.inter(
                          color: AppTheme.textMuted,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                if (room.claimDeadline != null) ...[
                  Row(
                    children: [
                      Text(
                        'Window closes in: ',
                        style: GoogleFonts.inter(
                            color: AppTheme.textMuted, fontSize: 11),
                      ),
                      ClaimWindowTimer(
                        deadline: room.claimDeadline!,
                        compact: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => WinnerClaimDialog.show(
                      context,
                      roomId: room.id,
                      playerUid: uid,
                      playerName: playerName,
                      existingClaim: claim,
                      claimDeadline: room.claimDeadline,
                    ),
                    icon: const Icon(Icons.edit_rounded, size: 16),
                    label: const Text('Update Proof / Phone Number'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.goldLight,
                      side: const BorderSide(color: AppTheme.gold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      );
    }

    // If player hasn't submitted yet
    final canClaim = room.status == 'completed' || room.status == 'started';
    if (!canClaim) {
      return const SizedBox.shrink();
    }

    // Check if 3-hour window expired
    if (room.isClaimWindowExpired) {
      return Container(
        decoration: AppTheme.glassCard(
          borderColor: AppTheme.accentRed.withValues(alpha: 0.5),
          borderRadius: 16,
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentRed.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.timer_off_rounded,
                  color: AppTheme.accentRed, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '3-HOUR CLAIM WINDOW EXPIRED',
                    style: GoogleFonts.plusJakartaSans(
                      color: AppTheme.accentRed,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'The 3-hour deadline after match completion has expired. No new victory screenshots can be submitted.',
                    style: GoogleFonts.inter(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final deadline = room.claimDeadline;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.gold.withValues(alpha: 0.2),
            AppTheme.primary.withValues(alpha: 0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.gold.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.gold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.emoji_events_rounded,
                    color: AppTheme.gold, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DID YOU WIN THIS MATCH?',
                      style: GoogleFonts.plusJakartaSans(
                        color: AppTheme.goldLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                    Text(
                      'You have 3 hours after match completion to upload your victory screenshot & payment phone number.',
                      style: GoogleFonts.inter(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (room.isCompleted && deadline != null) ...[
            const SizedBox(height: 12),
            ClaimWindowTimer(deadline: deadline),
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => WinnerClaimDialog.show(
                context,
                roomId: room.id,
                playerUid: uid,
                playerName: playerName,
                claimDeadline: deadline,
              ),
              icon: const Icon(Icons.cloud_upload_rounded, size: 18),
              label: const Text('Upload Winner Screenshot & Phone'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

