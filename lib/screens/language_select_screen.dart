import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';
import '../config/localization.dart';
import '../services/auth_service.dart';

class LanguageSelectScreen extends StatefulWidget {
  final AuthService authService;
  const LanguageSelectScreen({super.key, required this.authService});

  @override
  State<LanguageSelectScreen> createState() => _LanguageSelectScreenState();
}

class _LanguageSelectScreenState extends State<LanguageSelectScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedLang;
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_selectedLang == null) return;
    AppStrings.setLang(_selectedLang!);
    await widget.authService.saveLang(_selectedLang!);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('lang_selected', true);
    if (mounted) Navigator.pushReplacementNamed(context, '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: AppTheme.currentGradient(context)),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 60),

                    // Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset('assets/images/logo.png', fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      AppStrings.appName,
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 48),

                    // prompt
                    Text(
                      'Tilni tanlang / Выберите язык',
                      style: theme.textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Language options
                    _LangCard(
                      flag: '🇷🇺',
                      name: 'Русский',
                      subtitle: 'Russian',
                      selected: _selectedLang == 'ru',
                      onTap: () => setState(() => _selectedLang = 'ru'),
                    ),
                    const SizedBox(height: 16),
                    _LangCard(
                      flag: '🇺🇿',
                      name: "O'zbek",
                      subtitle: 'Uzbek',
                      selected: _selectedLang == 'uz',
                      onTap: () => setState(() => _selectedLang = 'uz'),
                    ),

                    const Spacer(),

                    // Confirm button
                    AnimatedOpacity(
                      opacity: _selectedLang != null ? 1.0 : 0.4,
                      duration: const Duration(milliseconds: 300),
                      child: GestureDetector(
                        onTap: _selectedLang != null ? _confirm : null,
                        child: Container(
                          width: double.infinity,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              _selectedLang == 'uz' ? 'Davom etish →' : 'Продолжить →',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LangCard extends StatelessWidget {
  final String flag;
  final String name;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _LangCard({
    required this.flag,
    required this.name,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.08) : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : theme.dividerColor.withOpacity(0.5),
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
            ? [BoxShadow(color: AppColors.primary.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 4))]
            : [],
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 36)),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primary : null,
                )),
                Text(subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
            const Spacer(),
            AnimatedScale(
              scale: selected ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 26),
            ),
          ],
        ),
      ),
    );
  }
}
