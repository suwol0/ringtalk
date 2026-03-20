// 유저 관련 Dart 모델

enum UserStatus { active, inactive, blocked, withdrawn }

enum Presence { online, offline, away }

enum FriendStatus { pending, accepted, blocked }

class User {
  final String id;
  final String displayName;
  final String? profileImageUrl;
  final String? statusMessage;
  final UserStatus status;
  final Presence presence;
  final DateTime? lastSeenAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const User({
    required this.id,
    required this.displayName,
    this.profileImageUrl,
    this.statusMessage,
    required this.status,
    required this.presence,
    this.lastSeenAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        profileImageUrl: json['profileImageUrl'] as String?,
        statusMessage: json['statusMessage'] as String?,
        status: UserStatus.values.byName(json['status'] as String? ?? 'active'),
        presence: Presence.values.byName(json['presence'] as String? ?? 'offline'),
        lastSeenAt: json['lastSeenAt'] != null
            ? DateTime.parse(json['lastSeenAt'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'displayName': displayName,
        if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
        if (statusMessage != null) 'statusMessage': statusMessage,
        'status': status.name,
        'presence': presence.name,
        if (lastSeenAt != null) 'lastSeenAt': lastSeenAt!.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  User copyWith({
    String? displayName,
    String? profileImageUrl,
    String? statusMessage,
    Presence? presence,
    DateTime? lastSeenAt,
  }) =>
      User(
        id: id,
        displayName: displayName ?? this.displayName,
        profileImageUrl: profileImageUrl ?? this.profileImageUrl,
        statusMessage: statusMessage ?? this.statusMessage,
        status: status,
        presence: presence ?? this.presence,
        lastSeenAt: lastSeenAt ?? this.lastSeenAt,
        createdAt: createdAt,
        updatedAt: DateTime.now(),
      );
}

class UserPublicProfile {
  final String id;
  final String displayName;
  final String? profileImageUrl;
  final String? statusMessage;
  final Presence presence;
  final DateTime? lastSeenAt;

  /// 서버가 연락처 매칭 응답 시 함께 반환하는 phoneHash
  /// (일반 프로필 조회에서는 null)
  final String? phoneHash;

  const UserPublicProfile({
    required this.id,
    required this.displayName,
    this.profileImageUrl,
    this.statusMessage,
    required this.presence,
    this.lastSeenAt,
    this.phoneHash,
  });

  factory UserPublicProfile.fromJson(Map<String, dynamic> json) =>
      UserPublicProfile(
        id: json['id'] as String,
        displayName: json['displayName'] as String,
        profileImageUrl: json['profileImageUrl'] as String?,
        statusMessage: json['statusMessage'] as String?,
        presence: Presence.values.byName(json['presence'] as String? ?? 'offline'),
        lastSeenAt: json['lastSeenAt'] != null
            ? DateTime.parse(json['lastSeenAt'] as String)
            : null,
        phoneHash: json['phoneHash'] as String?,
      );
}

class Friend {
  final String id;
  final String userId;
  final String friendId;
  final FriendStatus status;
  final String? alias;
  final DateTime createdAt;
  final UserPublicProfile friend;

  const Friend({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    this.alias,
    required this.createdAt,
    required this.friend,
  });

  factory Friend.fromJson(Map<String, dynamic> json) => Friend(
        id: json['id'] as String,
        userId: json['userId'] as String,
        friendId: json['friendId'] as String,
        status: FriendStatus.values.byName(json['status'] as String),
        alias: json['alias'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        friend: UserPublicProfile.fromJson(json['friend'] as Map<String, dynamic>),
      );

  String get displayName => alias ?? friend.displayName;
}

class UpdateProfileRequest {
  final String? displayName;
  final String? statusMessage;

  const UpdateProfileRequest({this.displayName, this.statusMessage});

  Map<String, dynamic> toJson() => {
        if (displayName != null) 'displayName': displayName,
        if (statusMessage != null) 'statusMessage': statusMessage,
      };
}
