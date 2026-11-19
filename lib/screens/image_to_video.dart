/// VYRO AI â€” Image-to-Video Screen


import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../widgets/unavailable_state.dart';
import '../../core/animations/button_animations.dart';
import '../../core/providers/ai_provider.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/services/storage_service.dart';

class ImageToVideoScreen extends StatefulWidget {
  const ImageToVideoScreen({super.key});

  @override
  State<ImageToVideoScreen> createState() => _ImageToVideoScreenState();
}

class _ImageToVideoScreenState extends State<ImageToVideoScreen> {
  final _promptCtrl = TextEditingController();
  File? _imageFile;
  String? _imageUrl;
  String? _resultUrl;
  bool _generating = false;
  String? _error;
  int _duration = 5;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, maxHeight: 1024);
    if (file == null) return;
    setState(() => _imageFile = File(file.path));
  }

  Future<void> _generate() async {
    if (_promptCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a description.');
      return;
    }
    if (_imageFile == null) {
      setState(() => _error = 'Please select an image first.');
      return;
    }
    setState(() { _generating = true; _error = null; _resultUrl = null; });

    // Upload image to storage so the AI provider can fetch it.
    String? uploaded;
    try {
      uploaded = await _uploadImage();
    } catch (e) {
      setState(() { _generating = false; _error = 'Failed to upload image: $e'; });
      return;
    }

    final result = await context.read<AiJobNotifier>().generateVideo(
      prompt: _promptCtrl.text.trim(),
      imageUrl: uploaded,
      durationSeconds: _duration,
      width: 1080,
      height: 1920,
    );

    if (!mounted) return;
    setState(() => _generating = false);
    if (result.success && result.data != null) {
      setState(() => _resultUrl = result.data);
    } else if (result.unavailable) {
      setState(() => _error = result.error);
    } else {
      setState(() => _error = result.error ?? 'Video generation failed.');
    }
  }

  Future<String> _uploadImage() async {
    if (_imageFile == null) throw Exception('No image selected');
    // Use Firebase storage if configured; otherwise fall back to a local file path
    // that providers cannot fetch â€” we surface an honest limitation.
    final url = await _storageUpload(_imageFile!);
    return url;
  }

  Future<String> _storageUpload(File file) async {
    final uid = _currentUid();
    if (uid == null) throw Exception('Sign in to generate video.');
    return StorageService.instance.uploadImage(uid: uid, file: file);
  }

  String? _currentUid() => AuthProvider.instance.firebaseUser?.uid;

  @override
  void dispose() {
    _promptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A101C),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Image-to-Video', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: Consumer<AiJobNotifier>(
        builder: (context, ai, child) {
          if (ai.unavailable) {
            return UnavailableState(
              title: 'AI Video generation unavailable',
              message: ai.unavailableMessage ?? 'No video provider configured.',
              setupHint: 'Add an API key for Runware, Stability AI or fal.ai in the .env file.',
              icon: Icons.videocam_off,
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GlassCard(
                  child: Column(
                    children: [
                      const Text('1. Upload an image', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.image, color: Color(0xFF8855FF)),
                          label: const Text('Choose image', style: TextStyle(fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFF263750)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                      if (_imageFile != null) ...[
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(_imageFile!, height: 200, width: double.infinity, fit: BoxFit.cover),
                        ),
                      ],
                      const SizedBox(height: 20),
                      const Text('2. Describe the motion', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _promptCtrl,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Make the clouds move slowly, add cinematic camera pan',
                          hintStyle: const TextStyle(color: Color(0xFF64748B)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF263750)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: Color(0xFF8855FF)),
                          ),
                          filled: true,
                          fillColor: const Color(0xFF101B35),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          const Text('Duration (seconds)', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13)),
                          const Spacer(),
                          DropdownButton<int>(
                            value: _duration,
                            dropdownColor: const Color(0xFF17243B),
                            style: const TextStyle(color: Colors.white),
                            items: [3, 5, 8, 10].map((d) => DropdownMenuItem(value: d, child: Text('$d s'))).toList(),
                            onChanged: (v) => setState(() => _duration = v!),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: LoadingButton(
                          loading: _generating,
                          onPressed: _generating ? null : _generate,
                          child: const Text('Animate Image', style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Inter')),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
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
                if (_resultUrl != null) ...[
                  const SizedBox(height: 20),
                  GlassCard(
                    child: Column(
                      children: [
                        const Text('Animated Video', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            _resultUrl!,
                            height: 320,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 320, color: const Color(0xFF263750),
                              child: const Center(child: Icon(Icons.play_circle, color: Color(0xFF64748B), size: 48)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(onPressed: () => _navigatePreview(_resultUrl!), child: const Text('Open in Editor')),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  void _navigatePreview(String url) {
    Navigator.of(context).pushNamed(AppRoutes.videoPreview, arguments: {'videoUrl': url, 'type': 'video'});
  }
}
