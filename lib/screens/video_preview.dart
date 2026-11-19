/// VYRO AI â€” Video Preview Screen


import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import '../../config/routes.dart';
import '../widgets/unavailable_state.dart';

class VideoPreviewScreen extends StatefulWidget {
  const VideoPreviewScreen({super.key});

  @override
  State<VideoPreviewScreen> createState() => _VideoPreviewScreenState();
}

class _VideoPreviewScreenState extends State<VideoPreviewScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  String? _url;
  String _type = 'video'; // video | image
  bool _init = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments as Map?;
    if (args != null && !_init) {
      _init = true;
      _url = args['videoUrl'] ?? args['imageUrl'];
      _type = args['type'] ?? 'video';
      if (_type == 'video' && _url != null) _initVideo(_url!);
    }
  }

  Future<void> _initVideo(String url) async {
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    await _videoController!.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoController!,
      autoPlay: true,
      looping: false,
      showControls: true,
      materialProgressColors: ChewieProgressColors(
        playedColor: const Color(0xFF8855FF),
        handleColor: const Color(0xFF8855FF),
        backgroundColor: const Color(0xFF263750),
        bufferedColor: const Color(0xFF00D5FF),
      ),
      placeholder: Container(color: const Color(0xFF0A101C)),
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A101C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Preview', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white),
            onPressed: () => Navigator.of(context).pushNamed(AppRoutes.videoEditor),
          ),
        ],
      ),
      body: Center(
        child: _type == 'image' && _url != null
            ? GlassCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(_url!, height: 400, width: double.infinity, fit: BoxFit.cover),
                    ),
                    const SizedBox(height: 16),
                    const Text('Image preview', style: TextStyle(color: Color(0xFF94A3B8))),
                  ],
                ),
              )
            : (_chewieController != null
                ? Chewie(controller: _chewieController!)
                : const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('Loading preview...', style: TextStyle(color: Color(0xFF94A3B8))),
                    ],
                  )),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        color: const Color(0xFF0A101C),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.export),
                child: const Text('Export', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pushNamed(AppRoutes.videoEditor),
                child: const Text('Edit', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
