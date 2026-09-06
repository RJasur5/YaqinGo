import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../../config/theme.dart';
import '../../config/localization.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/gradient_button.dart';
import '../../utils/phone_utils.dart';
import '../home_screen.dart';

class RegisterScreen extends StatefulWidget {
  final AuthService authService;
  const RegisterScreen({super.key, required this.authService});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController(text: '+998 ');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureConfirmPassword = true;
  final _phoneFormatter = PhoneUtils.maskFormatter;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _acceptedPolicy = false;
  String? _error;

  // Wizard state: 1 = Form, 2 = Account Type Selection, 3 = OTP Verification
  int _step = 1;
  String _selectedAccountType = 'person'; // 'person' or 'company'

  // SMS verification state
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());
  Timer? _countdownTimer;
  int _secondsRemaining = 0;
  int _resendCooldown = 0;
  bool _isSendingCode = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_protectPrefix);
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  void _protectPrefix() {
    const prefix = '+998 ';
    if (!_phoneController.text.startsWith(prefix)) {
      _phoneController.removeListener(_protectPrefix);
      _phoneController.text = prefix;
      _phoneController.selection = TextSelection.fromPosition(
        TextPosition(offset: prefix.length),
      );
      _phoneController.addListener(_protectPrefix);
    }
  }

  void _startCountdown(int seconds) {
    _countdownTimer?.cancel();
    setState(() => _secondsRemaining = seconds);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining <= 0) {
        timer.cancel();
        if (mounted) setState(() {});
      } else {
        if (mounted) setState(() => _secondsRemaining--);
      }
    });
  }

  void _startResendCooldown(int seconds) {
    setState(() => _resendCooldown = seconds);
    Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCooldown <= 0) {
        timer.cancel();
        if (mounted) setState(() {});
      } else {
        if (mounted) setState(() => _resendCooldown--);
      }
    });
  }

  String get _formattedTime {
    final min = (_secondsRemaining ~/ 60).toString().padLeft(2, '0');
    final sec = (_secondsRemaining % 60).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  void _validateAndProceedToTypeSelection() {
    if (_nameController.text.trim().isEmpty || _nameController.text.trim().length < 10) {
      setState(() => _error = AppStrings.isRu
          ? 'Имя должно содержать не менее 10 символов'
          : 'Ism kamida 10 ta belgidan iborat bo\'lishi kerak');
      return;
    }
    if (_passwordController.text.length < 6) {
      setState(() => _error = AppStrings.isRu
          ? 'Пароль должен содержать не менее 6 символов'
          : 'Parol kamida 6 ta belgidan iborat bo\'lishi kerak');
      return;
    }
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = AppStrings.isRu
          ? 'Пароли не совпадают'
          : 'Parollar mos kelmayapti');
      return;
    }
    final digits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 12) {
      setState(() => _error = AppStrings.isRu
          ? 'Номер телефона должен содержать ровно 9 цифр (после +998)'
          : 'Telefon raqami +998 dan keyin aynan 9 ta raqam bo\'lishi kerak');
      return;
    }
    if (!_acceptedPolicy) {
      setState(() => _error = AppStrings.isRu
          ? 'Необходимо согласиться с политикой конфиденциальности'
          : 'Maxfiylik siyosatiga rozi bo\'lishingiz kerak');
      return;
    }
    setState(() {
      _error = null;
      _step = 2;
    });
  }

  Future<void> _sendCode() async {
    setState(() {
      _isSendingCode = true;
      _error = null;
    });

    try {
      final result = await widget.authService.sendCode(
        PhoneUtils.normalize(_phoneController.text),
      );
      final expiresIn = result['expires_in'] ?? 120;
      final retryAfter = result['retry_after'] ?? 60;
      final success = result['success'] ?? true;

      if (success == false) {
        setState(() => _error = result['message'] ?? 'Error');
        return;
      }

      setState(() {
        _step = 3;
        _error = null;
      });
      _startCountdown(expiresIn is int ? expiresIn : 120);
      _startResendCooldown(retryAfter is int ? retryAfter : 60);

      // Focus first OTP field
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _otpFocusNodes[0].requestFocus();
      });
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSendingCode = false);
    }
  }

  Future<void> _resendCode() async {
    if (_resendCooldown > 0) return;
    for (var c in _otpControllers) {
      c.clear();
    }
    setState(() => _error = null);
    _otpFocusNodes[0].requestFocus();

    setState(() => _isSendingCode = true);
    try {
      final result = await widget.authService.sendCode(
        PhoneUtils.normalize(_phoneController.text),
      );
      final expiresIn = result['expires_in'] ?? 120;
      final retryAfter = result['retry_after'] ?? 60;
      final success = result['success'] ?? true;

      if (success == false) {
        setState(() => _error = result['message'] ?? 'Error');
        _startResendCooldown(result['retry_after'] ?? 30);
        return;
      }

      _startCountdown(expiresIn is int ? expiresIn : 120);
      _startResendCooldown(retryAfter is int ? retryAfter : 60);
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSendingCode = false);
    }
  }

  Future<void> _verifyAndRegister() async {
    final code = _otpControllers.map((c) => c.text).join();
    if (code.length != 4) {
      _shakeController.forward(from: 0);
      setState(() => _error = AppStrings.isRu
          ? 'Введите 4-значный код'
          : '4 xonali kodni kiriting');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await widget.authService.register(
        name: _nameController.text.trim(),
        phone: PhoneUtils.normalize(_phoneController.text),
        password: _passwordController.text,
        code: code,
        role: 'client',
        lang: AppStrings.lang,
      );

      // Update accountType selection (person or company)
      try {
        await widget.authService.updateProfile(accountType: _selectedAccountType);
      } catch (err) {
        debugPrint('Failed to set account_type: $err');
      }

      if (mounted) {
        HomeScreen.switchToTab?.call(4); // Switch directly to Profile screen
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      final msg = e.toString().replaceAll('Exception: ', '');
      setState(() => _error = msg);
      _shakeController.forward(from: 0);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onOtpChanged(int index, String value) {
    final cleanDigits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanDigits.length > 1) {
      // Multi-digit paste or iOS SMS autofill!
      for (int i = 0; i < 4; i++) {
        if (i < cleanDigits.length) {
          _otpControllers[i].text = cleanDigits[i];
        } else {
          _otpControllers[i].clear();
        }
      }
      setState(() {});
      if (cleanDigits.length >= 4) {
        _otpFocusNodes[3].unfocus();
        _verifyAndRegister();
      } else {
        _otpFocusNodes[cleanDigits.length].requestFocus();
      }
      return;
    }

    if (value.isNotEmpty) {
      _otpControllers[index].text = value[0];
      setState(() {});
      if (index < 3) {
        _otpFocusNodes[index + 1].requestFocus();
      } else {
        _otpFocusNodes[index].unfocus();
        final code = _otpControllers.map((c) => c.text).join();
        if (code.length == 4) {
          _verifyAndRegister();
        }
      }
    } else {
      setState(() {});
      if (index > 0) {
        _otpFocusNodes[index - 1].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppTheme.currentGradient(context)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _step == 1
                ? _buildRegistrationForm()
                : _step == 2
                    ? _buildAccountTypeSelection()
                    : _buildOtpScreen(),
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrationForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),

        // Back
        IconButton(
          onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 16),

        Text(
          AppStrings.register,
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.appSlogan,
          style: TextStyle(fontSize: 14, color: Theme.of(context).textTheme.bodySmall?.color),
        ),
        const SizedBox(height: 24),

        // Error
        if (_error != null) _buildErrorBanner(),

        const SizedBox(height: 24),

        // Name
        TextField(
          controller: _nameController,
          textCapitalization: TextCapitalization.words,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            labelText: AppStrings.name,
            labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
            prefixIcon: Icon(Icons.person_rounded, color: Theme.of(context).hintColor),
          ),
        ),
        const SizedBox(height: 14),

        // Phone
        TextField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          inputFormatters: [_phoneFormatter],
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            hintText: '+998 (99) 858-56-88',
            hintStyle: TextStyle(color: Theme.of(context).hintColor),
            labelText: AppStrings.phone,
            labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
            prefixIcon: Icon(Icons.phone_rounded, color: Theme.of(context).hintColor),
          ),
        ),
        const SizedBox(height: 14),

        // Password
        TextField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            labelText: AppStrings.password,
            labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
            prefixIcon: Icon(Icons.lock_rounded, color: Theme.of(context).hintColor),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: Theme.of(context).hintColor,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Confirm Password
        TextField(
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
          decoration: InputDecoration(
            labelText: AppStrings.isRu ? 'Подтвердите пароль' : 'Parolni tasdiqlang',
            labelStyle: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
            prefixIcon: Icon(Icons.lock_outline_rounded, color: Theme.of(context).hintColor),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                color: Theme.of(context).hintColor,
              ),
              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Privacy Policy Checkbox
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Checkbox(
              value: _acceptedPolicy,
              activeColor: Theme.of(context).primaryColor,
              onChanged: (val) {
                setState(() => _acceptedPolicy = val ?? false);
              },
            ),
            Expanded(
              child: GestureDetector(
                onTap: () => _showPrivacyPolicy(context),
                child: Text(
                  AppStrings.isRu
                    ? 'С политикой конфиденциальности ознакомлен(а) и согласен(а)'
                    : 'Maxfiylik siyosati bilan tanishdim va roziman',
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 13,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Continue to Account Type Selection
        GradientButton(
          text: AppStrings.isRu ? 'Далее' : 'Davom etish',
          icon: Icons.arrow_forward_rounded,
          onPressed: _acceptedPolicy ? _validateAndProceedToTypeSelection : () {
            setState(() => _error = AppStrings.isRu
                ? 'Необходимо согласиться с политикой конфиденциальности'
                : 'Maxfiylik siyosatiga rozi bo\'lishingiz kerak');
          },
        ),
        const SizedBox(height: 20),

        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.alreadyHaveAccount,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: Text(
                  AppStrings.login,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 36),
      ],
    );
  }

  Widget _buildAccountTypeSelection() {
    final theme = Theme.of(context);
    final isRu = AppStrings.isRu;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),

        // Back button to Step 1 Form
        IconButton(
          onPressed: () => setState(() => _step = 1),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),

        Text(
          isRu ? 'Выберите тип аккаунта' : 'Hisob turini tanlang',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          isRu
              ? 'Выберите, как вы планируете использовать приложение'
              : 'Ilovadan qanday foydalanishingizni tanlang',
          style: TextStyle(fontSize: 14, color: theme.textTheme.bodySmall?.color),
        ),
        const SizedBox(height: 24),

        if (_error != null) ...[
          _buildErrorBanner(),
          const SizedBox(height: 16),
        ],

        // --- Card 1: Частное лицо ---
        _buildAccountTypeCard(
          type: 'person',
          title: isRu ? 'Частное лицо' : 'Jismoniy shaxs',
          badge: isRu ? 'Для себя и бытовых задач' : 'O\'zingiz va maishiy ishlar uchun',
          icon: Icons.person_rounded,
          iconColor: Colors.blue,
          features: [
            isRu
                ? '🔍 Найдите любого специалиста для любых задач — ремонт, уборка, доставка и многое другое'
                : '🔍 Har qanday vazifa uchun mutaxassis toping — ta\'mirlash, tozalash, yetkazish va boshqalar',
            isRu
                ? '🛠️ Станьте любым специалистом сами — принимайте заказы и зарабатывайте'
                : '🛠️ O\'zingiz istalgan mutaxassis bo\'ling — buyurtmalar qabul qiling va pul ishlang',
            isRu
                ? '💰 Бесплатная регистрация — начните искать или работать прямо сейчас'
                : '💰 Bepul ro\'yxatdan o\'tish — hoziroq qidiring yoki ishlang',
          ],
        ),

        const SizedBox(height: 16),

        // --- Card 2: Компания / Бизнес ---
        _buildAccountTypeCard(
          type: 'company',
          title: isRu ? 'Компания / Бизнес' : 'Kompaniya / Biznes',
          badge: isRu ? 'Для бизнеса и работодателей' : 'Biznes va ish beruvchilar uchun',
          icon: Icons.business_rounded,
          iconColor: Colors.amber.shade700,
          features: [
            isRu
                ? '💼 Найдите любого специалиста, работника или бригаду для вашего бизнеса'
                : '💼 Biznesingiz uchun istalgan mutaxassis, xodim yoki brigadani toping',
            isRu
                ? '🏗️ Публикуйте вакансии и крупные проекты для привлечения профессионалов'
                : '🏗️ Vakansiyalar va yirik loyihalarni joylashtiring',
            isRu
                ? '📊 Официальный профиль компании с логотипом, банером и контактами'
                : '📊 Kompaniyaning rasmiy profili logotip, banner va kontaktlar bilan',
          ],
        ),

        const SizedBox(height: 28),

        // Send SMS Code button
        GradientButton(
          text: isRu ? 'Получить SMS код' : 'SMS kod olish',
          isLoading: _isSendingCode,
          icon: Icons.sms_rounded,
          onPressed: _sendCode,
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  Widget _buildAccountTypeCard({
    required String type,
    required String title,
    required String badge,
    required IconData icon,
    required Color iconColor,
    required List<String> features,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedAccountType == type;

    return GestureDetector(
      onTap: () => setState(() => _selectedAccountType = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.08)
              : theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : theme.dividerColor.withValues(alpha: 0.3),
            width: isSelected ? 2.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleMedium?.color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? AppColors.primary : theme.textTheme.bodySmall?.color,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Radio<String>(
                  value: type,
                  groupValue: _selectedAccountType,
                  activeColor: AppColors.primary,
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedAccountType = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.2)),
            const SizedBox(height: 12),
            ...features.map((feat) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    feat,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildOtpScreen() {
    final theme = Theme.of(context);
    final maskedPhone = _phoneController.text;
    final isExpired = _secondsRemaining <= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 40),

        // Back to form
        Align(
          alignment: Alignment.centerLeft,
          child: IconButton(
            onPressed: () {
              setState(() {
                _step = 2;
                _error = null;
              });
              for (var c in _otpControllers) {
                c.clear();
              }
              _countdownTimer?.cancel();
            },
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: 24),

        // Lock icon
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.15),
                AppColors.primary.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.verified_user_rounded,
            size: 40,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 24),

        Text(
          AppStrings.isRu ? 'Подтверждение' : 'Tasdiqlash',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: theme.textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppStrings.isRu
              ? 'Введите 4-значный код, отправленный на'
              : '4 xonali kodni kiriting, yuborilgan raqam:',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: theme.textTheme.bodySmall?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          maskedPhone,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 32),

        // Error
        if (_error != null) _buildErrorBanner(),
        if (_error != null) const SizedBox(height: 16),

        // OTP Input Boxes
        AnimatedBuilder(
          animation: _shakeAnimation,
          builder: (context, child) {
            final dx = _shakeAnimation.value * 10 * ((_shakeController.value * 6).toInt().isEven ? 1 : -1);
            return Transform.translate(
              offset: Offset(dx, 0),
              child: child,
            );
          },
          child: AutofillGroup(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) => _buildOtpBox(i)),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // Timer
        if (!isExpired)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.timer_rounded, size: 18, color: _secondsRemaining <= 30 ? Colors.redAccent : AppColors.primary),
              const SizedBox(width: 6),
              Text(
                _formattedTime,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: _secondsRemaining <= 30 ? Colors.redAccent : AppColors.primary,
                ),
              ),
            ],
          ),

        if (isExpired)
          Text(
            AppStrings.isRu ? 'Код истёк' : 'Kod muddati tugadi',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.redAccent,
            ),
          ),

        const SizedBox(height: 24),

        // Verify Button
        GradientButton(
          text: AppStrings.isRu ? 'Подтвердить' : 'Tasdiqlash',
          isLoading: _isLoading,
          icon: Icons.check_circle_rounded,
          onPressed: isExpired ? null : _verifyAndRegister,
        ),
        const SizedBox(height: 16),

        // Resend
        TextButton(
          onPressed: _resendCooldown > 0 || _isSendingCode ? null : _resendCode,
          child: Text(
            _resendCooldown > 0
                ? (AppStrings.isRu
                    ? 'Отправить повторно через $_resendCooldown сек'
                    : '$_resendCooldown soniyadan keyin qayta yuborish')
                : (AppStrings.isRu ? 'Отправить код повторно' : 'Kodni qayta yuborish'),
            style: TextStyle(
              color: _resendCooldown > 0 ? theme.hintColor : AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 36),
      ],
    );
  }

  Widget _buildOtpBox(int index) {
    final theme = Theme.of(context);
    final bool hasValue = _otpControllers[index].text.isNotEmpty;

    return Container(
      width: 64,
      height: 72,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
            if (_otpControllers[index].text.isEmpty && index > 0) {
              _otpFocusNodes[index - 1].requestFocus();
              _otpControllers[index - 1].clear();
              setState(() {});
            }
          }
        },
        child: TextField(
          controller: _otpControllers[index],
          focusNode: _otpFocusNodes[index],
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.oneTimeCode],
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w900,
            color: theme.textTheme.titleLarge?.color ?? Colors.black,
          ),
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
          ],
          decoration: InputDecoration(
            counterText: '',
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            filled: true,
            fillColor: hasValue
                ? AppColors.primary.withValues(alpha: 0.08)
                : theme.inputDecorationTheme.fillColor ?? Colors.grey.withValues(alpha: 0.05),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: hasValue ? AppColors.primary : (theme.dividerColor),
                width: hasValue ? 2.0 : 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 2.5,
              ),
            ),
          ),
          onChanged: (value) => _onOtpChanged(index, value),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 0),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.cardTheme.color,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        maxChildSize: 0.95,
        builder: (_, controller) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppStrings.isRu ? 'Политика конфиденциальности' : 'Maxfiylik siyosati',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  controller: controller,
                  children: [
                    Text(
                      AppStrings.isRu
                        ? '''1. Мы собираем только необходимые данные: имя, номер телефона, город.

2. Ваши данные используются исключительно для работы платформы Yaqin Go.

3. Мы не передаём ваши данные третьим лицам без вашего согласия.

4. Фото профиля проверяется модераторами. Отсутствие лица на фото может привести к блокировке профиля.

5. 3 плохих отзыва = Блок профиля.

6. Вы можете удалить аккаунт, обратившись в поддержку.

7. Используя приложение, вы принимаете данную политику.'''
                        : '''1. Biz faqat kerakli ma\'lumotlarni yig\'amiz: ism, telefon, shahar.

2. Ma\'lumotlaringiz faqat Yaqin Go platformasi uchun ishlatiladi.

3. Roziligingizisiz ma\'lumotlaringizni uchinchi shaxslarga bermaymiz.

4. Profil rasmi moderatorlar tomonidan tekshiriladi. Yuzingiz ko'rsatilmagan rasm profilning bloklanishiga olib kelishi mumkin.

5. 3 ta yomon sharh = Profil bloki.

6. Akkauntni o\'chirish uchun qo\'llab-quvvatlash xizmatiga murojaat qiling.

7. Ilovadan foydalanib, siz ushbu siyosatni qabul qilasiz.''',
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _countdownTimer?.cancel();
    _shakeController.dispose();
    for (var c in _otpControllers) {
      c.dispose();
    }
    for (var n in _otpFocusNodes) {
      n.dispose();
    }
    super.dispose();
  }
}
