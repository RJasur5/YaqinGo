import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import '../../config/theme.dart';
import '../../config/localization.dart';
import '../../services/auth_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/gradient_button.dart';
import '../../utils/phone_utils.dart';

class LoginScreen extends StatefulWidget {
  final AuthService authService;
  const LoginScreen({super.key, required this.authService});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneController = TextEditingController(text: '+998 ');
  final _passwordController = TextEditingController();
  final _phoneFormatter = PhoneUtils.maskFormatter;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_protectPrefix);
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

  Future<void> _login() async {
    if (_phoneController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = AppStrings.isRu ? 'Заполните все поля' : 'Barcha maydonlarni to\'ldiring');
      return;
    }
    if (_passwordController.text.length < 6) {
      setState(() => _error = AppStrings.isRu 
          ? 'Пароль должен содержать не менее 6 символов' 
          : 'Parol kamida 6 ta belgidan iborat bo\'lishi kerak');
      return;
    }
    // Phone digit count check: must have exactly 9 digits after 998
    final digits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 12) {
      setState(() => _error = AppStrings.isRu
          ? 'Номер телефона должен содержать ровно 9 цифр (после +998)'
          : 'Telefon raqami +998 dan keyin aynan 9 ta raqam bo\'lishi kerak');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await widget.authService.login(
        PhoneUtils.normalize(_phoneController.text),
        _passwordController.text,
      );
      
      // CRITICAL FIX: Sync the locally selected language to the backend so push notifications are correctly localized
      await widget.authService.saveLang(AppStrings.lang);

      if (mounted) Navigator.pushReplacementNamed(context, '/home');
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // Logo
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/logo.png',
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    AppStrings.appName,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Title
                Text(
                  AppStrings.login,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.appSlogan,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                const SizedBox(height: 32),

                // Error
                if (_error != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                    ),
                    child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                  ),

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
                const SizedBox(height: 16),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
                  decoration: InputDecoration(
                    hintText: '••••••',
                    hintStyle: TextStyle(color: Theme.of(context).hintColor),
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
                const SizedBox(height: 28),

                // Login button
                GradientButton(
                  text: AppStrings.login,
                  isLoading: _isLoading,
                  onPressed: _login,
                ),
                const SizedBox(height: 14),

                // Forgot Password link (under Login button)
                Center(
                  child: TextButton(
                    onPressed: () => _showForgotPasswordSheet(context),
                    child: Text(
                      AppStrings.isRu ? 'Забыли пароль?' : 'Parolni unutdingizmi?',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Register link
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AppStrings.noAccount,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
                          child: Text(
                            AppStrings.register,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotPasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ForgotPasswordSheet(authService: widget.authService),
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
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

class _ForgotPasswordSheet extends StatefulWidget {
  final AuthService authService;
  const _ForgotPasswordSheet({required this.authService});

  @override
  State<_ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<_ForgotPasswordSheet> {
  int _step = 1; // 1=phone, 2=OTP, 3=new password
  final _phoneController = TextEditingController(text: '+998 ');
  final _phoneFormatter = PhoneUtils.maskFormatter;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final List<TextEditingController> _otpControllers = List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(4, (_) => FocusNode());
  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  String? _error;
  Timer? _countdownTimer;
  int _secondsRemaining = 0;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(_protectPrefix);
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

  Future<void> _sendCode() async {
    final digits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length < 12) {
      setState(() => _error = AppStrings.isRu
          ? 'Введите корректный номер телефона'
          : 'To\'g\'ri telefon raqamini kiriting');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      await widget.authService.sendForgotPasswordCode(
        PhoneUtils.normalize(_phoneController.text),
      );
      setState(() { _step = 2; _isLoading = false; });
      _startCountdown(120);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _otpFocusNodes[0].requestFocus();
      });
    } catch (e) {
      String err = e.toString().replaceAll('Exception: ', '');
      if (err.toLowerCase().contains('not found') || err.toLowerCase().contains('topilmadi') || err.toLowerCase().contains('не найден')) {
        err = AppStrings.isRu
            ? 'Номер не найден. Пожалуйста, пройдите регистрацию'
            : 'Raqam topilmadi. Iltimos, ro\'yxatdan o\'ting';
      }
      setState(() {
        _error = err;
        _isLoading = false;
      });
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
        setState(() => _step = 3);
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
          setState(() => _step = 3);
        }
      }
    } else {
      setState(() {});
      if (index > 0) {
        _otpFocusNodes[index - 1].requestFocus();
      }
    }
  }

  Future<void> _resetPassword() async {
    if (_newPasswordController.text.length < 6) {
      setState(() => _error = AppStrings.isRu
          ? 'Пароль должен содержать не менее 6 символов'
          : 'Parol kamida 6 ta belgidan iborat bo\'lishi kerak');
      return;
    }
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() => _error = AppStrings.isRu
          ? 'Пароли не совпадают'
          : 'Parollar mos kelmayapti');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final code = _otpControllers.map((c) => c.text).join();
      await widget.authService.resetPassword(
        PhoneUtils.normalize(_phoneController.text),
        code,
        _newPasswordController.text,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.isRu
                ? 'Пароль успешно изменён! Войдите с новым паролем.'
                : 'Parol muvaffaqiyatli o\'zgartirildi! Yangi parol bilan kiring.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 20),
            Text(
              _step == 1
                  ? (AppStrings.isRu ? 'Восстановление пароля' : 'Parolni tiklash')
                  : _step == 2
                      ? (AppStrings.isRu ? 'Введите код из SMS' : 'SMS kodini kiriting')
                      : (AppStrings.isRu ? 'Новый пароль' : 'Yangi parol'),
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _step == 1
                  ? (AppStrings.isRu
                      ? 'Введите номер телефона, привязанный к вашему аккаунту'
                      : 'Hisobingizga bog\'langan telefon raqamini kiriting')
                  : _step == 2
                      ? (AppStrings.isRu
                          ? 'Мы отправили 4-значный код на номер: ${_phoneController.text}'
                          : 'Raqamingizga 4 xonali kod yubordik: ${_phoneController.text}')
                      : (AppStrings.isRu
                          ? 'Придумайте новый пароль для вашего аккаунта'
                          : 'Hisobingiz uchun yangi parol o\'ylab toping'),
              style: TextStyle(fontSize: 14, color: theme.textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 20),

            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    if (_error!.contains('регистраци') || _error!.contains('ro\'yxatdan')) ...[
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.pushReplacementNamed(context, '/register');
                        },
                        child: Text(
                          AppStrings.isRu ? 'Перейти к регистрации →' : 'Ro\'yxatdan o\'tishga o\'tish →',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            if (_step == 1) ...[
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                inputFormatters: [_phoneFormatter],
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  hintText: '+998 (99) 858-56-88',
                  hintStyle: TextStyle(color: theme.hintColor),
                  labelText: AppStrings.phone,
                  labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                  prefixIcon: Icon(Icons.phone_rounded, color: theme.hintColor),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(AppStrings.isRu ? 'Отправить код' : 'Kod yuborish', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],

            if (_step == 2) ...[
              AutofillGroup(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (i) {
                    final bool hasValue = _otpControllers[i].text.isNotEmpty;
                    return Container(
                      width: 60,
                      height: 68,
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      child: KeyboardListener(
                        focusNode: FocusNode(),
                        onKeyEvent: (event) {
                          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace) {
                            if (_otpControllers[i].text.isEmpty && i > 0) {
                              _otpFocusNodes[i - 1].requestFocus();
                              _otpControllers[i - 1].clear();
                              setState(() {});
                            }
                          }
                        },
                        child: TextField(
                          controller: _otpControllers[i],
                          focusNode: _otpFocusNodes[i],
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
                                : theme.cardTheme.color,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(
                                color: hasValue ? AppColors.primary : theme.dividerColor,
                                width: hasValue ? 2.0 : 1.5,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(color: AppColors.primary, width: 2.5),
                            ),
                          ),
                          onChanged: (val) => _onOtpChanged(i, val),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              if (_secondsRemaining > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Center(
                    child: Text(
                      '${AppStrings.isRu ? "Повторная отправка через" : "Qayta yuborish"}: ${_secondsRemaining ~/ 60}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}',
                      style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13),
                    ),
                  ),
                ),
            ],

            if (_step == 3) ...[
              TextField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  labelText: AppStrings.isRu ? 'Новый пароль' : 'Yangi parol',
                  labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                  prefixIcon: Icon(Icons.lock_rounded, color: theme.hintColor),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: theme.hintColor),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                decoration: InputDecoration(
                  labelText: AppStrings.isRu ? 'Подтвердите пароль' : 'Parolni tasdiqlang',
                  labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                  prefixIcon: Icon(Icons.lock_outline_rounded, color: theme.hintColor),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: theme.hintColor),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(AppStrings.isRu ? 'Сохранить новый пароль' : 'Yangi parolni saqlash', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    for (var c in _otpControllers) c.dispose();
    for (var n in _otpFocusNodes) n.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }
}
