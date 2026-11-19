/// VYRO AI â€” Data Models


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

final _uuid = const Uuid();

/// Parse a Firestore timestamp value that could be a [Timestamp] (from
/// Firestore) or a [DateTime] (from local maps / round-trips).
DateTime? _parseDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is String) return DateTime.tryParse(value);
  return null;
}

// ============================================================================
// USER
// ============================================================================

class UserModel extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final String? profileImage;
  final String? phoneNumber;
  final String authProvider; // 'email' | 'google' | 'facebook' | 'apple' | 'phone' | 'anonymous'
  final bool emailVerified;
  final String accountStatus; // 'active' | 'suspended' | 'banned'
  final String role; // 'user' | 'admin'
  final SubscriptionTier tier;
  final int credits;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final DateTime? updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.profileImage,
    this.phoneNumber,
    this.authProvider = 'email',
    this.emailVerified = false,
    this.accountStatus = 'active',
    this.role = 'user',
    this.tier = SubscriptionTier.free,
    this.credits = 0,
    required this.createdAt,
    this.lastLogin,
    this.updatedAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String id) {
    return UserModel(
      id: id,
      email: map['email'] ?? '',
      fullName: map['fullName'],
      profileImage: map['profileImage'],
      phoneNumber: map['phoneNumber'],
      authProvider: map['authProvider'] ?? 'email',
      emailVerified: map['emailVerified'] ?? false,
      accountStatus: map['accountStatus'] ?? 'active',
      role: map['role'] ?? 'user',
      tier: SubscriptionTier.values.firstWhere(
        (e) => e.name == (map['tier'] ?? 'free'),
        orElse: () => SubscriptionTier.free,
      ),
      credits: (map['credits'] ?? 0) as int,
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      lastLogin: _parseDate(map['lastLogin']),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'fullName': fullName,
      'profileImage': profileImage,
      'phoneNumber': phoneNumber,
      'authProvider': authProvider,
      'emailVerified': emailVerified,
      'accountStatus': accountStatus,
      'role': role,
      'tier': tier.name,
      'credits': credits,
      'createdAt': createdAt,
      'lastLogin': lastLogin,
      'updatedAt': updatedAt ?? DateTime.now(),
    };
  }

  UserModel copyWith({
    String? email,
    String? fullName,
    String? profileImage,
    String? phoneNumber,
    String? authProvider,
    bool? emailVerified,
    String? accountStatus,
    String? role,
    SubscriptionTier? tier,
    int? credits,
    DateTime? createdAt,
    DateTime? lastLogin,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      profileImage: profileImage ?? this.profileImage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      authProvider: authProvider ?? this.authProvider,
      emailVerified: emailVerified ?? this.emailVerified,
      accountStatus: accountStatus ?? this.accountStatus,
      role: role ?? this.role,
      tier: tier ?? this.tier,
      credits: credits ?? this.credits,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    profileImage,
    phoneNumber,
    authProvider,
    emailVerified,
    accountStatus,
    role,
    tier,
    credits,
    createdAt,
    lastLogin,
    updatedAt,
  ];
}

// ============================================================================
// SUBSCRIPTION TIER
// ============================================================================

enum SubscriptionTier { free, pro, enterprise }

extension SubscriptionTierExt on SubscriptionTier {
  String get label {
    switch (this) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.pro:
        return 'Pro';
      case SubscriptionTier.enterprise:
        return 'Enterprise';
    }
  }

  int get monthlyPriceCents {
    switch (this) {
      case SubscriptionTier.free:
        return 0;
      case SubscriptionTier.pro:
        return 999; // $9.99
      case SubscriptionTier.enterprise:
        return 2999; // $29.99
    }
  }

  int get creditsPerMonth {
    switch (this) {
      case SubscriptionTier.free:
        return 5;
      case SubscriptionTier.pro:
        return 100;
      case SubscriptionTier.enterprise:
        return 1000;
    }
  }

  bool get canGenerateAiVideo => this != SubscriptionTier.free;
  bool get canExportHd => this != SubscriptionTier.free;
  bool get canRemoveWatermark => this != SubscriptionTier.free;
}

// ============================================================================
// VIDEO (generated / project output)
// ============================================================================

class VideoModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? localPath;
  final String? storageUrl;
  final String? thumbnailUrl;
  final String? previewUrl;
  final AiGenerationType type;
  final int durationSeconds;
  final int width;
  final int height;
  final double fileSizeMb;
  final String? prompt;
  final List<String> tags;
  final bool isPublic;
  final bool isExported;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const VideoModel({
    required this.id,
    required this.userId,
    required this.title,
    this.localPath,
    this.storageUrl,
    this.thumbnailUrl,
    this.previewUrl,
    required this.type,
    this.durationSeconds = 0,
    this.width = 1080,
    this.height = 1920,
    this.fileSizeMb = 0,
    this.prompt,
    this.tags = const [],
    this.isPublic = false,
    this.isExported = false,
    required this.createdAt,
    this.updatedAt,
  });

  factory VideoModel.fromMap(Map<String, dynamic> map, String id) {
    return VideoModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? 'Untitled',
      localPath: map['localPath'],
      storageUrl: map['storageUrl'],
      thumbnailUrl: map['thumbnailUrl'],
      previewUrl: map['previewUrl'],
      type: AiGenerationType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'text_to_video'),
        orElse: () => AiGenerationType.textToVideo,
      ),
      durationSeconds: (map['durationSeconds'] ?? 0) as int,
      width: (map['width'] ?? 1080) as int,
      height: (map['height'] ?? 1920) as int,
      fileSizeMb: ((map['fileSizeMb'] ?? 0) as num).toDouble(),
      prompt: map['prompt'],
      tags: List<String>.from(map['tags'] ?? []),
      isPublic: map['isPublic'] ?? false,
      isExported: map['isExported'] ?? false,
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'localPath': localPath,
      'storageUrl': storageUrl,
      'thumbnailUrl': thumbnailUrl,
      'previewUrl': previewUrl,
      'type': type.name,
      'durationSeconds': durationSeconds,
      'width': width,
      'height': height,
      'fileSizeMb': fileSizeMb,
      'prompt': prompt,
      'tags': tags,
      'isPublic': isPublic,
      'isExported': isExported,
      'createdAt': createdAt,
      'updatedAt': updatedAt ?? DateTime.now(),
    };
  }

  VideoModel copyWith({
    String? title,
    String? localPath,
    String? storageUrl,
    String? thumbnailUrl,
    String? previewUrl,
    AiGenerationType? type,
    int? durationSeconds,
    int? width,
    int? height,
    double? fileSizeMb,
    String? prompt,
    List<String>? tags,
    bool? isPublic,
    bool? isExported,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VideoModel(
      id: id,
      userId: userId,
      title: title ?? this.title,
      localPath: localPath ?? this.localPath,
      storageUrl: storageUrl ?? this.storageUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      previewUrl: previewUrl ?? this.previewUrl,
      type: type ?? this.type,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      width: width ?? this.width,
      height: height ?? this.height,
      fileSizeMb: fileSizeMb ?? this.fileSizeMb,
      prompt: prompt ?? this.prompt,
      tags: tags ?? this.tags,
      isPublic: isPublic ?? this.isPublic,
      isExported: isExported ?? this.isExported,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    localPath,
    storageUrl,
    thumbnailUrl,
    previewUrl,
    type,
    durationSeconds,
    width,
    height,
    fileSizeMb,
    prompt,
    tags,
    isPublic,
    isExported,
    createdAt,
    updatedAt,
  ];
}

// ============================================================================
// PROJECT (editable project in editor)
// ============================================================================

class ProjectModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? videoPath;
  final double progress; // 0..1
  final DateTime lastEdited;
  final DateTime createdAt;
  final String? thumbnailUrl;

  const ProjectModel({
    required this.id,
    required this.userId,
    required this.title,
    this.videoPath,
    this.progress = 0,
    required this.lastEdited,
    required this.createdAt,
    this.thumbnailUrl,
  });

  factory ProjectModel.fromMap(Map<String, dynamic> map, String id) {
    return ProjectModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? 'Untitled Project',
      videoPath: map['videoPath'],
      progress: ((map['progress'] ?? 0) as num).toDouble(),
      lastEdited: _parseDate(map['lastEdited']) ?? DateTime.now(),
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      thumbnailUrl: map['thumbnailUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'videoPath': videoPath,
      'progress': progress,
      'lastEdited': lastEdited,
      'createdAt': createdAt,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    videoPath,
    progress,
    lastEdited,
    createdAt,
    thumbnailUrl,
  ];
}

// ============================================================================
// TEMPLATE
// ============================================================================

class TemplateModel extends Equatable {
  final String id;
  final String title;
  final String category;
  final String thumbnailUrl;
  final String previewVideoUrl;
  final int durationSeconds;
  final bool isPremium;
  final int creditsCost;
  final List<String> tags;

  const TemplateModel({
    required this.id,
    required this.title,
    required this.category,
    required this.thumbnailUrl,
    required this.previewVideoUrl,
    this.durationSeconds = 15,
    this.isPremium = false,
    this.creditsCost = 0,
    this.tags = const [],
  });

  factory TemplateModel.fromMap(Map<String, dynamic> map) {
    return TemplateModel(
      id: map['id'] ?? '',
      title: map['title'] ?? 'Template',
      category: map['category'] ?? 'General',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      previewVideoUrl: map['previewVideoUrl'] ?? '',
      durationSeconds: (map['durationSeconds'] ?? 15) as int,
      isPremium: map['isPremium'] ?? false,
      creditsCost: (map['creditsCost'] ?? 0) as int,
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'thumbnailUrl': thumbnailUrl,
      'previewVideoUrl': previewVideoUrl,
      'durationSeconds': durationSeconds,
      'isPremium': isPremium,
      'creditsCost': creditsCost,
      'tags': tags,
    };
  }

  @override
  List<Object?> get props => [
    id,
    title,
    category,
    thumbnailUrl,
    previewVideoUrl,
    durationSeconds,
    isPremium,
    creditsCost,
    tags,
  ];
}

// ============================================================================
// AI GENERATION JOB
// ============================================================================

enum AiGenerationType {
  textToVideo,
  imageToVideo,
  scriptToVideo,
  aiImage,
  aiVoice,
}

enum AiJobStatus {
  queued,
  processing,
  completed,
  failed,
  cancelled,
}

class AiJobModel extends Equatable {
  final String id;
  final String userId;
  final AiGenerationType type;
  final AiJobStatus status;
  final String prompt;
  final String? imageUrl; // input image for image-to-video
  final String? resultUrl;
  final String? thumbnailUrl;
  final int creditsCost;
  final String? errorMessage;
  final int progressPercent; // 0..100
  final DateTime createdAt;
  final DateTime? completedAt;

  const AiJobModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.prompt,
    this.imageUrl,
    this.resultUrl,
    this.thumbnailUrl,
    this.creditsCost = 0,
    this.errorMessage,
    this.progressPercent = 0,
    required this.createdAt,
    this.completedAt,
  });

  factory AiJobModel.fromMap(Map<String, dynamic> map, String id) {
    return AiJobModel(
      id: id,
      userId: map['userId'] ?? '',
      type: AiGenerationType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'text_to_video'),
        orElse: () => AiGenerationType.textToVideo,
      ),
      status: AiJobStatus.values.firstWhere(
        (e) => e.name == (map['status'] ?? 'queued'),
        orElse: () => AiJobStatus.queued,
      ),
      prompt: map['prompt'] ?? '',
      imageUrl: map['imageUrl'],
      resultUrl: map['resultUrl'],
      thumbnailUrl: map['thumbnailUrl'],
      creditsCost: (map['creditsCost'] ?? 0) as int,
      errorMessage: map['errorMessage'],
      progressPercent: (map['progressPercent'] ?? 0) as int,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      completedAt: _parseDate(map['completedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.name,
      'status': status.name,
      'prompt': prompt,
      'imageUrl': imageUrl,
      'resultUrl': resultUrl,
      'thumbnailUrl': thumbnailUrl,
      'creditsCost': creditsCost,
      'errorMessage': errorMessage,
      'progressPercent': progressPercent,
      'createdAt': createdAt,
      'completedAt': completedAt,
    };
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    status,
    prompt,
    imageUrl,
    resultUrl,
    thumbnailUrl,
    creditsCost,
    errorMessage,
    progressPercent,
    createdAt,
    completedAt,
  ];
}

// ============================================================================
// SUBSCRIPTION / PURCHASE RECORD
// ============================================================================

class SubscriptionModel extends Equatable {
  final String id;
  final String userId;
  final String productId;
  final SubscriptionTier tier;
  final DateTime startDate;
  final DateTime? expiryDate;
  final bool isActive;

  const SubscriptionModel({
    required this.id,
    required this.userId,
    required this.productId,
    required this.tier,
    required this.startDate,
    this.expiryDate,
    this.isActive = false,
  });

  factory SubscriptionModel.fromMap(Map<String, dynamic> map, String id) {
    return SubscriptionModel(
      id: id,
      userId: map['userId'] ?? '',
      productId: map['productId'] ?? '',
      tier: SubscriptionTier.values.firstWhere(
        (e) => e.name == (map['tier'] ?? 'free'),
        orElse: () => SubscriptionTier.free,
      ),
      startDate: _parseDate(map['startDate']) ?? DateTime.now(),
      expiryDate: _parseDate(map['expiryDate']),
      isActive: map['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productId': productId,
      'tier': tier.name,
      'startDate': startDate,
      'expiryDate': expiryDate,
      'isActive': isActive,
    };
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    productId,
    tier,
    startDate,
    expiryDate,
    isActive,
  ];
}

// ============================================================================
// USER PROFILE (extended profile data)
// Collection: user_profiles/{uid}
// ============================================================================

class UserProfileModel extends Equatable {
  final String uid;
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? bio;
  final String? country;
  final String? language;
  final bool notificationsEnabled;
  final bool marketingEmails;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfileModel({
    required this.uid,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.profileImageUrl,
    this.bio,
    this.country,
    this.language,
    this.notificationsEnabled = true,
    this.marketingEmails = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserProfileModel.fromMap(Map<String, dynamic> map, String id) {
    return UserProfileModel(
      uid: id,
      fullName: map['fullName'],
      email: map['email'],
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      bio: map['bio'],
      country: map['country'],
      language: map['language'],
      notificationsEnabled: map['notificationsEnabled'] ?? true,
      marketingEmails: map['marketingEmails'] ?? false,
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'country': country,
      'language': language,
      'notificationsEnabled': notificationsEnabled,
      'marketingEmails': marketingEmails,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  @override
  List<Object?> get props => [
    uid,
    fullName,
    email,
    phoneNumber,
    profileImageUrl,
    bio,
    country,
    language,
    notificationsEnabled,
    marketingEmails,
    createdAt,
    updatedAt,
  ];
}

// ============================================================================
// USER PROJECT (editable project)
// Collection: user_projects/{projectId}
// ============================================================================

class UserProjectModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String? description;
  final String? videoStorageUrl;
  final String? thumbnailStorageUrl;
  final int durationSeconds;
  final int width;
  final int height;
  final double fileSizeMb;
  final bool isExported;
  final bool isPublic;
  final DateTime createdAt;
  final DateTime lastEdited;
  final DateTime? updatedAt;

  const UserProjectModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description,
    this.videoStorageUrl,
    this.thumbnailStorageUrl,
    this.durationSeconds = 0,
    this.width = 1080,
    this.height = 1920,
    this.fileSizeMb = 0,
    this.isExported = false,
    this.isPublic = false,
    required this.createdAt,
    required this.lastEdited,
    this.updatedAt,
  });

  factory UserProjectModel.fromMap(Map<String, dynamic> map, String id) {
    return UserProjectModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? 'Untitled Project',
      description: map['description'],
      videoStorageUrl: map['videoStorageUrl'],
      thumbnailStorageUrl: map['thumbnailStorageUrl'],
      durationSeconds: (map['durationSeconds'] ?? 0) as int,
      width: (map['width'] ?? 1080) as int,
      height: (map['height'] ?? 1920) as int,
      fileSizeMb: ((map['fileSizeMb'] ?? 0) as num).toDouble(),
      isExported: map['isExported'] ?? false,
      isPublic: map['isPublic'] ?? false,
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
      lastEdited: _parseDate(map['lastEdited']) ?? DateTime.now(),
      updatedAt: _parseDate(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'description': description,
      'videoStorageUrl': videoStorageUrl,
      'thumbnailStorageUrl': thumbnailStorageUrl,
      'durationSeconds': durationSeconds,
      'width': width,
      'height': height,
      'fileSizeMb': fileSizeMb,
      'isExported': isExported,
      'isPublic': isPublic,
      'createdAt': createdAt,
      'lastEdited': lastEdited,
      'updatedAt': updatedAt,
    };
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    description,
    videoStorageUrl,
    thumbnailStorageUrl,
    durationSeconds,
    width,
    height,
    fileSizeMb,
    isExported,
    isPublic,
    createdAt,
    lastEdited,
    updatedAt,
  ];
}

// ============================================================================
// GENERATED STORY
// Collection: generated_stories/{storyId}
// ============================================================================

class GeneratedStoryModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String prompt;
  final String? storyText;
  final String? imageStorageUrl;
  final String? audioStorageUrl;
  final int durationSeconds;
  final int creditsCost;
  final DateTime createdAt;

  const GeneratedStoryModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.prompt,
    this.storyText,
    this.imageStorageUrl,
    this.audioStorageUrl,
    this.durationSeconds = 0,
    this.creditsCost = 0,
    required this.createdAt,
  });

  factory GeneratedStoryModel.fromMap(Map<String, dynamic> map, String id) {
    return GeneratedStoryModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? 'Untitled Story',
      prompt: map['prompt'] ?? '',
      storyText: map['storyText'],
      imageStorageUrl: map['imageStorageUrl'],
      audioStorageUrl: map['audioStorageUrl'],
      durationSeconds: (map['durationSeconds'] ?? 0) as int,
      creditsCost: (map['creditsCost'] ?? 0) as int,
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'prompt': prompt,
      'storyText': storyText,
      'imageStorageUrl': imageStorageUrl,
      'audioStorageUrl': audioStorageUrl,
      'durationSeconds': durationSeconds,
      'creditsCost': creditsCost,
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    prompt,
    storyText,
    imageStorageUrl,
    audioStorageUrl,
    durationSeconds,
    creditsCost,
    createdAt,
  ];
}

// ============================================================================
// GENERATED VIDEO
// Collection: generated_videos/{videoId}
// ============================================================================

class GeneratedVideoModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String prompt;
  final String? videoStorageUrl;
  final String? thumbnailStorageUrl;
  final AiGenerationType type;
  final int durationSeconds;
  final int width;
  final int height;
  final double fileSizeMb;
  final int creditsCost;
  final DateTime createdAt;

  const GeneratedVideoModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.prompt,
    this.videoStorageUrl,
    this.thumbnailStorageUrl,
    required this.type,
    this.durationSeconds = 0,
    this.width = 1080,
    this.height = 1920,
    this.fileSizeMb = 0,
    this.creditsCost = 0,
    required this.createdAt,
  });

  factory GeneratedVideoModel.fromMap(Map<String, dynamic> map, String id) {
    return GeneratedVideoModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? 'Untitled Video',
      prompt: map['prompt'] ?? '',
      videoStorageUrl: map['videoStorageUrl'],
      thumbnailStorageUrl: map['thumbnailStorageUrl'],
      type: AiGenerationType.values.firstWhere(
        (e) => e.name == (map['type'] ?? 'text_to_video'),
        orElse: () => AiGenerationType.textToVideo,
      ),
      durationSeconds: (map['durationSeconds'] ?? 0) as int,
      width: (map['width'] ?? 1080) as int,
      height: (map['height'] ?? 1920) as int,
      fileSizeMb: ((map['fileSizeMb'] ?? 0) as num).toDouble(),
      creditsCost: (map['creditsCost'] ?? 0) as int,
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'prompt': prompt,
      'videoStorageUrl': videoStorageUrl,
      'thumbnailStorageUrl': thumbnailStorageUrl,
      'type': type.name,
      'durationSeconds': durationSeconds,
      'width': width,
      'height': height,
      'fileSizeMb': fileSizeMb,
      'creditsCost': creditsCost,
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    prompt,
    videoStorageUrl,
    thumbnailStorageUrl,
    type,
    durationSeconds,
    width,
    height,
    fileSizeMb,
    creditsCost,
    createdAt,
  ];
}

// ============================================================================
// GENERATED IMAGE
// Collection: generated_images/{imageId}
// ============================================================================

class GeneratedImageModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final String prompt;
  final String? imageStorageUrl;
  final String? thumbnailStorageUrl;
  final int width;
  final int height;
  final double fileSizeMb;
  final int creditsCost;
  final DateTime createdAt;

  const GeneratedImageModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.prompt,
    this.imageStorageUrl,
    this.thumbnailStorageUrl,
    this.width = 1024,
    this.height = 1024,
    this.fileSizeMb = 0,
    this.creditsCost = 0,
    required this.createdAt,
  });

  factory GeneratedImageModel.fromMap(Map<String, dynamic> map, String id) {
    return GeneratedImageModel(
      id: id,
      userId: map['userId'] ?? '',
      title: map['title'] ?? 'Untitled Image',
      prompt: map['prompt'] ?? '',
      imageStorageUrl: map['imageStorageUrl'],
      thumbnailStorageUrl: map['thumbnailStorageUrl'],
      width: (map['width'] ?? 1024) as int,
      height: (map['height'] ?? 1024) as int,
      fileSizeMb: ((map['fileSizeMb'] ?? 0) as num).toDouble(),
      creditsCost: (map['creditsCost'] ?? 0) as int,
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'title': title,
      'prompt': prompt,
      'imageStorageUrl': imageStorageUrl,
      'thumbnailStorageUrl': thumbnailStorageUrl,
      'width': width,
      'height': height,
      'fileSizeMb': fileSizeMb,
      'creditsCost': creditsCost,
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    title,
    prompt,
    imageStorageUrl,
    thumbnailStorageUrl,
    width,
    height,
    fileSizeMb,
    creditsCost,
    createdAt,
  ];
}

// ============================================================================
// USER CREDITS
// Collection: user_credits/{uid}
// ============================================================================

class UserCreditsModel extends Equatable {
  final String uid;
  final int balance;
  final int totalEarned;
  final int totalSpent;
  final DateTime lastUpdated;

  const UserCreditsModel({
    required this.uid,
    this.balance = 0,
    this.totalEarned = 0,
    this.totalSpent = 0,
    required this.lastUpdated,
  });

  factory UserCreditsModel.fromMap(Map<String, dynamic> map, String id) {
    return UserCreditsModel(
      uid: id,
      balance: (map['balance'] ?? 0) as int,
      totalEarned: (map['totalEarned'] ?? 0) as int,
      totalSpent: (map['totalSpent'] ?? 0) as int,
      lastUpdated: _parseDate(map['lastUpdated']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'balance': balance,
      'totalEarned': totalEarned,
      'totalSpent': totalSpent,
      'lastUpdated': lastUpdated,
    };
  }

  @override
  List<Object?> get props => [
    uid,
    balance,
    totalEarned,
    totalSpent,
    lastUpdated,
  ];
}

// ============================================================================
// TRANSACTION
// Collection: transactions/{transactionId}
// ============================================================================

class TransactionModel extends Equatable {
  final String id;
  final String userId;
  final String type; // 'purchase' | 'spend' | 'refund' | 'bonus'
  final int amount;
  final int credits;
  final String? description;
  final String? referenceId; // orderId, jobId, etc.
  final DateTime createdAt;

  const TransactionModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.amount,
    required this.credits,
    this.description,
    this.referenceId,
    required this.createdAt,
  });

  factory TransactionModel.fromMap(Map<String, dynamic> map, String id) {
    return TransactionModel(
      id: id,
      userId: map['userId'] ?? '',
      type: map['type'] ?? 'purchase',
      amount: (map['amount'] ?? 0) as int,
      credits: (map['credits'] ?? 0) as int,
      description: map['description'],
      referenceId: map['referenceId'],
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type,
      'amount': amount,
      'credits': credits,
      'description': description,
      'referenceId': referenceId,
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    type,
    amount,
    credits,
    description,
    referenceId,
    createdAt,
  ];
}

// ============================================================================
// LOGIN ACTIVITY
// Collection: login_activity/{activityId}
// ============================================================================

class LoginActivityModel extends Equatable {
  final String id;
  final String userId;
  final String provider; // 'email' | 'google' | 'facebook' | 'apple' | 'phone'
  final String? ipAddress;
  final String? deviceInfo;
  final bool success;
  final String? failureReason;
  final DateTime createdAt;

  const LoginActivityModel({
    required this.id,
    required this.userId,
    required this.provider,
    this.ipAddress,
    this.deviceInfo,
    this.success = true,
    this.failureReason,
    required this.createdAt,
  });

  factory LoginActivityModel.fromMap(Map<String, dynamic> map, String id) {
    return LoginActivityModel(
      id: id,
      userId: map['userId'] ?? '',
      provider: map['provider'] ?? 'email',
      ipAddress: map['ipAddress'],
      deviceInfo: map['deviceInfo'],
      success: map['success'] ?? true,
      failureReason: map['failureReason'],
      createdAt: _parseDate(map['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'provider': provider,
      'ipAddress': ipAddress,
      'deviceInfo': deviceInfo,
      'success': success,
      'failureReason': failureReason,
      'createdAt': createdAt,
    };
  }

  @override
  List<Object?> get props => [
    id,
    userId,
    provider,
    ipAddress,
    deviceInfo,
    success,
    failureReason,
    createdAt,
  ];
}
