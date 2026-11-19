/// VYRO AI â€” Templates Library Screen


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/routes.dart';
import '../../core/providers/video_provider.dart';
import '../../core/providers/subscription_provider.dart';
import '../widgets/unavailable_state.dart';
import '../../models/user_model.dart';

class TemplatesLibraryScreen extends StatefulWidget {
  const TemplatesLibraryScreen({super.key});

  @override
  State<TemplatesLibraryScreen> createState() => _TemplatesLibraryScreenState();
}

class _TemplatesLibraryScreenState extends State<TemplatesLibraryScreen> {
  String? _selectedCategory;

  final List<String> _categories = const ['All', 'Reels', 'TikTok', 'Shorts', 'Promo', 'Event'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VideoProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VideoProvider>(
      builder: (context, vp, child) {
        final templates = vp.templates;
        return Scaffold(
          backgroundColor: const Color(0xFF0A101C),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Templates', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800)),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Category chips
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: _categories.map((c) {
                    final selected = _selectedCategory == c;
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(c),
                        selected: selected,
                        onSelected: (_) => setState(() => _selectedCategory = selected ? null : c),
                        selectedColor: const Color(0xFF8855FF),
                        backgroundColor: const Color(0xFF17243B),
                        labelStyle: TextStyle(
                          color: selected ? Colors.white : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: templates.isEmpty
                    ? const Center(
                        child: Text('No templates available.', style: TextStyle(color: Color(0xFF94A3B8))),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.68,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: templates.length,
                        itemBuilder: (context, i) {
                          final t = templates[i];
                          return _templateCard(context, t, vp, context.read<SubscriptionProvider>());
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _templateCard(BuildContext context, TemplateModel t, VideoProvider vp, SubscriptionProvider sub) {
    final premium = t.isPremium;
    return GestureDetector(
      onTap: premium && !sub.isPro
          ? () => Navigator.of(context).pushNamed(AppRoutes.subscription)
          : () => _useTemplate(context, t),
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      t.thumbnailUrl.isNotEmpty ? t.thumbnailUrl : '',
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: const Color(0xFF17243B),
                        child: const Icon(Icons.videocam, color: Color(0xFF64748B)),
                      ),
                    ),
                  ),
                  if (premium)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEC4899),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Pro', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800)),
                      ),
                    ),
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('${t.durationSeconds}s', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(t.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
            const SizedBox(height: 4),
            Text(t.category, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
            if (premium && !sub.isPro)
              const SizedBox(height: 6),
            if (premium && !sub.isPro)
              Text('Upgrade to use', style: const TextStyle(color: Color(0xFFEC4899), fontSize: 11, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  void _useTemplate(BuildContext context, TemplateModel t) {
    Navigator.of(context).pushNamed(AppRoutes.videoEditor, arguments: {'template': t});
  }
}

