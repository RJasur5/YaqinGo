import 'package:intl/intl.dart';

class OrderResponse {
  final int id;
  final int clientId;
  final String clientName;
  final String? clientPhone;
  final double clientRating;
  final int clientReviewsCount;
  final String? clientAvatar;
  final int? masterId;
  final String? masterName;
  final String? masterAvatar;
  final int subcategoryId;
  final String subcategoryNameRu;
  final String subcategoryNameUz;
  final String description;
  final String city;
  final String? district;
  final double? price;
  final String status;
  final DateTime createdAt;
  final bool isClientReviewed;
  final bool isMasterReviewed;
  final bool includeLunch;
  final bool includeTaxi;
  final bool canChat;
  final bool isCompany;
  final int applicantsCount;

  OrderResponse({
    required this.id,
    required this.clientId,
    required this.clientName,
    this.clientPhone,
    this.clientRating = 0.0,
    this.clientReviewsCount = 0,
    this.clientAvatar,
    this.masterId,
    this.masterName,
    this.masterAvatar,
    required this.subcategoryId,
    required this.subcategoryNameRu,
    required this.subcategoryNameUz,
    required this.description,
    required this.city,
    this.district,
    this.price,
    required this.status,
    required this.createdAt,
    this.isClientReviewed = false,
    this.isMasterReviewed = false,
    this.includeLunch = false,
    this.includeTaxi = false,
    this.canChat = true,
    this.isCompany = false,
    this.applicantsCount = 0,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      id: json['id'],
      clientId: json['client_id'],
      clientName: json['client_name'] ?? '',
      clientPhone: json['client_phone'],
      clientRating: (json['client_rating'] ?? 0.0).toDouble(),
      clientReviewsCount: json['client_reviews_count'] ?? 0,
      clientAvatar: json['client_avatar'],
      masterId: json['master_id'],
      masterName: json['master_name'],
      masterAvatar: json['master_avatar'],
      subcategoryId: json['subcategory_id'],
      subcategoryNameRu: json['subcategory_name_ru'] ?? '',
      subcategoryNameUz: json['subcategory_name_uz'] ?? '',
      description: json['description'] ?? '',
      city: json['city'] ?? '',
      district: json['district'],
      price: json['price']?.toDouble(),
      status: json['status'] ?? 'open',
      createdAt: DateTime.parse(json['created_at']),
      isClientReviewed: json['is_client_reviewed'] ?? false,
      isMasterReviewed: json['is_master_reviewed'] ?? false,
      includeLunch: json['include_lunch'] ?? false,
      includeTaxi: json['include_taxi'] ?? false,
      canChat: json['can_chat'] ?? true,
      isCompany: json['is_company'] ?? false,
      applicantsCount: json['applicants_count'] ?? 0,
    );
  }

  String subcategoryName(String lang) =>
      lang == 'ru' ? subcategoryNameRu : subcategoryNameUz;
}
