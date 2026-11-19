/// VYRO AI — Blob URL helper (platform-conditional)
///
/// Exposes [createBlobUrl] on web (dart:html) and a null-returning stub on
/// IO platforms. Used by VyroWorkerProvider to keep generated images
/// visible when Firebase Storage persistence fails (e.g. CORS).
export 'image_blob_io.dart' if (dart.library.html) 'image_blob_web.dart';
