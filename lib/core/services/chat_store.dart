/// VYRO AI — Chat persistence for the AI Assistant.
///
/// Stores the current conversation in Firestore under the signed-in user's
/// own document (`users/{uid}/aiChats/latest`) so the assistant remembers
/// the conversation across app restarts and navigation. Only the user's
/// private document is read/written. Image attachment bytes are intentionally
/// NOT persisted (only the filename note survives).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chat_service.dart';

class ChatStore {
  ChatStore._();

  static DocumentReference<Map<String, dynamic>>? _doc() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('aiChats')
        .doc('latest');
  }

  /// Saves the conversation (excluding UI-only error turns and the synthetic
  /// welcome message is kept so restoring feels identical). Capped at 60
  /// turns to keep the document small.
  static Future<void> save(List<ChatTurn> messages) async {
    final doc = _doc();
    if (doc == null) return;
    final keep = messages
        .where((m) => !m.isError && m.content.trim().isNotEmpty)
        .toList()
        .sublist(messages.length > 60 ? messages.length - 60 : 0);
    final data = keep
        .map((m) => {
              'role': m.role,
              'content': m.content,
              'createdAt': m.createdAt.millisecondsSinceEpoch,
            })
        .toList();
    try {
      await doc.set({
        'messages': data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Persistence is best-effort — chat still works without Firestore.
    }
  }

  /// Loads the persisted conversation. Returns an empty list when there is
  /// nothing saved (fresh chat) or Firestore is unavailable.
  static Future<List<ChatTurn>> load() async {
    final doc = _doc();
    if (doc == null) return [];
    try {
      final snap = await doc.get();
      final raw = snap.data()?['messages'];
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((m) {
            final role = m['role']?.toString() ?? 'assistant';
            final content = m['content']?.toString() ?? '';
            final ts = m['createdAt'];
            return ChatTurn(
              role: role == 'user' ? 'user' : 'assistant',
              content: content,
              createdAt: ts is int
                  ? DateTime.fromMillisecondsSinceEpoch(ts)
                  : null,
            );
          })
          .where((t) => t.content.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> clear() async {
    final doc = _doc();
    if (doc == null) return;
    try {
      await doc.delete();
    } catch (_) {
      // best-effort
    }
  }
}
