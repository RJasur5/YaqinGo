class SubscriptionModel {
  final int userId;
  final String userRole;
  final String planName;
  final int adsLimit;
  final int adsUsed;
  final DateTime expiresAt;
  final bool isActive;

  SubscriptionModel({
    required this.userId,
    required this.userRole,
    required this.planName,
    required this.adsLimit,
    required this.adsUsed,
    required this.expiresAt,
    required this.isActive,
  });

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) {
    return SubscriptionModel(
      userId: json['user_id'],
      userRole: json['user_role'] ?? 'client',
      planName: json['plan_name'] ?? 'none',
      adsLimit: json['ads_limit'] ?? 0,
      adsUsed: json['ads_used'] ?? 0,
      expiresAt: DateTime.parse(json['expires_at']),
      isActive: json['is_active'] ?? false,
    );
  }

  bool get isTrial => planName == 'trial';
  
  String get planTitle {
    switch (planName) {
      case 'trial': return 'Trial (3 min)';
      case 'day': return 'Daily';
      case 'week': return 'Weekly';
      case 'month': return 'Monthly';
      default: return 'None';
    }
  }

  int get remainingAds => adsLimit - adsUsed;
}
