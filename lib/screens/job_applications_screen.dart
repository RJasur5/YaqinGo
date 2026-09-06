import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/theme.dart';
import '../config/localization.dart';
import '../config/api_config.dart';
import '../services/api_service.dart';
import '../services/theme_service.dart';

class JobApplicationsScreen extends StatefulWidget {
  final ApiService apiService;
  const JobApplicationsScreen({super.key, required this.apiService});

  @override
  State<JobApplicationsScreen> createState() => _JobApplicationsScreenState();
}

class _JobApplicationsScreenState extends State<JobApplicationsScreen> {
  List<dynamic> _applications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    setState(() => _isLoading = true);
    try {
      final apps = await widget.apiService.getMyReceivedApplications();
      if (mounted) setState(() { _applications = apps; _isLoading = false; });
    } catch (e) {
      debugPrint('Error loading applications: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _updateStatus(int applicationId, String status) async {
    try {
      await widget.apiService.updateApplicationStatus(applicationId, status);
      _loadApplications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.isRu
                ? 'Статус обновлен'
                : 'Holat yangilandi'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending': return AppColors.warning;
      case 'viewed': return AppColors.blue;
      case 'accepted': return AppColors.success;
      case 'rejected': return AppColors.error;
      default: return Colors.grey;
    }
  }

  String _statusText(String status) {
    switch (status) {
      case 'pending': return AppStrings.applicationPending;
      case 'viewed': return AppStrings.applicationViewed;
      case 'accepted': return AppStrings.applicationAccepted;
      case 'rejected': return AppStrings.applicationRejected;
      default: return status;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'pending': return Icons.schedule_rounded;
      case 'viewed': return Icons.visibility_rounded;
      case 'accepted': return Icons.check_circle_rounded;
      case 'rejected': return Icons.cancel_rounded;
      default: return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final palette = AppTheme.getPalette(ThemeService().currentMode);

    return Container(
      decoration: BoxDecoration(gradient: palette.bgGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(AppStrings.jobApplications),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
            : _applications.isEmpty
                ? _buildEmptyState(theme)
                : RefreshIndicator(
                    onRefresh: _loadApplications,
                    color: theme.primaryColor,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                      itemCount: _applications.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) => _buildApplicationCard(_applications[index], theme),
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(Icons.work_off_rounded, size: 64, color: theme.primaryColor.withOpacity(0.4)),
          ),
          const SizedBox(height: 20),
          Text(
            AppStrings.noApplications,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppStrings.isRu
                ? 'Когда работодатели отправят вам заявки,\nони появятся здесь'
                : "Ish beruvchilar sizga ariza yuborganida,\nular shu yerda ko'rinadi",
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildApplicationCard(Map<String, dynamic> app, ThemeData theme) {
    final status = app['status'] as String? ?? 'pending';
    final statusColor = _statusColor(status);
    final createdAt = app['created_at'] != null
        ? DateTime.tryParse(app['created_at'])?.toLocal()
        : null;
    final dateStr = createdAt != null
        ? DateFormat('dd.MM.yyyy HH:mm').format(createdAt)
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.10),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with employer info & status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              children: [
                // Employer avatar
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: app['employer_avatar'] == null
                        ? AppColors.primaryGradient
                        : null,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                    image: app['employer_avatar'] != null
                        ? DecorationImage(
                            image: NetworkImage(
                              (app['employer_avatar'] as String).startsWith('http')
                                  ? app['employer_avatar']
                                  : '${ApiConfig.baseUrl.replaceAll("/api", "")}${app['employer_avatar']}',
                            ),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: app['employer_avatar'] == null
                      ? Center(
                          child: Text(
                            (app['employer_name'] as String? ?? '?')
                                .split(' ')
                                .map((w) => w.isNotEmpty ? w[0] : '')
                                .take(2)
                                .join()
                                .toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 14),
                // Name & date
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        app['employer_name'] ?? '',
                        style: TextStyle(
                          color: theme.textTheme.bodyLarge?.color,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (dateStr.isNotEmpty)
                        Text(
                          dateStr,
                          style: TextStyle(
                            color: theme.textTheme.bodySmall?.color,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(status), size: 14, color: statusColor),
                      const SizedBox(width: 5),
                      Text(
                        _statusText(status),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(height: 1, color: statusColor.withOpacity(0.15)),

          // Description
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: _ExpandableDescription(description: app['description'] ?? '', theme: theme),
          ),

          // Contact info — only show when accepted
          if (status == 'accepted' && app['phone'] != null && (app['phone'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.phone_rounded, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  Text(
                    app['phone'],
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

          if (app['city'] != null && (app['city'] as String).isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 16, color: theme.textTheme.bodySmall?.color),
                  const SizedBox(width: 6),
                  Text(
                    app['city'],
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),

          // Action buttons (only for pending applications)
          if (status == 'pending' || status == 'viewed')
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      AppStrings.isRu ? 'Принять' : 'Qabul qilish',
                      Icons.check_circle_rounded,
                      AppColors.success,
                      () => _updateStatus(app['id'], 'accepted'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _actionButton(
                      AppStrings.isRu ? 'Отклонить' : 'Rad etish',
                      Icons.cancel_rounded,
                      AppColors.error,
                      () => _updateStatus(app['id'], 'rejected'),
                    ),
                  ),
                ],
              ),
            ),

          if (status != 'pending' && status != 'viewed')
            const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _actionButton(String text, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              text,
              style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandableDescription extends StatelessWidget {
  final String description;
  final ThemeData theme;
  const _ExpandableDescription({required this.description, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        if (description.length > 100)
          GestureDetector(
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(AppStrings.isRu ? 'Описание' : 'Tavsif'),
                  content: SingleChildScrollView(
                    child: Text(description, style: const TextStyle(fontSize: 15, height: 1.5)),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(AppStrings.isRu ? 'Закрыть' : 'Yopish'),
                    ),
                  ],
                ),
              );
            },
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                AppStrings.isRu ? 'Подробнее →' : 'Batafsil →',
                style: TextStyle(color: theme.primaryColor, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
      ],
    );
  }
}
