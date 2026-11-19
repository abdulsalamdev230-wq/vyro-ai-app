/// VYRO AI — Image download helper (platform-conditional)
///
/// Web: fetches the image as a blob and triggers a browser download.
/// IO:  copies the image URL to the clipboard (no gallery plugin needed).
export 'image_download_io.dart' if (dart.library.html) 'image_download_web.dart';
