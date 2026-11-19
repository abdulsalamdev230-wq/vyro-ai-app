/// VYRO AI â€” Environment & App Configuration
///
/// IMPORTANT: API keys and secrets must NEVER be hardcoded in Flutter source.
/// All provider credentials are read from environment variables via flutter_dotenv
/// (.env file, gitignored) or from platform-native secure storage at runtime.
/// When a provider is unavailable, the app shows an honest "unavailable" state
/// instead of faking results.


import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Load environment variables from .env file.
/// Call this once in main() before runApp.
Future<void> loadAppConfig() async {
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    if (kDebugMode) {
      debugPrint('[VYRO AI] Warning: .env file not found or failed to load: $e');
    }
  }
}

class AppConfig {
  AppConfig._();

  // --- App identity ---
  static const String appName = 'VYRO AI';
  static const String packageName = 'com.vyro.ai';
  static const String version = '1.0.0';

  // --- Design tokens ---
  static const Duration animationDuration = Duration(milliseconds: 700);
  static const Duration fastAnimation = Duration(milliseconds: 300);

  // --- Firebase project identifiers live in the getters below (.env driven).
  // They are intentionally NOT API keys — they are project identifiers safe to ship.

  // --- Provider API keys (loaded from .env / environment at runtime) ---
  // Never commit real keys. Use .env.example as a template.
  static String get openAIApiKey => dotenv.env['OPENAI_API_KEY'] ?? '';
  static String get runwareApiKey => dotenv.env['RUNWARE_API_KEY'] ?? '';
  static String get stabilityApiKey => dotenv.env['STABILITY_API_KEY'] ?? '';
  static String get falApiKey => dotenv.env['FAL_API_KEY'] ?? '';
  static String get elevenlabsApiKey => dotenv.env['ELEVENLABS_API_KEY'] ?? '';
  static String get googleTtsApiKey => dotenv.env['GOOGLE_TTS_API_KEY'] ?? '';
  static String get assemblyAiApiKey => dotenv.env['ASSEMBLY_AI_API_KEY'] ?? '';

  // --- Social Auth credentials (loaded from .env / environment at runtime) ---
  // Google: webClientId from Google Cloud Console (OAuth 2.0 Client ID)
  //         Android/iOS: configure via google-services.json / GoogleService-Info.plist
  static String get googleWebClientId => dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';

  // Facebook: App ID from Meta for Developers
  static String get facebookAppId => dotenv.env['FACEBOOK_APP_ID'] ?? '';

  // Apple: Services ID from Apple Developer (Sign in with Apple)
  static String get appleServicesId => dotenv.env['APPLE_SERVICES_ID'] ?? '';

  // --- Firebase web app config (.env driven) ---
  // Leave empty to use the built-in fallback project (vyro-ai-7dce3).
  // Fill these in to point the app at a different Firebase project —
  // e.g. ecommerence-1e7da — without touching any Dart code.
  static String get firebaseApiKey => dotenv.env['FIREBASE_API_KEY'] ?? '';
  static String get firebaseAppId => dotenv.env['FIREBASE_APP_ID'] ?? '';
  static String get firebaseProjectId => dotenv.env['FIREBASE_PROJECT_ID'] ?? '';
  static String get firebaseAuthDomain => dotenv.env['FIREBASE_AUTH_DOMAIN'] ?? '';
  static String get firebaseStorageBucket =>
      dotenv.env['FIREBASE_STORAGE_BUCKET'] ?? '';
  static String get firebaseMessagingSenderId =>
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'] ?? '';

  // --- VYRO Cloudflare Worker (AI image generation) ---
  // Public endpoint, not a secret. Override with VYRO_WORKER_URL in .env.
  static String get vyroWorkerUrl =>
      dotenv.env['VYRO_WORKER_URL'] ??
      'https://vyro-ai-api.abdulsalam-dev230.workers.dev';

  // --- Backend REST API base URL ---
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000/api';

  // --- AdMob unit IDs (test IDs by default; replace with real IDs for release) ---
  static String get admobAppId {
    if (kReleaseMode) {
      return dotenv.env['ADMOB_APP_ID'] ?? 'ca-app-pub-3940256099942544~3347511713';
    }
    return 'ca-app-pub-3940256099942544~3347511713'; // test app id
  }

  static String get admobBannerUnitId {
    if (kReleaseMode) {
      return dotenv.env['ADMOB_BANNER_UNIT_ID'] ?? '';
    }
    return 'ca-app-pub-3940256099942544/6300978111'; // test banner
  }

  static String get admobInterstitialUnitId {
    if (kReleaseMode) {
      return dotenv.env['ADMOB_INTERSTITIAL_UNIT_ID'] ?? '';
    }
    return 'ca-app-pub-3940256099942544/1033173712'; // test interstitial
  }

  static String get admobRewardedUnitId {
    if (kReleaseMode) {
      return dotenv.env['ADMOB_REWARDED_UNIT_ID'] ?? '';
    }
    return 'ca-app-pub-3940256099942544/5224354917'; // test rewarded
  }

  // --- In-app purchase product IDs (configure in App Store / Play Console) ---
  static const List<String> subscriptionProductIds = [
    'vyro_ai_monthly',
    'vyro_ai_yearly',
    'vyro_ai_credits_pack_10',
    'vyro_ai_credits_pack_50',
  ];

  // --- Feature flags ---
  static bool get isAiImageEnabled => openAIApiKey.isNotEmpty ||
      runwareApiKey.isNotEmpty ||
      stabilityApiKey.isNotEmpty ||
      falApiKey.isNotEmpty;

  static bool get isAiVideoEnabled =>
      runwareApiKey.isNotEmpty || stabilityApiKey.isNotEmpty || falApiKey.isNotEmpty;

  static bool get isTtsEnabled =>
      elevenlabsApiKey.isNotEmpty || googleTtsApiKey.isNotEmpty;

  static bool get isFirebaseConfigured {
    // firebase_options.dart is generated by flutterfire_cli; check its presence.
    return const bool.fromEnvironment('FIREBASE_CONFIGURED', defaultValue: false);
  }

  /// Whether Google Sign-In is configured (web client ID present).
  static bool get isGoogleAuthConfigured => googleWebClientId.isNotEmpty;

  /// Whether Facebook Login is configured (App ID present).
  static bool get isFacebookAuthConfigured => facebookAppId.isNotEmpty;

  /// Whether Sign in with Apple is configured (Services ID present).
  static bool get isAppleAuthConfigured => appleServicesId.isNotEmpty;

  /// Returns a human-readable summary of which providers are configured.
  /// Used to render honest "unavailable" states in the UI.
  static Map<String, bool> providerAvailability() {
    return {
      'AI Image': isAiImageEnabled,
      'AI Video': isAiVideoEnabled,
      'Text-to-Speech': isTtsEnabled,
      'Firebase Auth': isFirebaseConfigured,
      'Google Sign-In': isGoogleAuthConfigured,
      'Facebook Login': isFacebookAuthConfigured,
      'Sign in with Apple': isAppleAuthConfigured,
    };
  }
}

/// Environment flavor. Use `dart run --dart-define=FLAVOR=development` etc.
enum AppFlavor { development, staging, production }

class Environment {
  Environment._();
  static AppFlavor flavor = AppFlavor.development;
}
