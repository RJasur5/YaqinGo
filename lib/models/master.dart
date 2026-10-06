class MasterModel {
  final int id;
  final int userId;
  final String userName;
  final String? userAvatar;
  final int subcategoryId;
  final String subcategoryNameRu;
  final String subcategoryNameUz;
  final String categoryNameRu;
  final String categoryNameUz;
  final String? description;
  final int experienceYears;
  final double? hourlyRate;
  final String? city;
  final String? district;
  final String? address;
  final List<String> skills;
  final double rating;
  final int reviewsCount;
  final bool isAvailable;
  final List<String> portfolioImages;
  final List<ReviewModel>? reviews;
  final String? phone;
  final bool canContact;
  final String accountType;
  final String? companyLogo;
  final String? companyBanner;
  final double? latitude;
  final double? longitude;
  final List<dynamic>? languages;
  final List<String>? basicSkills;
  final Map<String, dynamic>? driverLicense;
  final List<dynamic>? education;
  final List<dynamic>? workExperience;
  final Map<String, dynamic>? disability;
  final bool isFavorite;

  MasterModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userAvatar,
    required this.subcategoryId,
    required this.subcategoryNameRu,
    required this.subcategoryNameUz,
    required this.categoryNameRu,
    required this.categoryNameUz,
    this.description,
    this.experienceYears = 0,
    this.hourlyRate,
    this.city,
    this.district,
    this.address,
    this.skills = const [],
    this.rating = 0.0,
    this.reviewsCount = 0,
    this.isAvailable = true,
    this.portfolioImages = const [],
    this.reviews,
    this.phone,
    this.canContact = true,
    this.accountType = 'person',
    this.companyLogo,
    this.companyBanner,
    this.latitude,
    this.longitude,
    this.languages,
    this.basicSkills,
    this.driverLicense,
    this.education,
    this.workExperience,
    this.disability,
    this.isFavorite = false,
  });

  factory MasterModel.fromJson(Map<String, dynamic> json) {
    return MasterModel(
      id: json['id'],
      userId: json['user_id'],
      userName: json['user_name'] ?? '',
      userAvatar: json['user_avatar'],
      subcategoryId: json['subcategory_id'],
      subcategoryNameRu: json['subcategory_name_ru'] ?? '',
      subcategoryNameUz: json['subcategory_name_uz'] ?? '',
      categoryNameRu: json['category_name_ru'] ?? '',
      categoryNameUz: json['category_name_uz'] ?? '',
      description: json['description'],
      experienceYears: json['experience_years'] ?? 0,
      hourlyRate: json['hourly_rate']?.toDouble(),
      city: json['city'],
      district: json['district'],
      address: json['address'],
      skills: List<String>.from(json['skills'] ?? []),
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewsCount: json['reviews_count'] ?? 0,
      isAvailable: json['is_available'] ?? true,
      portfolioImages: List<String>.from(json['portfolio_images'] ?? []),
      reviews: json['reviews'] != null
          ? (json['reviews'] as List).map((r) => ReviewModel.fromJson(r)).toList()
          : null,
      phone: json['phone'],
      canContact: json['can_contact'] ?? true,
      accountType: json['account_type'] ?? 'person',
      companyLogo: json['company_logo'],
      companyBanner: json['company_banner'],
      latitude: json['latitude'] != null
          ? (json['latitude'] is num
              ? (json['latitude'] as num).toDouble()
              : double.tryParse(json['latitude'].toString()))
          : null,
      longitude: json['longitude'] != null
          ? (json['longitude'] is num
              ? (json['longitude'] as num).toDouble()
              : double.tryParse(json['longitude'].toString()))
          : null,
      languages: json['languages'] != null ? List<dynamic>.from(json['languages']) : null,
      basicSkills: json['basic_skills'] != null ? List<String>.from(json['basic_skills']) : null,
      driverLicense: json['driver_license'] is Map
          ? Map<String, dynamic>.from(json['driver_license'] as Map)
          : null,
      education: json['education'] != null ? List<dynamic>.from(json['education']) : null,
      workExperience: json['work_experience'] != null ? List<dynamic>.from(json['work_experience']) : null,
      disability: json['disability'] is Map
          ? Map<String, dynamic>.from(json['disability'] as Map)
          : null,
      isFavorite: json['is_favorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'user_name': userName,
      'user_avatar': userAvatar,
      'subcategory_id': subcategoryId,
      'subcategory_name_ru': subcategoryNameRu,
      'subcategory_name_uz': subcategoryNameUz,
      'category_name_ru': categoryNameRu,
      'category_name_uz': categoryNameUz,
      'description': description,
      'experience_years': experienceYears,
      'hourly_rate': hourlyRate,
      'city': city,
      'district': district,
      'address': address,
      'skills': skills,
      'rating': rating,
      'reviews_count': reviewsCount,
      'is_available': isAvailable,
      'portfolio_images': portfolioImages,
      'phone': phone,
      'account_type': accountType,
      'company_logo': companyLogo,
      'company_banner': companyBanner,
      'latitude': latitude,
      'longitude': longitude,
      'languages': languages,
      'basic_skills': basicSkills,
      'driver_license': driverLicense,
      'education': education,
      'work_experience': workExperience,
      'disability': disability,
      'is_favorite': isFavorite,
    };
  }

  String subcategoryName(String lang) =>
      lang == 'ru' ? subcategoryNameRu : subcategoryNameUz;
  String categoryName(String lang) =>
      lang == 'ru' ? categoryNameRu : categoryNameUz;

  String get initials {
    final cleanName = userName.trim();
    if (cleanName.isEmpty) return '?';
    final parts = cleanName.split(' ');
    if (parts.length >= 2) {
      final p1 = parts[0];
      final p2 = parts[1];
      if (p1.isNotEmpty && p2.isNotEmpty) {
        return '${p1[0]}${p2[0]}'.toUpperCase();
      }
      if (p1.isNotEmpty) return p1[0].toUpperCase();
    }
    return cleanName.isNotEmpty ? cleanName[0].toUpperCase() : '?';
  }
}

class ReviewModel {
  final int id;
  final int masterId;
  final int clientId;
  final String clientName;
  final String? clientAvatar;
  final int rating;
  final String? comment;
  final String? createdAt;

  ReviewModel({
    required this.id,
    required this.masterId,
    required this.clientId,
    required this.clientName,
    this.clientAvatar,
    required this.rating,
    this.comment,
    this.createdAt,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'],
      masterId: json['master_id'],
      clientId: json['client_id'],
      clientName: json['client_name'] ?? '',
      clientAvatar: json['client_avatar'],
      rating: json['rating'] ?? 0,
      comment: json['comment'],
      createdAt: json['created_at'],
    );
  }
}
