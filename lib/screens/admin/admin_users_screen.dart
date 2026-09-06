import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/localization.dart';
import '../../config/api_config.dart';
import '../../services/api_service.dart';
import '../../services/theme_service.dart';
import '../../models/user.dart';
import '../../widgets/glass_container.dart';

class AdminUsersScreen extends StatefulWidget {
  final ApiService apiService;
  const AdminUsersScreen({super.key, required this.apiService});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  List<UserModel> _users = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    try {
      final users = await widget.apiService.getAdminUsers();
      if (mounted) {
        setState(() {
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showUserDetail(UserModel user) async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final fullUser = await widget.apiService.getAdminUserDetail(user.id);
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      final mode = ThemeService().currentMode;
      final palette = AppTheme.getPalette(mode);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            gradient: palette.bgGradient,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: palette.cardBorder.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: palette.textSecondary.withOpacity(0.3), borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: palette.card,
                          backgroundImage: fullUser.avatar != null 
                            ? NetworkImage('${ApiConfig.baseUrl}${fullUser.avatar}')
                            : null,
                          child: fullUser.avatar == null 
                            ? Icon(Icons.person_rounded, size: 50, color: palette.textSecondary.withOpacity(0.5))
                            : null,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextButton.icon(
                        icon: const Icon(Icons.vpn_key_rounded),
                        label: Text(AppStrings.isRu ? 'Сбросить пароль' : 'Parolni almashtirish'),
                        style: TextButton.styleFrom(foregroundColor: palette.primary),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _changePassword(fullUser);
                        },
                      ),
                      const SizedBox(height: 12),
                      _sectionTitle(AppStrings.isRu ? 'Данные клиента' : 'Mijoz ma\'lumotlari', palette),
                      _detailTile(Icons.person_rounded, AppStrings.isRu ? 'Имя' : 'Ism', fullUser.name, palette),
                      _detailTile(Icons.phone_rounded, AppStrings.isRu ? 'Телефон' : 'Telefon', fullUser.phone, palette),
                      _detailTile(Icons.location_city_rounded, AppStrings.city, fullUser.city ?? '-', palette),
                      _detailTile(Icons.star_rounded, AppStrings.isRu ? 'Рейтинг клиента' : 'Mijoz reytingi', '${fullUser.clientRating} (${fullUser.clientReviewsCount})', palette),
                      
                      if (fullUser.masterProfile != null) ...[
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _sectionTitle(AppStrings.isRu ? 'Данные мастера' : 'Usta ma\'lumotlari', palette),
                            TextButton.icon(
                              icon: const Icon(Icons.edit_rounded, size: 16),
                              label: Text(AppStrings.isRu ? 'Изм. данные' : 'Tahrirlash'),
                              onPressed: () => _editMasterProfile(fullUser),
                            ),
                          ],
                        ),
                        _detailTile(Icons.work_rounded, AppStrings.isRu ? 'Специализация' : 'Mutaxassislik', fullUser.masterProfile!.subcategoryName(AppStrings.lang), palette),
                        _detailTile(Icons.history_rounded, AppStrings.experience, '${fullUser.masterProfile!.experienceYears} ${AppStrings.years}', palette),
                        _detailTile(Icons.payments_rounded, AppStrings.isRu ? 'Цена/час' : 'Narx/soat', '${fullUser.masterProfile!.hourlyRate ?? "-"}', palette),
                        _detailTile(Icons.description_rounded, AppStrings.isRu ? 'Описание' : 'Tavsif', fullUser.masterProfile!.description ?? '-', palette),
                        
                        const SizedBox(height: 16),
                        _sectionTitle(AppStrings.isRu ? 'Статистика отзывов' : 'Sharhlar statistikasi', palette),
                        _buildStats(fullUser.reviewStats, palette),
                      ],
                      const SizedBox(height: 40),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                              label: Text(AppStrings.isRu ? 'Удалить аккаунт' : 'O\'chirish', style: const TextStyle(color: Colors.redAccent)),
                              style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.redAccent)),
                              onPressed: () {
                                Navigator.pop(ctx);
                                _deleteUser(fullUser);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _changePassword(UserModel user) async {
    final palette = AppTheme.currentPalette(context);
    final controller = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.card,
        surfaceTintColor: palette.primary,
        title: Text(AppStrings.isRu ? 'Новый пароль' : 'Yangi parol', style: TextStyle(color: palette.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${AppStrings.isRu ? 'Смена пароля для' : 'Parolni almashtirish:'} ${user.name}',
              style: TextStyle(color: palette.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              style: TextStyle(color: palette.textPrimary),
              decoration: InputDecoration(
                labelText: AppStrings.isRu ? 'Пароль' : 'Parol',
                labelStyle: TextStyle(color: palette.textSecondary),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: palette.textHint.withOpacity(0.3))),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.isRu ? 'Отмена' : 'Bekor', style: TextStyle(color: palette.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: palette.primary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text(AppStrings.isRu ? 'Сохранить' : 'Saqlash'),
          ),
        ],
      ),
    );

    if (result == true && controller.text.isNotEmpty) {
      if (mounted) setState(() => _isLoading = true);
      try {
        await widget.apiService.adminChangeUserPassword(user.id, controller.text);
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.isRu ? 'Пароль успешно изменен' : 'Parol muvaffaqiyatli almashtirildi'),
              backgroundColor: Colors.green,
            )
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Widget _buildStats(List<Map<String, dynamic>>? stats, ThemePalette palette) {
    if (stats == null || stats.isEmpty) {
      return Text(AppStrings.isRu ? 'Отзывов еще нет' : 'Sharhlar yo\'q', style: TextStyle(color: palette.textSecondary, fontStyle: FontStyle.italic));
    }

    final Map<int, int> data = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (var s in stats) {
      data[s['rating']] = s['count'];
    }

    return Column(
      children: [5, 4, 3, 2, 1].map((star) {
        final count = data[star] ?? 0;
        final total = data.values.fold(0, (a, b) => a + b);
        final percent = total > 0 ? count / total : 0.0;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              SizedBox(width: 15, child: Text('$star', style: TextStyle(color: palette.textSecondary))),
              const Icon(Icons.star_rounded, size: 12, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: palette.cardBorder.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      star >= 4 ? Colors.green : (star == 3 ? Colors.orange : Colors.red),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(width: 30, child: Text('$count', style: TextStyle(color: palette.textHint, fontSize: 12))),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _sectionTitle(String title, ThemePalette palette) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: palette.textPrimary)),
    );
  }

  Widget _detailTile(IconData icon, String label, String value, ThemePalette palette) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: palette.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: palette.textSecondary)),
                Text(value, style: TextStyle(fontSize: 16, color: palette.textPrimary, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteUser(UserModel user) async {
    final palette = AppTheme.currentPalette(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.card,
        title: Text(AppStrings.isRu ? 'Полное удаление?' : 'To\'liq o\'chirish?', style: TextStyle(color: palette.textPrimary)),
        content: Text(
          AppStrings.isRu 
            ? 'Это удалит ВСЕ данные пользователя ${user.name}, включая заказы и отзывы. Это действие необратимо.'
            : 'Bu foydalanuvchining barcha ma\'lumotlarini, shu jumladan buyurtmalar va sharhlarni o\'chirib tashlaydi. Bu amalni qaytarib bo\'lmaydi.',
          style: TextStyle(color: palette.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.isRu ? 'Отмена' : 'Bekor', style: TextStyle(color: palette.textSecondary))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text(AppStrings.isRu ? 'Удалить' : 'O\'chirish', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (mounted) setState(() => _isLoading = true);
      try {
        await widget.apiService.deleteUser(user.id);
        _fetchUsers(); 
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _editMasterProfile(UserModel user) async {
    final palette = AppTheme.currentPalette(context);
    final descController = TextEditingController(text: user.masterProfile?.description);
    final expController = TextEditingController(text: user.masterProfile?.experienceYears.toString());
    final rateController = TextEditingController(text: user.masterProfile?.hourlyRate?.toString());
    final cityController = TextEditingController(text: user.masterProfile?.city ?? user.city);
    final districtController = TextEditingController(text: user.masterProfile?.district);

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: palette.card,
        surfaceTintColor: palette.primary,
        title: Text(AppStrings.isRu ? 'Данные мастера' : 'Usta ma\'lumotlari', style: TextStyle(color: palette.textPrimary)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildField(AppStrings.city, cityController, palette),
              _buildField(AppStrings.isRu ? 'Район' : 'Tuman', districtController, palette),
              _buildField(AppStrings.isRu ? 'Стаж (лет)' : 'Tajriba (yil)', expController, palette, keyboardType: TextInputType.number),
              _buildField(AppStrings.isRu ? 'Цена в час' : 'Soatiga narx', rateController, palette, keyboardType: TextInputType.number),
              _buildField(AppStrings.isRu ? 'Описание' : 'Tavsif', descController, palette, maxLines: 3),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.isRu ? 'Отмена' : 'Bekor', style: TextStyle(color: palette.textSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: palette.primary, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text(AppStrings.isRu ? 'Сохранить' : 'Saqlash'),
          ),
        ],
      ),
    );

    if (result == true) {
      if (mounted) setState(() => _isLoading = true);
      try {
        await widget.apiService.updateMasterProfileAdmin(user.id, {
          'description': descController.text,
          'experience_years': int.tryParse(expController.text) ?? 1,
          'hourly_rate': double.tryParse(rateController.text) ?? 0.0,
          'city': cityController.text,
          'district': districtController.text,
        });
        if (mounted) {
          // Refresh list instead of trying to reopen sheet
          _fetchUsers();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Future<void> _editUser(UserModel user) async {
    final palette = AppTheme.currentPalette(context);
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);
    final cityController = TextEditingController(text: user.city);
    String selectedRole = user.role;
    bool isBlocked = user.isBlocked;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: palette.card,
          surfaceTintColor: palette.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(AppStrings.isRu ? 'Редактировать' : 'Tahrirlash', style: TextStyle(color: palette.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildField(AppStrings.isRu ? 'Имя' : 'Ism', nameController, palette),
                _buildField(AppStrings.isRu ? 'Телефон' : 'Telefon', phoneController, palette),
                _buildField(AppStrings.isRu ? 'Город' : 'Shahar', cityController, palette),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedRole,
                  dropdownColor: palette.card,
                  style: TextStyle(color: palette.textPrimary),
                  decoration: InputDecoration(
                    labelText: AppStrings.isRu ? 'Роль' : 'Rol',
                    labelStyle: TextStyle(color: palette.textSecondary),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: ['client', 'master', 'admin'].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                  onChanged: (val) {
                    if (val != null) setDialogState(() => selectedRole = val);
                  },
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: Text(AppStrings.isRu ? 'Заблокирован' : 'Bloklangan', style: TextStyle(color: palette.textPrimary)),
                  value: isBlocked,
                  onChanged: (val) => setDialogState(() => isBlocked = val),
                  activeColor: palette.primary,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppStrings.isRu ? 'Отмена' : 'Bekor', style: TextStyle(color: palette.textSecondary))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: palette.primary, foregroundColor: Colors.white),
              onPressed: () => Navigator.pop(ctx, true), 
              child: Text(AppStrings.isRu ? 'Сохранить' : 'Saqlash'),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      if (mounted) setState(() => _isLoading = true);
      try {
        await widget.apiService.updateUserAdmin(user.id, {
          'name': nameController.text,
          'phone': phoneController.text,
          'city': cityController.text,
          'role': selectedRole,
          'is_blocked': isBlocked,
        });
        _fetchUsers();
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  Widget _buildField(String label, TextEditingController controller, ThemePalette palette, {TextInputType? keyboardType, int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        style: TextStyle(color: palette.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: palette.textSecondary),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: palette.textHint.withOpacity(0.3))),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: palette.primary)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeMode>(
      valueListenable: ThemeService().themeNotifier,
      builder: (context, mode, child) {
        final palette = AppTheme.getPalette(mode);
        
        if (_isLoading) return Center(child: CircularProgressIndicator(color: palette.primary));
 
        return RefreshIndicator(
          onRefresh: _fetchUsers,
          color: palette.primary,
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: _users.length,
            itemBuilder: (context, index) {
              final user = _users[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassContainer(
                  padding: const EdgeInsets.all(4),
                  child: ListTile(
                    onTap: () => _showUserDetail(user),
                    leading: CircleAvatar(
                      radius: 20,
                      backgroundColor: user.isBlocked ? Colors.red.withOpacity(0.2) : palette.primary.withOpacity(0.1),
                      backgroundImage: user.avatar != null 
                        ? NetworkImage('${ApiConfig.baseUrl}${user.avatar}')
                        : null,
                      child: user.avatar == null 
                        ? Text(
                            user.name.isNotEmpty ? user.name[0].toUpperCase() : '?', 
                            style: TextStyle(color: user.isBlocked ? Colors.red : palette.primary, fontWeight: FontWeight.bold)
                          )
                        : null,
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name, 
                            style: TextStyle(color: palette.textPrimary, fontWeight: FontWeight.bold)
                          )
                        ),
                        if (user.role == 'master' || user.role == 'admin')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: palette.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                            child: Text(
                              user.role == 'admin' ? 'A' : 'M', 
                              style: TextStyle(color: palette.primary, fontSize: 10, fontWeight: FontWeight.bold)
                            ),
                          ),
                      ],
                    ),
                    subtitle: Text('${user.phone}', style: TextStyle(color: palette.textSecondary)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.vpn_key_rounded, color: palette.primary.withOpacity(0.6), size: 18),
                          onPressed: () => _changePassword(user),
                          tooltip: AppStrings.isRu ? 'Сменить пароль' : 'Parolni almashtirish',
                        ),
                        IconButton(
                          icon: Icon(Icons.edit_outlined, color: palette.primary.withOpacity(0.7), size: 18),
                          onPressed: () => _editUser(user),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                          onPressed: () => _deleteUser(user),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
