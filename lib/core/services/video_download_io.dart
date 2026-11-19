/// VYRO AI — Video download helper (non-web implementation)
///
/// Without a gallery-saver plugin the honest mobile behaviour is to copy the
/// hosted video URL so the user can save it from their browser/gallery app.
import 'package:flutter/services.dart';

/// Copies [url] to the clipboard. Returns a user-facing status message.
Future<String> downloadVideo(String url) async {
  try {
    await Clipboard.setData(ClipboardData(text: url));
    return 'Video link copied — open it in your browser to save.';
  } catch (_) {
    return 'Could not copy the video link.';
  }
}
