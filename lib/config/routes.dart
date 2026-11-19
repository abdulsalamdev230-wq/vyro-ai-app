/// VYRO AI â€” Navigation Routes


class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String aiVideoGenerator = '/ai-video-generator';
  static const String textToVideo = '/text-to-video';
  static const String imageToVideo = '/image-to-video';
  static const String scriptToVideo = '/script-to-video';
  static const String aiVoiceGenerator = '/ai-voice-generator';
  static const String aiAssistant = '/ai-assistant';
  static const String aiImageGenerator = '/ai-image-generator';
  static const String videoEditor = '/video-editor';
  static const String templatesLibrary = '/templates-library';
  static const String myProjects = '/my-projects';
  static const String videoPreview = '/video-preview';
  static const String export = '/export';
  static const String subscription = '/subscription';
  static const String profile = '/profile';
  static const String adminDashboard = '/admin-dashboard';
  static const String create = '/create';
  static const String aiHistory = '/ai-history';

  /// All named routes for MaterialApp route registration.
  static const List<String> all = [
    splash,
    onboarding,
    auth,
    login,
    register,
    forgotPassword,
    home,
    aiVideoGenerator,
    textToVideo,
    imageToVideo,
    scriptToVideo,
    aiVoiceGenerator,
    aiAssistant,
    aiImageGenerator,
    videoEditor,
    templatesLibrary,
    myProjects,
    videoPreview,
    export,
    subscription,
    profile,
    adminDashboard,
    create,
    aiHistory,
  ];
}
