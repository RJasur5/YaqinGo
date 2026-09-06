import 'package:flutter/material.dart';
import '../utils/formatters.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../config/theme.dart';
import '../config/localization.dart';
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import 'master_profile_setup_screen.dart';
import 'location_picker_screen.dart';
import '../models/master.dart';
import '../models/subscription.dart';
import 'admin/admin_panel_screen.dart';
import 'job_applications_screen.dart';
import '../config/regions.dart';
import 'orders/accepted_orders_screen.dart';

class ProfileScreen extends StatefulWidget {
  final AuthService authService;
  final ApiService apiService;
  const ProfileScreen({super.key, required this.authService, required this.apiService});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  MasterModel? _masterProfile;
  SubscriptionModel? _subscription;
  bool _isLoadingMaster = false;
  String _selectedAccountType = 'person'; // 'person' or 'company'

  @override
  void initState() {
    super.initState();
    _loadMasterProfile();
    _loadSubscription();
    final user = widget.authService.currentUser;
    if (user != null) {
      _selectedAccountType = (user.isCompany || user.accountType == 'company') ? 'company' : 'person';
    }
  }

  Future<void> _loadSubscription() async {
    try {
      final sub = await widget.apiService.getMySubscription();
      if (mounted) setState(() => _subscription = sub);
    } catch (_) {}
  }

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _isLoadingMaster = true);
      try {
        await widget.authService.uploadAvatar(picked.path);
        if (mounted) setState(() {});
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoadingMaster = false);
      }
    }
  }

  Future<void> _pickCompanyBanner() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 720,
      imageQuality: 85,
    );
    if (picked != null) {
      setState(() => _isLoadingMaster = true);
      try {
        await widget.authService.uploadCompanyBanner(picked.path);
        await widget.authService.refreshUser();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.isRu ? 'Обложка компании обновлена!' : "Kompaniya muqovasi yangilandi!")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoadingMaster = false);
      }
    }
  }

  Future<void> _openLocationPicker() async {
    final user = widget.authService.currentUser;
    final result = await Navigator.push<LocationPickerResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialLat: user?.latitude,
          initialLon: user?.longitude,
          initialAddress: user?.city,
        ),
      ),
    );

    if (result != null) {
      try {
        setState(() => _isLoadingMaster = true);
        await widget.apiService.updateProfile(
          latitude: result.latitude,
          longitude: result.longitude,
        );
        await widget.authService.refreshUser();
        await _loadMasterProfile();
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.isRu ? 'Локация сохранена и обновлена на карте!' : 'Joylashuv saqlandi va xaritada yangilandi!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoadingMaster = false);
      }
    }
  }

  Future<void> _loadMasterProfile() async {
    final user = await widget.authService.refreshUser();
    if (user != null) {
      setState(() {
        _selectedAccountType = (user.isCompany || user.accountType == 'company') ? 'company' : 'person';
      });
      if (user.isMaster) {
        setState(() => _isLoadingMaster = true);
        try {
          final profile = await widget.apiService.getMyMasterProfile();
          if (mounted) setState(() => _masterProfile = profile);
        } catch (_) {} finally {
          if (mounted) setState(() => _isLoadingMaster = false);
        }
      }
    }
  }

  Future<void> _toggleAccountType(String type) async {
    if (_selectedAccountType == type) return;

    if (type == 'company') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          final theme = Theme.of(ctx);
          return AlertDialog(
            backgroundColor: theme.cardTheme.color,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.business_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    AppStrings.isRu ? 'Переключить на компанию?' : "Kompaniya profiliga o'tish?",
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              AppStrings.isRu
                  ? 'Вы хотите переключить данный профиль на официальный аккаунт компании? Вы сможете указать название бренда, загрузить обложку и логотип.'
                  : "Ushbu profilni kompaniya akkauntiga o'tkazishni xohlaysizmi? Siz muqova, logotip va ma'lumotlarni qo'shishingiz mumkin bo'ladi.",
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  AppStrings.isRu ? 'Отмена' : 'Bekor',
                  style: TextStyle(color: theme.textTheme.bodySmall?.color),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(AppStrings.isRu ? 'Да, переключить' : "Ha, o'tish"),
              ),
            ],
          );
        },
      );

      if (confirm != true) return;
    }

    setState(() {
      _selectedAccountType = type;
    });

    try {
      if (type == 'person') {
        await widget.authService.updateProfile(
          accountType: 'person',
        );
      } else {
        await widget.authService.updateProfile(accountType: 'company');
      }
      await widget.authService.refreshUser();
      await _loadMasterProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(type == 'company'
                ? (AppStrings.isRu ? 'Статус аккаунта: Компания' : 'Akkaunt maqomi: Kompaniya')
                : (AppStrings.isRu ? 'Статус аккаунта: Частное лицо' : 'Akkaunt maqomi: Jismoniy shaxs')),
          ),
        );
        if (type == 'company') {
          _showCompanyInfoSheet();
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = widget.authService.currentUser;
    if (user == null) {
      return const Center(child: Text('Not logged in', style: TextStyle(color: AppColors.textPrimary)));
    }

    final isCompany = _selectedAccountType == 'company' || (user.isCompany == true);

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.currentGradient(context)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 10),

                // Profile Header Card: Company Banner vs Personal Avatar
                if (isCompany) ...[
                  // Company Cover Banner with Overlapping Squircle Logo
                  Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      GestureDetector(
                        onTap: _pickCompanyBanner,
                        child: Container(
                          width: double.infinity,
                          height: 155,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: user.companyBanner == null
                                ? const LinearGradient(
                                    colors: [Color(0xFF00A651), Color(0xFF13773C)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              if (user.companyBanner != null && user.companyBanner!.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: Image.network(
                                    user.companyBanner!.startsWith('http')
                                        ? user.companyBanner!
                                        : '${ApiConfig.baseUrl.replaceAll("/api", "")}${user.companyBanner}',
                                    width: double.infinity,
                                    height: 155,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.add_photo_alternate_rounded, color: Colors.white, size: 36),
                                      const SizedBox(height: 6),
                                      Text(
                                        AppStrings.isRu ? 'Добавить обложку компании' : 'Kompaniya muqovasini yuklash',
                                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                      ),
                                    ],
                                  ),
                                ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        AppStrings.isRu ? 'Обложка' : 'Muqova',
                                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Overlapping Logo Squircle
                      Positioned(
                        bottom: -45,
                        child: GestureDetector(
                          onTap: _pickPhoto,
                          child: Stack(
                            children: [
                              Container(
                                width: 92,
                                height: 92,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  color: theme.cardTheme.color ?? Colors.white,
                                  border: Border.all(
                                    color: theme.scaffoldBackgroundColor,
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
                                  borderRadius: BorderRadius.circular(20),
                                  child: user.avatar != null
                                      ? Image.network(
                                          user.avatar!.startsWith('http')
                                              ? user.avatar!
                                              : '${ApiConfig.baseUrl.replaceAll("/api", "")}${user.avatar}',
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          color: AppColors.primary.withValues(alpha: 0.12),
                                          child: const Center(
                                            child: Icon(Icons.business_rounded, size: 42, color: AppColors.primary),
                                          ),
                                        ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                                  ),
                                  child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 55),
                ] else ...[
                  // Individual Avatar Box
                  GestureDetector(
                    onTap: _pickPhoto,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            gradient: user.avatar == null ? AppColors.primaryGradient : null,
                            borderRadius: BorderRadius.circular(36),
                            boxShadow: [
                              BoxShadow(
                                color: theme.primaryColor.withValues(alpha: 0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: user.avatar != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(36),
                                  child: Image.network(
                                    user.avatar!.startsWith('http')
                                        ? user.avatar!
                                        : '${ApiConfig.baseUrl.replaceAll("/api", "")}${user.avatar}',
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Center(
                                  child: Icon(
                                    Icons.person_rounded,
                                    size: 48,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                        // Camera overlay
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: theme.primaryColor,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Name
                Text(
                  user.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                if (isCompany) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      AppStrings.isRu ? 'Компания' : 'Kompaniya',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.4)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: Text(AppStrings.isRu ? 'Настройка информации компании' : 'Kompaniya ma\'lumotlarini sozlash'),
                    onPressed: _showCompanyInfoSheet,
                  ),
                ],
                const SizedBox(height: 24),

                // Info Cards
                _infoTile(
                  Icons.fingerprint_rounded,
                  AppStrings.isRu ? 'Ваш ID (для оплаты)' : 'Sizning ID (to\'lov uchun)',
                  '${user.id}',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: user.id.toString()));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(AppStrings.isRu ? 'ID скопирован!' : 'ID nusxalandi!')),
                    );
                  },
                  trailing: const Icon(Icons.copy_rounded, size: 18, color: Colors.grey),
                ),
                _infoTile(Icons.phone_rounded, AppStrings.phone, user.phone),

                // Location on Map Card (Clickable to change position)
                _infoTile(
                  Icons.map_rounded,
                  AppStrings.isRu ? 'Локация на карте (Нажмите, чтобы изменить)' : 'Xaritada joylashuv (O\'zgartirish uchun bosing)',
                  user.latitude != null
                      ? '${user.latitude!.toStringAsFixed(4)}, ${user.longitude!.toStringAsFixed(4)} (${(user.city != null && user.city!.trim().isNotEmpty) ? user.city! : (AppStrings.isRu ? 'Ташкент' : 'Toshkent')})'
                      : ((user.city != null && user.city!.trim().isNotEmpty) ? user.city! : (AppStrings.isRu ? 'Укажите точку на карте 📍' : 'Xaritada nuqtani belgilang 📍')),
                  onTap: _openLocationPicker,
                  trailing: const Icon(Icons.edit_location_alt_rounded, size: 20, color: AppColors.primary),
                ),

                _infoTile(Icons.location_city_rounded, AppStrings.city, user.city ?? '-'),
                _infoTile(Icons.language_rounded, AppStrings.language, user.lang == 'ru' ? AppStrings.russian : AppStrings.uzbek),

                // Company Description Card
                if (isCompany) ...[
                  const SizedBox(height: 12),
                  _infoTile(
                    Icons.business_center_rounded,
                    AppStrings.isRu ? 'О компании / Чем занимается' : 'Kompaniya haqida / Faoliyat turi',
                    (user.companyDescription != null && user.companyDescription!.isNotEmpty)
                        ? user.companyDescription!
                        : (AppStrings.isRu ? 'Нажмите, чтобы указать сферу деятельности и услуги' : 'Faoliyat sohasi va xizmatlarni kiritish uchun bosing'),
                    onTap: _showCompanyInfoSheet,
                    trailing: const Icon(Icons.edit_note_rounded, size: 22, color: AppColors.primary),
                  ),
                ],

                // Master Info Box
                if (_isLoadingMaster)
                  CircularProgressIndicator(color: theme.primaryColor)
                else if (_masterProfile != null) ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Container(
                        width: 4,
                        height: 20,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        AppStrings.isRu ? 'Профиль мастера' : 'Mutaxassis profili',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: [
                      _infoTile(
                        Icons.medical_services_rounded,
                        AppStrings.isRu ? 'Специализация' : 'Mutaxassislik',
                        '${_masterProfile!.categoryName(AppStrings.lang)} -> ${_masterProfile!.subcategoryName(AppStrings.lang)}',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MasterProfileSetupScreen(
                                apiService: widget.apiService,
                                authService: widget.authService,
                              ),
                            ),
                          ).then((_) => _loadMasterProfile());
                        },
                      ),
                      _infoTile(
                        Icons.work_history_rounded,
                        AppStrings.experience,
                        '${_masterProfile!.experienceYears} ${AppStrings.years}',
                      ),
                      if (_masterProfile!.hourlyRate != null)
                        _infoTile(
                          Icons.payments_rounded,
                          AppStrings.hourlyRate,
                          '${_masterProfile!.hourlyRate!.toStringAsFixed(0)} ${AppStrings.sum}${AppStrings.perHour}',
                        ),
                      _infoTile(
                        Icons.location_on_rounded,
                        AppStrings.isRu ? 'Район и локация (Изменить на карте)' : 'Tuman va joylashuv (Xaritada o\'zgartirish)',
                        _masterProfile!.district ?? (AppStrings.isRu ? 'Указать на карте' : 'Xaritada ko\'rsatish'),
                        onTap: _openLocationPicker,
                        trailing: const Icon(Icons.pin_drop_rounded, color: AppColors.primary, size: 20),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),

                // Admin Panel (Visible only to admins)
                if (user.isAdmin) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.cardTheme.color,
                      foregroundColor: theme.primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: const Icon(Icons.admin_panel_settings_rounded),
                    label: Text(AppStrings.isRu ? 'Админ-панель' : 'Admin paneli'),
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => AdminPanelScreen(apiService: widget.apiService)));
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Action Buttons
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: Text(AppStrings.isRu ? 'Подать объявление' : 'E\'lon berish'),
                  onPressed: () {
                    Navigator.pushNamed(context, '/create-order');
                  },
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  icon: const Icon(Icons.assignment_rounded),
                  label: Text(AppStrings.isRu ? 'Мои заказы' : 'Mening buyurtmalarim'),
                  onPressed: () {
                    Navigator.pushNamed(context, '/my-orders');
                  },
                ),
                const SizedBox(height: 12),

                if (!isCompany) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: const Icon(Icons.task_alt_rounded),
                    label: Text(AppStrings.isRu ? 'Принятые заказы' : 'Qabul qilingan buyurtmalar'),
                    onPressed: () {
                      Navigator.pushNamed(context, '/accepted-orders');
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: const Icon(Icons.mark_email_unread_rounded),
                    label: Text(AppStrings.jobApplications),
                    onPressed: () {
                      Navigator.pushNamed(context, '/job-applications');
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                if (user.role == 'master' || user.role == 'admin') ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: const Icon(Icons.edit_note_rounded),
                    label: Text(AppStrings.isRu ? 'Настроить профиль мастера' : 'Master profilini sozlash'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MasterProfileSetupScreen(
                            apiService: widget.apiService,
                            authService: widget.authService,
                          ),
                        ),
                      ).then((_) => _loadMasterProfile());
                    },
                  ),
                ] else if (isCompany) ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(AppStrings.isRu ? 'Настройка информации компании' : 'Kompaniya ma\'lumotlarini sozlash'),
                    onPressed: _showCompanyInfoSheet,
                  ),
                ] else ...[
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    icon: const Icon(Icons.engineering_rounded),
                    label: Text(AppStrings.isRu ? 'Стать мастером' : 'Usta bo\'lish'),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => MasterProfileSetupScreen(
                            apiService: widget.apiService,
                            authService: widget.authService,
                          ),
                        ),
                      ).then((_) => _loadMasterProfile());
                    },
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCompanyInfoSheet() {
    final user = widget.authService.currentUser;
    if (user == null) return;

    final nameCtrl = TextEditingController(text: user.name);
    final descCtrl = TextEditingController(text: user.companyDescription ?? '');

    // Parse region and district from user.city
    String? selectedCityKey;
    if (user.city != null && user.city!.trim().isNotEmpty) {
      final parts = user.city!.split(',');
      selectedCityKey = RegionsConfig.getKey(parts.first.trim());
    }
    if (selectedCityKey == null || !RegionsConfig.regionKeys.contains(selectedCityKey)) {
      selectedCityKey = RegionsConfig.regionKeys.first;
    }

    String? selectedDistrictKey;
    if (user.city != null && user.city!.contains(',')) {
      final parts = user.city!.split(',');
      if (parts.length > 1) {
        selectedDistrictKey = RegionsConfig.getDistrictKey(parts[1].trim(), selectedCityKey);
      }
    }

    double? selectedLat = user.latitude;
    double? selectedLon = user.longitude;
    String? selectedAddress = user.city;
    String? currentBannerUrl = user.companyBanner;
    String? currentLogoUrl = user.avatar;
    bool isUploadingBanner = false;
    bool isUploadingLogo = false;
    bool isSaving = false;
    String? errorText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) {
          final theme = Theme.of(context);
          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            behavior: HitTestBehavior.opaque,
            child: Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 16,
                left: 20,
                right: 20,
              ),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.business_rounded, color: AppColors.primary, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStrings.isRu ? 'Настройка информации компании' : 'Kompaniya ma\'lumotlarini sozlash',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: theme.textTheme.titleLarge?.color,
                                ),
                              ),
                              Text(
                                AppStrings.isRu
                                    ? 'Заполните данные вашей организации'
                                    : 'Tashkilotingiz ma\'lumotlarini to\'ldiring',
                                style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 24),
                          color: theme.hintColor,
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    if (errorText != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Text(errorText!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                      ),

                    // Logo & Banner Upload Pickers
                    Row(
                      children: [
                        // Logo Picker
                        GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 512,
                              maxHeight: 512,
                              imageQuality: 85,
                            );
                            if (picked != null) {
                              setSheetState(() => isUploadingLogo = true);
                              try {
                                final updated = await widget.authService.uploadAvatar(picked.path);
                                setSheetState(() {
                                  currentLogoUrl = updated.avatar;
                                  isUploadingLogo = false;
                                });
                                setState(() {});
                              } catch (e) {
                                setSheetState(() {
                                  isUploadingLogo = false;
                                  errorText = 'Logo error: $e';
                                });
                              }
                            }
                          },
                          child: Stack(
                            children: [
                              Container(
                                width: 76,
                                height: 76,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: theme.cardTheme.color,
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: isUploadingLogo
                                      ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)))
                                      : (currentLogoUrl != null && currentLogoUrl!.isNotEmpty)
                                          ? Image.network(
                                              currentLogoUrl!.startsWith('http')
                                                  ? currentLogoUrl!
                                                  : '${ApiConfig.baseUrl.replaceAll("/api", "")}$currentLogoUrl',
                                              fit: BoxFit.cover,
                                            )
                                          : Column(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                const Icon(Icons.add_a_photo_rounded, size: 24, color: AppColors.primary),
                                                const SizedBox(height: 2),
                                                Text(AppStrings.isRu ? 'Логотип' : 'Logotip', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                              ],
                                            ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                                  child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Banner Picker
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final picked = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 1280,
                                maxHeight: 720,
                                imageQuality: 85,
                              );
                              if (picked != null) {
                                setSheetState(() => isUploadingBanner = true);
                                try {
                                  final updated = await widget.authService.uploadCompanyBanner(picked.path);
                                  setSheetState(() {
                                    currentBannerUrl = updated.companyBanner;
                                    isUploadingBanner = false;
                                  });
                                  setState(() {});
                                } catch (e) {
                                  setSheetState(() {
                                    isUploadingBanner = false;
                                    errorText = 'Banner error: $e';
                                  });
                                }
                              }
                            },
                            child: Stack(
                              children: [
                                Container(
                                  height: 76,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: theme.cardTheme.color,
                                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.35)),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: isUploadingBanner
                                        ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)))
                                        : (currentBannerUrl != null && currentBannerUrl!.isNotEmpty)
                                            ? Image.network(
                                                currentBannerUrl!.startsWith('http')
                                                    ? currentBannerUrl!
                                                    : '${ApiConfig.baseUrl.replaceAll("/api", "")}$currentBannerUrl',
                                                fit: BoxFit.cover,
                                                width: double.infinity,
                                              )
                                            : Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.add_photo_alternate_rounded, size: 24, color: AppColors.primary),
                                                  const SizedBox(width: 8),
                                                  Text(AppStrings.isRu ? 'Обложка компании' : 'Kompaniya muqovasi', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
                                                ],
                                              ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 6,
                                  right: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                                    child: const Icon(Icons.camera_alt_rounded, size: 12, color: Colors.white),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: nameCtrl,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        labelText: AppStrings.isRu ? 'Название компании / Бренд' : 'Kompaniya nomi / Brend',
                        prefixIcon: const Icon(Icons.apartment_rounded),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Region / City Selector from Database
                    DropdownButtonFormField<String>(
                      value: selectedCityKey,
                      decoration: InputDecoration(
                        labelText: AppStrings.city,
                        prefixIcon: const Icon(Icons.location_city_rounded),
                      ),
                      dropdownColor: theme.cardTheme.color,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      items: RegionsConfig.regionKeys.map((key) {
                        return DropdownMenuItem<String>(
                          value: key,
                          child: Text(
                            RegionsConfig.getDisplayName(key),
                            style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setSheetState(() {
                            selectedCityKey = val;
                            selectedDistrictKey = null;
                          });
                        }
                      },
                    ),

                    // District Selector (if selected city has districts)
                    if (selectedCityKey != null && RegionsConfig.getDistricts(selectedCityKey!).isNotEmpty) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedDistrictKey,
                        decoration: InputDecoration(
                          labelText: AppStrings.isRu ? 'Район' : 'Tuman',
                          prefixIcon: const Icon(Icons.map_outlined),
                        ),
                        hint: Text(
                          AppStrings.isRu ? 'Выберите район' : 'Tumanni tanlang',
                          style: TextStyle(color: theme.hintColor),
                        ),
                        dropdownColor: theme.cardTheme.color,
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                        items: RegionsConfig.getDistricts(selectedCityKey!).map((displayName) {
                          final key = RegionsConfig.getDistrictKey(displayName, selectedCityKey);
                          return DropdownMenuItem<String>(
                            value: key,
                            child: Text(
                              displayName,
                              style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setSheetState(() => selectedDistrictKey = val);
                        },
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Map Location Tile inside Sheet
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push<LocationPickerResult>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LocationPickerScreen(
                              initialLat: selectedLat,
                              initialLon: selectedLon,
                              initialAddress: selectedAddress,
                            ),
                          ),
                        );
                        if (result != null) {
                          setSheetState(() {
                            selectedLat = result.latitude;
                            selectedLon = result.longitude;
                            selectedAddress = result.address;
                          });
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    AppStrings.isRu ? 'Локация на карте' : 'Xaritadagi joylashuv',
                                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    selectedLat != null
                                        ? '${selectedLat!.toStringAsFixed(4)}, ${selectedLon!.toStringAsFixed(4)} (${selectedAddress ?? (AppStrings.isRu ? "Указана" : "Belgilangan")})'
                                        : (AppStrings.isRu ? 'Указать на карте 📍' : 'Xaritada belgilash 📍'),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: theme.textTheme.bodyLarge?.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    TextField(
                      controller: descCtrl,
                      maxLines: 5,
                      minLines: 3,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        labelText: AppStrings.isRu
                            ? 'Чем занимается компания (услуги, сфера)'
                            : 'Kompaniya nima bilan shug\'ullanadi (xizmatlar, soha)',
                        hintText: AppStrings.isRu
                            ? 'Например: Строительные и ремонтные работы под ключ, электромонтаж, отделка, поставка материалов...'
                            : 'Masalan: Qurilish va ta\'mirlash ishlari, elektromontaj, pardozlash...',
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 60),
                          child: Icon(Icons.description_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isSaving ? null : () async {
                          if (nameCtrl.text.trim().isEmpty) {
                            setSheetState(() => errorText = AppStrings.isRu ? 'Введите название компании' : 'Kompaniya nomini kiriting');
                            return;
                          }
                          setSheetState(() { isSaving = true; errorText = null; });
                          try {
                            final cityForApi = selectedCityKey != null ? RegionsConfig.getDisplayName(selectedCityKey!) : '';
                            final districtForApi = (selectedDistrictKey != null && selectedCityKey != null)
                                ? RegionsConfig.getDistrictDisplay(selectedDistrictKey!, selectedCityKey!)
                                : null;
                            final fullLocation = (districtForApi != null && districtForApi.isNotEmpty)
                                ? '$cityForApi, $districtForApi'
                                : cityForApi;

                            await widget.authService.updateProfile(
                              name: nameCtrl.text.trim(),
                              city: fullLocation.isNotEmpty ? fullLocation : selectedAddress,
                              companyDescription: descCtrl.text.trim(),
                              accountType: 'company',
                              latitude: selectedLat,
                              longitude: selectedLon,
                            );
                            _selectedAccountType = 'company';
                            await widget.authService.refreshUser();
                            if (mounted) {
                              setState(() {});
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppStrings.isRu
                                      ? 'Информация о компании сохранена!'
                                      : 'Kompaniya ma\'lumotlari saqlandi!'),
                                  backgroundColor: AppColors.primary,
                                ),
                              );
                            }
                          } catch (e) {
                            setSheetState(() {
                              isSaving = false;
                              errorText = e.toString().replaceAll('Exception: ', '');
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: isSaving
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                                AppStrings.isRu ? 'Сохранить информацию' : 'Ma\'lumotlarni saqlash',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value, {VoidCallback? onTap, Widget? trailing}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: theme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: theme.primaryColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
