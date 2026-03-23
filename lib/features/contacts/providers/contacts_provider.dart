import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/contact_model.dart';
import '../data/contacts_repository.dart';

// ─── Repository 싱글톤 ────────────────────────────────────────────────────────
final contactsRepositoryProvider = Provider<ContactsRepository>(
  (_) => ContactsRepository(),
);

// ─── 동기화 상태 Notifier ─────────────────────────────────────────────────────

class ContactSyncNotifier extends StateNotifier<ContactSyncResult> {
  final ContactsRepository _repo;

  ContactSyncNotifier(this._repo) : super(ContactSyncResult.idle());

  Future<void> sync() async {
    // 이미 진행 중이면 중복 방지
    if (state.status == ContactSyncStatus.requestingPermission ||
        state.status == ContactSyncStatus.fetchingContacts ||
        state.status == ContactSyncStatus.processing ||
        state.status == ContactSyncStatus.syncing) {
      return;
    }

    await _repo.syncContacts(
      onProgress: (status) {
        state = ContactSyncResult(
          status: status,
          contacts: state.contacts,
          totalContacts: state.totalContacts,
          matchedCount: state.matchedCount,
        );
      },
    ).then((result) => state = result);
  }

  void reset() => state = ContactSyncResult.idle();
}

final contactSyncProvider =
    StateNotifierProvider<ContactSyncNotifier, ContactSyncResult>(
  (ref) => ContactSyncNotifier(ref.read(contactsRepositoryProvider)),
);

// ─── 링톡 친구만 필터링 ──────────────────────────────────────────────────────
final ringTalkFriendsProvider = Provider<List<RingTalkContact>>((ref) {
  final sync = ref.watch(contactSyncProvider);
  return sync.contacts.where((c) => c.isOnRingTalk).toList()
    ..sort((a, b) => a.displayName.compareTo(b.displayName));
});

// ─── 미가입 연락처 ────────────────────────────────────────────────────────────
final nonMemberContactsProvider = Provider<List<RingTalkContact>>((ref) {
  final sync = ref.watch(contactSyncProvider);
  return sync.contacts.where((c) => !c.isOnRingTalk).toList()
    ..sort((a, b) => a.displayName.compareTo(b.displayName));
});
