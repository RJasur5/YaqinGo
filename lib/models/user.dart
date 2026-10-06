import 'master.dart';

class UserModel {
  final int id;
  final String name;
  final String phone;
  final String role;
  final String? avatar;
  final String? city;
  final String lang;
  final double clientRating;
  final int clientReviewsCount;
  final bool isBlocked;
  final String accountType; // 'person' or 'company'
  final String? companyLogo;
  final String? companyBanner;
  final String? companyDescription;
  final double? latitude;
  final double? longitude;
  final bool canManageBranches;
  final List<Map<String, dynamic>> companyBranches;
  final Map<String, dynamic>? managedBranch;
  final MasterModel? masterProfile;
  final List<Map<String, dynamic>>? reviewStats;

  UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.role,
    this.avatar,
    this.city,
    this.lang = 'ru',
    this.clientRating = 0.0,
    this.clientReviewsCount = 0,
    this.isBlocked = false,
    this.accountType = 'person',
    this.companyLogo,
    this.companyBanner,
    this.companyDescription,
    this.latitude,
    this.longitude,
    this.canManageBranches = false,
    this.companyBranches = const [],
    this.managedBranch,
    this.masterProfile,
    this.reviewStats,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'client',
      avatar: json['avatar'],
      city: json['city'],
      lang: json['lang'] ?? 'ru',
      clientRating: (json['client_rating'] ?? 0.0).toDouble(),
      clientReviewsCount: json['client_reviews_count'] ?? 0,
      isBlocked: json['is_blocked'] ?? false,
      accountType: (json['account_type'] == 'company') ? 'company' : 'person',
      companyLogo: json['company_logo'],
      companyBanner: json['company_banner'],
      companyDescription: json['company_description'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      canManageBranches: json['can_manage_branches'] ?? false,
      companyBranches: json['company_branches'] != null
          ? List<Map<String, dynamic>>.from(json['company_branches'])
          : const [],
      managedBranch: json['managed_branch'] != null
          ? Map<String, dynamic>.from(json['managed_branch'])
          : null,
      masterProfile: json['master_profile'] != null ? MasterModel.fromJson(json['master_profile']) : null,
      reviewStats: json['review_stats'] != null ? List<Map<String, dynamic>>.from(json['review_stats']) : null,
    );
  }

  bool get isMaster => role == 'master' || role == 'admin';
  bool get isAdmin => role == 'admin';
  bool get isCompany => accountType == 'company';
  bool get isBranchAdmin => managedBranch != null && managedBranch!['branch_id'] != null;
}

class ClientReviewModel {
  final int id;
  final int clientId;
  final int masterId;
  final String masterName;
  final String? masterAvatar;
  final int rating;
  final String? comment;
  final String? createdAt;

  ClientReviewModel({
    required this.id,
    required this.clientId,
    required this.masterId,
    required this.masterName,
    this.masterAvatar,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  factory ClientReviewModel.fromJson(Map<String, dynamic> json) {
    return ClientReviewModel(
      id: json['id'],
      clientId: json['client_id'],
      masterId: json['master_id'],
      masterName: json['master_name'] ?? '',
      masterAvatar: json['master_avatar'],
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt: json['created_at'],
    );
  }
}
