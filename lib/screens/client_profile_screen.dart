import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../config/api_config.dart';
import '../config/localization.dart';
import '../utils/formatters.dart';
import '../services/api_service.dart';
import '../../widgets/full_screen_image.dart';
import '../../utils/date_utils.dart';

class ClientProfileScreen extends StatefulWidget {
  final int clientId;
  final ApiService apiService;
  final bool hidePhone;
  final String? overridePhone;
  final String? branchId;
  final String? branchName;

  const ClientProfileScreen({
    super.key,
    required this.clientId,
    required this.apiService,
    this.hidePhone = false,
    this.overridePhone,
    this.branchId,
    this.branchName,
  });

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  Map<String, dynamic>? _client;
  List<dynamic> _vacancies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await widget.apiService.getClientProfile(widget.clientId);
      final isCompanyProfile = profile['account_type'] == 'company' ||
          profile['is_company'] == true ||
          (profile['company_banner'] != null && profile['company_banner'].toString().isNotEmpty) ||
          (profile['company_description'] != null && profile['company_description'].toString().isNotEmpty);
      List<dynamic> vacancies = [];
      if (isCompanyProfile) {
        try {
          final queryBranch = (widget.branchId != null && widget.branchId!.isNotEmpty)
              ? widget.branchId
              : widget.branchName;
          List<dynamic> allOrders = [];
          if (queryBranch != null && queryBranch.isNotEmpty) {
            allOrders = await widget.apiService.getAvailableOrders(branchId: queryBranch);
          }
          if (allOrders.isEmpty) {
            allOrders = await widget.apiService.getAvailableOrders(clientId: widget.clientId);
          }
          if ((widget.branchId != null && widget.branchId!.isNotEmpty) ||
              (widget.branchName != null && widget.branchName!.isNotEmpty)) {
            final filtered = allOrders.where((o) {
              final bId = o['branch_id']?.toString();
              final bName = o['branch_name']?.toString();
              if (widget.branchId != null && widget.branchId!.isNotEmpty && bId == widget.branchId) {
                return true;
              }
              if (widget.branchName != null && widget.branchName!.isNotEmpty && bName == widget.branchName) {
                return true;
              }
              return false;
            }).toList();
            vacancies = filtered.isNotEmpty ? filtered : allOrders;
          } else {
            vacancies = allOrders;
          }
        } catch (_) {}
      }
      if (mounted) {
        setState(() {
          _client = profile;
          _vacancies = vacancies;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка загрузки: $e')),
        );
      }
    }
  }

  bool _isCompanyProfile() {
    return _client != null && (
      _client!['account_type'] == 'company' ||
      _client!['is_company'] == true ||
      _vacancies.isNotEmpty ||
      (_client!['company_banner'] != null && _client!['company_banner'].toString().isNotEmpty) ||
      (_client!['company_description'] != null && _client!['company_description'].toString().isNotEmpty)
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompany = _isCompanyProfile();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isCompany
              ? (AppStrings.isRu ? 'Профиль компании' : 'Kompaniya profili')
              : (AppStrings.isRu ? 'Профиль клиента' : 'Mijoz profili'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppTheme.currentGradient(context)),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : _client == null
                ? Center(child: Text(AppStrings.isRu ? 'Профиль не найден' : 'Profil topilmadi'))
                : _buildContent(theme),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    final isCompany = _isCompanyProfile();
    final avatar = _client!['avatar'] ?? _client!['company_logo'];
    final avatarUrl = avatar != null && avatar.toString().isNotEmpty
        ? (avatar.toString().startsWith('http') ? avatar.toString() : '${ApiConfig.baseUrl.replaceAll("/api", "")}$avatar')
        : null;

    final banner = _client!['company_banner'];
    final bannerUrl = banner != null && banner.toString().isNotEmpty
        ? (banner.toString().startsWith('http') ? banner.toString() : '${ApiConfig.baseUrl.replaceAll("/api", "")}$banner')
        : null;

    final createdAt = DateTimeUtils.parseUtc(_client!['created_at']);
    final joinDate = DateTimeUtils.formatMonthYear(createdAt, AppStrings.lang);
    final phone = widget.overridePhone ?? _client!['phone'];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      child: Column(
        children: [
          // Header Card with Cover Banner
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                if (isCompany) ...[
                  // Cover Banner with overlapping squircle logo
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      SizedBox(
                        height: 155,
                        width: double.infinity,
                        child: bannerUrl != null
                            ? GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => FullScreenImage(imageUrl: bannerUrl, tag: 'profile_banner_${widget.clientId}'),
                                    ),
                                  );
                                },
                                child: Hero(
                                  tag: 'profile_banner_${widget.clientId}',
                                  child: Image.network(
                                    bannerUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => _buildDefaultBanner(),
                                  ),
                                ),
                              )
                            : _buildDefaultBanner(),
                      ),
                      // Overlapping Squircle Avatar
                      Positioned(
                        bottom: -45,
                        child: _buildAvatar(avatarUrl, true, theme),
                      ),
                    ],
                  ),
                  const SizedBox(height: 44),
                ] else ...[
                  const SizedBox(height: 24),
                  _buildAvatar(avatarUrl, false, theme),
                  const SizedBox(height: 14),
                ],

                // Name & Info
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: [
                      Text(
                        _client!['name'] ?? '',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 15, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _client!['city'] ?? (AppStrings.isRu ? 'Город не указан' : 'Shahar ko\'rsatilmagan'),
                              style: TextStyle(
                                color: theme.hintColor,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (widget.branchName != null && widget.branchName!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.store_mall_directory_rounded, size: 14, color: Colors.blue),
                              const SizedBox(width: 6),
                              Text(
                                '${AppStrings.isRu ? "Филиал: " : "Filial: "}${widget.branchName}',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (isCompany) ...[
                        const SizedBox(height: 14),

                        // Badges / Highlights Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_vacancies.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.work_outline_rounded, size: 15, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${_vacancies.length} ${AppStrings.isRu ? (_vacancies.length == 1 ? "вакансия" : "вакансии") : "ta vakansiya"}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.star_rounded,
                                    size: 16,
                                    color: Colors.amber.shade700,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${((_client!['client_rating'] as num?)?.toDouble() ?? 0.0).toStringAsFixed(1)} ${AppStrings.isRu ? "Рейтинг" : "Reyting"}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Colors.amber.shade800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ] else ...[
                        const SizedBox(height: 18),
                        Divider(color: theme.dividerColor.withValues(alpha: 0.15)),
                        const SizedBox(height: 10),

                        // Stats Row for personal client
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatCol(
                              AppStrings.isRu ? 'Рейтинг' : 'Reyting',
                              '⭐ ${_client!['client_rating']?.toStringAsFixed(1) ?? '0.0'}',
                              theme,
                            ),
                            Container(width: 1, height: 28, color: theme.dividerColor.withValues(alpha: 0.2)),
                            _buildStatCol(
                              AppStrings.isRu ? 'Отзывы' : 'Sharhlar',
                              '${_client!['client_reviews_count'] ?? 0}',
                              theme,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Company Description Card
          if (isCompany && _client!['company_description'] != null && _client!['company_description'].toString().trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: theme.cardTheme.color ?? theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.12)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.business_center_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        AppStrings.isRu ? 'О компании / Сфера деятельности' : 'Kompaniya haqida / Faoliyat turi',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _client!['company_description'].toString().trim(),
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Open Vacancies Section
          if (isCompany && _vacancies.isNotEmpty) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.work_outline_rounded, color: AppColors.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  widget.branchName != null && widget.branchName!.isNotEmpty
                      ? '${AppStrings.isRu ? "Вакансии филиала" : "Filial vakansiyalari"} (${_vacancies.length})'
                      : '${AppStrings.isRu ? "Открытые вакансии компании" : "Kompaniyaning ochiq vakansiyalari"} (${_vacancies.length})',
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _vacancies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = _vacancies[index];
                final price = item['price'];
                final priceStr = price != null ? '${PriceFormatter.format(price)} ${AppStrings.sum}' : (AppStrings.isRu ? 'Договорная' : 'Kelishilgan');
                final title = item['title'] ?? item['subcategory_name_ru'] ?? item['subcategory_name_uz'] ?? (AppStrings.isRu ? 'Вакансия' : 'Vakansiya');

                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color ?? theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              priceStr,
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                      if (item['description'] != null && item['description'].toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          item['description'],
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: theme.hintColor, fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 20),

          // Details Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: theme.cardTheme.color ?? theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  Icons.calendar_today_rounded,
                  AppStrings.isRu ? 'На Yaqin Go с' : 'Yaqin Go ilovasida',
                  joinDate,
                  theme,
                ),
                if (phone != null && !widget.hidePhone) ...[
                  Divider(color: theme.dividerColor.withValues(alpha: 0.15)),
                  _buildPhoneRow(phone, theme, isCompany: isCompany),
                ],
              ],
            ),
          ),

          const SizedBox(height: 28),

          // Reviews
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              AppStrings.isRu ? 'Отзывы мастеров' : 'Ustalar fikrlari',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 14),
          _buildReviewsList(theme, isCompany),
        ],
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl, bool isCompany, ThemeData theme) {
    final size = isCompany ? 90.0 : 88.0;
    final borderRadius = isCompany ? BorderRadius.circular(24) : BorderRadius.circular(44);

    return GestureDetector(
      onTap: () {
        if (avatarUrl != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FullScreenImage(imageUrl: avatarUrl, tag: 'profile_avatar_${widget.clientId}'),
            ),
          );
        }
      },
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: borderRadius,
          color: theme.cardTheme.color ?? Colors.white,
          border: Border.all(
            color: theme.cardTheme.color ?? Colors.white,
            width: 3.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: borderRadius - const BorderRadius.all(Radius.circular(3.5)),
          child: Hero(
            tag: 'profile_avatar_${widget.clientId}',
            child: avatarUrl != null
                ? Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    width: size,
                    height: size,
                    errorBuilder: (_, __, ___) => _buildAvatarPlaceholder(isCompany),
                  )
                : _buildAvatarPlaceholder(isCompany),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarPlaceholder(bool isCompany) {
    if (isCompany) {
      return Container(
        color: AppColors.primary.withValues(alpha: 0.12),
        child: const Center(
          child: Icon(Icons.business_rounded, size: 40, color: AppColors.primary),
        ),
      );
    }
    return Container(
      color: AppColors.primary.withValues(alpha: 0.1),
      child: Center(
        child: Text(
          (_client!['name'] != null && _client!['name'].toString().isNotEmpty)
              ? _client!['name'][0].toUpperCase()
              : '?',
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildDefaultBanner() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00A651), Color(0xFF13773C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            bottom: -20,
            child: Icon(
              Icons.apartment_rounded,
              size: 130,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.business_rounded, size: 28, color: Colors.white.withValues(alpha: 0.8)),
                const SizedBox(width: 8),
                Text(
                  AppStrings.isRu ? 'КОМПАНИЯ' : 'KOMPANIYA',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCol(String label, String value, ThemeData theme) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: theme.hintColor)),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(color: theme.hintColor, fontSize: 14)),
          const Spacer(),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildPhoneRow(String phone, ThemeData theme, {bool isCompany = false}) {
    final cleanPhone = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    final formattedPhone = PriceFormatter.formatPhone(phone);
    final isMasked = !isCompany && phone.contains('*');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.phone_rounded, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Text(AppStrings.isRu ? 'Телефон' : 'Telefon', style: TextStyle(color: theme.hintColor, fontSize: 14)),
          const Spacer(),
          if (!isMasked)
            GestureDetector(
              onTap: () => launchUrl(Uri.parse('tel:$cleanPhone')),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      formattedPhone,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary, fontSize: 13),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.call_rounded, size: 15, color: AppColors.primary),
                  ],
                ),
              ),
            )
          else
            Text(phone, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildReviewsList(ThemeData theme, bool isCompany) {
    final List<dynamic> reviews = _client!['reviews'] ?? [];
    if (reviews.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: theme.cardTheme.color?.withValues(alpha: 0.5) ?? theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(Icons.rate_review_outlined, size: 44, color: theme.hintColor.withValues(alpha: 0.4)),
            const SizedBox(height: 10),
            Text(
              isCompany
                  ? (AppStrings.isRu ? 'У этой компании пока нет отзывов' : 'Bu kompaniyada hali sharhlar yo\'q')
                  : (AppStrings.isRu ? 'У этого клиента пока нет отзывов' : 'Bu mijozda hali sharhlar yo\'q'),
              style: TextStyle(color: theme.hintColor, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final r = reviews[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('⭐ ${r['rating']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  const Spacer(),
                  Text(
                    DateTimeUtils.formatDate(DateTimeUtils.parseUtc(r['created_at'])),
                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(r['comment'] ?? (AppStrings.isRu ? 'Без комментария' : 'Izohsiz'), style: const TextStyle(fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(AppStrings.isRu ? 'Мастер: ' : 'Usta: ', style: TextStyle(fontSize: 12, color: theme.hintColor)),
                  Text(r['master_name'] ?? (AppStrings.isRu ? 'Аноним' : 'Anonim'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
