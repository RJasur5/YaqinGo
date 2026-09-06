import 'package:flutter/material.dart';
import '../config/theme.dart';

class RatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final bool showNumber;

  const RatingStars({
    super.key,
    required this.rating,
    this.size = 16,
    this.showNumber = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          final starValue = i + 1;
          IconData icon;
          Color color;
          if (rating >= starValue) {
            icon = Icons.star_rounded;
            color = AppColors.yellow;
          } else if (rating >= starValue - 0.5) {
            icon = Icons.star_half_rounded;
            color = AppColors.yellow;
          } else {
            icon = Icons.star_outline_rounded;
            color = AppColors.textHint;
          }
          return Icon(icon, size: size, color: color);
        }),
        if (showNumber) ...[
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: size * 0.8,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class RatingInput extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final double size;

  const RatingInput({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starValue = i + 1;
        return GestureDetector(
          onTap: () => onChanged(starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              starValue <= value ? Icons.star_rounded : Icons.star_outline_rounded,
              size: size,
              color: starValue <= value ? AppColors.yellow : AppColors.textHint,
            ),
          ),
        );
      }),
    );
  }
}
