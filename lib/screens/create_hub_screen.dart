/// VYRO AI — Create Hub
///
/// The "Create" tab of the bottom navigation: every AI generation tool in one
/// premium grid — Image, Video (text/image/script), Voice, plus the advanced
/// studio tools (Video Editor, Templates, My Projects).

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../widgets/unavailable_state.dart';
import '../../core/animations/dashboard_animations.dart';

class CreateHub extends StatelessWidget {
  const CreateHub({super.key});

  @override
  Widget build(BuildContext context) {
    void go(String route) => Navigator.of(context).pushNamed(route);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
        children: [
          const SectionHeader(
            title: 'Create',
            subtitle: 'Generate with AI — image, video and voice',
          ),
          const SizedBox(height: 16),
          _toolCard(
            context,
            title: 'AI Image Generator',
            subtitle: 'Text prompts → stunning AI artwork',
            icon: Icons.image_outlined,
            gradient: const [Color(0xFF00D5FF), Color(0xFF0EA5E9)],
            onTap: () => go(AppRoutes.aiImageGenerator),
          ),
          const SizedBox(height: 14),
          _toolCard(
            context,
            title: 'AI Video Generator',
            subtitle: 'Text, image or script → video',
            icon: Icons.movie_creation_outlined,
            gradient: const [Color(0xFF8855FF), Color(0xFF6D3AFF)],
            onTap: () => go(AppRoutes.aiVideoGenerator),
          ),
          const SizedBox(height: 14),
          _toolCard(
            context,
            title: 'AI Voice Generator',
            subtitle: 'Realistic AI voice-overs from text',
            icon: Icons.mic_none_outlined,
            gradient: const [Color(0xFFEC4899), Color(0xFFBE185D)],
            onTap: () => go(AppRoutes.aiVoiceGenerator),
          ),
          const SizedBox(height: 26),
          const SectionHeader(
            title: 'Video Studio',
            subtitle: 'Advanced editing tools',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _miniTool(
                  context,
                  label: 'Editor',
                  icon: Icons.edit_outlined,
                  color: const Color(0xFF10B981),
                  onTap: () => go(AppRoutes.videoEditor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniTool(
                  context,
                  label: 'Templates',
                  icon: Icons.dashboard_outlined,
                  color: const Color(0xFFF59E0B),
                  onTap: () => go(AppRoutes.templatesLibrary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _miniTool(
                  context,
                  label: 'Text-to-Video',
                  icon: Icons.text_fields,
                  color: const Color(0xFF8855FF),
                  onTap: () => go(AppRoutes.textToVideo),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniTool(
                  context,
                  label: 'Image-to-Video',
                  icon: Icons.photo_library_outlined,
                  color: const Color(0xFF00D5FF),
                  onTap: () => go(AppRoutes.imageToVideo),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _miniTool(
                  context,
                  label: 'Script-to-Video',
                  icon: Icons.subject_outlined,
                  color: const Color(0xFFEC4899),
                  onTap: () => go(AppRoutes.scriptToVideo),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _miniTool(
                  context,
                  label: 'My Projects',
                  icon: Icons.folder_outlined,
                  color: const Color(0xFF10B981),
                  onTap: () => go(AppRoutes.myProjects),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          const UnavailableState(
            title: 'More tools coming soon',
            message: 'AI avatars, lip-sync and auto-captions are on the way.',
            icon: Icons.auto_awesome_outlined,
          ),
        ],
      ),
    );
  }

  Widget _toolCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradient,
    required VoidCallback onTap,
  }) {
    return CardEntrance(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF17243B),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
              boxShadow: [
                BoxShadow(
                  color: gradient.first.withValues(alpha: 0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          fontFamily: 'Inter',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFF94A3B8),
                          fontSize: 12.5,
                          fontFamily: 'Inter',
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Color(0xFF64748B)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _miniTool(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF101B35),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    fontFamily: 'Inter',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
