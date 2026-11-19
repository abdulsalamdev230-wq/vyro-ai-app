// VYRO AI — Model unit tests (round-trip Firestore maps + defaults)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vyro_ai/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('fromMap applies defaults for empty map', () {
      final u = UserModel.fromMap({}, 'u1');
      expect(u.id, 'u1');
      expect(u.email, '');
      expect(u.authProvider, 'email');
      expect(u.tier, SubscriptionTier.free);
      expect(u.credits, 0);
      expect(u.createdAt, isA<DateTime>());
    });

    test('round-trip toMap/fromMap preserves fields', () {
      final created = DateTime(2026, 1, 1, 12);
      final user = UserModel(
        id: 'u2',
        email: 'test@vyro.ai',
        fullName: 'Vyro Dev',
        authProvider: 'email',
        tier: SubscriptionTier.pro,
        credits: 42,
        createdAt: created,
      );
      final map = user.toMap();
      map['createdAt'] = Timestamp.fromDate(created);
      final parsed = UserModel.fromMap(map, 'u2');
      expect(parsed.email, 'test@vyro.ai');
      expect(parsed.fullName, 'Vyro Dev');
      expect(parsed.tier, SubscriptionTier.pro);
      expect(parsed.credits, 42);
      expect(parsed.createdAt, created);
    });

    test('unknown tier falls back to free', () {
      final u = UserModel.fromMap({'tier': 'solana-unlimited'}, 'u3');
      expect(u.tier, SubscriptionTier.free);
    });
  });

  group('VideoModel', () {
    test('round-trip preserves generation type and dimensions', () {
      final v = VideoModel(
        id: 'v1',
        userId: 'u1',
        title: 'Neon Reel',
        type: AiGenerationType.scriptToVideo,
        durationSeconds: 12,
        width: 720,
        height: 1280,
        fileSizeMb: 4.5,
        tags: ['neon', 'city'],
        isExported: true,
        createdAt: DateTime(2026, 2, 2),
      );
      final map = v.toMap();
      map['createdAt'] = Timestamp.fromDate(DateTime(2026, 2, 2));
      final parsed = VideoModel.fromMap(map, 'v1');
      expect(parsed.type, AiGenerationType.scriptToVideo);
      expect(parsed.width, 720);
      expect(parsed.height, 1280);
      expect(parsed.fileSizeMb, 4.5);
      expect(parsed.tags, ['neon', 'city']);
      expect(parsed.isExported, true);
    });

    test('unknown type falls back to textToVideo', () {
      final v = VideoModel.fromMap({'type': 'hyperdrive'}, 'v2');
      expect(v.type, AiGenerationType.textToVideo);
      expect(v.title, 'Untitled');
    });
  });
}
