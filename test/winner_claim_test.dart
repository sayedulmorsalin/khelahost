import 'package:flutter_test/flutter_test.dart';
import 'package:khelahost/models/tournament_room.dart';
import 'package:khelahost/models/winner_claim.dart';

void main() {
  group('WinnerClaim Model Tests', () {
    test('WinnerClaim toMap and serialization works correctly', () {
      final now = DateTime.now();
      final claim = WinnerClaim(
        id: 'claim_123',
        roomId: 'room_abc',
        playerUid: 'user_456',
        playerName: 'ProGamer99',
        phoneNumber: '01712345678',
        paymentMethod: 'bKash',
        screenshotUrl: 'https://files.catbox.moe/test.png',
        note: 'Booyah with 10 kills',
        status: 'pending',
        submittedAt: now,
      );

      expect(claim.isPending, true);
      expect(claim.isApproved, false);
      expect(claim.isRejected, false);

      final map = claim.toMap();
      expect(map['roomId'], 'room_abc');
      expect(map['playerUid'], 'user_456');
      expect(map['phoneNumber'], '01712345678');
      expect(map['paymentMethod'], 'bKash');
      expect(map['screenshotUrl'], 'https://files.catbox.moe/test.png');
      expect(map['status'], 'pending');

      final updated = claim.copyWith(status: 'approved', hostComment: 'Prize sent');
      expect(updated.isApproved, true);
      expect(updated.hostComment, 'Prize sent');
    });

    test('TournamentRoom 3-hour deadline calculation and window expiration', () {
      final completedTime = DateTime.now().subtract(const Duration(hours: 1));
      final roomActive = TournamentRoom(
        id: 'room_1',
        name: 'Squad Championship',
        game: 'Free Fire',
        roomId: '123',
        roomPassword: 'pass',
        maxPlayers: 48,
        startTime: DateTime.now().subtract(const Duration(hours: 2)),
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        hostId: 'host_1',
        players: [],
        status: 'completed',
        completedAt: completedTime,
      );

      // 1 hour has elapsed, so deadline is 2 hours from now
      expect(roomActive.claimDeadline != null, true);
      expect(roomActive.isClaimWindowOpen, true);
      expect(roomActive.isClaimWindowExpired, false);
      expect(roomActive.remainingClaimTime.inMinutes > 100, true);

      // Now test room completed 4 hours ago (expired)
      final expiredCompletedTime = DateTime.now().subtract(const Duration(hours: 4));
      final roomExpired = roomActive.copyWith(completedAt: expiredCompletedTime);

      expect(roomExpired.isClaimWindowOpen, false);
      expect(roomExpired.isClaimWindowExpired, true);
      expect(roomExpired.remainingClaimTime, Duration.zero);
    });
  });
}
