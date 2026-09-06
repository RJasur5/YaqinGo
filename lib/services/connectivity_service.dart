import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../config/localization.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  static ConnectivityService get instance => _instance;
  ConnectivityService._();

  final _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();
  bool _isOnline = true;
  StreamSubscription? _sub;

  bool get isOnline => _isOnline;
  Stream<bool> get onStatusChange => _controller.stream;

  Future<void> init() async {
    final result = await _connectivity.checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);

    _sub = _connectivity.onConnectivityChanged.listen((results) {
      final online = !results.contains(ConnectivityResult.none);
      if (online != _isOnline) {
        _isOnline = online;
        _controller.add(online);
      }
    });
  }

  Future<bool> checkNow() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isOnline = !result.contains(ConnectivityResult.none);
      return _isOnline;
    } catch (_) {
      return false;
    }
  }

  /// Returns true if the error looks like a network issue
  static bool isNetworkError(dynamic error) {
    final msg = error.toString().toLowerCase();
    return error is SocketException ||
        error is TimeoutException ||
        msg.contains('socketexception') ||
        msg.contains('connection refused') ||
        msg.contains('network is unreachable') ||
        msg.contains('failed host lookup') ||
        msg.contains('connection reset') ||
        msg.contains('connection closed') ||
        msg.contains('handshake') ||
        msg.contains('no address') ||
        msg.contains('timed out') ||
        msg.contains('timeout') ||
        msg.contains('clientexception') ||
        msg.contains('no internet');
  }

  /// User-friendly error message
  static String get noInternetMessage => AppStrings.isRu
      ? 'Нет подключения к интернету.\nПроверьте соединение и попробуйте снова.'
      : 'Internet aloqasi yo\'q.\nAloqani tekshiring va qayta urinib ko\'ring.';

  /// Show a nice no-internet dialog
  static void showNoInternetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        final theme = Theme.of(context);
        return AlertDialog(
          backgroundColor: theme.cardTheme.color ?? theme.dialogBackgroundColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Icon(Icons.wifi_off_rounded, size: 64, color: theme.hintColor),
              const SizedBox(height: 16),
              Text(
                AppStrings.isRu ? 'Нет интернета' : 'Internet yo\'q',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleLarge?.color,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                noInternetMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.textTheme.bodyMedium?.color,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(AppStrings.isRu ? 'Понятно' : 'Tushunarli'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void dispose() {
    _sub?.cancel();
    _controller.close();
  }
}
