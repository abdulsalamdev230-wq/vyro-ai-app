/// VYRO AI — Video download helper (platform-conditional)
///
/// Web: fetches the video as a blob and triggers a browser download (.mp4).
/// IO:  copies the hosted video URL to the clipboard.
export 'video_download_io.dart' if (dart.library.html) 'video_download_web.dart';
