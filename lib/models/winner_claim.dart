import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _parseDateTime(dynamic val) {
  if (val is Timestamp) return val.toDate();
  if (val is DateTime) return val;
  if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
  if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
  return DateTime.now();
}

class WinnerClaim {
  final String id;
  final String roomId;
  final String playerUid;
  final String playerName;
  final String phoneNumber;
  final String paymentMethod;
  final String screenshotUrl;
  final String? note;
  final String status; // 'pending' | 'approved' | 'rejected'
  final DateTime submittedAt;
  final DateTime? reviewedAt;
  final String? hostComment;

  WinnerClaim({
    required this.id,
    required this.roomId,
    required this.playerUid,
    required this.playerName,
    required this.phoneNumber,
    required this.paymentMethod,
    required this.screenshotUrl,
    this.note,
    this.status = 'pending',
    required this.submittedAt,
    this.reviewedAt,
    this.hostComment,
  });

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';

  Map<String, dynamic> toMap() => {
        'roomId': roomId,
        'playerUid': playerUid,
        'playerName': playerName,
        'phoneNumber': phoneNumber,
        'paymentMethod': paymentMethod,
        'screenshotUrl': screenshotUrl,
        'note': note,
        'status': status,
        'submittedAt': Timestamp.fromDate(submittedAt),
        'reviewedAt':
            reviewedAt != null ? Timestamp.fromDate(reviewedAt!) : null,
        'hostComment': hostComment,
      };

  factory WinnerClaim.fromDoc(DocumentSnapshot doc) {
    final rawData = doc.data();
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};

    return WinnerClaim(
      id: doc.id,
      roomId: data['roomId']?.toString() ?? '',
      playerUid: data['playerUid']?.toString() ?? '',
      playerName: data['playerName']?.toString() ?? 'Player',
      phoneNumber: data['phoneNumber']?.toString() ?? '',
      paymentMethod: data['paymentMethod']?.toString() ?? 'bKash',
      screenshotUrl: data['screenshotUrl']?.toString() ?? '',
      note: data['note']?.toString(),
      status: data['status']?.toString() ?? 'pending',
      submittedAt: _parseDateTime(data['submittedAt']),
      reviewedAt: data['reviewedAt'] != null
          ? _parseDateTime(data['reviewedAt'])
          : null,
      hostComment: data['hostComment']?.toString(),
    );
  }

  static WinnerClaim? fromDocSafe(DocumentSnapshot doc) {
    try {
      if (!doc.exists || doc.data() == null) return null;
      return WinnerClaim.fromDoc(doc);
    } catch (_) {
      return null;
    }
  }

  WinnerClaim copyWith({
    String? phoneNumber,
    String? paymentMethod,
    String? screenshotUrl,
    String? note,
    String? status,
    DateTime? reviewedAt,
    String? hostComment,
  }) {
    return WinnerClaim(
      id: id,
      roomId: roomId,
      playerUid: playerUid,
      playerName: playerName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      screenshotUrl: screenshotUrl ?? this.screenshotUrl,
      note: note ?? this.note,
      status: status ?? this.status,
      submittedAt: submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      hostComment: hostComment ?? this.hostComment,
    );
  }
}

