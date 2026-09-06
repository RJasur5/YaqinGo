import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../config/localization.dart';
import '../../services/api_service.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/glass_container.dart';

import 'package:flutter/services.dart'; // For HapticFeedback
import '../widgets/premium_card_widget.dart';

class CardPaymentScreen extends StatefulWidget {
  final ApiService apiService;
  final String planName;
  final int price;
  final String role;

  const CardPaymentScreen({
    super.key,
    required this.apiService,
    required this.planName,
    required this.price,
    required this.role,
  });

  @override
  State<CardPaymentScreen> createState() => _CardPaymentScreenState();
}

class _CardPaymentScreenState extends State<CardPaymentScreen> {
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _holderController = TextEditingController();
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _cardNumberController.addListener(() => setState(() {}));
    _expiryController.addListener(() => setState(() {}));
    _holderController.addListener(() => setState(() {}));
  }

  String _getPlanTitle() {
    switch (widget.planName) {
      case 'day': return AppStrings.isRu ? '1 День' : '1 Kun';
      case 'week': return AppStrings.isRu ? '1 Неделя' : '1 Hafta';
      case 'month': return AppStrings.isRu ? '1 Месяц' : '1 Oy';
      default: return '';
    }
  }

  Future<void> _processPayment() async {
    if (_cardNumberController.text.length < 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.isRu ? 'Некорректный номер карты' : 'Karta raqami xato')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      // Simulate real payment delay
      await Future.delayed(const Duration(seconds: 2));
      
      await widget.apiService.payWithCard(
        cardNumber: _cardNumberController.text,
        expiry: _expiryController.text,
        cvv: _cvvController.text,
        planName: widget.planName,
      );
      
      if (mounted) {
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: Colors.white, size: 40),
            ),
            const SizedBox(height: 24),
            Text(
              AppStrings.isRu ? 'Успешно!' : 'Muvaffaqiyatli!',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              AppStrings.isRu 
              ? 'Ваша подписка активирована. Теперь вам доступны все функции приложения.' 
              : 'Obunangiz faollashtirildi. Endi sizga ilovaning barcha funksiyalari mavjud.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: GradientButton(
                text: 'OK',
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pop(true);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.isRu ? 'Оплата картой' : 'Karta orqali to\'lov'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Visual Card
            PremiumCardWidget(
              cardNumber: _cardNumberController.text.replaceAll(' ', ''),
              expiry: _expiryController.text,
              holderName: _holderController.text.isEmpty ? 'SIMURG FINDER' : _holderController.text,
            ),
            
            const SizedBox(height: 30),
            
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _getPlanTitle(),
                    style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const Spacer(),
                Text(
                  '${widget.price} ${AppStrings.sum}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primary),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            _buildTextField(
              controller: _cardNumberController,
              label: AppStrings.isRu ? 'Номер карты' : 'Karta raqami',
              hint: '8600 **** **** ****',
              keyboardType: TextInputType.number,
              icon: Icons.credit_card_rounded,
              maxLength: 19,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _holderController,
              label: AppStrings.isRu ? 'Имя владельца (как на карте)' : 'Karta egasining ismi',
              hint: 'MIRONSHOH NEMATOV',
              textCapitalization: TextCapitalization.characters,
              icon: Icons.person_rounded,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    controller: _expiryController,
                    label: AppStrings.isRu ? 'Срок' : 'Muddati',
                    hint: 'MM/YY',
                    keyboardType: TextInputType.number,
                    maxLength: 5,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _cvvController,
                    label: 'CVV',
                    hint: '***',
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    maxLength: 3,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 40),
            
            _isProcessing
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : GradientButton(
                  text: AppStrings.isRu ? 'Оплатить сейчас' : 'Hozir to\'lash',
                  onPressed: _processPayment,
                ),
                
            const SizedBox(height: 20),
            Center(
              child: Opacity(
                opacity: 0.6,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.security_rounded, size: 16, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.isRu ? 'Защищено SSL шифрованием' : 'SSL shifrlash bilan himoyalangan',
                      style: const TextStyle(fontSize: 12),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    IconData? icon,
    bool obscureText = false,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: theme.hintColor, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          maxLength: maxLength,
          textCapitalization: textCapitalization,
          style: const TextStyle(fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            counterText: '',
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, color: AppColors.primary) : null,
            filled: true,
            fillColor: theme.cardTheme.color?.withOpacity(0.5),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
          ),
          onChanged: (v) {
            // Haptic feed for premium feel
            // HapticFeedback.lightImpact(); 
          },
        ),
      ],
    );
  }
}
