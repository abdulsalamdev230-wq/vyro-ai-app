/// VYRO AI — Video share helper (platform-conditional)
///
/// Web: uses the Web Share API when available, else copies the URL.
/// IO:  opens the native share sheet via share_plus.
export 'video_share_io.dart' if (dart.library.html) 'video_share_web.dart';
