/// VYRO AI â€” In-App Purchase Service
///
/// Handles subscription and credit-pack purchases via platform billing
/// (Google Play Billing). Product IDs come from AppConfig. Purchase
/// verification is delegated to the backend.


import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../config/app_config.dart';

class IapService {
  IapService._();
  static final IapService instance = IapService._();

  final InAppPurchase _iap = InAppPurchase.instance;

  bool _available = false;
  bool get isAvailable => _available;

  Stream<List<PurchaseDetails>> get purchaseStream => _iap.purchaseStream;

  Future<void> initialize() async {
    try {
      _available = await _iap.isAvailable();
    } catch (e) {
      debugPrint('[VYRO AI] In-app purchases unavailable: $e');
      _available = false;
    }
  }

  /// Fetch available products from the store.
  Future<List<ProductDetails>> fetchProducts() async {
    if (!_available) return [];
    final productSet = Set<String>.from(AppConfig.subscriptionProductIds);
    final response = await _iap.queryProductDetails(productSet);
    return response.productDetails;
  }

  /// Buy a product (subscription or consumable credit pack).
  /// In in_app_purchase 3.x, subscriptions are purchased via buyNonConsumable.
  Future<bool> buy(ProductDetails product) async {
    if (!_available) return false;
    final param = PurchaseParam(productDetails: product);
    try {
      await _iap.buyNonConsumable(purchaseParam: param);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Consumable purchase (credit packs).
  Future<bool> buyConsumable(ProductDetails product) async {
    if (!_available) return false;
    final param = PurchaseParam(productDetails: product);
    try {
      await _iap.buyConsumable(purchaseParam: param);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Complete a purchase (consume / acknowledge).
  Future<void> completePurchase(PurchaseDetails purchase) async {
    if (purchase.pendingCompletePurchase) {
      await _iap.completePurchase(purchase);
    }
  }

  /// Restore previous purchases (subscriptions).
  Future<void> restorePurchases() async {
    if (!_available) return;
    await _iap.restorePurchases();
  }
}
