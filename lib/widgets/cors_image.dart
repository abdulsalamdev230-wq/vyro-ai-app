/// VYRO AI — CORS-safe image widget (platform-conditional)
///
/// Web builds use a native <img> element inside an HtmlElementView so hosts
/// without CORS headers (e.g. img.pixelvault.dev) still render — Flutter's
/// CanvasKit Image.network fetches via XHR and would show a broken image.
/// Non-web builds use Image.network directly.
export 'cors_image_io.dart' if (dart.library.html) 'cors_image_web.dart';
