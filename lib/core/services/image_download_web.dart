/// VYRO AI — Image download helper (web implementation)
///
/// Downloads the image via a blob object URL and a synthetic anchor click so
/// the browser saves the file directly. Falls back to opening the URL in a
/// new tab when the host disallows CORS blob fetching.
import 'dart:html' as html;

/// Triggers a browser download for [url]. Returns a user-facing message.
Future<String> downloadImage(String url) async {
  try {
    final res = await html.HttpRequest.request(
      url,
      responseType: 'blob',
    );
    final blob = res.response as html.Blob;
    final objectUrl = html.Url.createObjectUrl(blob);
    final anchor = html.AnchorElement(href: objectUrl)
      ..download = 'vyro-ai-${DateTime.now().millisecondsSinceEpoch}.jpg'
      ..click();
    html.Url.revokeObjectUrl(objectUrl);
    return 'Image downloaded.';
  } catch (_) {
    // CORS-restricted host: open in a new tab so the user can save manually.
    html.window.open(url, '_blank');
    return 'Image opened in a new tab — right-click to save.';
  }
}
