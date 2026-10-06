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
import '../models/user.dart';
import '../models/subscription.dart';
import 'admin/admin_panel_screen.dart';
import '../config/regions.dart';
import 'orders/accepted_orders_screen.dart';
import 'favorites_screen.dart';
import '../widgets/master_cv_view.dart';
import '../utils/phone_utils.dart';

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
      setState(() => _isLoadingMaster = true);
      try {
        final profile = await widget.apiService.getMyMasterProfile();
        if (mounted) setState(() => _masterProfile = profile);
      } catch (_) {
        if (mounted) setState(() => _masterProfile = null);
      } finally {
        if (mounted) setState(() => _isLoadingMaster = false);
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
                ] else if (user.isBranchAdmin) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.admin_panel_settings_rounded, size: 16, color: Colors.blue),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            AppStrings.isRu
                                ? 'Администратор филиала: ${user.managedBranch!['branch_name'] ?? ""}'
                                : 'Filial administratori: ${user.managedBranch!['branch_name'] ?? ""}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
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
                _infoTile(Icons.phone_rounded, AppStrings.phone, PhoneUtils.formatPhone(user.phone)),

                // Location on Map Card (Clickable to change position) - only for individuals/masters
                if (!isCompany)
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

                // Company Description & Multi-Branch Network Cards
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
                  const SizedBox(height: 12),
                  _buildCompanyBranchesSection(context, theme, user),
                ],

                // Master Info Box (CV / Resume) - ONLY for individuals/masters, NEVER for companies
                if (!isCompany) ...[
                  if (_isLoadingMaster)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator(color: theme.primaryColor)),
                    )
                  else if (_masterProfile != null) ...[
                    const SizedBox(height: 24),
                    MasterCvView(
                      master: _masterProfile!,
                      isOwner: true,
                      apiService: widget.apiService,
                      onEdit: () {
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
                      onLocationTap: _openLocationPicker,
                      onProfileUpdated: _loadMasterProfile,
                    ),
                  ],
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
                    backgroundColor: const Color(0xFFF59E0B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    minimumSize: const Size(double.infinity, 50),
                    elevation: 2,
                  ),
                  icon: const Icon(Icons.star_rounded, size: 22),
                  label: Text(AppStrings.isRu ? 'Избранные' : 'Sevimlilar', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FavoritesScreen(
                          apiService: widget.apiService,
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                ],

                if (isCompany) ...[
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
                ] else if (user.role == 'master' || user.role == 'admin') ...[
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
                              companyBranches: user.companyBranches,
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

  Widget _buildCompanyBranchesSection(BuildContext context, ThemeData theme, UserModel user) {
    final isRu = AppStrings.isRu;
    final branches = user.companyBranches;
    final canManage = user.canManageBranches;

    if (!canManage && branches.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.storefront_rounded, color: Colors.amber, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isRu ? 'Филиалы компании (сеть)' : 'Kompaniya filiallar tarmog\'i',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isRu
                        ? 'Управление сетью филиалов (Чиланзар, Юнусабад и др.) активируется администратором сервиса.'
                        : 'Filiallar tarmog\'ini qo\'shish administrator tasdig\'idan so\'ng faollashtiriladi.',
                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.store_mall_directory_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    Text(
                      isRu ? 'Филиалы компании' : 'Kompaniya filiallari',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${branches.length}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              if (canManage)
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => _showBranchModal(),
                  child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add_rounded, size: 16, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        isRu ? 'Добавить' : 'Qo\'shish',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (branches.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Icon(Icons.add_business_rounded, size: 36, color: theme.hintColor.withValues(alpha: 0.5)),
                  const SizedBox(height: 8),
                  Text(
                    isRu
                        ? 'Вы можете добавить все филиалы (например: Чиланзар, Юнусабад, Самарканд) с точными адресами и точками на карте.'
                        : 'Barcha filiallarni (masalan: Chilonzor, Yunusobod, Samarqand) aniq xarita nuqtalari bilan qo\'shishingiz mumkin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: theme.hintColor),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => _showBranchModal(),
                    icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                    label: Text(isRu ? 'Добавить первый филиал' : 'Birinchi filialni qo\'shish'),
                  ),
                ],
              ),
            ),
          ] else ...[
            ...branches.asMap().entries.map((entry) {
              final idx = entry.key;
              final b = entry.value;
              final name = b['name']?.toString() ?? '';
              final city = b['city']?.toString() ?? '';
              final district = b['district']?.toString() ?? '';
              final address = b['address']?.toString() ?? '';
              final lat = b['lat'] != null ? (b['lat'] as num).toDouble() : null;
              final lon = b['lon'] != null ? (b['lon'] as num).toDouble() : null;
              final phone = b['phone']?.toString() ?? '';
              final isLast = idx == branches.length - 1;

              return Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.store_rounded, size: 18, color: AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              if (city.isNotEmpty || district.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  '$city${district.isNotEmpty ? ", $district" : ""}',
                                  style: TextStyle(fontSize: 12, color: theme.hintColor),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, size: 18, color: AppColors.primary),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _showBranchModal(branch: b, index: idx),
                            ),
                            const SizedBox(width: 10),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _deleteBranch(idx),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (address.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on_outlined, size: 14, color: theme.hintColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              address,
                              style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (lat != null && lon != null || phone.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          if (lat != null && lon != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.pin_drop_rounded, size: 12, color: Colors.blue),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                                  ),
                                ],
                              ),
                            ),
                          if (phone.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.phone_rounded, size: 12, color: Colors.green),
                                  const SizedBox(width: 4),
                                  Text(
                                    phone,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],

                    // Branch Administrators Section
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color ?? Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    const Icon(Icons.badge_rounded, size: 16, color: AppColors.primary),
                                    const SizedBox(width: 6),
                                    Flexible(
                                      child: Text(
                                        isRu ? 'Админ филиала' : 'Filial admini',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if ((b['administrators'] as List?)?.isEmpty ?? true)
                                TextButton.icon(
                                  style: TextButton.styleFrom(
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16, color: AppColors.primary),
                                  label: Text(
                                    isRu ? '+ Добавить' : '+ Qo\'shish',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                  onPressed: () => _showAddBranchAdminSheet(idx, b),
                                ),
                            ],
                          ),
                          if ((b['administrators'] as List?)?.isNotEmpty == true) ...[
                            const SizedBox(height: 8),
                            ...((b['administrators'] as List).asMap().entries.map((adminEntry) {
                              final adminIdx = adminEntry.key;
                              final admin = adminEntry.value as Map<String, dynamic>;
                              final adminName = admin['name']?.toString() ?? 'Администратор';
                              final adminPhone = admin['phone']?.toString() ?? '';
                              final adminAvatar = admin['avatar']?.toString();

                              return Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 14,
                                      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                                      backgroundImage: (adminAvatar != null && adminAvatar.isNotEmpty)
                                          ? NetworkImage(adminAvatar.startsWith('http')
                                              ? adminAvatar
                                              : '${ApiConfig.baseUrl.replaceAll("/api", "")}$adminAvatar')
                                          : null,
                                      child: (adminAvatar == null || adminAvatar.isEmpty)
                                          ? const Icon(Icons.person, size: 16, color: AppColors.primary)
                                          : null,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            adminName,
                                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                          ),
                                          if (adminPhone.isNotEmpty)
                                            Text(
                                              PhoneUtils.formatPhone(adminPhone),
                                              style: TextStyle(fontSize: 11, color: theme.hintColor),
                                            ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline_rounded, size: 18, color: Colors.red),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                      tooltip: isRu ? 'Удалить администратора' : 'O\'chirish',
                                      onPressed: () => _removeBranchAdmin(idx, adminIdx),
                                    ),
                                  ],
                                ),
                              );
                            })),
                          ] else ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Text(
                                isRu
                                    ? 'Администраторы не назначены. Назначенный администратор сможет искать работников только для этого филиала.'
                                    : 'Administratorlar tayinlanmagan. Tayinlangan xodim faqat shu filial uchun ishchi topa oladi.',
                                style: TextStyle(fontSize: 11, color: theme.hintColor),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Future<void> _removeBranchAdmin(int branchIdx, int adminIdx) async {
    final isRu = AppStrings.isRu;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isRu ? 'Удалить администратора?' : 'Administratorni o\'chirish?'),
        content: Text(isRu
            ? 'Этот пользователь больше не сможет искать работников для данного филиала.'
            : 'Bu foydalanuvchi endi ushbu filial uchun ishchi qidira olmaydi.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isRu ? 'Отмена' : 'Bekor qilish')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isRu ? 'Удалить' : 'O\'chirish'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final user = widget.authService.currentUser;
    if (user == null) return;
    final branches = List<Map<String, dynamic>>.from(user.companyBranches);
    if (branchIdx >= branches.length) return;

    final targetBranch = Map<String, dynamic>.from(branches[branchIdx]);
    final admins = List<Map<String, dynamic>>.from(targetBranch['administrators'] ?? []);
    if (adminIdx < admins.length) {
      admins.removeAt(adminIdx);
      targetBranch['administrators'] = admins;
      branches[branchIdx] = targetBranch;
      try {
        await widget.authService.updateProfile(companyBranches: branches);
        await widget.authService.refreshUser();
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isRu ? 'Администратор удален' : 'Administrator o\'chirildi')),
          );
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showAddBranchAdminSheet(int branchIdx, Map<String, dynamic> branch) {
    final theme = Theme.of(context);
    final isRu = AppStrings.isRu;
    final phoneCtrl = TextEditingController();
    final phoneMaskFormatter = PhoneUtils.uzPhoneMaskFormatter;
    bool isSearching = false;
    bool isAdding = false;
    String? searchError;
    Map<String, dynamic>? foundUser;

    Future<void> performLookup(StateSetter setSheetState) async {
      final digits = phoneCtrl.text.replaceAll(RegExp(r'\D'), '');
      if (digits.length != 9) {
        setSheetState(() {
          searchError = isRu
              ? 'Номер должен содержать ровно 9 цифр (например: 99 999 99 99)'
              : 'Raqam aynan 9 ta raqamdan iborat bo\'lishi kerak (masalan: 99 999 99 99)';
          foundUser = null;
        });
        return;
      }
      setSheetState(() {
        isSearching = true;
        searchError = null;
        foundUser = null;
      });
      try {
        final fullPhone = '+998$digits';
        final u = await widget.apiService.lookupUserByPhone(fullPhone);
        setSheetState(() {
          isSearching = false;
          if (u == null) {
            searchError = isRu
                ? 'Такого пользователя нет в системе. Попросите его сначала зарегистрироваться в приложении.'
                : 'Bunday foydalanuvchi tizimda topilmadi. Avval ilovadan ro\'yxatdan o\'tishini so\'rang.';
            foundUser = null;
          } else {
            foundUser = u;
            searchError = null;
          }
        });
      } catch (e) {
        setSheetState(() {
          isSearching = false;
          final msg = e.toString().replaceFirst('Exception: ', '').trim();
          searchError = msg.isNotEmpty
              ? msg
              : (isRu ? 'Такого пользователя нет в системе' : 'Bunday foydalanuvchi topilmadi');
          foundUser = null;
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.hintColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRu ? 'Назначить администратора' : 'Administrator tayinlash',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        Text(
                          isRu ? 'Филиал: «${branch['name']}»' : 'Filial: «${branch['name']}»',
                          style: TextStyle(fontSize: 12, color: theme.hintColor),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                isRu
                    ? 'Введите номер телефона сотрудника (в формате 99 999 99 99). Добавленный администратор сможет находить работников исключительно для этого филиала.'
                    : 'Xodimning telefon raqamini kiriting (99 999 99 99 formatida). Tayinlangan administrator faqat ushbu filial uchun ishchilarni qidira oladi.',
                style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8)),
              ),
              const SizedBox(height: 16),

              // Phone Field with strict 9-digit uzPhoneMaskFormatter
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                autofocus: true,
                inputFormatters: [phoneMaskFormatter],
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 1.0,
                ),
                decoration: InputDecoration(
                  labelText: isRu ? 'Номер телефона пользователя' : 'Foydalanuvchi telefon raqami',
                  hintText: '99 999 99 99',
                  prefixText: '+998 ',
                  prefixStyle: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1.0,
                  ),
                  prefixIcon: const Icon(Icons.phone_android_rounded, color: AppColors.primary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  suffixIcon: isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : IconButton(
                          icon: const Icon(Icons.search_rounded, color: AppColors.primary),
                          onPressed: () => performLookup(setSheetState),
                        ),
                ),
                onSubmitted: (_) => performLookup(setSheetState),
              ),

              if (searchError != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          searchError!,
                          style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (foundUser != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        backgroundImage: (foundUser!['avatar'] != null && foundUser!['avatar'].toString().isNotEmpty)
                            ? NetworkImage(foundUser!['avatar'].toString().startsWith('http')
                                ? foundUser!['avatar']
                                : '${ApiConfig.baseUrl.replaceAll("/api", "")}${foundUser!['avatar']}')
                            : null,
                        child: (foundUser!['avatar'] == null || foundUser!['avatar'].toString().isEmpty)
                            ? const Icon(Icons.person, size: 28, color: AppColors.primary)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              foundUser!['name'] ?? 'Пользователь',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              PhoneUtils.formatPhone(foundUser!['phone'] ?? ''),
                              style: TextStyle(fontSize: 13, color: theme.hintColor),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                isRu ? 'Пользователь найден' : 'Foydalanuvchi topildi',
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: isAdding
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_circle_rounded),
                    label: Text(
                      isRu ? 'Назначить администратором' : 'Administrator etib tayinlash',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    onPressed: isAdding ? null : () async {
                      setSheetState(() => isAdding = true);
                      try {
                        final user = widget.authService.currentUser;
                        if (user == null) return;
                        final branches = List<Map<String, dynamic>>.from(user.companyBranches);
                        if (branchIdx >= branches.length) return;

                        final targetBranch = Map<String, dynamic>.from(branches[branchIdx]);
                        final admins = List<Map<String, dynamic>>.from(targetBranch['administrators'] ?? []);

                        final already = admins.any((a) => a['user_id'] == foundUser!['id'] || a['phone'] == foundUser!['phone']);
                        if (already) {
                          setSheetState(() {
                            isAdding = false;
                            searchError = isRu ? 'Этот пользователь уже назначен администратором' : 'Bu foydalanuvchi allaqachon tayinlangan';
                          });
                          return;
                        }

                        final singleAdmin = {
                          'user_id': foundUser!['id'],
                          'name': foundUser!['name'],
                          'phone': foundUser!['phone'],
                          'avatar': foundUser!['avatar'],
                        };
                        targetBranch['administrators'] = [singleAdmin];
                        branches[branchIdx] = targetBranch;

                        await widget.authService.updateProfile(companyBranches: branches);
                        await widget.authService.refreshUser();
                        if (mounted) {
                          setState(() {});
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isRu ? 'Администратор успешно добавлен!' : 'Administrator muvaffaqiyatli qo\'shildi!'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      } catch (e) {
                        setSheetState(() {
                          isAdding = false;
                          searchError = 'Error: $e';
                        });
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showBranchModal({Map<String, dynamic>? branch, int? index}) {
    final theme = Theme.of(context);
    final isRu = AppStrings.isRu;
    final nameCtrl = TextEditingController(text: branch?['name'] ?? '');
    final addressCtrl = TextEditingController(text: branch?['address'] ?? '');

    String? selectedCityKey = branch?['city_key'] ?? RegionsConfig.regionKeys.first;
    String? selectedDistrictKey = branch?['district_key'];
    double? branchLat = branch?['lat'] != null ? (branch!['lat'] as num).toDouble() : null;
    double? branchLon = branch?['lon'] != null ? (branch!['lon'] as num).toDouble() : null;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.hintColor.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      index != null
                          ? (isRu ? 'Редактировать филиал' : 'Filialni tahrirlash')
                          : (isRu ? 'Добавить филиал' : 'Filial qo\'shish'),
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Branch Name
                TextField(
                  controller: nameCtrl,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: isRu ? 'Название филиала *' : 'Filial nomi *',
                    hintText: isRu ? 'Например: Филиал Чиланзар, Филиал Ц-1' : 'Masalan: Chilonzor filiali',
                    prefixIcon: const Icon(Icons.store_mall_directory_rounded, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 14),

                // Region / City
                DropdownButtonFormField<String>(
                  value: selectedCityKey,
                  dropdownColor: theme.cardTheme.color,
                  decoration: InputDecoration(
                    labelText: isRu ? 'Регион / Город *' : 'Viloyat / Shahar *',
                    prefixIcon: const Icon(Icons.location_city_rounded, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  items: RegionsConfig.regionKeys.map((key) {
                    return DropdownMenuItem<String>(
                      value: key,
                      child: Text(RegionsConfig.getDisplayName(key)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    setModalState(() {
                      selectedCityKey = val;
                      selectedDistrictKey = null;
                    });
                  },
                ),
                const SizedBox(height: 14),

                // District
                if (selectedCityKey != null && RegionsConfig.getDistricts(selectedCityKey!).isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    value: selectedDistrictKey,
                    dropdownColor: theme.cardTheme.color,
                    decoration: InputDecoration(
                      labelText: isRu ? 'Район' : 'Tuman',
                      prefixIcon: const Icon(Icons.map_outlined, color: AppColors.primary),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: RegionsConfig.getDistricts(selectedCityKey!).map((displayName) {
                      final key = RegionsConfig.getDistrictKey(displayName, selectedCityKey);
                      return DropdownMenuItem<String>(
                        value: key,
                        child: Text(displayName),
                      );
                    }).toList(),
                    onChanged: (val) => setModalState(() => selectedDistrictKey = val),
                  ),
                  const SizedBox(height: 14),
                ],

                // Address
                TextField(
                  controller: addressCtrl,
                  style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    labelText: isRu ? 'Точный адрес *' : 'Aniq manzil *',
                    hintText: isRu ? 'Например: ул. Катартал, 28 (ор-р ТЦ Парус)' : 'Masalan: Qatortol ko\'chasi, 28',
                    prefixIcon: const Icon(Icons.home_work_rounded, color: AppColors.primary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
                const SizedBox(height: 14),

                // Map location button
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    final result = await Navigator.push<LocationPickerResult>(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LocationPickerScreen(
                          initialLat: branchLat,
                          initialLon: branchLon,
                          initialAddress: addressCtrl.text.isNotEmpty ? addressCtrl.text : null,
                        ),
                      ),
                    );
                    if (result != null) {
                      setModalState(() {
                        branchLat = result.latitude;
                        branchLon = result.longitude;
                        if (addressCtrl.text.trim().isEmpty && result.address != null && result.address!.isNotEmpty) {
                          addressCtrl.text = result.address!;
                        }
                      });
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: branchLat != null
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : theme.scaffoldBackgroundColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: branchLat != null
                            ? AppColors.primary.withValues(alpha: 0.3)
                            : theme.dividerColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.pin_drop_rounded, color: branchLat != null ? AppColors.primary : Colors.grey),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isRu ? 'Точка филиала на карте' : 'Xaritada filial nuqtasi',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              Text(
                                branchLat != null
                                    ? 'Lat: ${branchLat!.toStringAsFixed(4)}, Lon: ${branchLon!.toStringAsFixed(4)}'
                                    : (isRu ? 'Нажмите, чтобы отметить на карте 📍' : 'Xaritada belgilash uchun bosing 📍'),
                                style: TextStyle(fontSize: 11, color: theme.hintColor),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // Save button
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: isSaving ? null : () async {
                      final name = nameCtrl.text.trim();
                      final address = addressCtrl.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(isRu ? 'Введите название филиала' : 'Filial nomini kiriting')),
                        );
                        return;
                      }
                      if (address.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text(isRu ? 'Введите адрес филиала' : 'Filial manzilini kiriting')),
                        );
                        return;
                      }

                      setModalState(() => isSaving = true);
                      try {
                        final user = widget.authService.currentUser;
                        if (user == null) return;

                        final cityDisplay = selectedCityKey != null ? RegionsConfig.getDisplayName(selectedCityKey!) : '';
                        final districtDisplay = (selectedDistrictKey != null && selectedCityKey != null)
                            ? RegionsConfig.getDistrictDisplay(selectedDistrictKey!, selectedCityKey!)
                            : null;

                        final newBranch = {
                          'id': branch?['id'] ?? 'branch_${DateTime.now().millisecondsSinceEpoch}',
                          'name': name,
                          'city': cityDisplay,
                          'city_key': selectedCityKey,
                          'district': districtDisplay,
                          'district_key': selectedDistrictKey,
                          'address': address,
                          'lat': branchLat,
                          'lon': branchLon,
                          if (branch?['phone'] != null) 'phone': branch!['phone'],
                          if (branch?['administrators'] != null) 'administrators': branch!['administrators'],
                        };

                        final currentBranches = List<Map<String, dynamic>>.from(user.companyBranches);
                        if (index != null && index < currentBranches.length) {
                          currentBranches[index] = newBranch;
                        } else {
                          currentBranches.add(newBranch);
                        }

                        await widget.authService.updateProfile(companyBranches: currentBranches);
                        await widget.authService.refreshUser();
                        if (mounted) {
                          setState(() {});
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isRu ? 'Филиал сохранен!' : 'Filial saqlandi!'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        }
                      } catch (e) {
                        setModalState(() => isSaving = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                        );
                      }
                    },
                    child: Text(isRu ? 'Сохранить филиал' : 'Filialni saqlash', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteBranch(int index) async {
    final isRu = AppStrings.isRu;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isRu ? 'Удалить филиал?' : 'Filialni o\'chirish?'),
        content: Text(isRu ? 'Вы уверены, что хотите удалить этот филиал?' : 'Haqiqatan ham bu filialni o\'chirmoqchimisiz?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isRu ? 'Отмена' : 'Bekor')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isRu ? 'Удалить' : 'O\'chirish'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final user = widget.authService.currentUser;
      if (user == null) return;
      final currentBranches = List<Map<String, dynamic>>.from(user.companyBranches);
      if (index < currentBranches.length) {
        currentBranches.removeAt(index);
        await widget.authService.updateProfile(companyBranches: currentBranches);
        await widget.authService.refreshUser();
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isRu ? 'Филиал удален' : 'Filial o\'chirildi')),
          );
        }
      }
    } catch (_) {}
  }
}
