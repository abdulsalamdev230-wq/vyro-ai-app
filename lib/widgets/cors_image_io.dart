/// VYRO AI — CORS-safe image widget (non-web implementation)
///
/// Mobile/desktop builds have no CORS restrictions on Image.network.
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFF101B35),
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image, color: Color(0xFF64748B)),
      ),
    );
  }
}
