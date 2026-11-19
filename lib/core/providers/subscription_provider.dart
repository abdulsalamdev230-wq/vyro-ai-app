/// VYRO AI â€” Subscription Provider
///
/// Manages subscription tier, credits and purchase flow. Works with the
/// IAP service and syncs status with Firestore. Free tier users get an
/// honest paywall for premium features.


import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/services/iap_service.dart';
import '../../core/services/firebase_service.dart';
import '../../models/user_model.dart';
import 'auth_provider.dart';

class SubscriptionProvider extends ChangeNotifier {
  SubscriptionProvider._();
  static final SubscriptionProvider instance = SubscriptionProvider._();

  final IapService _iap = IapService.instance;

  SubscriptionTier _tier = SubscriptionTier.free;
  int _credits = 0;
  bool _isLoading = false;
  String? _error;
  List<ProductDetails> _products = [];
  bool _productsLoaded = false;

  SubscriptionTier get tier => _tier;
  int get credits => _credits;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<ProductDetails> get products => _products;
  bool get productsLoaded => _productsLoaded;
  bool get isPro => _tier == SubscriptionTier.pro || _tier == SubscriptionTier.enterprise;
  bool get isFree => _tier == SubscriptionTier.free;

  String? get _uid => AuthProvider.instance.firebaseUser?.uid;

  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();
    await _iap.initialize();
    await fetchProducts();
    await _syncFromServer();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> fetchProducts() async {
    _products = await _iap.fetchProducts();
    _productsLoaded = true;
    notifyListeners();
  }

  Future<void> _syncFromServer() async {
    final uid = _uid;
    if (uid == null) return;
    try {
      final doc = await FirebaseService.instance.userDoc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        _tier = SubscriptionTier.values.firstWhere(
          (e) => e.name == (data['tier'] ?? 'free'),
          orElse: () => SubscriptionTier.free,
        );
        _credits = (data['credits'] ?? 0) as int;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('[Subscription] sync: $e');
    }
  }

  /// Purchase a subscription product.
  Future<bool> purchaseSubscription(ProductDetails product) async {
    _setLoading(true);
    _error = null;
    try {
      await _iap.buy(product);
      // The purchase stream (handled by a listener) confirms & updates tier.
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Purchase a consumable credit pack.
  Future<bool> purchaseCredits(ProductDetails product) async {
    _setLoading(true);
    _error = null;
    try {
      await _iap.buyConsumable(product);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Handle a confirmed purchase from the purchase stream.
  Future<void> onPurchaseCompleted(PurchaseDetails purchase) async {
    await _iap.completePurchase(purchase);
    await _syncFromServer();
    notifyListeners();
  }

  Future<void> restorePurchases() async {
    _setLoading(true);
    try {
      await _iap.restorePurchases();
      await _syncFromServer();
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// Deduct credits for a generation (honest paywall: free tier limited).
  bool deductCredits(int cost) {
    if (_credits >= cost) {
      _credits -= cost;
      notifyListeners();
      return true;
    }
    _error = 'Not enough credits. Upgrade or purchase a credit pack.';
    notifyListeners();
    return false;
  }

  void addCredits(int amount) {
    _credits += amount;
    notifyListeners();
  }

  void setTier(SubscriptionTier tier, {int? credits}) {
    _tier = tier;
    if (credits != null) _credits = credits;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}

