import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/theme.dart';
import '../config/localization.dart';
import '../services/api_service.dart';
import '../models/subscription.dart';
import '../widgets/gradient_button.dart';
import 'card_payment_screen.dart';
import '../services/auth_service.dart';
import '../utils/formatters.dart';

class SubscriptionScreen extends StatefulWidget {
  final ApiService apiService;
  final AuthService authService;
  const SubscriptionScreen({super.key, required this.apiService, required this.authService});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  SubscriptionModel? _sub;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    try {
      final sub = await widget.apiService.getMySubscription();
      if (mounted) setState(() { _sub = sub; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRu = AppStrings.isRu;

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.currentGradient(context)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(isRu ? 'Подписка' : 'Obuna'),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTrialPromo(),
                    const SizedBox(height: 20),
                    if (_sub != null) _buildCurrentStatus(_sub!),
                    const SizedBox(height: 12),
                    // Show User ID for manual payment reference
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.badge_rounded, size: 16, color: AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              '${isRu ? 'Ваш ID для оплаты' : 'To\'lov uchun ID'}: ',
                              style: const TextStyle(fontSize: 13),
                            ),
                            Text(
                              '${widget.authService.currentUser?.id ?? ""}',
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.primary),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      isRu ? 'Доступные тарифы' : 'Mavjud tariflar',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    // Worker tiers
                    Text(
                      isRu ? '👷 Иш олувчи (Работник)' : '👷 Ish oluvchi (Ishchi)',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    _tierCard('day', isRu ? '1 День' : '1 Kun', '${PriceFormatter.format(5000)} ${AppStrings.sum}', isRu ? '1 Объявление' : '1 e\'lon', Icons.bolt_rounded, 5000, 'master'),
                    _tierCard('week', isRu ? '1 Неделя' : '1 Hafta', '${PriceFormatter.format(40000)} ${AppStrings.sum}', isRu ? '10 Объявлений' : '10 e\'lon', Icons.auto_awesome_rounded, 40000, 'master'),
                    _tierCard('2_weeks', isRu ? '2 Недели' : '2 Hafta', '${PriceFormatter.format(100000)} ${AppStrings.sum}', isRu ? '30 Объявлений' : '30 e\'lon', Icons.explore_rounded, 100000, 'master'),
                    _tierCard('month', isRu ? '1 Месяц' : '1 Oy', '${PriceFormatter.format(150000)} ${AppStrings.sum}', isRu ? '50 Объявлений' : '50 e\'lon', Icons.star_rounded, 150000, 'master', isBest: true),
                    
                    const SizedBox(height: 32),
                    _buildPaymentInfo(),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTrialPromo() {
    final isRu = AppStrings.isRu;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C853), Color(0xFF00E676)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF00C853).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isRu ? '🎉 АКЦИЯ!' : '🎉 AKSIYA!',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                ),
                const SizedBox(height: 4),
                Text(
                  isRu ? 'С 4 мая до 10 июня — БЕСПЛАТНО!\nПосле регистрации вы получаете полный доступ.' : '4-maydan 10-iyungacha — BEPUL!\nRo\'yxatdan o\'tganingizdan keyin to\'liq kirish.',
                  style: const TextStyle(color: Colors.white, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentStatus(SubscriptionModel sub) {
    final theme = Theme.of(context);
    final isRu = AppStrings.isRu;
    final expiryStr = DateFormat('dd.MM.yyyy HH:mm').format(sub.expiresAt.toLocal());
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: sub.isActive ? [AppColors.primary, AppColors.secondary] : [Colors.grey, Colors.grey.shade700],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: (sub.isActive ? AppColors.primary : Colors.black).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                sub.planTitle.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.2),
              ),
              Icon(sub.isActive ? Icons.verified_rounded : Icons.info_outline_rounded, color: Colors.white, size: 28),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            isRu ? 'Статус: ${sub.isActive ? "Активна" : "Истекла"}' : 'Holati: ${sub.isActive ? "Faol" : "Muddati o'tgan"}',
            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            isRu ? 'Истекает: $expiryStr' : 'Tugash vaqti: $expiryStr',
            style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
          ),
          if (sub.isActive) ...[
             const SizedBox(height: 16),
             ClipRRect(
               borderRadius: BorderRadius.circular(10),
               child: LinearProgressIndicator(
                 value: sub.adsUsed / sub.adsLimit,
                 backgroundColor: Colors.white.withOpacity(0.2),
                 valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                 minHeight: 8,
               ),
             ),
             const SizedBox(height: 8),
             Text(
               isRu ? 'Использовано объявлений: ${sub.adsUsed} из ${sub.adsLimit}' : 'Ishlatilgan e\'lonlar: ${sub.adsUsed} dan ${sub.adsLimit}',
               style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 13),
             ),
          ],
        ],
      ),
    );
  }

  Widget _tierCard(String planId, String title, String price, String limit, IconData icon, int priceVal, String role, {bool isBest = false}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isBest ? AppColors.primary : theme.dividerColor.withOpacity(0.1), width: isBest ? 2 : 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (isBest ? AppColors.primary : theme.primaryColor).withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: isBest ? AppColors.primary : theme.primaryColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Text(limit, style: theme.textTheme.bodySmall),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(price, style: TextStyle(fontWeight: FontWeight.w900, color: isBest ? AppColors.primary : theme.textTheme.bodyLarge?.color, fontSize: 16)),
            const SizedBox(height: 4),
            Text(AppStrings.isRu ? 'Купить' : 'Sotib olish', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
        onTap: () {
          _showPaymentMethodSheet(planId, priceVal, role);
        },
      ),
    );
  }

  void _showPaymentMethodSheet(String planId, int priceVal, String role) {
    final isRu = AppStrings.isRu;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              isRu ? 'Выберите способ оплаты' : 'To\'lov usulini tanlang',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _paymentOption(
              title: 'Click Up',
              subtitle: isRu ? 'Переход в приложение Click' : 'Click ilovasiga o\'tish',
              icon: Icons.account_balance_wallet_rounded,
              onTap: () async {
                Navigator.pop(context);
                _processClickPayment(planId, role);
              },
            ),
            const SizedBox(height: 12),
            _paymentOption(
              title: 'Payme',
              subtitle: isRu ? 'Переход в приложение Payme' : 'Payme ilovasiga o\'tish',
              icon: Icons.payment_rounded,
              color: const Color(0xFF00BFA5),
              onTap: () async {
                Navigator.pop(context);
                _processPaymePayment(planId, role);
              },
            ),
            const SizedBox(height: 12),
            _paymentOption(
              title: 'Paynet',
              subtitle: isRu ? 'Оплата через Paynet' : 'Paynet orqali to\'lov',
              icon: Icons.storefront_rounded,
              color: const Color(0xFFFFA000),
              onTap: () {
                Navigator.pop(context);
                _processPaynetPayment(planId, role);
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _processPaynetPayment(String planId, String role) async {
    setState(() => _isLoading = true);
    try {
      final url = await widget.apiService.getPaynetUrl(planId, role: role);
      final uri = Uri.parse(url);
      
      bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }

      if (mounted && launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.isRu ? 'Ожидание подтверждения оплаты...' : 'To\'lov tasdiqlanishini kutilmoqda...'))
        );
        Future.delayed(const Duration(seconds: 5), () => _loadSubscription());
      } else if (!launched) {
        throw 'Could not launch Paynet URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _paymentOption({required String title, required String subtitle, required IconData icon, required VoidCallback onTap, Color? color}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: (color ?? AppColors.primary).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color ?? AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withOpacity(0.1))),
    );
  }

  Future<void> _processClickPayment(String planId, String role) async {
    setState(() => _isLoading = true);
    try {
      final url = await widget.apiService.getClickUrl(planId, role: role);
      final uri = Uri.parse(url);
      
      // Try to launch external application directly
      bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      
      if (!launched) {
        // Fallback to in-app webview or internal browser if external fails
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }

      if (mounted && launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.isRu ? 'Ожидание подтверждения оплаты...' : 'To\'lov tasdiqlanishini kutilmoqda...'))
        );
        Future.delayed(const Duration(seconds: 5), () => _loadSubscription());
      } else if (!launched) {
        throw 'Could not launch Click URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _processPaymePayment(String planId, String role) async {
    setState(() => _isLoading = true);
    try {
      final url = await widget.apiService.getPaymeUrl(planId, role: role);
      final uri = Uri.parse(url);
      
      bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        launched = await launchUrl(uri, mode: LaunchMode.platformDefault);
      }

      if (mounted && launched) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.isRu ? 'Ожидание подтверждения оплаты...' : 'To\'lov tasdiqlanishini kutilmoqda...'))
        );
        Future.delayed(const Duration(seconds: 5), () => _loadSubscription());
      } else if (!launched) {
        throw 'Could not launch Payme URL';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPaymentInfo() {
    final theme = Theme.of(context);
    final isRu = AppStrings.isRu;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network('https://paynet.uz/assets/img/logo.png', height: 24, errorBuilder: (_,__,___) => const SizedBox()),
              const SizedBox(width: 12),
              Image.network('https://upload.wikimedia.org/wikipedia/commons/b/b5/Payme_logo.png', height: 24, errorBuilder: (_,__,___) => const SizedBox()),
              const SizedBox(width: 12),
              Image.network('https://click.uz/static/img/logo.png', height: 24, errorBuilder: (_,__,___) => const SizedBox()),
            ],
          ),
        ],
      ),
    );
  }
}
