/// VYRO AI â€” Video Processing Service (FFmpeg)
///
/// Wraps ffmpeg_kit_flutter_min for thumbnail generation, trimming, merging,
/// audio mixing and export. All operations write to the app's document/cache
/// directory and return local file paths.


import 'dart:io';
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min/return_code.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class VideoProcessingService {
  VideoProcessingService._();
  static final VideoProcessingService instance = VideoProcessingService._();

  Future<Directory> get _tempDir async {
    final dir = await getTemporaryDirectory();
    final v = Directory(p.join(dir.path, 'vyro_video'));
    await v.create(recursive: true);
    return v;
  }

  /// Run an FFmpeg command and return a result.
  Future<AiVideoProcessResult> run(String command) async {
    final session = await FFmpegKit.execute(command);
    final code = await session.getReturnCode();
    if (ReturnCode.isSuccess(code)) {
      return AiVideoProcessResult.success();
    }
    final log = await session.getAllLogs() ?? '';
    return AiVideoProcessResult.failure(
      'FFmpeg failed (code ${code?.getValue()}): $log',
    );
  }

  // -----------------------------------------------------------------------
  // Thumbnail generation
  // -----------------------------------------------------------------------

  Future<AiVideoProcessResult<String>> generateThumbnail({
    required String inputPath,
    double timestamp = 1.0,
    int width = 320,
    int height = 320,
  }) async {
    final out = p.join((await _tempDir).path, 'thumb_${DateTime.now().millisecondsSinceEpoch}.jpg');
    final cmd =
        '-y -i "$inputPath" -ss $timestamp -vframes 1 -vf "scale=$width:$height:force_original_aspect_ratio=decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2" -q:v 2 "$out"';
    final result = await run(cmd);
    if (result.success) {
      return AiVideoProcessResult.successData(out);
    }
    return AiVideoProcessResult.failureData(result.error ?? 'Thumbnail generation failed');
  }

  // -----------------------------------------------------------------------
  // Trimming / cutting
  // -----------------------------------------------------------------------

  Future<AiVideoProcessResult<String>> trim({
    required String inputPath,
    required double start,
    required double end,
    int width = 1080,
    int height = 1920,
  }) async {
    final duration = end - start;
    final out = p.join((await _tempDir).path, 'trim_${DateTime.now().millisecondsSinceEpoch}.mp4');
    final cmd =
        '-y -ss $start -i "$inputPath" -t $duration -vf "scale=$width:$height:force_original_aspect_ratio=decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2" -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 128k -movflags +faststart "$out"';
    final result = await run(cmd);
    if (result.success) {
      return AiVideoProcessResult.successData(out);
    }
    return AiVideoProcessResult.failureData(result.error ?? 'Trim failed');
  }

  // -----------------------------------------------------------------------
  // Merge / concatenate multiple clips
  // -----------------------------------------------------------------------

  Future<AiVideoProcessResult<String>> merge({
    required List<String> inputPaths,
    int width = 1080,
    int height = 1920,
  }) async {
    if (inputPaths.isEmpty) {
      return AiVideoProcessResult.failureData('No clips to merge.');
    }
    final dir = await _tempDir;
    final listFile = p.join(dir.path, 'concat_${DateTime.now().millisecondsSinceEpoch}.txt');
    final buffer = StringBuffer();
    for (final path in inputPaths) {
      buffer.writeln("file '${path.replaceAll("'", "'\\''")}'");
    }
    final file = File(listFile);
    await file.writeAsString(buffer.toString());

    final out = p.join(dir.path, 'merged_${DateTime.now().millisecondsSinceEpoch}.mp4');
    final cmd =
        '-y -f concat -safe 0 -i "$listFile" -vf "scale=$width:$height:force_original_aspect_ratio=decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2,format=yuv420p" -c:v libx264 -preset fast -crf 23 -c:a aac -b:a 128k -movflags +faststart "$out"';
    final result = await run(cmd);
    if (result.success) {
      return AiVideoProcessResult.successData(out);
    }
    return AiVideoProcessResult.failureData(result.error ?? 'Merge failed');
  }

  // -----------------------------------------------------------------------
  // Add/replace audio
  // -----------------------------------------------------------------------

  Future<AiVideoProcessResult<String>> addAudio({
    required String videoPath,
    required String audioPath,
    bool replace = true,
  }) async {
    final out = p.join((await _tempDir).path, 'with_audio_${DateTime.now().millisecondsSinceEpoch}.mp4');
    final audioFilter = replace ? '' : '-filter_complex "[0:a][1:a]amerge=inputs=2[a]" -map "[a]"';
    final cmd =
        '-y -i "$videoPath" -i "$audioPath" -c:v copy -c:a aac -b:a 128k -shortest $audioFilter "$out"';
    final result = await run(cmd);
    if (result.success) {
      return AiVideoProcessResult.successData(out);
    }
    return AiVideoProcessResult.failureData(result.error ?? 'Add audio failed');
  }

  // -----------------------------------------------------------------------
  // Export (resize / re-encode for social)
  // -----------------------------------------------------------------------

  Future<AiVideoProcessResult<String>> export({
    required String inputPath,
    required String outputPath,
    int width = 1080,
    int height = 1920,
    int crf = 23,
    String preset = 'fast',
  }) async {
    final cmd =
        '-y -i "$inputPath" -vf "scale=$width:$height:force_original_aspect_ratio=decrease,pad=$width:$height:(ow-iw)/2:(oh-ih)/2,format=yuv420p" -c:v libx264 -preset $preset -crf $crf -c:a aac -b:a 128k -movflags +faststart "$outputPath"';
    final result = await run(cmd);
    if (result.success) {
      return AiVideoProcessResult.successData(outputPath);
    }
    return AiVideoProcessResult.failureData(result.error ?? 'Export failed');
  }

  // -----------------------------------------------------------------------
  // Probe duration
  // -----------------------------------------------------------------------

  Future<double> getDuration(String inputPath) async {
    final session = await FFprobeKit.execute('-i "$inputPath" -show_entries format=duration -v quiet -of csv="p=0"');
    final code = await session.getReturnCode();
    if (ReturnCode.isSuccess(code)) {
      final output = await session.getOutput() ?? '';
      return double.tryParse(output.trim()) ?? 0.0;
    }
    return 0.0;
  }
}

/// Generic result of a FFmpeg process.
class AiVideoProcessResult<T> {
  final bool success;
  final T? data;
  final String? error;

  AiVideoProcessResult._({required this.success, this.data, this.error});

  factory AiVideoProcessResult.success() => AiVideoProcessResult._(success: true);
  factory AiVideoProcessResult.successData(T data) =>
      AiVideoProcessResult._(success: true, data: data);
  factory AiVideoProcessResult.failure(String error) =>
      AiVideoProcessResult._(success: false, error: error);
  factory AiVideoProcessResult.failureData(String error) =>
      AiVideoProcessResult._(success: false, error: error);
}
