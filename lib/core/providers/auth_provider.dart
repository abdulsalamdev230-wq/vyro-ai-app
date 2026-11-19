/// VYRO AI â€” Authentication Provider
///
/// Manages Firebase Auth state and user profile in Firestore.
/// Supports email/password, Google, Facebook, Apple and phone (OTP) auth.
/// Works with anonymous/guest auth when no credentials provided.
///

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../core/services/firebase_service.dart';
import '../../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider._();
  static final AuthProvider instance = AuthProvider._();

  final FirebaseService _fs = FirebaseService.instance;

  // --- Google (constructed lazily; only used on mobile) ---
  GoogleSignIn? _googleSignInInstance;
  GoogleSignIn get _googleSignIn =>
      _googleSignInInstance ??= GoogleSignIn(
        scopes: <String>['email', 'profile'],
      );

  User? _firebaseUser;
  UserModel? _user;
  bool _isLoading = false;
  String? _error;
  bool _isInitialized = false;

  // --- Phone auth state ---
  String? _verificationId;
  int? _resendToken;
  bool _phoneAuthSent = false;

  User? get firebaseUser => _firebaseUser;
  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isInitialized => _isInitialized;
  bool get isSignedIn => _firebaseUser != null;
  bool get isAnonymous => _firebaseUser?.isAnonymous ?? false;
  bool get isAdmin => _user?.role == 'admin';

  /// True when a phone OTP code has been sent and is awaiting verification.
  bool get phoneOtpSent => _phoneAuthSent;

  /// Initialize auth and listen to auth state changes.
  Future<void> initialize() async {
    if (_isInitialized) return;
    // Firebase may be unconfigured (no google-services.json / firebase_options.dart).
    // In that case the app still runs and shows honest "service unavailable"
    // states instead of faking accounts.
    try {
      await _fs.initialize();
    } catch (e) {
      debugPrint('[VYRO AI] Firebase unavailable: $e');
      _error = 'Firebase not configured on this device';
      _isInitialized = true;
      notifyListeners();
      return;
    }
    if (!_fs.isInitialized) {
      _isInitialized = true;
      notifyListeners();
      return;
    }
    _fs.authStateChanges.listen((user) async {
      _firebaseUser = user;
      if (user != null) {
        await _loadProfile(user.uid);
      } else {
        _user = null;
      }
      notifyListeners();
    });
    // Emit current user.
    _firebaseUser = _fs.auth.currentUser;
    if (_firebaseUser != null) {
      await _loadProfile(_firebaseUser!.uid);
    }
    _isInitialized = true;
    notifyListeners();
  }

  /// Load (or create) the user profile document in Firestore.
  ///
  /// FAST PATH (perf): shows an ephemeral user instantly from the Firebase
  /// auth user (zero network) so the UI can navigate immediately, then syncs
  /// the real Firestore profile in the background. A dedup guard prevents the
  /// authStateChanges listener and explicit calls from doing the same work
  /// twice, and first-time setup writes are batched into one round-trip.
  String? _syncingProfileFor;
  Future<void> _loadProfile(String uid) async {
    // Zero-network instant user so navigation never waits on Firestore.
    if (_user == null || _user!.id != uid) {
      _user = _ephemeralUser();
      notifyListeners();
    }
    // De-duplicate: background sync only once per uid at a time.
    if (_syncingProfileFor == uid) return;
    _syncingProfileFor = uid;
    unawaited(_syncProfileInBackground(uid));
  }

  /// A minimal user built directly from Firebase Auth data. Firestore sync
  /// replaces it (or confirms it) shortly after in the background.
  UserModel _ephemeralUser() {
    final now = DateTime.now();
    return UserModel(
      id: _firebaseUser?.uid ?? '',
      email: _firebaseUser?.email ?? '',
      fullName: _firebaseUser?.displayName,
      profileImage: _firebaseUser?.photoURL,
      phoneNumber: _firebaseUser?.phoneNumber,
      authProvider: _providerLabel(),
      emailVerified: _firebaseUser?.emailVerified ?? false,
      accountStatus: 'active',
      role: 'user',
      createdAt: now,
      lastLogin: now,
      updatedAt: now,
    );
  }

  Future<void> _syncProfileInBackground(String uid) async {
    try {
      final doc = await _fs.userDoc(uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final stored = UserModel.fromMap(data, doc.id);

        // Refresh identity details from the live Firebase auth user so the
        // (possibly new) Google/Facebook profile photo and display name are
        // always reflected — Instagram-style "account gets updated" flow.
        final fbPhoto = _firebaseUser?.photoURL;
        final fbName = _firebaseUser?.displayName;
        final photoChanged = (fbPhoto != null && fbPhoto != stored.profileImage);
        final nameChanged = (fbName != null && fbName != stored.fullName);
        if (photoChanged || nameChanged) {
          final updates = <String, dynamic>{
            'updatedAt': FieldValue.serverTimestamp(),
            'lastLogin': FieldValue.serverTimestamp(),
          };
          if (photoChanged) {
            updates['profileImage'] = fbPhoto;
            updates['profileImageUrl'] = fbPhoto;
          }
          if (nameChanged) updates['fullName'] = fbName;
          // user_profiles doc mirrors these fields.
          final profileUpdates = <String, dynamic>{
            'updatedAt': DateTime.now().toIso8601String(),
          };
          if (photoChanged) profileUpdates['profileImageUrl'] = fbPhoto;
          if (nameChanged) profileUpdates['fullName'] = fbName;
          // One batched round-trip for both collections (merge-set works for
          // both existing and missing docs).
          final batch = _fs.firestore.batch();
          batch.set(_fs.userDoc(uid), updates, SetOptions(merge: true));
          batch.set(
            _fs.userProfileDoc(uid),
            profileUpdates,
            SetOptions(merge: true),
          );
          await batch.commit();
        } else {
          // Update lastLogin on every sign-in.
          await _fs.userDoc(uid).update({
            'lastLogin': FieldValue.serverTimestamp(),
          });
        }
        _user = _user!.copyWith(
          profileImage: photoChanged ? fbPhoto : stored.profileImage,
          fullName: nameChanged ? fbName : stored.fullName,
        );
        notifyListeners();
        return;
      }
      // New user: create all three documents in ONE batched round-trip.
      final now = DateTime.now();
      final user = UserModel(
        id: uid,
        email: _firebaseUser?.email ?? '',
        fullName: _firebaseUser?.displayName,
        profileImage: _firebaseUser?.photoURL,
        phoneNumber: _firebaseUser?.phoneNumber,
        authProvider: _providerLabel(),
        emailVerified: _firebaseUser?.emailVerified ?? false,
        accountStatus: 'active',
        role: 'user',
        createdAt: now,
        lastLogin: now,
        updatedAt: now,
      );
      final batch = _fs.firestore.batch();
      batch.set(
        _fs.userDoc(uid),
        user.toMap(),
        SetOptions(merge: true),
      );
      batch.set(
        _fs.userProfileDoc(uid),
        {
          'uid': uid,
          'fullName': _firebaseUser?.displayName,
          'email': _firebaseUser?.email,
          'phoneNumber': _firebaseUser?.phoneNumber,
          'profileImageUrl': _firebaseUser?.photoURL,
          'notificationsEnabled': true,
          'marketingEmails': false,
          'createdAt': now,
          'updatedAt': now,
        },
        SetOptions(merge: true),
      );
      batch.set(
        _fs.userCreditsDoc(uid),
        {
          'uid': uid,
          'balance': 0,
          'totalEarned': 0,
          'totalSpent': 0,
          'lastUpdated': now,
        },
        SetOptions(merge: true),
      );
      await batch.commit();
      _user = user;
    } catch (e) {
      if (kDebugMode) debugPrint('[Auth] loadProfile error: $e');
    } finally {
      _syncingProfileFor = null;
      notifyListeners();
    }
  }

  String _providerLabel() {
    if (_firebaseUser?.isAnonymous == true) return 'anonymous';
    final p = _firebaseUser?.providerData.firstOrNull;
    if (p == null) return 'password';
    final id = p.providerId;
    switch (id) {
      case 'google.com':
        return 'google';
      case 'facebook.com':
        return 'facebook';
      case 'apple.com':
        return 'apple';
      case 'phone':
        return 'phone';
      case 'password':
        return 'password';
      default:
        return id;
    }
  }

  // ============================================================================
  // LOGIN ACTIVITY HELPER
  // ============================================================================

  Future<void> _logLoginActivity({
    required String provider,
    required bool success,
    String? failureReason,
  }) async {
    if (!_fs.isInitialized) return;
    try {
      final activityId = '${_firebaseUser?.uid ?? 'unknown'}_${DateTime.now().millisecondsSinceEpoch}';
      await _fs.loginActivityDoc(activityId).set({
        'userId': _firebaseUser?.uid ?? '',
        'provider': provider,
        'success': success,
        'failureReason': failureReason,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      if (kDebugMode) debugPrint('[Auth] loginActivity error: $e');
    }
  }

  /// Wrap-up after a successful sign-in. Fast: instant user + background
  /// profile sync; login-analytics logging is fire-and-forget so the UI does
  /// not wait on any extra network round-trips.
  Future<void> _onSignInSuccess(User user, String provider) async {
    _firebaseUser = user;
    await _loadProfile(user.uid); // instant (background sync inside)
    unawaited(_logLoginActivity(provider: provider, success: true));
  }

  // ============================================================================
  // ANONYMOUS / GUEST
  // ============================================================================
  Future<bool> signInAnonymously() async {
    _setLoading(true);
    _error = null;
    try {
      final cred = await _fs.signInAnonymously();
      await _onSignInSuccess(cred.user!, 'anonymous');
      return true;
    } catch (e) {
      await _logLoginActivity(provider: 'anonymous', success: false, failureReason: e.toString());
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================================
  // EMAIL / PASSWORD
  // ============================================================================
  Future<bool> signInWithEmailPassword(String email, String password) async {
    _setLoading(true);
    _error = null;
    try {
      final cred = await _fs.signInWithEmailPassword(email, password);
      await _onSignInSuccess(cred.user!, 'email');
      return true;
    } on FirebaseAuthException catch (e) {
      await _logLoginActivity(provider: 'email', success: false, failureReason: _mapAuthError(e));
      _error = _mapAuthError(e);
      return false;
    } catch (e) {
      await _logLoginActivity(provider: 'email', success: false, failureReason: e.toString());
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createAccount(String email, String password, String displayName) async {
    _setLoading(true);
    _error = null;
    try {
      final cred = await _fs.createWithEmailPassword(email, password);
      await cred.user?.updateDisplayName(displayName);
      await _onSignInSuccess(cred.user!, 'email');
      if (_user != null) {
        _user = _user!.copyWith(fullName: displayName);
        unawaited(_fs.userDoc(_user!.id).update(_user!.toMap()));
      }
      // Email verification policy: send the link right after registration.
      // The user can use the app immediately, and a "verify your email"
      // prompt stays until the address is confirmed (see isEmailVerified).
      unawaited(cred.user?.sendEmailVerification());
      return true;
    } on FirebaseAuthException catch (e) {
      await _logLoginActivity(provider: 'email', success: false, failureReason: _mapAuthError(e));
      _error = _mapAuthError(e);
      return false;
    } catch (e) {
      await _logLoginActivity(provider: 'email', success: false, failureReason: e.toString());
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================================
  // EMAIL VERIFICATION
  // ============================================================================
  bool get isEmailVerified => _firebaseUser?.emailVerified ?? false;

  /// Send (or re-send) the verification email to the signed-in user.
  Future<bool> sendVerificationEmail() async {
    final user = _firebaseUser;
    if (user == null) {
      _error = 'No user signed in.';
      return false;
    }
    try {
      await user.sendEmailVerification();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e);
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// Re-check the verification flag from Firebase (after the user taps the
  /// link) and refresh the profile state.
  Future<bool> refreshEmailVerification() async {
    final user = _firebaseUser;
    if (user == null) return false;
    try {
      await user.reload();
      _firebaseUser = _fs.auth.currentUser;
      if (_user != null) {
        _user = _user!.copyWith(
          emailVerified: _firebaseUser?.emailVerified ?? false,
        );
        notifyListeners();
      }
      return _firebaseUser?.emailVerified ?? false;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _error = null;
    try {
      await _fs.sendPasswordReset(email);
      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e);
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================================
  // GOOGLE
  // ============================================================================
  /// Sign in with Google.
  /// On web uses Firebase's native OAuth popup (no extra configuration needed
  /// beyond enabling the provider in Firebase Console). On mobile uses
  /// google_sign_in package flow.
  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _error = null;
    try {
      final UserCredential userCred;
      if (kIsWeb) {
        userCred = await _fs.auth.signInWithPopup(GoogleAuthProvider());
      } else {
        final googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          _error = 'Google sign-in cancelled';
          return false;
        }
        final googleAuth = await googleUser.authentication;
        if (googleAuth.accessToken == null || googleAuth.idToken == null) {
          _error = 'Google sign-in failed: no tokens received';
          return false;
        }
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        userCred = await _fs.auth.signInWithCredential(credential);
      }
      await _onSignInSuccess(userCred.user!, 'google');
      return true;
    } on FirebaseAuthException catch (e) {
      await _logLoginActivity(provider: 'google', success: false, failureReason: _mapAuthError(e));
      _error = _mapAuthError(e);
      return false;
    } catch (e) {
      await _logLoginActivity(provider: 'google', success: false, failureReason: e.toString());
      _error = 'Google sign-in unavailable: ${e.toString()}';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Sign out of Google.
  /// Sign out of Google (mobile only; web uses Firebase signOut).
  Future<void> signOutGoogle() async {
    if (kIsWeb) return;
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  // ============================================================================
  // FACEBOOK
  // ============================================================================
  /// Sign in with Facebook via Firebase OAuth popup on web and the official
  /// Meta SDK on mobile.
  Future<bool> signInWithFacebook() async {
    _setLoading(true);
    _error = null;
    try {
      if (kIsWeb) {
        final userCred = await _fs.auth.signInWithPopup(FacebookAuthProvider());
        await _onSignInSuccess(userCred.user!, 'facebook');
        return true;
      }
      final result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );
      switch (result.status) {
        case LoginStatus.success:
          final accessToken = result.accessToken?.tokenString;
          if (accessToken == null) {
            _error = 'Facebook sign-in failed: no access token';
            return false;
          }
          final credential = FacebookAuthProvider.credential(accessToken);
          final userCred = await _fs.auth.signInWithCredential(credential);
          await _onSignInSuccess(userCred.user!, 'facebook');
          return true;
        case LoginStatus.cancelled:
          _error = 'Facebook sign-in cancelled';
          return false;
        case LoginStatus.failed:
        case LoginStatus.operationInProgress:
          _error = result.message ?? 'Facebook sign-in failed';
          return false;
      }
    } on FirebaseAuthException catch (e) {
      await _logLoginActivity(provider: 'facebook', success: false, failureReason: _mapAuthError(e));
      _error = _mapAuthError(e);
      return false;
    } catch (e) {
      await _logLoginActivity(provider: 'facebook', success: false, failureReason: e.toString());
      _error = 'Facebook sign-in unavailable: ${e.toString()}';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOutFacebook() async {
    if (kIsWeb) return;
    try {
      await FacebookAuth.instance.logOut();
    } catch (_) {}
  }

  // ============================================================================
  // APPLE
  // ============================================================================
  /// Sign in with Apple.
  Future<bool> signInWithApple() async {
    _setLoading(true);
    _error = null;
    try {
      if (kIsWeb) {
        // Web: Firebase OAuth popup flow (Apple provider enabled in console).
        final userCred = await _fs.auth.signInWithPopup(OAuthProvider('apple.com'));
        await _onSignInSuccess(userCred.user!, 'apple');
        return true;
      }
      final appleCred = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );
      if (appleCred.identityToken == null) {
        _error = 'Apple sign-in failed: no identity token';
        return false;
      }
      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCred.identityToken,
        accessToken: appleCred.authorizationCode,
      );
      final userCred = await _fs.auth.signInWithCredential(oauthCredential);
      await _onSignInSuccess(userCred.user!, 'apple');
      return true;
    } on FirebaseAuthException catch (e) {
      await _logLoginActivity(provider: 'apple', success: false, failureReason: _mapAuthError(e));
      _error = _mapAuthError(e);
      return false;
    } catch (e) {
      await _logLoginActivity(provider: 'apple', success: false, failureReason: e.toString());
      _error = 'Apple sign-in unavailable: ${e.toString()}';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ============================================================================
  // PHONE (OTP)
  // ============================================================================
  /// Send OTP via SMS to [phoneNumber] (E.164 format).
  Future<bool> sendOtp(String phoneNumber) async {
    _setLoading(true);
    _error = null;
    _phoneAuthSent = false;
    _verificationId = null;
    _resendToken = null;
    try {
      await _fs.auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (PhoneAuthCredential cred) async {
          try {
            final userCred = await _fs.auth.signInWithCredential(cred);
            await _onSignInSuccess(userCred.user!, 'phone');
          } catch (e) {
            _error = 'OTP auto-verification failed: $e';
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          _error = _mapAuthError(e);
          _setLoading(false);
        },
        codeSent: (String vid, int? resendToken) {
          _verificationId = vid;
          _resendToken = resendToken;
          _phoneAuthSent = true;
          _setLoading(false);
        },
        codeAutoRetrievalTimeout: (String vid) {
          _verificationId = vid;
        },
        timeout: const Duration(seconds: 30),
      );
      return _phoneAuthSent;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e);
      return false;
    } catch (e) {
      _error = 'Phone OTP unavailable: ${e.toString()}';
      return false;
    } finally {
      if (!_phoneAuthSent) _setLoading(false);
    }
  }

  /// Verify the SMS OTP code.
  Future<bool> verifyOtp(String smsCode) async {
    _setLoading(true);
    _error = null;
    try {
      if (_verificationId == null) {
        _error = 'No OTP session. Please request a code first.';
        return false;
      }
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      final userCred = await _fs.auth.signInWithCredential(credential);
      await _onSignInSuccess(userCred.user!, 'phone');
      return true;
    } on FirebaseAuthException catch (e) {
      await _logLoginActivity(provider: 'phone', success: false, failureReason: _mapAuthError(e));
      _error = _mapAuthError(e);
      return false;
    } catch (e) {
      _error = 'OTP verification failed: ${e.toString()}';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resendOtp(String phoneNumber) async {
    return sendOtp(phoneNumber);
  }

  // ============================================================================
  // PROFILE UPDATE
  // ============================================================================
  /// Update the current user's profile fields.
  Future<bool> updateProfile({
    String? fullName,
    String? phoneNumber,
  }) async {
    if (_user == null) {
      _error = 'No user signed in.';
      return false;
    }
    _setLoading(true);
    _error = null;
    try {
      final updates = <String, dynamic>{};
      if (fullName != null) updates['fullName'] = fullName;
      if (phoneNumber != null) updates['phoneNumber'] = phoneNumber;
      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _fs.userDoc(_user!.id).update(updates);

      // Also update Firebase Auth displayName if fullName changed.
      if (fullName != null) {
        await _firebaseUser?.updateDisplayName(fullName);
      }

      _user = _user!.copyWith(
        fullName: fullName ?? _user!.fullName,
        phoneNumber: phoneNumber ?? _user!.phoneNumber,
        updatedAt: DateTime.now(),
      );
      await _fs.userProfileDoc(_user!.id).update({
        'fullName': fullName,
        'phoneNumber': phoneNumber,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } on FirebaseAuthException catch (e) {
      _error = _mapAuthError(e);
      return false;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Upload a new profile picture to Firebase Storage (users/{uid}/profile/)
  /// and sync the download URL into Firestore — Phase 8.
  ///
  /// Validation: only image/jpeg | png | webp, max 5 MB. Upload progress is
  /// reported through [uploadProgress] (0.0–1.0) so the UI can show a real
  /// progress bar. Fails honestly when Storage is not configured.
  double? _uploadProgress;
  double? get uploadProgress => _uploadProgress;

  Future<bool> updateProfilePhoto(
    Uint8List bytes, {
    required String contentType,
  }) async {
    if (_user == null) {
      _error = 'No user signed in.';
      return false;
    }
    // --- Validation ---
    const allowed = {'image/jpeg', 'image/png', 'image/webp'};
    if (!allowed.contains(contentType)) {
      _error = 'Only JPG, PNG or WebP images are allowed.';
      return false;
    }
    const maxBytes = 5 * 1024 * 1024; // 5 MB
    if (bytes.length > maxBytes) {
      _error = 'Image is too large. Maximum size is 5 MB.';
      return false;
    }

    _setLoading(true);
    _error = null;
    _uploadProgress = 0.0;
    notifyListeners();
    try {
      final uid = _user!.id;
      final ref = _fs.profilePictureRef(uid);
      final task = ref.putData(
        bytes,
        SettableMetadata(contentType: contentType),
      );
      task.snapshotEvents.listen((snapshot) {
        if (snapshot.totalBytes > 0) {
          _uploadProgress = snapshot.bytesTransferred / snapshot.totalBytes;
          notifyListeners();
        }
      });
      final snapshot = await task;
      final url = await snapshot.ref.getDownloadURL();

      // Sync URL into both user docs in one batched round-trip.
      final batch = _fs.firestore.batch();
      batch.set(
        _fs.userDoc(uid),
        {
          'profileImage': url,
          'profileImageUrl': url,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      batch.set(
        _fs.userProfileDoc(uid),
        {
          'profileImageUrl': url,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await batch.commit();

      _user = _user!.copyWith(profileImage: url, updatedAt: DateTime.now());
      _uploadProgress = 1.0;
      return true;
    } on FirebaseException catch (e) {
      _error = 'Photo upload failed: ${e.message ?? e.code}';
      return false;
    } catch (e) {
      _error = 'Photo upload failed: $e';
      return false;
    } finally {
      _setLoading(false);
      _uploadProgress = null;
      notifyListeners();
    }
  }

  // ============================================================================
  // SIGN OUT
  // ============================================================================
  Future<void> signOut() async {
    _error = null;
    await signOutGoogle();
    await signOutFacebook();
    await _fs.signOut();
    _user = null;
    _firebaseUser = null;
    _verificationId = null;
    _resendToken = null;
    _phoneAuthSent = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _isLoading = v;
    notifyListeners();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found for this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      case 'configuration-not-found':
        return 'Sign-in is not configured yet. The app owner must enable Authentication providers in the Firebase Console first.';
      case 'popup-closed-by-user':
      case 'cancelled-popup-request':
        return 'Sign-in window was closed before finishing. Please try again.';
      case 'account-exists-with-different-credential':
        return 'An account already exists with this email using a different sign-in method. Sign in with that method first.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'Network problem. Check your internet connection and try again.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'invalid-verification-code':
        return 'Invalid verification code.';
      case 'invalid-verification-id':
        return 'Invalid verification session. Request a new code.';
      case 'session-expired':
        return 'Session expired. Request a new code.';
      case 'missing-phone-number':
      case 'missing-verification-code':
        return 'Missing verification information.';
      case 'quota-exceeded':
        return 'SMS quota exceeded. Try again later.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }
}
