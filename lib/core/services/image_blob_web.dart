/// VYRO AI — Blob URL helper (web implementation)
///
/// Creates a browser object URL from raw image bytes so Flutter web can
/// render a generated image even when Firebase Storage is unreachable
/// (e.g. CORS not yet configured for the dev origin).
import 'dart:html' as html;
import 'dart:typed_data';

String? createBlobUrl(Uint8List bytes, String contentType) {
  try {
    final blob = html.Blob(<Object>[bytes], contentType);
    return html.Url.createObjectUrl(blob);
  } catch (_) {
    return null;
  }
}
