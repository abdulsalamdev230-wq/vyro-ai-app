/// VYRO AI â€” Google AdMob Service
///
/// Initializes and loads ads using test unit IDs by default. Real unit IDs
/// come from environment config. Never hardcodes production ad IDs.


import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../config/app_config.dart';

class AdMobService {
  AdMobService._();
  static final AdMobService instance = AdMobService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
    } catch (e) {
      debugPrint('[VYRO AI] AdMob unavailable: $e');
    }
  }

  // ------ Banner ------
  BannerAd? _bannerAd;
  bool get isBannerLoaded => _bannerAd != null;

  void createBanner({
    required void Function(BannerAd) onLoaded,
    required void Function(BannerAd, LoadAdError) onFailed,
    required void Function()? onClosed,
  }) {
    _bannerAd = BannerAd(
      adUnitId: AppConfig.admobBannerUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) => onLoaded(ad as BannerAd),
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _bannerAd = null;
          onFailed(ad as BannerAd, error);
        },
        onAdClosed: (ad) {
          onClosed?.call();
        },
      ),
    );
    _bannerAd!.load();
  }

  void disposeBanner() {
    _bannerAd?.dispose();
    _bannerAd = null;
  }

  BannerAd? get bannerAd => _bannerAd;

  // ------ Interstitial ------
  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoaded = false;
  bool get isInterstitialLoaded => _isInterstitialLoaded && _interstitialAd != null;

  void loadInterstitial({
    required void Function() onLoaded,
    required void Function(LoadAdError) onFailed,
  }) {
    InterstitialAd.load(
      adUnitId: AppConfig.admobInterstitialUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
          _isInterstitialLoaded = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialLoaded = false;
            },
          );
          onLoaded();
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
          _isInterstitialLoaded = false;
          onFailed(error);
        },
      ),
    );
  }

  void showInterstitial({void Function()? onDismissed}) {
    if (_interstitialAd == null) {
      onDismissed?.call();
      return;
    }
    _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _interstitialAd = null;
        _isInterstitialLoaded = false;
        onDismissed?.call();
      },
    );
    _interstitialAd!.show();
    _interstitialAd = null;
    _isInterstitialLoaded = false;
  }

  // ------ Rewarded ------
  RewardedAd? _rewardedAd;
  bool _isRewardedLoaded = false;
  bool get isRewardedLoaded => _isRewardedLoaded && _rewardedAd != null;

  void loadRewarded({
    required void Function() onLoaded,
    required void Function(LoadAdError) onFailed,
  }) {
    RewardedAd.load(
      adUnitId: AppConfig.admobRewardedUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isRewardedLoaded = true;
          ad.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _isRewardedLoaded = false;
            },
          );
          onLoaded();
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isRewardedLoaded = false;
          onFailed(error);
        },
      ),
    );
  }

  /// Show rewarded ad. [onReward] is called when the user earns the reward.
  void showRewarded({
    required void Function(RewardItem) onReward,
    required void Function() onDismissed,
  }) {
    if (_rewardedAd == null) {
      onDismissed.call();
      return;
    }
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _rewardedAd = null;
        _isRewardedLoaded = false;
        onDismissed.call();
      },
    );
    _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
      onReward(reward);
    });
    _rewardedAd = null;
    _isRewardedLoaded = false;
  }

  void disposeAll() {
    disposeBanner();
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _isInterstitialLoaded = false;
    _isRewardedLoaded = false;
  }
}
