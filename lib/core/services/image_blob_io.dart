/// VYRO AI — Blob URL helper (non-web stub)
///
/// On non-web platforms there is no browser Blob store, so this always
/// returns null and the caller keeps its normal download-URL flow.
import 'dart:typed_data';

String? createBlobUrl(Uint8List bytes, String contentType) => null;
