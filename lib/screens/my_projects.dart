/// VYRO AI â€” My Projects Screen


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../widgets/unavailable_state.dart';
import '../../core/providers/video_provider.dart';
import '../../models/user_model.dart';

class MyProjectsScreen extends StatefulWidget {
  const MyProjectsScreen({super.key});

  @override
  State<MyProjectsScreen> createState() => _MyProjectsScreenState();
}

class _MyProjectsScreenState extends State<MyProjectsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VideoProvider>().initialize();
    });
  }

  Future<void> _createProject() async {
    final ctrl = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF17243B),
        title: const Text('New Project', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(hintText: 'Project name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    final id = await context.read<VideoProvider>().createProject(name);
    if (id != null && mounted) {
      Navigator.of(context).pushNamed(AppRoutes.videoEditor, arguments: {'projectId': id});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoProvider>(
      builder: (context, vp, child) {
        if (vp.isLoading) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final projects = vp.projects;
        return Scaffold(
          backgroundColor: const Color(0xFF0A101C),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('My Projects', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800)),
            centerTitle: true,
          ),
          body: projects.isEmpty
              ? UnavailableState(
                  title: 'No projects yet',
                  message: 'Create your first project or generate a video to get started.',
                  icon: Icons.folder_outlined,
                  onConfigure: _createProject,
                )
              : ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    ...projects.map((p) => _projectTile(context, p)),
                    const SizedBox(height: 30),
                  ],
                ),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: const Color(0xFF8855FF),
            onPressed: _createProject,
            icon: const Icon(Icons.add),
            label: const Text('New Project'),
          ),
        );
      },
    );
  }

  Widget _projectTile(BuildContext context, ProjectModel p) {
    return GlassCard(
      child: ListTile(
        leading: Container(
          width: 56, height: 56,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF8855FF), Color(0xFF00D5FF)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.videocam, color: Colors.white),
        ),
        title: Text(p.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        subtitle: Text('${(p.progress * 100).toInt()}% complete â€¢ ${_ago(p.lastEdited)}',
            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF8855FF)),
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.videoEditor, arguments: {'projectId': p.id}),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Color(0xFFEF4444)),
              onPressed: () async {
                await context.read<VideoProvider>().deleteVideo(p.id);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _ago(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }
}

