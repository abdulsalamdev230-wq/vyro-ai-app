/// VYRO AI — inline video result player (non-web implementation)
///
/// Plays a hosted video with chewie (video_player). Used in the AI tool
/// result cards so the finished video plays right where it was generated.
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../config/theme.dart';

class VideoResultPlayer extends StatefulWidget {
  final String url;
  final double aspectRatio;
  const VideoResultPlayer({
    super.key,
    required this.url,
    this.aspectRatio = 16 / 9,
  });

  @override
  State<VideoResultPlayer> createState() => _VideoResultPlayerState();
}

class _VideoResultPlayerState extends State<VideoResultPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant VideoResultPlayer old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) _init();
  }

  Future<void> _init() async {
    setState(() {
      _error = null;
      _chewieController = null;
    });
    _videoController?.dispose();
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    _videoController = controller;
    try {
      await controller.initialize();
      if (!mounted || _videoController != controller) {
        await controller.dispose();
        return;
      }
      setState(() {
        _chewieController = ChewieController(
          videoPlayerController: controller,
          autoPlay: false,
          looping: true,
          showControls: true,
          materialProgressColors: ChewieProgressColors(
            playedColor: VyroColors.electricBlue,
            handleColor: VyroColors.electricBlue,
            backgroundColor: VyroColors.surfaceElevated,
            bufferedColor: VyroColors.divider,
          ),
          placeholder: Container(color: VyroColors.backgroundDeep),
        );
      });
    } catch (e) {
      if (mounted) setState(() => _error = 'Video could not be played: $e');
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Container(
        color: VyroColors.backgroundDeep,
        child: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: VyroColors.textMuted, fontSize: 12),
                  ),
                ),
              )
            : _chewieController != null
                ? Chewie(controller: _chewieController!)
                : const Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: VyroColors.electricBlue),
                    ),
                  ),
      ),
    );
  }
}
