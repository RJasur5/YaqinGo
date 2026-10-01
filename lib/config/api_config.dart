class ApiConfig {
  static const bool isProduction = true; // Toggle this for server deployment
  
  static const String devUrl = 'http://192.168.88.111:8005';
  static const String prodUrl = 'https://yaqingo.uz';
  
  static String get baseUrl => isProduction ? prodUrl : devUrl;
  static String get wsBaseUrl => baseUrl.replaceFirst('http', 'ws');
  
  static String wsNotifications(int id) => '$wsBaseUrl/ws/notifications/$id';

  static String get apiUrl => '$baseUrl/api';

  static String get authRegister => '$apiUrl/auth/register';
  static String get authLogin => '$apiUrl/auth/login';
  static String get authMe => '$apiUrl/auth/me';
  static String get authProfile => '$apiUrl/auth/profile';
  static String get authSendCode => '$apiUrl/auth/send-code';
  static String get authFcmToken => '$apiUrl/auth/fcm-token';
  static String get masters => '$apiUrl/masters';
  static String get masterProfile => '$apiUrl/masters/profile';
  static String get categories => '$apiUrl/categories';
  static String get favorites => '$apiUrl/favorites';
  static String get orders => '$apiUrl/orders';
  static String get ordersAvailable => '$apiUrl/orders/available';
  static String get ordersMy => '$apiUrl/orders/my';

  static String masterDetail(int id) => '$apiUrl/masters/$id';
  static String masterReview(int id) => '$apiUrl/masters/$id/review';
  static String toggleFavorite(int id) => '$apiUrl/favorites/$id';
  static String acceptOrder(int id) => '$apiUrl/orders/$id/accept';
  static String rateClient(int id) => '$apiUrl/orders/$id/rate_client';
  static String clientProfile(int id) => '$apiUrl/clients/$id';
  static String orderChat(int id) => '$apiUrl/orders/$id/chat';
  static String get orderChatList => '$apiUrl/orders/chats';
  
  // Admin
  static String get adminUsers => '$apiUrl/admin/users';
  static String adminUserDetail(int id) => '$apiUrl/admin/users/$id';
  static String get adminOrders => '$apiUrl/admin/orders';
  static String adminOrderDetail(int id) => '$apiUrl/admin/orders/$id';
  static String get adminStats => '$apiUrl/admin/stats';
  
  static String get appReviews => '$apiUrl/app-reviews/';

  // Order tracking & analytics
  static String trackOrderView(int id) => '$apiUrl/orders/$id/view';
  static String trackOrderClick(int id) => '$apiUrl/orders/$id/click';
  static String trackOrderCall(int id) => '$apiUrl/orders/$id/call';

  // Favorite authors/employers
  static String toggleFavoriteAuthor(int authorId) => '$apiUrl/favorites/author/$authorId';
  static String get favoriteAuthorIds => '$apiUrl/favorites/authors/ids';
}


