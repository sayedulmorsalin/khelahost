import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _parseDateTime(dynamic val) {
  if (val is Timestamp) return val.toDate();
  if (val is DateTime) return val;
  if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
  if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
  return DateTime.now();
}

int _parseInt(dynamic val, int fallback) {
  if (val is int) return val;
  if (val is num) return val.toInt();
  if (val is String) return int.tryParse(val) ?? fallback;
  return fallback;
}

class Player {
  final String uid;
  final String name;
  final DateTime joinedAt;

  Player({required this.uid, required this.name, required this.joinedAt});

  Map<String, dynamic> toMap() => {
        'uid': uid,
        'name': name,
        'joinedAt': Timestamp.fromDate(joinedAt),
      };

  factory Player.fromMap(Map<dynamic, dynamic> map) => Player(
        uid: map['uid']?.toString() ?? '',
        name: map['name']?.toString() ?? 'Unknown',
        joinedAt: _parseDateTime(map['joinedAt']),
      );
}

class TournamentRoom {
  final String id;
  final String name;
  final String game;
  final String roomId;
  final String roomPassword;
  final int maxPlayers;
  final String? prizePool;
  final String? rules;
  final DateTime startTime;
  final DateTime createdAt;
  final String hostId;
  final List<Player> players;
  final String status; // 'waiting' | 'started' | 'closed'
  final DateTime? credentialsVisibleAt;

  TournamentRoom({
    required this.id,
    required this.name,
    required this.game,
    required this.roomId,
    required this.roomPassword,
    required this.maxPlayers,
    this.prizePool,
    this.rules,
    required this.startTime,
    required this.createdAt,
    required this.hostId,
    required this.players,
    required this.status,
    this.credentialsVisibleAt,
  });

  bool get hasCredentials =>
      roomId.trim().isNotEmpty || roomPassword.trim().isNotEmpty;

  bool get areCredentialsRevealed =>
      credentialsVisibleAt == null ||
      !DateTime.now().isBefore(credentialsVisibleAt!);

  bool get isWaiting => status == 'waiting';
  bool get isStarted => status == 'started';
  bool get isCompleted => status == 'completed';
  bool get isClosed => status == 'closed';

  Map<String, dynamic> toMap() => {
        'name': name,
        'game': game,
        'roomId': roomId,
        'roomPassword': roomPassword,
        'maxPlayers': maxPlayers,
        'prizePool': prizePool,
        'rules': rules,
        'startTime': Timestamp.fromDate(startTime),
        'createdAt': Timestamp.fromDate(createdAt),
        'hostId': hostId,
        'players': players.map((p) => p.toMap()).toList(),
        'status': status,
        'credentialsVisibleAt': credentialsVisibleAt != null
            ? Timestamp.fromDate(credentialsVisibleAt!)
            : null,
      };

  factory TournamentRoom.fromDoc(DocumentSnapshot doc) {
    final rawData = doc.data();
    final data = rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : <String, dynamic>{};

    return TournamentRoom(
      id: doc.id,
      name: data['name']?.toString() ?? '',
      game: data['game']?.toString() ?? '',
      roomId: data['roomId']?.toString() ?? '',
      roomPassword: data['roomPassword']?.toString() ?? '',
      maxPlayers: _parseInt(data['maxPlayers'], 100),
      prizePool: data['prizePool']?.toString(),
      rules: data['rules']?.toString(),
      startTime: _parseDateTime(data['startTime']),
      createdAt: _parseDateTime(data['createdAt']),
      hostId: data['hostId']?.toString() ?? '',
      players: (data['players'] as List<dynamic>? ?? [])
          .map((p) => p is Map ? Player.fromMap(p) : null)
          .whereType<Player>()
          .toList(),
      status: data['status']?.toString() ?? 'waiting',
      credentialsVisibleAt: data['credentialsVisibleAt'] != null
          ? _parseDateTime(data['credentialsVisibleAt'])
          : null,
    );
  }

  static TournamentRoom? fromDocSafe(DocumentSnapshot doc) {
    try {
      if (!doc.exists || doc.data() == null) return null;
      return TournamentRoom.fromDoc(doc);
    } catch (_) {
      return null;
    }
  }

  TournamentRoom copyWith({
    String? status,
    List<Player>? players,
    String? roomId,
    String? roomPassword,
    int? maxPlayers,
    DateTime? credentialsVisibleAt,
    bool clearCredentialsTimer = false,
  }) =>
      TournamentRoom(
        id: id,
        name: name,
        game: game,
        roomId: roomId ?? this.roomId,
        roomPassword: roomPassword ?? this.roomPassword,
        maxPlayers: maxPlayers ?? this.maxPlayers,
        prizePool: prizePool,
        rules: rules,
        startTime: startTime,
        createdAt: createdAt,
        hostId: hostId,
        players: players ?? this.players,
        status: status ?? this.status,
        credentialsVisibleAt: clearCredentialsTimer
            ? null
            : (credentialsVisibleAt ?? this.credentialsVisibleAt),
      );
}
