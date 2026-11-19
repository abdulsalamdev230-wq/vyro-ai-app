/// VYRO AI â€” Subscription / Pricing Screen


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/providers/subscription_provider.dart';
import '../widgets/unavailable_state.dart';
import '../../models/user_model.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SubscriptionProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SubscriptionProvider>(
      builder: (context, sub, child) {
        return Scaffold(
          backgroundColor: const Color(0xFF0A101C),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Go Pro', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.w800)),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('Choose your plan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                const SizedBox(height: 20),
                ...[
                  _planCard(
                    context,
                    tier: SubscriptionTier.free,
                    price: 'Free',
                    subtitle: 'Get started with VYRO AI',
                    features: const [
                      '5 AI generations / month',
                      '720p exports',
                      'Watermark included',
                      'Standard templates',
                    ],
                    isPro: false,
                    isCurrent: sub.tier == SubscriptionTier.free,
                    product: null,
                  ),
                  const SizedBox(height: 16),
                  _planCard(
                    context,
                    tier: SubscriptionTier.pro,
                    price: '\$9.99',
                    subtitle: 'Per month â€” best for creators',
                    features: const [
                      '100 AI generations / month',
                      '1080p & 4K exports',
                      'No watermark',
                      'Premium templates',
                      'Priority processing',
                    ],
                    isPro: true,
                    isCurrent: sub.tier == SubscriptionTier.pro,
                    product: sub.products.isNotEmpty ? sub.products.first : null,
                  ),
                  const SizedBox(height: 16),
                  _planCard(
                    context,
                    tier: SubscriptionTier.enterprise,
                    price: '\$29.99',
                    subtitle: 'Per month â€” teams & agencies',
                    features: const [
                      '1,000 AI generations / month',
                      '4K HDR exports',
                      'No watermark',
                      'All templates',
                      'Team collaboration',
                    ],
                    isPro: true,
                    isCurrent: sub.tier == SubscriptionTier.enterprise,
                    product: sub.products.length > 1 ? sub.products[1] : null,
                  ),
                ],
                const SizedBox(height: 24),
                if (sub.error != null)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
                    ),
                    child: Text(sub.error!, style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13)),
                  ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: sub.products.isNotEmpty ? () => sub.restorePurchases() : null,
                    child: const Text('Restore purchases', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Subscriptions are handled by Google Play Billing. Prices may vary by region.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _planCard(BuildContext context, {
    required SubscriptionTier tier,
    required String price,
    required String subtitle,
    required List<String> features,
    required bool isPro,
    required bool isCurrent,
    ProductDetails? product,
  }) {
    final sub = context.read<SubscriptionProvider>();
    return GlassCard(
      child: Column(
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8855FF), Color(0xFF00D5FF)]),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white),
          ),
          const SizedBox(height: 14),
          Text(
            tier.label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20, fontFamily: 'Inter'),
          ),
          const SizedBox(height: 6),
          Text(
            price,
            style: const TextStyle(color: Color(0xFF8855FF), fontWeight: FontWeight.w800, fontSize: 32, fontFamily: 'Inter'),
          ),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14)),
          const SizedBox(height: 16),
          ...features.map((f) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(isPro ? Icons.check_circle : Icons.circle, color: const Color(0xFF10B981), size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(f, style: const TextStyle(color: Colors.white, fontSize: 13))),
              ],
            ),
          )),
          const SizedBox(height: 18),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
              ),
              child: const Text('Current plan', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w700)),
            )
          else if (product != null)
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: sub.isLoading ? null : () => sub.purchaseSubscription(product),
                child: sub.isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)))
                    : const Text('Subscribe', style: TextStyle(fontWeight: FontWeight.w800, fontFamily: 'Inter')),
              ),
            )
          else
            const Text('Product not available in store.', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
        ],
      ),
    );
  }
}
