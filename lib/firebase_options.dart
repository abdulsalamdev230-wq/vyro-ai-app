/// VYRO AI — Firebase Options
///
/// The active Firebase project is driven by `.env` (loaded in main.dart before
/// Firebase init, so values are available at first access):
///
///   FIREBASE_API_KEY, FIREBASE_APP_ID, FIREBASE_PROJECT_ID,
///   FIREBASE_AUTH_DOMAIN, FIREBASE_STORAGE_BUCKET,
///   FIREBASE_MESSAGING_SENDER_ID
///
/// When those keys are empty the built-in fallback project below is used, so
/// the app keeps working out of the box. To switch projects (e.g. to
/// ecommerence-1e7da) only the `.env` file needs editing — no Dart changes.
///
/// These values are public Firebase project identifiers (not secret keys);
/// the real secrets (AI provider keys) stay in `.env` and are never hardcoded.

import 'package:firebase_core/firebase_core.dart';
import 'config/app_config.dart';

class DefaultFirebaseOptions {
  /// Fallback project: the original VYRO AI Firebase project.
  static const _fallback = FirebaseOptions(
    apiKey: 'AIzaSyBbjFjPJIAwEOSdJOhsCjgikEYy34G5U90',
    appId: '1:691377591215:web:843610d270ffa89c24d55a',
    messagingSenderId: '691377591215',
    projectId: 'vyro-ai-7dce3',
    storageBucket: 'vyro-ai-7dce3.firebasestorage.app',
    authDomain: 'vyro-ai-7dce3.firebaseapp.com',
    measurementId: '',
  );

  static FirebaseOptions get currentPlatform {
    final apiKey = AppConfig.firebaseApiKey;
    final appId = AppConfig.firebaseAppId;
    final projectId = AppConfig.firebaseProjectId;

    // Nothing configured in .env → use the fallback project untouched.
    if (apiKey.isEmpty || appId.isEmpty || projectId.isEmpty) {
      return _fallback;
    }

    final authDomain = AppConfig.firebaseAuthDomain;
    final bucket = AppConfig.firebaseStorageBucket;
    return FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: AppConfig.firebaseMessagingSenderId,
      projectId: projectId,
      storageBucket: bucket.isNotEmpty
          ? bucket
          : '$projectId.firebasestorage.app',
      authDomain: authDomain.isNotEmpty ? authDomain : '$projectId.firebaseapp.com',
      measurementId: '',
    );
  }

  /// True when the app is running against a project configured via `.env`.
  static bool get isEnvDriven => AppConfig.firebaseProjectId.isNotEmpty;
}
