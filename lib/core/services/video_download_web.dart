/// VYRO AI — Video download helper (web implementation)
///
/// Downloads the generated .mp4 via a blob object URL and a synthetic anchor
/// click. Falls back to opening the URL in a new tab when the host disallows
/// CORS blob fetching.
import 'dart:html' as html;

/// Triggers a browser download for [url]. Returns a user-facing message.
Future<String> downloadVideo(String url) async {
  try {
    final res = await html.HttpRequest.request(
      url,
      responseType: 'blob',
    );
    final blob = res.response as html.Blob;
    final objectUrl = html.Url.createObjectUrl(blob);
    final anchor = html.AnchorElement(href: objectUrl)
      ..download = 'vyro-ai-video-${DateTime.now().millisecondsSinceEpoch}.mp4'
      ..click();
    html.Url.revokeObjectUrl(objectUrl);
    return 'Video downloaded.';
  } catch (_) {
    // CORS-restricted host: open in a new tab so the user can save manually.
    html.window.open(url, '_blank');
    return 'Video opened in a new tab — use the player controls to save.';
  }
}
