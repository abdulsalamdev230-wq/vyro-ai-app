/// VYRO AI — inline video result player (web implementation)
///
/// Renders a native <video> element inside an HtmlElementView so hosted
/// generated videos play directly on the web build with browser controls
/// (no CORS setup required — native video elements can play cross-origin).
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

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
  static final Map<String, String> _registered = <String, String>{};
  String? _viewType;
  html.VideoElement? _element;

  @override
  void initState() {
    super.initState();
    _register();
  }

  @override
  void didUpdateWidget(covariant VideoResultPlayer old) {
    super.didUpdateWidget(old);
    if (old.url != widget.url) _register();
  }

  void _register() {
    _element = null;
    _viewType = _registered.putIfAbsent(widget.url, () {
      final viewType = 'vyro-video-${_registered.length}';
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        final video = html.VideoElement()
          ..src = widget.url
          ..controls = true
          ..loop = true
          ..setAttribute('playsinline', 'true')
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = 'contain'
          ..style.display = 'block'
          ..style.backgroundColor = '#0A101C';
        _element = video;
        return video;
      });
      return viewType;
    });
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _element?.pause();
    _element = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewType = _viewType;
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: Container(
        color: const Color(0xFF0A101C),
        child: viewType != null
            ? HtmlElementView(viewType: viewType)
            : const Center(
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Color(0xFF00D5FF)),
                ),
              ),
      ),
    );
  }
}
