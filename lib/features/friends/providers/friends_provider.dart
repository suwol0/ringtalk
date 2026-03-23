import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/contact_model.dart';
import '../../contacts/providers/contacts_provider.dart';
import '../data/friends_repository.dart';

const _undefined = Object();

// ─── Repository ─────────────────────────────────────────────────────────────
final friendsRepositoryProvider = Provider<FriendsRepository>(
  (_) => FriendsRepository(),
);

// 친구 목록 상태
enum FriendsLoadStatus { idle, loading, done, error }

class FriendsState {
  final FriendsLoadStatus status;
  final List<RingTalkContact> friends;
  final ContactSyncStatus syncStatus;
  final int totalContacts;
  final int matchedCount;
  final String? errorMessage;

  const FriendsState({
    this.status = FriendsLoadStatus.idle,
    this.friends = const [],
    this.syncStatus = ContactSyncStatus.idle,
    this.totalContacts = 0,
    this.matchedCount = 0,
    this.errorMessage,
  });

  FriendsState copyWith({
    FriendsLoadStatus? status,
    List<RingTalkContact>? friends,
    ContactSyncStatus? syncStatus,
    int? totalContacts,
    int? matchedCount,
    Object? errorMessage = _undefined,
  }) =>
      FriendsState(
        status: status ?? this.status,
        friends: friends ?? this.friends,
        syncStatus: syncStatus ?? this.syncStatus,
        totalContacts: totalContacts ?? this.totalContacts,
        matchedCount: matchedCount ?? this.matchedCount,
        errorMessage: identical(errorMessage, _undefined)
            ? this.errorMessage
            : errorMessage as String?,
      );

  bool get isSyncing =>
      syncStatus == ContactSyncStatus.requestingPermission ||
      syncStatus == ContactSyncStatus.fetchingContacts ||
      syncStatus == ContactSyncStatus.processing ||
      syncStatus == ContactSyncStatus.syncing;

  String get syncStatusLabel {
    switch (syncStatus) {
      case ContactSyncStatus.requestingPermission:
        return '연락처 권한 요청 중...';
      case ContactSyncStatus.fetchingContacts:
        return '연락처 불러오는 중...';
      case ContactSyncStatus.processing:
        return '연락처 분석 중...';
      case ContactSyncStatus.syncing:
        return '링톡 친구 찾는 중...';
      case ContactSyncStatus.done:
        return '$matchedCount명의 링톡 친구를 찾았어요';
      case ContactSyncStatus.permissionDenied:
        return '연락처 권한이 필요합니다';
      case ContactSyncStatus.permissionPermanentlyDenied:
        return '설정에서 연락처 권한을 허용해 주세요';
      case ContactSyncStatus.unsupported:
        return '이 플랫폼은 연락처를 지원하지 않습니다';
      case ContactSyncStatus.error:
        return errorMessage ?? '동기화 중 오류가 발생했습니다';
      default:
        return '';
    }
  }
}

class FriendsNotifier extends StateNotifier<FriendsState> {
  final Ref _ref;

  FriendsNotifier(this._ref) : super(const FriendsState());

  /// 연락처 동기화 (POST /contacts/sync)
  Future<void> syncContacts() async {
    final notifier = _ref.read(contactSyncProvider.notifier);
    await notifier.sync();
  }

  /// 서버에서 친구 목록 조회 (GET /users/me/friends)
  Future<void> fetchFriends() async {
    state = state.copyWith(status: FriendsLoadStatus.loading);
    try {
      final repo = _ref.read(friendsRepositoryProvider);
      final friends = await repo.fetchFriends();
      state = state.copyWith(
        status: FriendsLoadStatus.done,
        friends: friends,
      );
    } catch (e) {
      state = state.copyWith(
        status: FriendsLoadStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  void _onSyncResultChanged(ContactSyncResult result) {
    state = state.copyWith(
      syncStatus: result.status,
      friends: result.contacts.where((c) => c.isOnRingTalk).toList(),
      totalContacts: result.totalContacts,
      matchedCount: result.matchedCount,
      errorMessage: result.errorMessage, // null이면 이전 에러 초기화
    );
  }
}

final friendsProvider = StateNotifierProvider<FriendsNotifier, FriendsState>((ref) {
  final notifier = FriendsNotifier(ref);

  // contactSyncProvider 변경 감지 → 친구 상태 자동 업데이트
  ref.listen(contactSyncProvider, (_, next) {
    notifier._onSyncResultChanged(next);
  });

  return notifier;
});
