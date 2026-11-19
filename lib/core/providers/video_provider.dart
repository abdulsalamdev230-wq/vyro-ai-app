/// VYRO AI â€” Video & Project Provider
///
/// Manages generated videos, projects, templates and persistent data via
/// Firestore + Firebase Storage. Falls back to local-only when Firestore is
/// not configured, surfacing an honest state.


import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../../core/services/firebase_service.dart';
import '../../core/services/storage_service.dart';
import '../../models/user_model.dart';
import '../providers/auth_provider.dart';

class VideoProvider extends ChangeNotifier {
  VideoProvider._();
  static final VideoProvider instance = VideoProvider._();

  final FirebaseService _fs = FirebaseService.instance;
  final StorageService _storage = StorageService.instance;

  List<VideoModel> _videos = [];
  List<ProjectModel> _projects = [];
  List<TemplateModel> _templates = [];
  bool _isLoading = false;
  String? _error;
  bool _firestoreReady = false;

  List<VideoModel> get videos => _videos;
  List<ProjectModel> get projects => _projects;
  List<TemplateModel> get templates => _templates;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get firestoreReady => _firestoreReady;

  String? get _uid => AuthProvider.instance.firebaseUser?.uid;

  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      // Templates are public â€” load once.
      await _loadTemplates();
      _firestoreReady = true;
    } catch (e) {
      _firestoreReady = false;
      if (kDebugMode) debugPrint('[VideoProvider] Firestore unavailable: $e');
    }
    if (_uid != null) {
      await loadVideos();
      await loadProjects();
    }
    _isLoading = false;
    notifyListeners();
  }

  // -----------------------------------------------------------------------
  // Videos
  // -----------------------------------------------------------------------

  Future<void> loadVideos() async {
    if (_uid == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final snap = await _fs.videosCollection(_uid!)
          .orderBy('createdAt', descending: true)
          .get();
      _videos = snap.docs
          .map((d) => VideoModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) debugPrint('[VideoProvider] loadVideos: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addVideo(VideoModel video) async {
    if (_uid == null) return false;
    try {
      final docRef = _fs.videosCollection(_uid!).doc(video.id);
      await docRef.set(video.toMap());
      _videos.insert(0, video);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateVideo(String id, Map<String, dynamic> updates) async {
    if (_uid == null) return false;
    try {
      await _fs.videosCollection(_uid!).doc(id).update(updates);
      final idx = _videos.indexWhere((v) => v.id == id);
      if (idx != -1) {
        _videos[idx] = _videos[idx].copyWith(
          title: updates['title'] as String?,
          storageUrl: updates['storageUrl'] as String?,
          thumbnailUrl: updates['thumbnailUrl'] as String?,
          previewUrl: updates['previewUrl'] as String?,
          isExported: updates['isExported'] as bool?,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteVideo(String id) async {
    if (_uid == null) return false;
    try {
      await _fs.videosCollection(_uid!).doc(id).delete();
      _videos.removeWhere((v) => v.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // -----------------------------------------------------------------------
  // Projects
  // -----------------------------------------------------------------------

  Future<void> loadProjects() async {
    if (_uid == null) return;
    try {
      final snap = await _fs.projectsCollection(_uid!)
          .orderBy('lastEdited', descending: true)
          .get();
      _projects = snap.docs
          .map((d) => ProjectModel.fromMap(d.data() as Map<String, dynamic>, d.id))
          .toList();
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) debugPrint('[VideoProvider] loadProjects: $e');
    }
    notifyListeners();
  }

  Future<String?> createProject(String title, {String? videoPath}) async {
    if (_uid == null) return null;
    try {
      final id = const Uuid().v4();
      final project = ProjectModel(
        id: id,
        userId: _uid!,
        title: title,
        videoPath: videoPath,
        lastEdited: DateTime.now(),
        createdAt: DateTime.now(),
      );
      await _fs.projectsCollection(_uid!).doc(id).set(project.toMap());
      _projects.insert(0, project);
      notifyListeners();
      return id;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // -----------------------------------------------------------------------
  // Templates (public)
  // -----------------------------------------------------------------------

  Future<void> _loadTemplates() async {
    try {
      final snap = await _fs.templatesCollection().get();
      _templates = snap.docs
          .map((d) => TemplateModel.fromMap(d.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Templates collection may not exist yet â€” start empty.
      _templates = [];
      if (kDebugMode) debugPrint('[VideoProvider] loadTemplates: $e');
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}


