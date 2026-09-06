import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/localization.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  final AuthService authService;
  const SettingsScreen({super.key, required this.authService});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late String _currentLang;
  late AppThemeMode _currentMode;

  @override
  void initState() {
    super.initState();
    _currentLang = AppStrings.lang;
    _currentMode = ThemeService().currentMode;
  }

  void _changeLang(String lang) async {
    AppStrings.setLang(lang);
    await widget.authService.saveLang(lang);
    setState(() => _currentLang = lang);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppTheme.getPalette(ThemeService().currentMode);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.settings),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.currentGradient(context)),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Language
            Text(
              AppStrings.language,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            _buildLangOption('ru', AppStrings.russian, '🇷🇺'),
            const SizedBox(height: 8),
            _buildLangOption('uz', AppStrings.uzbek, '🇺🇿'),

            const SizedBox(height: 32),

            // Theme
            Text(
              AppStrings.isRu ? 'Оформление' : 'Mavzu',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).textTheme.bodyLarge?.color),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildThemeOption(AppThemeMode.light, AppStrings.isRu ? 'Светлая' : 'Yorug\'', Icons.light_mode_rounded, Colors.orange),
                  _buildThemeOption(AppThemeMode.dark, AppStrings.isRu ? 'Темная' : 'Tungi', Icons.dark_mode_rounded, Colors.indigo),
                  _buildThemeOption(AppThemeMode.oled, AppStrings.isRu ? 'OLED' : 'OLED', Icons.brightness_2_rounded, Colors.black),
                  _buildThemeOption(AppThemeMode.blue, AppStrings.isRu ? 'Синяя' : 'Ko\'k', Icons.water_drop_rounded, Colors.blue),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // About
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.search_rounded, color: Colors.white, size: 28),
                  ),
                  const SizedBox(height: 12),
                  Text(AppStrings.appName, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text('v1.0.0', style: theme.textTheme.bodySmall),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.appSlogan,
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // App Reviews
            GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/app-reviews'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.rate_review_rounded, color: theme.primaryColor, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        AppStrings.isRu ? 'Отзывы о приложении' : 'Ilova haqida fikrlar',
                        style: theme.textTheme.titleMedium?.copyWith(fontSize: 16),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: theme.dividerColor),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Logout
            GestureDetector(
              onTap: () async {
                await widget.authService.logout();
                if (mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, '/register', (_) => false);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: theme.cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.logout_rounded, color: theme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.logout,
                      style: TextStyle(color: theme.primaryColor, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),

            // Delete Account
            GestureDetector(
              onTap: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(AppStrings.isRu ? 'Удалить аккаунт?' : 'Akkauntni o\'chirish?'),
                    content: Text(
                      AppStrings.isRu 
                        ? 'Вы уверены, что хотите удалить свой аккаунт? Это действие необратимо и все ваши данные будут удалены.'
                        : 'Akkauntingizni o\'chirishga ishonchingiz komilmi? Bu harakat ortga qaytarilmaydi va barcha ma\'lumotlaringiz o\'chiriladi.'
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(AppStrings.isRu ? 'Отмена' : 'Bekor qilish'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        child: Text(
                          AppStrings.isRu ? 'Удалить' : 'O\'chirish', 
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true && mounted) {
                  // Show loading overlay while deleting
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (_) => const Center(child: CircularProgressIndicator()),
                  );
                  
                  try {
                    await widget.authService.deleteAccount();
                    if (mounted) {
                      Navigator.pop(context); // close loading
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                    }
                  } catch (e) {
                    if (mounted) {
                      Navigator.pop(context); // close loading
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString())),
                      );
                    }
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.delete_forever_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.isRu ? 'Удалить аккаунт' : 'Akkauntni o\'chirish',
                      style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(AppThemeMode mode, String label, IconData icon, Color color) {
    final selected = _currentMode == mode;
    final theme = Theme.of(context);
    
    return GestureDetector(
      onTap: () {
        ThemeService().setTheme(mode);
        setState(() => _currentMode = mode);
      },
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? theme.primaryColor : theme.dividerColor.withOpacity(0.1),
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: selected ? theme.primaryColor : color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                color: selected ? theme.primaryColor : theme.textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLangOption(String lang, String label, String flag) {
    final theme = Theme.of(context);
    final selected = _currentLang == lang;
    return GestureDetector(
      onTap: () => _changeLang(lang),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? theme.primaryColor : theme.dividerColor.withOpacity(0.5),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Text(label, style: theme.textTheme.bodyLarge?.copyWith(
              color: selected ? theme.primaryColor : theme.textTheme.bodyLarge?.color,
              fontWeight: FontWeight.w600,
            )),
            const Spacer(),
            if (selected) Icon(Icons.check_circle_rounded, color: theme.primaryColor, size: 22),
          ],
        ),
      ),
    );
  }
}
