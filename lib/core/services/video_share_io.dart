/// VYRO AI — Video share helper (non-web implementation)
///
/// Opens the native Android/iOS share sheet through share_plus (v10 API).
import 'package:share_plus/share_plus.dart';

/// Shares [url] through the system share sheet. Returns a status message.
Future<String> shareVideo(String url) async {
  try {
    final result = await Share.share(url);
    if (result.status == ShareResultStatus.success) {
      return 'Video shared.';
    }
    return 'Video link ready — paste it anywhere to share.';
  } catch (_) {
    return 'Sharing unavailable on this device.';
  }
}
