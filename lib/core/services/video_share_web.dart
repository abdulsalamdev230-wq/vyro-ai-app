/// VYRO AI — Video share helper (web implementation)
///
/// Uses the Web Share API (navigator.share) when the browser supports it and
/// the page is served over HTTPS; otherwise copies the video link.
import 'dart:html' as html;

/// Shares [url]. Returns a user-facing status message.
Future<String> shareVideo(String url) async {
  try {
    if (html.window.navigator.share != null) {
      await html.window.navigator.share(<String, dynamic>{
        'url': url,
        'title': 'VYRO AI generated video',
        'text': 'Video generated with VYRO AI',
      });
      return 'Video shared.';
    }
  } catch (_) {
    // share aborted or unsupported → fall through to clipboard.
  }
  try {
    await html.window.navigator.clipboard?.writeText(url);
    return 'Video link copied — paste it anywhere to share.';
  } catch (_) {
    return 'Sharing unavailable — the video link could not be copied.';
  }
}
