import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../config/localization.dart';

/// A widget that shows a top banner when internet is lost
class NoInternetBanner extends StatefulWidget {
  final Widget child;
  const NoInternetBanner({super.key, required this.child});

  @override
  State<NoInternetBanner> createState() => _NoInternetBannerState();
}

class _NoInternetBannerState extends State<NoInternetBanner> with SingleTickerProviderStateMixin {
  bool _isOffline = false;
  StreamSubscription? _sub;
  late AnimationController _animController;
  late Animation<double> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );

    _isOffline = !ConnectivityService.instance.isOnline;
    if (_isOffline) _animController.forward();

    _sub = ConnectivityService.instance.onStatusChange.listen((online) {
      if (mounted) {
        setState(() => _isOffline = !online);
        if (_isOffline) {
          _animController.forward();
        } else {
          _animController.reverse();
        }
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _slideAnim,
          builder: (context, child) {
            if (_slideAnim.value <= -0.95) return const SizedBox.shrink();
            return Positioned(
              top: MediaQuery.of(context).padding.top,
              left: 0,
              right: 0,
              child: Transform.translate(
                offset: Offset(0, _slideAnim.value * 60),
                child: child,
              ),
            );
          },
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppStrings.isRu ? 'Нет подключения к интернету' : 'Internet aloqasi yo\'q',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
