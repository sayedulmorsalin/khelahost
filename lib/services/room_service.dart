import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:khelahost/models/tournament_room.dart';
import 'package:khelahost/models/winner_claim.dart';

class RoomService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _collection = 'tournament_rooms';

  // Create a new tournament room
  Future<TournamentRoom> createRoom(TournamentRoom room) async {
    final docRef = await _db.collection(_collection).add(room.toMap());
    final doc = await docRef.get();
    return TournamentRoom.fromDoc(doc);
  }

  // Get room by Firestore document ID
  Future<TournamentRoom?> getRoomById(String docId) async {
    final doc = await _db.collection(_collection).doc(docId).get();
    if (!doc.exists) return null;
    return TournamentRoom.fromDocSafe(doc);
  }

  // Find room by in-game room ID and password
  Future<TournamentRoom?> findRoom(String roomId, String roomPassword) async {
    final query = await _db
        .collection(_collection)
        .where('roomId', isEqualTo: roomId)
        .where('roomPassword', isEqualTo: roomPassword)
        .limit(5)
        .get();

    for (final doc in query.docs) {
      final room = TournamentRoom.fromDocSafe(doc);
      if (room != null && room.status != 'closed') {
        return room;
      }
    }
    return null;
  }

  // Stream real-time updates for a room
  Stream<TournamentRoom?> streamRoom(String docId) {
    return _db.collection(_collection).doc(docId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return TournamentRoom.fromDocSafe(doc);
    });
  }

  // Add a player to a room
  Future<void> joinRoom(String docId, Player player) async {
    await _db.collection(_collection).doc(docId).update({
      'players': FieldValue.arrayUnion([player.toMap()]),
    });
  }

  // Remove a player from a room
  Future<void> removePlayer(String docId, Player player) async {
    await _db.collection(_collection).doc(docId).update({
      'players': FieldValue.arrayRemove([player.toMap()]),
    });
  }

  // Update room status
  Future<void> updateStatus(String docId, String status) async {
    await _db.collection(_collection).doc(docId).update({'status': status});
  }

  // Close/delete a room
  Future<void> closeRoom(String docId) async {
    await _db.collection(_collection).doc(docId).update({'status': 'closed'});
  }

  // Mark room match as completed
  Future<void> completeMatch(String docId) async {
    await _db.collection(_collection).doc(docId).update({'status': 'completed'});
  }

  // Submit or update winner claim
  Future<void> submitWinnerClaim(String docId, WinnerClaim claim) async {
    await _db
        .collection(_collection)
        .doc(docId)
        .collection('claims')
        .doc(claim.playerUid)
        .set(claim.toMap(), SetOptions(merge: true));
  }

  // Stream all winner claims for a room
  Stream<List<WinnerClaim>> streamWinnerClaims(String docId) {
    return _db
        .collection(_collection)
        .doc(docId)
        .collection('claims')
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map(WinnerClaim.fromDocSafe)
          .whereType<WinnerClaim>()
          .toList();
      list.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
      return list;
    });
  }

  // Stream current player's claim for a room
  Stream<WinnerClaim?> streamPlayerClaim(String docId, String playerUid) {
    return _db
        .collection(_collection)
        .doc(docId)
        .collection('claims')
        .doc(playerUid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return null;
      return WinnerClaim.fromDocSafe(doc);
    });
  }

  // Update claim status (e.g. approve/paid, reject)
  Future<void> updateClaimStatus(
    String docId,
    String claimPlayerUid,
    String status, {
    String? hostComment,
  }) async {
    final Map<String, dynamic> updates = {
      'status': status,
      'reviewedAt': Timestamp.now(),
    };
    if (hostComment != null) {
      updates['hostComment'] = hostComment;
    }
    await _db
        .collection(_collection)
        .doc(docId)
        .collection('claims')
        .doc(claimPlayerUid)
        .update(updates);
  }

  // Stream all public active rooms
  Stream<List<TournamentRoom>> streamPublicRooms() {
    return _db.collection(_collection).snapshots().map((snap) {
      final list = snap.docs
          .map(TournamentRoom.fromDocSafe)
          .whereType<TournamentRoom>()
          .where((room) => room.status != 'closed')
          .toList();
      list.sort((a, b) => a.startTime.compareTo(b.startTime));
      return list;
    });
  }

  // Get active rooms hosted by a user
  Stream<List<TournamentRoom>> streamHostRooms(String hostId) {
    return _db
        .collection(_collection)
        .where('hostId', isEqualTo: hostId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map(TournamentRoom.fromDocSafe)
          .whereType<TournamentRoom>()
          .where((room) => room.status != 'closed')
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Get ALL rooms hosted by a user (including closed) for the dashboard
  Stream<List<TournamentRoom>> streamAllHostRooms(String hostId) {
    return _db
        .collection(_collection)
        .where('hostId', isEqualTo: hostId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map(TournamentRoom.fromDocSafe)
          .whereType<TournamentRoom>()
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  // Update in-game room credentials and optional reveal timer
  Future<void> updateCredentials(
    String docId, {
    required String roomId,
    required String roomPassword,
    DateTime? credentialsVisibleAt,
    bool clearTimer = false,
  }) async {
    final Map<String, dynamic> updates = {
      'roomId': roomId.trim(),
      'roomPassword': roomPassword.trim(),
    };
    if (clearTimer || credentialsVisibleAt == null) {
      updates['credentialsVisibleAt'] = null;
    } else {
      updates['credentialsVisibleAt'] =
          Timestamp.fromDate(credentialsVisibleAt);
    }
    await _db.collection(_collection).doc(docId).update(updates);
  }

  // Instantly reveal credentials to all players
  Future<void> revealCredentialsImmediately(String docId) async {
    await _db.collection(_collection).doc(docId).update({
      'credentialsVisibleAt': null,
    });
  }
}
