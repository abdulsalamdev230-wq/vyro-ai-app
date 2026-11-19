/// VYRO AI â€” Export Screen


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../config/routes.dart';
import '../widgets/unavailable_state.dart';
import '../../core/animations/button_animations.dart';
import '../../core/services/video_processing_service.dart';
import '../../core/providers/subscription_provider.dart';

class ExportScreen extends StatefulWidget {
  const ExportScreen({super.key});

  @override
  State<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends State<ExportScreen> {
  int _resolutionIndex = 1; // 0=720,1=1080,2=4K
  bool _watermark = true;
  bool _hdr = false;
  bool _exporting = false;
  String? _exportPath;
  String? _error;

  final List<String> _resolutions = const ['720p HD', '1080p Full HD', '4K UHD'];

  Future<void> _export() async {
    // For demonstration, export a placeholder demo clip if none provided.
    // In a full build, this would process the current timeline.
    setState(() { _exporting = true; _error = null; _exportPath = null; });

    final sub = context.read<SubscriptionProvider>();
    if (_hdr && !sub.isPro) {
      setState(() { _exporting = false; _error = 'HD/4K export requires Pro.'; });
      return;
    }
    if (_watermark && !sub.isPro) {
      // free tier keeps watermark; pro can remove
    }

    final res = _resolutions[_resolutionIndex];
    final (w, h) = res == '720p HD' ? (1280, 720) : res == '1080p Full HD' ? (1080, 1920) : (3840, 2160);

    // Create a simple color-bar test video via FFmpeg then encode to target res,
    // demonstrating real video processing.
    final dir = await getApplicationDocumentsDirectory();
    final out = p.join(dir.path, 'export_${DateTime.now().millisecondsSinceEpoch}.mp4');
    final src = p.join(dir.path, 'src_demo.mp4');

    // Generate a 5s test source
    final gen = await VideoProcessingService.instance.run(
      '-y -f lavfi -i testsrc=duration=5:size=1280x720:rate=30 "$src"',
    );
    if (!gen.success) {
      setState(() { _exporting = false; _error = 'FFmpeg source generation failed.'; });
      return;
    }

    final enc = await VideoProcessingService.instance.export(
      inputPath: src,
      outputPath: out,
      width: w,
      height: h,
      crf: _hdr ? 18 : 23,
    );

    if (!mounted) return;
    setState(() => _exporting = false);
    if (enc.success) {
      setState(() => _exportPath = enc.data);
    } else {
      setState(() => _error = enc.error ?? 'Export failed.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A101C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Export Video', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Export settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
            const SizedBox(height: 20),
            GlassCard(
              child: Column(
                children: [
                  _settingRow(
                    title: 'Resolution',
                    value: _resolutions[_resolutionIndex],
                    onTap: () => _pickResolution(),
                    pro: _resolutionIndex == 2,
                  ),
                  const Divider(height: 1),
                  _settingRow(
                    title: 'Remove watermark',
                    value: _watermark ? 'On (free)' : 'Off',
                    onTap: () => setState(() => _watermark = !_watermark),
                    pro: true,
                    info: 'Pro feature',
                  ),
                  const Divider(height: 1),
                  _settingRow(
                    title: 'HDR quality',
                    value: _hdr ? 'On' : 'Off',
                    onTap: () => setState(() => _hdr = !_hdr),
                    pro: true,
                    info: 'Pro feature',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                    const SizedBox(width: 10),
                    Expanded(child: Text(_error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13))),
                  ],
                ),
              ),
            if (_error != null) const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: LoadingButton(
                loading: _exporting,
                onPressed: _exporting ? null : _export,
                child: const Text('Export Video', style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Inter')),
              ),
            ),
            const SizedBox(height: 16),
            if (_exportPath != null) ...[
              GlassCard(
                child: Column(
                  children: [
                    const Text('Export complete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                    const SizedBox(height: 10),
                    Text(_exportPath!, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Done'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _settingRow({
    required String title,
    required String value,
    required VoidCallback onTap,
    bool pro = false,
    String? info,
  }) {
    return ListTile(
      title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      subtitle: info != null ? Text(info, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pro) const Icon(Icons.lock, color: Color(0xFF94A3B8), size: 16),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(color: Color(0xFF8855FF), fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: Color(0xFF64748B)),
        ],
      ),
      onTap: pro ? () => Navigator.of(context).pushNamed(AppRoutes.subscription) : onTap,
    );
  }

  Future<void> _pickResolution() async {
    final sub = context.read<SubscriptionProvider>();
    final selected = await showDialog<int>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF17243B),
        title: const Text('Resolution', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_resolutions.length, (i) {
            final proNeeded = i == 2;
            return ListTile(
              title: Text(_resolutions[i], style: const TextStyle(color: Colors.white)),
              trailing: proNeeded && !sub.isPro ? const Icon(Icons.lock, color: Color(0xFF94A3B8)) : null,
              onTap: proNeeded && !sub.isPro
                  ? () => Navigator.of(context).pushNamed(AppRoutes.subscription)
                  : () => Navigator.pop(context, i),
            );
          }),
        ),
      ),
    );
    if (selected != null) setState(() => _resolutionIndex = selected);
  }
}
