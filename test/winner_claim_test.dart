import 'package:flutter_test/flutter_test.dart';
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
  });
}

