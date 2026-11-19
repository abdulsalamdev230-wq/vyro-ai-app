/// VYRO AI â€” Application Entry Point


import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/app_config.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'core/providers/auth_provider.dart';
import 'core/providers/video_provider.dart';
import 'core/providers/ai_provider.dart';
import 'core/providers/subscription_provider.dart';
import 'core/providers/theme_provider.dart';
import 'core/services/admob_service.dart';
import 'core/services/iap_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/home_dashboard.dart';
import 'screens/ai_video_generator.dart';
import 'screens/text_to_video.dart';
import 'screens/image_to_video.dart';
import 'screens/script_to_video.dart';
import 'screens/ai_voice_generator.dart';
import 'screens/ai_assistant.dart';
import 'screens/ai_image_generator.dart';
import 'screens/create_hub_screen.dart';
import 'screens/ai_history_screen.dart';
import 'screens/video_editor.dart';
import 'screens/templates_library.dart';
import 'screens/my_projects.dart';
import 'screens/video_preview.dart';
import 'screens/export_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/user_profile.dart';
import 'screens/admin_dashboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment config (.env) before anything else.
  await loadAppConfig();

  // Initialize Firebase (restores the persisted auth session so returning
  // users land straight on the dashboard — no forced re-login).
  await AuthProvider.instance.initialize();

  // AdMob and In-App Purchases initialize in the background: they are not
  // needed for the first frame and both fail gracefully when unavailable.
  unawaited(AdMobService.instance.initialize());
  unawaited(IapService.instance.initialize());

  runApp(const VyroAIApp());
}

class VyroAIApp extends StatelessWidget {
  const VyroAIApp({super.key});

  /// Routes that require an authenticated session.
  static const _protectedRoutes = <String>{
    AppRoutes.home,
    AppRoutes.aiVideoGenerator,
    AppRoutes.textToVideo,
    AppRoutes.imageToVideo,
    AppRoutes.scriptToVideo,
    AppRoutes.aiVoiceGenerator,
    AppRoutes.aiAssistant,
    AppRoutes.aiImageGenerator,
    AppRoutes.videoEditor,
    AppRoutes.templatesLibrary,
    AppRoutes.myProjects,
    AppRoutes.videoPreview,
    AppRoutes.export,
    AppRoutes.subscription,
    AppRoutes.profile,
    AppRoutes.adminDashboard,
  };

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider.instance),
        ChangeNotifierProvider(create: (_) => VideoProvider.instance),
        ChangeNotifierProvider(create: (_) => AiJobNotifier.instance),
        ChangeNotifierProvider(create: (_) => SubscriptionProvider.instance),
        ChangeNotifierProvider(create: (_) => ThemeProvider.instance),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'VYRO AI',
            debugShowCheckedModeBanner: false,
            theme: vyroTheme(context),
            darkTheme: vyroTheme(context),
            themeMode: ThemeMode.dark,
            initialRoute: AppRoutes.splash,
            onGenerateRoute: (settings) {
              // Route guard: unauthenticated users cannot reach protected
              // app screens — they are bounced to the login page instead.
              if (_protectedRoutes.contains(settings.name) &&
                  !AuthProvider.instance.isSignedIn) {
                return MaterialPageRoute(
                  builder: (_) => const LoginScreen(),
                  settings: settings,
                );
              }
              return _buildRoute(settings);
            },
            builder: (context, child) {
              // Ensure AdMob is initialized before ads load.
              return child!;
            },
          );
        },
      ),
    );
  }

  Route<dynamic> _buildRoute(RouteSettings settings) {
    final name = settings.name;

    Widget screen;
    switch (name) {
      case AppRoutes.splash:
        screen = const SplashScreen();
        break;
      case AppRoutes.onboarding:
        screen = const OnboardingScreen();
        break;
      case AppRoutes.auth:
      case AppRoutes.login:
        screen = const LoginScreen();
        break;
      case AppRoutes.register:
        screen = const RegisterScreen();
        break;
      case AppRoutes.forgotPassword:
        screen = const ForgotPasswordScreen();
        break;
      case AppRoutes.home:
        screen = const HomeDashboard();
        break;
      case AppRoutes.aiVideoGenerator:
        screen = const AIVideoGeneratorScreen();
        break;
      case AppRoutes.textToVideo:
        screen = const TextToVideoScreen();
        break;
      case AppRoutes.imageToVideo:
        screen = const ImageToVideoScreen();
        break;
      case AppRoutes.scriptToVideo:
        screen = const ScriptToVideoScreen();
        break;
      case AppRoutes.aiVoiceGenerator:
        screen = const AIVoiceGeneratorScreen();
        break;
      case AppRoutes.aiImageGenerator:
        screen = const AIImageGeneratorScreen();
        break;
      case AppRoutes.aiAssistant:
        screen = const AiAssistantScreen();
        break;
      case AppRoutes.videoEditor:
        screen = const VideoEditorScreen();
        break;
      case AppRoutes.templatesLibrary:
        screen = const TemplatesLibraryScreen();
        break;
      case AppRoutes.myProjects:
        screen = const MyProjectsScreen();
        break;
      case AppRoutes.videoPreview:
        screen = const VideoPreviewScreen();
        break;
      case AppRoutes.export:
        screen = const ExportScreen();
        break;
      case AppRoutes.subscription:
        screen = const SubscriptionScreen();
        break;
      case AppRoutes.profile:
        screen = const UserProfileScreen();
        break;
      case AppRoutes.adminDashboard:
        screen = const AdminDashboardScreen();
        break;
      case AppRoutes.create:
        screen = const CreateHub();
        break;
      case AppRoutes.aiHistory:
        screen = const AiHistoryScreen();
        break;
      default:
        screen = const SplashScreen();
    }

    return MaterialPageRoute(builder: (_) => screen, settings: settings);
  }
}
