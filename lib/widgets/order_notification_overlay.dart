import 'package:flutter/material.dart';
import 'dart:ui';
import '../config/theme.dart';
import '../config/localization.dart';

class OrderNotificationOverlay extends StatefulWidget {
  final dynamic order;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const OrderNotificationOverlay({
    super.key,
    required this.order,
    required this.onTap,
    required this.onClose,
  });

  @override
  State<OrderNotificationOverlay> createState() => _OrderNotificationOverlayState();
}

class _OrderNotificationOverlayState extends State<OrderNotificationOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));
    _controller.forward();
    
    // Auto-close after 10 seconds if not interacted with
    Future.delayed(const Duration(seconds: 10), () {
      if (mounted) {
        _handleClose();
      }
    });
  }

  void _handleClose() {
    _controller.reverse().then((_) => widget.onClose());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return SlideTransition(
      position: _offsetAnimation,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: EdgeInsets.only(top: padding.top + 10, left: 16, right: 16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.brightness == Brightness.light ? Colors.white : const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.primaryColor.withOpacity(0.3), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.primaryColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.flash_on_rounded, color: theme.primaryColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.isRu ? "НОВЫЙ ЗАКАЗ" : "YANGI BUYURTMA",
                            style: TextStyle(
                              color: theme.primaryColor.withOpacity(0.8),
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            widget.order['subcategory_name_ru'] ?? widget.order['title'] ?? '',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: theme.textTheme.titleMedium?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.close_rounded, size: 24, color: theme.textTheme.bodySmall?.color),
                      onPressed: _handleClose,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (widget.order['district'] != null) ...[
                      Icon(Icons.location_on_rounded, color: theme.primaryColor, size: 16),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.order['district'],
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (widget.order['price'] != null) ...[
                      const Icon(Icons.payments_rounded, color: Color(0xFF10B981), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${widget.order['price']} ${AppStrings.sum}',
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 15, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.brightness == Brightness.light ? Colors.black.withOpacity(0.04) : Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    widget.order['description'] ?? '',
                    style: TextStyle(color: theme.textTheme.bodyMedium?.color, fontSize: 14, height: 1.4),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: widget.onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      AppStrings.isRu ? "ПОСМОТРЕТЬ ДЕТАЛИ" : "BATAFSIL KO'RISH",
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
