/// VYRO AI â€” Video Editor Screen


import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/animations/editor_animations.dart';
import '../../core/animations/button_animations.dart';
import '../../models/user_model.dart';

class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key});

  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  final List<TimelineClip> _clips = [];
  double _duration = 30;
  double _playhead = 0;
  VideoPlayerController? _controller;
  String? _projectId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _seedDemoClip();
  }

  void _seedDemoClip() {
    setState(() {
      _clips.add(TimelineClip(id: 'c1', title: 'Clip 1', start: 0, duration: 8));
      _clips.add(TimelineClip(id: 'c2', title: 'Clip 2', start: 8, duration: 7));
      _clips.add(TimelineClip(id: 'c3', title: 'Clip 3', start: 15, duration: 10));
      _duration = 33;
    });
  }

  Future<void> _addClip() async {
    final picker = ImagePicker();
    final file = await picker.pickVideo(source: ImageSource.gallery);
    if (file == null) return;
    setState(() {
      _clips.add(TimelineClip(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: file.name,
        start: _duration,
        duration: 5,
      ));
      _duration += 5;
    });
  }

  Future<void> _mergeExport() async {
    if (_clips.isEmpty) return;
    setState(() => _saving = true);
    // In a real app we'd have actual local video paths per clip. Here we
    // demonstrate the FFmpeg merge path with a notice.
    setState(() => _saving = false);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Export would run FFmpeg merge on the timeline clips.'),
      backgroundColor: Color(0xFF8855FF),
    ));
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    final projectId = args?['projectId'] as String?;
    final template = args?['template'] as TemplateModel?;
    if (_projectId == null && projectId != null) _projectId = projectId;

    return Scaffold(
      backgroundColor: const Color(0xFF0A101C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(template != null ? 'Edit: ${template.title}' : 'Video Editor', style: const TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800)),
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => Navigator.pop(context)),
        actions: [
          IconButton(icon: const Icon(Icons.add_circle, color: Color(0xFF8855FF)), onPressed: _addClip),
        ],
      ),
      body: Column(
        children: [
          // Preview
          Expanded(
            flex: 2,
            child: Container(
              color: const Color(0xFF0A101C),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.videocam, color: Color(0xFF64748B), size: 48),
                    SizedBox(height: 10),
                    Text('Preview', style: TextStyle(color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
            ),
          ),
          // Timeline
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Timeline', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                      Text('${_duration.toInt()}s', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AnimatedTimeline(
                    clips: _clips,
                    durationSeconds: _duration,
                    width: 360,
                    onPlayheadChanged: (v) => setState(() => _playhead = v),
                    onClipMoved: (c) {
                      setState(() {
                        final idx = _clips.indexWhere((x) => x.id == c.id);
                        if (idx != -1) _clips[idx] = c;
                      });
                    },
                    playheadPosition: _playhead,
                  ),
                  const SizedBox(height: 16),
                  // Transition chips
                  SizedBox(
                    height: 56,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        TransitionPreview(name: 'Fade', icon: Icons.opacity, selected: false, onTap: () {}),
                        TransitionPreview(name: 'Slide', icon: Icons.arrow_right, selected: false, onTap: () {}),
                        TransitionPreview(name: 'Zoom', icon: Icons.zoom_in, selected: false, onTap: () {}),
                        TransitionPreview(name: 'Glitch', icon: Icons.flash_on, selected: false, onTap: () {}),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: NeonSlider(value: 0.8, min: 0, max: 1, onChanged: (_) {}, label: 'Volume')),
                      const SizedBox(width: 12),
                      Expanded(child: NeonSlider(value: 1.0, min: 0.5, max: 2, onChanged: (_) {}, label: 'Speed')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: LoadingButton(
                      loading: _saving,
                      onPressed: _mergeExport,
                      child: const Text('Merge & Export', style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Inter')),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}



