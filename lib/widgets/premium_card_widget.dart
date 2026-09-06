import 'package:flutter/material.dart';
import '../config/theme.dart';

class PremiumCardWidget extends StatelessWidget {
  final String cardNumber;
  final String expiry;
  final String holderName;
  final String cvv;
  final bool isCvvFocused;

  const PremiumCardWidget({
    super.key,
    required this.cardNumber,
    required this.expiry,
    this.holderName = 'CARD HOLDER',
    this.cvv = '',
    this.isCvvFocused = false,
  });

  String _getCardType() {
    if (cardNumber.startsWith('8600')) return 'UZCARD';
    if (cardNumber.startsWith('9860')) return 'HUMO';
    if (cardNumber.startsWith('4')) return 'VISA';
    if (cardNumber.startsWith('5')) return 'MASTERCARD';
    return 'CARD';
  }

  Color _getCardColor() {
    String type = _getCardType();
    if (type == 'UZCARD') return const Color(0xFF1A237E);
    if (type == 'HUMO') return const Color(0xFF006064);
    if (type == 'VISA') return const Color(0xFF01579B);
    if (type == 'MASTERCARD') return const Color(0xFFBF360C);
    return Colors.grey.shade900;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      height: 220,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getCardColor(),
            _getCardColor().withOpacity(0.8),
            _getCardColor().withValues(alpha: 0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _getCardColor().withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Stack(
        children: [
          // Background pattern
          Positioned(
            right: -50,
            top: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Icon(Icons.contactless_rounded, color: Colors.white, size: 32),
                    Text(
                      _getCardType(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Chip
                Container(
                  width: 50,
                  height: 35,
                  decoration: BoxDecoration(
                    color: Colors.amber.shade300.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade300, Colors.amber.shade100],
                    )
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Card Number
                Text(
                  cardNumber.isEmpty ? '**** **** **** ****' : _formatCardNumber(cardNumber),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                    fontFamily: 'Courier',
                  ),
                ),
                
                const Spacer(),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CARD HOLDER',
                          style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1),
                        ),
                        Text(
                          holderName.toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'EXPIRES',
                          style: TextStyle(color: Colors.white70, fontSize: 10, letterSpacing: 1),
                        ),
                        Text(
                          expiry.isEmpty ? 'MM/YY' : expiry,
                          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatCardNumber(String number) {
    if (number.length <= 4) return number;
    List<String> chunks = [];
    for (int i = 0; i < number.length; i += 4) {
      chunks.add(number.substring(i, i + 4 > number.length ? number.length : i + 4));
    }
    return chunks.join(' ');
  }
}
