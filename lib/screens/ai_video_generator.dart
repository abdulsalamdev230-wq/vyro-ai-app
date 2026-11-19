/// VYRO AI â€” AI Video Generator Hub
///
/// Entry point for the three AI video generation modes:
///   Text-to-Video, Image-to-Video, Script-to-Video.


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../widgets/unavailable_state.dart';
import '../../core/providers/ai_provider.dart';

class AIVideoGeneratorScreen extends StatelessWidget {
  const AIVideoGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A101C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('AI Video Generator', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: Consumer<AiJobNotifier>(
        builder: (context, ai, child) {
          if (ai.unavailable) {
            return UnavailableState(
              title: 'AI Video generation unavailable',
              message: ai.unavailableMessage ?? 'No video provider configured.',
              setupHint: 'Add an API key for Runware, Stability AI or fal.ai in the .env file.',
              icon: Icons.videocam_off,
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('Choose a generation mode', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 16),
                _modeCard(
                  context,
                  title: 'Text-to-Video',
                  subtitle: 'Describe a scene and AI creates a video from scratch.',
                  icon: Icons.text_fields,
                  color: const Color(0xFF8855FF),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.textToVideo),
                ),
                const SizedBox(height: 14),
                _modeCard(
                  context,
                  title: 'Image-to-Video',
                  subtitle: 'Upload an image and animate it with AI motion.',
                  icon: Icons.image,
                  color: const Color(0xFF00D5FF),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.imageToVideo),
                ),
                const SizedBox(height: 14),
                _modeCard(
                  context,
                  title: 'Script-to-Video',
                  subtitle: 'Turn a script into a narrated video with AI voice.',
                  icon: Icons.description,
                  color: const Color(0xFFEC4899),
                  onTap: () => Navigator.of(context).pushNamed(AppRoutes.scriptToVideo),
                ),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _modeCard(BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
        ],
      ),
    );
  }
}
