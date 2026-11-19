/// VYRO AI — CORS-safe image widget (web implementation)
///
/// Renders the image through a native <img> element (HtmlElementView). Native
/// image loading is not subject to CORS, so hosts that omit
/// Access-Control-Allow-Origin still display correctly on Flutter web.
/// The element fills its parent box; BoxFit.cover/contain is applied natively.
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class CorsImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double? width;
  final double? height;

  const CorsImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  /// Cache of registered view types per (url, fit) pair.
  static final Map<String, String> _registered = <String, String>{};

  String _viewTypeFor(String url, BoxFit fit) {
    final cacheKey = '$url|${fit.index}';
    return _registered.putIfAbsent(cacheKey, () {
      final viewType = 'vyro-cors-img-${_registered.length}';
      ui_web.platformViewRegistry.registerViewFactory(viewType, (int viewId) {
        final img = html.ImageElement()
          ..src = url
          ..style.width = '100%'
          ..style.height = '100%'
          ..style.objectFit = fit == BoxFit.contain ? 'contain' : 'cover'
          ..style.display = 'block'
          ..style.backgroundColor = '#0E111E';
        return img;
      });
      return viewType;
    });
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewTypeFor(url, fit));
  }
}
