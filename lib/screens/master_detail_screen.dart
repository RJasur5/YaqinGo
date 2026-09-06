import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/localization.dart';
import '../config/api_config.dart';
import '../models/master.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';
import '../widgets/rating_stars.dart';
import '../widgets/gradient_button.dart';
import '../widgets/full_screen_image.dart';
import '../utils/phone_utils.dart';
import '../utils/formatters.dart';
import '../config/regions.dart';
class MasterDetailScreen extends StatefulWidget {
  final ApiService apiService;
  final int masterId;
  const MasterDetailScreen({super.key, required this.apiService, required this.masterId});

  @override
  State<MasterDetailScreen> createState() => _MasterDetailScreenState();
}

class _MasterDetailScreenState extends State<MasterDetailScreen> {
  MasterModel? _master;
  bool _isLoading = true;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _loadMaster();
  }

  Future<void> _loadMaster() async {
    try {
      final master = await widget.apiService.getMasterDetail(widget.masterId);
      if (mounted) setState(() { _master = master; _isLoading = false; });
    } catch (e) {
      debugPrint('Error loading master: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      await widget.apiService.toggleFavorite(widget.masterId);
      setState(() => _isFavorite = !_isFavorite);
    } catch (_) {}
  }

  void _showReviewDialog() {
    final theme = Theme.of(context);
    int rating = 5;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardTheme.color,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(AppStrings.writeReview, style: theme.textTheme.titleMedium),
              const SizedBox(height: 20),
              RatingInput(
                value: rating,
                onChanged: (v) => setModalState(() => rating = v),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: AppStrings.isRu ? 'Ваш комментарий...' : 'Sharhingiz...',
                ),
              ),
              const SizedBox(height: 20),
              GradientButton(
                text: AppStrings.save,
                onPressed: () async {
                  try {
                    await widget.apiService.createReview(widget.masterId, rating, commentController.text);
                    if (mounted) {
                      Navigator.pop(context);
                      _loadMaster();
                    }
                  } catch (_) {}
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showJobApplicationDialog() {
    final theme = Theme.of(context);
    final descController = TextEditingController();
    final phoneController = TextEditingController(text: '+998 ');
    final _phoneFormatter = PhoneUtils.maskFormatter;
    String? selectedCity;
    String? selectedDistrict;
    bool isSending = false;
    String? descError;
    String? phoneError;

    void protectPrefix() {
      const prefix = '+998 ';
      if (!phoneController.text.startsWith(prefix)) {
        phoneController.removeListener(protectPrefix);
        phoneController.text = prefix;
        phoneController.selection = TextSelection.fromPosition(
          TextPosition(offset: prefix.length),
        );
        phoneController.addListener(protectPrefix);
      }
    }
    phoneController.addListener(protectPrefix);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardTheme.color,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => GestureDetector(
          onTap: () => FocusScope.of(ctx).unfocus(),
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
              // Close button row (replaces drag handle — prevents accidental swipe-dismiss)
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () => Navigator.pop(ctx),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 22,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Header with icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.1),
                      AppColors.secondary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.work_outline_rounded, color: AppColors.primary, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.submitApplication,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _master?.userName?.capitalizeWords() ?? '',
                            style: const TextStyle(color: AppColors.primary, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Description field
              TextField(
                controller: descController,
                minLines: 4,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                style: theme.textTheme.bodyLarge,
                onChanged: (_) {
                  if (descError != null) setModalState(() => descError = null);
                },
                decoration: InputDecoration(
                  hintText: AppStrings.applicationDescription,
                  labelText: AppStrings.isRu ? 'Описание работы *' : 'Ish tavsifi *',
                  errorText: descError,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.description_rounded),
                ),
              ),
              const SizedBox(height: 14),
              // City field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedCity,
                    hint: Text(AppStrings.city, style: TextStyle(color: theme.hintColor)),
                    dropdownColor: theme.cardTheme.color,
                    items: RegionsConfig.regionKeys.map((key) {
                      return DropdownMenuItem<String>(
                        value: key,
                        child: Text(RegionsConfig.getDisplayName(key), style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setModalState(() { selectedCity = val; selectedDistrict = null; });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // District field
              if (selectedCity != null && RegionsConfig.getDistricts(selectedCity!).isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: selectedDistrict,
                      hint: Text(AppStrings.isRu ? 'Район' : 'Tuman', style: TextStyle(color: theme.hintColor)),
                      dropdownColor: theme.cardTheme.color,
                      items: RegionsConfig.getDistricts(selectedCity!).map((displayName) {
                        final key = RegionsConfig.getDistrictKey(displayName, selectedCity);
                        return DropdownMenuItem<String>(
                          value: key,
                          child: Text(displayName, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setModalState(() => selectedDistrict = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              const SizedBox(height: 14),
              // Phone field
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [_phoneFormatter],
                style: theme.textTheme.bodyLarge,
                onChanged: (_) {
                  if (phoneError != null) setModalState(() => phoneError = null);
                },
                decoration: InputDecoration(
                  hintText: '+998 (99) 858-56-88',
                  labelText: AppStrings.applicationPhone,
                  errorText: phoneError,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  prefixIcon: const Icon(Icons.phone_rounded),
                ),
              ),
              const SizedBox(height: 24),
              // Submit button
              GradientButton(
                text: isSending
                    ? (AppStrings.isRu ? 'Отправка...' : 'Yuborilmoqda...')
                    : AppStrings.submitApplication,
                icon: Icons.send_rounded,
                onPressed: isSending ? null : () async {
                  bool hasError = false;
                  setModalState(() {
                    descError = null;
                    phoneError = null;
                  });

                  if (descController.text.trim().length < 5) {
                    setModalState(() => descError = AppStrings.isRu ? 'Минимум 5 символов' : 'Kamida 5 ta belgi');
                    hasError = true;
                  }
                  final cleanPhone = phoneController.text.replaceAll(RegExp(r'\D'), '');
                  if (cleanPhone.length < 12) { // e.g. 998901234567
                    setModalState(() => phoneError = AppStrings.isRu ? 'Некорректный номер телефона' : 'Noto\'g\'ri telefon raqami');
                    hasError = true;
                  }

                  if (hasError) return;

                  if (selectedCity == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppStrings.isRu ? 'Выберите город' : 'Shaharni tanlang')),
                    );
                    return;
                  }
                  if (RegionsConfig.getDistricts(selectedCity!).isNotEmpty && selectedDistrict == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppStrings.isRu ? 'Выберите район' : 'Tumanni tanlang')),
                    );
                    return;
                  }
                  
                  setModalState(() => isSending = true);
                  try {
                    final cityDisplay = selectedCity != null ? RegionsConfig.getDisplayName(selectedCity!) : '';
                    final districtDisplay = selectedDistrict != null ? RegionsConfig.getDistrictDisplay(selectedDistrict!, selectedCity) : null;
                    String fullCity = districtDisplay != null ? '$cityDisplay, $districtDisplay' : cityDisplay;
                    await widget.apiService.createJobApplication(
                      widget.masterId,
                      description: descController.text.trim(),
                      city: fullCity,
                      phone: phoneController.text.trim().isNotEmpty ? PhoneUtils.normalize(phoneController.text) : null,
                    );
                    if (mounted) {
                      Navigator.pop(ctx);
                      _showApplicationSentSuccess();
                    }
                  } catch (e) {
                    setModalState(() => isSending = false);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                      );
                    }
                  }
                },
              ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showApplicationSentSuccess() {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.cardTheme.color,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 64),
            ),
            const SizedBox(height: 20),
            Text(
              AppStrings.applicationSent,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              AppStrings.isRu
                  ? 'Мастер получит уведомление о вашей заявке и свяжется с вами.'
                  : "Usta sizning arizangiz haqida bildirishnoma oladi va siz bilan bog'lanadi.",
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'OK',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppTheme.getPalette(ThemeService().currentMode);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: palette.bgGradient),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
            : _master == null
                ? Center(child: Text(AppStrings.error, style: theme.textTheme.bodyMedium))
                : CustomScrollView(
                    slivers: [
                      // App bar with gradient header
                      SliverAppBar(
                        expandedHeight: 240,
                        pinned: true,
                        backgroundColor: palette.primary,
                        leading: IconButton(
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        actions: [
                          IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                                color: _isFavorite ? Colors.red.shade300 : Colors.white,
                              ),
                            ),
                            onPressed: _toggleFavorite,
                          ),
                        ],
                        flexibleSpace: FlexibleSpaceBar(
                          background: Stack(
                            fit: StackFit.expand,
                            children: [
                              // Background Banner Image if set, else gradient
                              if (_master!.companyBanner != null && _master!.companyBanner!.isNotEmpty)
                                Image.network(
                                  _master!.companyBanner!.startsWith('http')
                                      ? _master!.companyBanner!
                                      : '${ApiConfig.baseUrl.replaceAll("/api", "")}${_master!.companyBanner}',
                                  fit: BoxFit.cover,
                                )
                              else
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: _master!.accountType == 'company'
                                          ? const [Color(0xFF00A651), Color(0xFF33B874)]
                                          : [
                                              palette.primary.withOpacity(0.8),
                                              palette.primary.withOpacity(0.55),
                                              palette.bg,
                                            ],
                                      stops: _master!.accountType == 'company' ? null : const [0.0, 0.75, 1.0],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                  ),
                                ),

                              // Dark overlay gradient for readability
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.black.withOpacity(0.3),
                                      Colors.black.withOpacity(0.6),
                                    ],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                  ),
                                ),
                              ),

                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(height: 40),
                                    GestureDetector(
                                      onTap: () {
                                        final avatar = _master!.userAvatar;
                                        if (avatar != null) {
                                          final url = avatar.startsWith('http')
                                              ? avatar
                                              : '${ApiConfig.baseUrl.replaceAll("/api", "")}$avatar';
                                          Navigator.push(context, MaterialPageRoute(builder: (_) => FullScreenImage(imageUrl: url, tag: 'master_avatar_${_master!.id}')));
                                        }
                                      },
                                      child: Hero(
                                        tag: 'master_avatar_${_master!.id}',
                                        child: Container(
                                          width: 90,
                                          height: 90,
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(28),
                                            border: Border.all(color: Colors.white.withOpacity(0.25), width: 2),
                                            image: _master!.userAvatar != null
                                                ? DecorationImage(
                                                    image: NetworkImage(
                                                      _master!.userAvatar!.startsWith('http')
                                                          ? _master!.userAvatar!
                                                          : '${ApiConfig.baseUrl.replaceAll("/api", "")}${_master!.userAvatar}',
                                                    ),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null,
                                          ),
                                          child: _master!.userAvatar == null
                                            ? Center(
                                                child: Text(
                                                  _master!.initials,
                                                  style: const TextStyle(
                                                    fontSize: 34,
                                                    fontWeight: FontWeight.w900,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                              )
                                            : null,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _master!.userName.capitalizeWords(),
                                      style: const TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        if (_master!.accountType == 'company') ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.business_rounded, color: Colors.white, size: 13),
                                                const SizedBox(width: 4),
                                                Text(
                                                  AppStrings.isRu ? 'Компания' : 'Kompaniya',
                                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                        ],
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(0.3),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            _master!.subcategoryName(AppStrings.lang),
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Content
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Stats row
                              Row(
                                children: [
                                  _statCard(Icons.star_rounded, _master!.rating.toStringAsFixed(1), AppStrings.rating, AppColors.warning),
                                  const SizedBox(width: 12),
                                  _statCard(Icons.work_rounded, '${_master!.experienceYears}', AppStrings.experience, AppColors.blue),
                                  const SizedBox(width: 12),
                                  _statCard(Icons.chat_rounded, '${_master!.reviewsCount}', AppStrings.reviews, AppColors.success),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Availability badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                decoration: BoxDecoration(
                                  color: (_master!.isAvailable ? AppColors.success : AppColors.error).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (_master!.isAvailable ? AppColors.success : AppColors.error).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _master!.isAvailable ? Icons.check_circle_rounded : Icons.cancel_rounded,
                                      size: 18,
                                      color: _master!.isAvailable ? AppColors.success : AppColors.error,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _master!.isAvailable ? AppStrings.available : AppStrings.unavailable,
                                      style: TextStyle(
                                        color: _master!.isAvailable ? AppColors.success : AppColors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Description
                              if (_master!.description != null) ...[
                                Text(AppStrings.description, style: theme.textTheme.titleMedium),
                                const SizedBox(height: 8),
                                Text(
                                  _master!.description!,
                                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                                ),
                                const SizedBox(height: 20),
                              ],

                              // Info rows
                              if (_master!.city != null)
                                _infoRow(Icons.location_on_rounded, '${AppStrings.city}: ${_master!.city!}'),
                              if (_master!.hourlyRate != null)
                                _infoRow(Icons.payments_rounded, '${AppStrings.hourlyRate}: ${PriceFormatter.format(_master!.hourlyRate)} ${AppStrings.sum}'),
                              _infoRow(Icons.category_rounded, '${_master!.categoryName(AppStrings.lang)} → ${_master!.subcategoryName(AppStrings.lang)}'),

                              // Skills
                              if (_master!.skills.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                Text(AppStrings.skills, style: theme.textTheme.titleMedium),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _master!.skills.map((s) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
                                    ),
                                    child: Text(s, style: TextStyle(color: theme.primaryColor, fontSize: 13, fontWeight: FontWeight.w600)),
                                  )).toList(),
                                ),
                              ],

                              // Reviews
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Text(AppStrings.reviews, style: theme.textTheme.titleMedium),
                                  const SizedBox(width: 8),
                                  Text('(${_master!.reviewsCount})', style: theme.textTheme.bodySmall),
                                ],
                              ),
                              const SizedBox(height: 12),

                              if (_master!.reviews == null || _master!.reviews!.isEmpty)
                                Text(AppStrings.noReviews, style: theme.textTheme.bodySmall)
                              else
                                ..._master!.reviews!.map((r) => Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: theme.cardTheme.color,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(r.clientName, style: theme.textTheme.bodyLarge),
                                          const Spacer(),
                                          RatingStars(rating: r.rating.toDouble(), size: 14, showNumber: false),
                                        ],
                                      ),
                                      if (r.comment != null && r.comment!.isNotEmpty) ...[
                                        const SizedBox(height: 8),
                                        Text(r.comment!, style: theme.textTheme.bodyMedium?.copyWith(height: 1.4)),
                                      ],
                                    ],
                                  ),
                                )),

                              const SizedBox(height: 100),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
      bottomNavigationBar: _master != null
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                border: Border(top: BorderSide(color: theme.dividerColor.withOpacity(0.5))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GradientButton(
                      text: AppStrings.submitApplication,
                      icon: Icons.work_outline_rounded,
                      onPressed: _showJobApplicationDialog,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: theme.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: theme.primaryColor.withOpacity(0.3)),
                    ),
                    child: IconButton(
                      icon: Icon(Icons.rate_review_rounded, color: theme.primaryColor),
                      onPressed: _showReviewDialog,
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  Widget _statCard(IconData icon, String value, String label, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: theme.textTheme.titleMedium),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: theme.textTheme.bodySmall?.color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
