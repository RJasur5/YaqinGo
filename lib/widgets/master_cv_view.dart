import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/theme.dart';
import '../config/localization.dart';
import '../models/master.dart';
import '../services/api_service.dart';
import '../utils/formatters.dart';

class MasterCvView extends StatefulWidget {
  final MasterModel master;
  final bool isOwner;
  final bool isUnified;
  final ApiService? apiService;
  final VoidCallback? onEdit;
  final VoidCallback? onLocationTap;
  final VoidCallback? onProfileUpdated;

  const MasterCvView({
    super.key,
    required this.master,
    this.isOwner = false,
    this.isUnified = false,
    this.apiService,
    this.onEdit,
    this.onLocationTap,
    this.onProfileUpdated,
  });

  @override
  State<MasterCvView> createState() => _MasterCvViewState();
}

class _MasterCvViewState extends State<MasterCvView> {
  late List<dynamic> _workExperienceList;
  late List<dynamic> _educationList;
  bool _isWorkExperienceExpanded = true;
  bool _isEducationExpanded = true;
  bool _isLanguagesExpanded = true;
  bool _isBasicSkillsExpanded = true;
  bool _isCustomSkillsExpanded = true;
  bool _isDriverLicenseExpanded = true;
  bool _isDisabilityExpanded = true;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _workExperienceList = List<dynamic>.from(widget.master.workExperience ?? []);
    _educationList = List<dynamic>.from(widget.master.education ?? []);
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _isWorkExperienceExpanded = _prefs?.getBool('cv_work_expanded') ?? true;
        _isEducationExpanded = _prefs?.getBool('cv_edu_expanded') ?? true;
        _isLanguagesExpanded = _prefs?.getBool('cv_lang_expanded') ?? true;
        _isBasicSkillsExpanded = _prefs?.getBool('cv_basic_skills_expanded') ?? true;
        _isCustomSkillsExpanded = _prefs?.getBool('cv_custom_skills_expanded') ?? true;
        _isDriverLicenseExpanded = _prefs?.getBool('cv_driver_expanded') ?? true;
        _isDisabilityExpanded = _prefs?.getBool('cv_disability_expanded') ?? true;
      });
    }
  }

  void _toggleWorkExperience() {
    setState(() => _isWorkExperienceExpanded = !_isWorkExperienceExpanded);
    _prefs?.setBool('cv_work_expanded', _isWorkExperienceExpanded);
  }

  void _toggleEducation() {
    setState(() => _isEducationExpanded = !_isEducationExpanded);
    _prefs?.setBool('cv_edu_expanded', _isEducationExpanded);
  }

  void _toggleLanguages() {
    setState(() => _isLanguagesExpanded = !_isLanguagesExpanded);
    _prefs?.setBool('cv_lang_expanded', _isLanguagesExpanded);
  }

  void _toggleBasicSkills() {
    setState(() => _isBasicSkillsExpanded = !_isBasicSkillsExpanded);
    _prefs?.setBool('cv_basic_skills_expanded', _isBasicSkillsExpanded);
  }

  void _toggleCustomSkills() {
    setState(() => _isCustomSkillsExpanded = !_isCustomSkillsExpanded);
    _prefs?.setBool('cv_custom_skills_expanded', _isCustomSkillsExpanded);
  }

  void _toggleDriverLicense() {
    setState(() => _isDriverLicenseExpanded = !_isDriverLicenseExpanded);
    _prefs?.setBool('cv_driver_expanded', _isDriverLicenseExpanded);
  }

  void _toggleDisability() {
    setState(() => _isDisabilityExpanded = !_isDisabilityExpanded);
    _prefs?.setBool('cv_disability_expanded', _isDisabilityExpanded);
  }

  @override
  void didUpdateWidget(covariant MasterCvView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.master.workExperience != oldWidget.master.workExperience) {
      setState(() {
        _workExperienceList = List<dynamic>.from(widget.master.workExperience ?? []);
      });
    }
    if (widget.master.education != oldWidget.master.education) {
      setState(() {
        _educationList = List<dynamic>.from(widget.master.education ?? []);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRu = AppStrings.isRu;

    if (widget.isUnified) {
      return _buildUnifiedProfileView(context, theme, isRu);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Key Info: City, Rate (сколько просит), Category, Status, Metrics
        _buildMasterKeyInfo(context, theme, isRu),
        const SizedBox(height: 16),

        // 2. Professional Summary / Bio
        if (widget.master.description != null && widget.master.description!.trim().isNotEmpty) ...[
          _buildBioCard(context, theme, isRu),
          const SizedBox(height: 16),
        ],

        // Work Experience (Collapsible & Editable/Deletable)
        _buildWorkExperienceCard(context, theme, isRu),
        const SizedBox(height: 16),

        // 3. Education (Collapsible & Editable/Deletable)
        _buildEducationCard(context, theme, isRu),
        const SizedBox(height: 16),

        // 4. Languages (Collapsible)
        if (widget.master.languages != null && widget.master.languages!.isNotEmpty) ...[
          _buildLanguagesCard(context, theme, isRu),
          const SizedBox(height: 16),
        ],

        // 5. Core Basic Skills (Collapsible)
        if (widget.master.basicSkills != null && widget.master.basicSkills!.isNotEmpty) ...[
          _buildBasicSkillsCard(context, theme, isRu),
          const SizedBox(height: 16),
        ],

        // 6. Additional Special Skills (Collapsible)
        if (widget.master.skills.isNotEmpty) ...[
          _buildCustomSkillsCard(context, theme, isRu),
          const SizedBox(height: 16),
        ],

        // 7. Driver's License & Mobility (Collapsible)
        if (widget.master.driverLicense != null) ...[
          _buildDriverLicenseCard(context, theme, isRu),
          const SizedBox(height: 16),
        ],

        // 8. Special Notes / Disability (Collapsible)
        if (widget.master.disability != null) ...[
          _buildDisabilityCard(context, theme, isRu),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  // ==================== 1. MASTER KEY INFO CARD ====================
  Widget _buildMasterKeyInfo(BuildContext context, ThemeData theme, bool isRu) {
    final cityText = (widget.master.city != null && widget.master.city!.trim().isNotEmpty)
        ? '${widget.master.city}${widget.master.district != null && widget.master.district!.trim().isNotEmpty ? ", ${widget.master.district}" : ""}'
        : (isRu ? 'Не указан' : 'Ko\'rsatilmagan');

    final rateText = widget.master.hourlyRate != null
        ? '${PriceFormatter.format(widget.master.hourlyRate)} ${isRu ? "сум / час" : "so'm / soat"}'
        : (isRu ? 'По договоренности' : 'Kelishilgan');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: City / Location
          _infoRow(
            theme: theme,
            icon: Icons.location_on_rounded,
            iconColor: Colors.redAccent,
            label: isRu ? 'Город / Локация' : 'Shahar / Joylashuv',
            value: cityText,
            trailing: (widget.isOwner && widget.onLocationTap != null)
                ? InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: widget.onLocationTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_location_alt_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text(
                            isRu ? 'На карте' : 'Xaritada',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                          ),
                        ],
                      ),
                    ),
                  )
                : null,
          ),
          const Divider(height: 20),

          // Row 2: Rate / Сколько просит
          _infoRow(
            theme: theme,
            icon: Icons.payments_rounded,
            iconColor: Colors.green,
            label: isRu ? 'Стоимость работы (Ставка)' : 'Ish haqi (Narx)',
            value: rateText,
            valueColor: Colors.green.shade700,
            valueBold: true,
          ),
          const Divider(height: 20),

          // Row 3: Category & Subcategory
          _infoRow(
            theme: theme,
            icon: Icons.category_rounded,
            iconColor: AppColors.primary,
            label: isRu ? 'Сфера деятельности' : 'Faoliyat sohasi',
            value: '${widget.master.categoryName(AppStrings.lang)} → ${widget.master.subcategoryName(AppStrings.lang)}',
          ),
          const Divider(height: 20),

          // Row 4: Status (Available / Busy)
          _infoRow(
            theme: theme,
            icon: widget.master.isAvailable ? Icons.check_circle_rounded : Icons.cancel_rounded,
            iconColor: widget.master.isAvailable ? AppColors.success : AppColors.error,
            label: isRu ? 'Статус готовности' : 'Buyurtmaga tayyorlik',
            value: widget.master.isAvailable
                ? (isRu ? 'Свободен для заказов' : 'Buyurtmalar uchun bo\'sh')
                : (isRu ? 'Занят' : 'Band'),
            valueColor: widget.master.isAvailable ? AppColors.success : AppColors.error,
          ),
          const SizedBox(height: 18),

          // Metrics Row: Experience, Rating, Reviews
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                _metricItem(
                  theme: theme,
                  icon: Icons.work_history_rounded,
                  color: Colors.blue,
                  title: isRu ? 'Опыт' : 'Tajriba',
                  value: '${widget.master.experienceYears} ${isRu ? "лет" : "yil"}',
                ),
                Container(width: 1, height: 32, color: theme.dividerColor.withValues(alpha: 0.3)),
                _metricItem(
                  theme: theme,
                  icon: Icons.star_rounded,
                  color: Colors.amber,
                  title: isRu ? 'Рейтинг' : 'Reyting',
                  value: widget.master.rating > 0 ? widget.master.rating.toStringAsFixed(1) : (isRu ? 'Новый' : 'Yangi'),
                ),
                Container(width: 1, height: 32, color: theme.dividerColor.withValues(alpha: 0.3)),
                _metricItem(
                  theme: theme,
                  icon: Icons.chat_rounded,
                  color: Colors.teal,
                  title: isRu ? 'Отзывы' : 'Sharhlar',
                  value: '${widget.master.reviewsCount}',
                ),
              ],
            ),
          ),

          // Edit Master Profile button (if owner)
          if (widget.isOwner && widget.onEdit != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: widget.onEdit,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: Text(
                  isRu ? 'Настроить профиль мастера' : 'Mutaxassis profilini sozlash',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
    bool valueBold = false,
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.hintColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: valueBold ? FontWeight.bold : FontWeight.w600,
                  color: valueColor ?? theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _metricItem({
    required ThemeData theme,
    required IconData icon,
    required Color color,
    required String title,
    required String value,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: theme.textTheme.titleMedium?.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: theme.hintColor,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== 2. BIO CARD ====================
  Widget _buildBioCard(BuildContext context, ThemeData theme, bool isRu) {
    return _collapsibleContainer(
      theme: theme,
      icon: Icons.person_outline_rounded,
      iconColor: AppColors.primary,
      title: isRu ? 'О себе' : 'O\'zi haqida',
      isExpanded: true,
      onToggle: null, // always visible if present
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
        ),
        child: Text(
          widget.master.description!.trim(),
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: theme.textTheme.bodyLarge?.color,
          ),
        ),
      ),
    );
  }


  // ==================== WORK EXPERIENCE (COLLAPSIBLE & EDITABLE) ====================
  Widget _buildWorkExperienceCard(BuildContext context, ThemeData theme, bool isRu) {
    final count = _workExperienceList.length;

    return _collapsibleContainer(
      theme: theme,
      icon: Icons.business_center_rounded,
      iconColor: Colors.blue,
      title: isRu ? 'Опыт работы' : 'Ish tajribasi',
      badgeText: count > 0 ? '$count' : null,
      isExpanded: _isWorkExperienceExpanded,
      onToggle: _toggleWorkExperience,
      headerAction: null,
      previewText: (!_isWorkExperienceExpanded && count > 0)
          ? _workExperienceList.map((e) => (e is Map ? (e['position'] ?? '') : '').toString()).where((s) => s.isNotEmpty).join(' • ')
          : null,
      child: count == 0
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.business_center_outlined, size: 36, color: theme.hintColor.withValues(alpha: 0.4)),
                  const SizedBox(height: 8),
                  Text(
                    isRu ? 'Опыт работы не указан' : 'Ish tajribasi ko\'rsatilmagan',
                    style: TextStyle(color: theme.hintColor, fontSize: 13),
                  ),
                  if (widget.isOwner) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () => _showWorkExperienceModal(),
                      icon: const Icon(Icons.add_rounded, size: 16, color: Colors.blue),
                      label: Text(
                        isRu ? 'Добавить опыт работы' : 'Ish tajribasi qo\'shish',
                        style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            )
          : Column(
              children: [
                ..._workExperienceList.asMap().entries.map((entry) {
                  final i = entry.key;
                  final exp = entry.value;
                  final pos = exp is Map ? (exp['position'] ?? '').toString() : '';
                  final comp = exp is Map ? (exp['company'] ?? '').toString() : '';
                  final start = exp is Map ? (exp['start_date'] ?? '').toString() : '';
                  final end = exp is Map ? (exp['end_date'] ?? '').toString() : '';
                  final isCur = exp is Map ? (exp['is_current'] == true) : false;
                  final desc = exp is Map ? (exp['description'] ?? exp['comment'] ?? '').toString() : '';
                  final isLast = i == _workExperienceList.length - 1;

                  return Container(
                    margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Position
                        Text(
                          pos,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleMedium?.color,
                          ),
                        ),

                        // Company
                        if (comp.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.apartment_rounded, size: 15, color: Colors.blue),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  comp,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Dates
                        if (start.isNotEmpty || end.isNotEmpty || isCur) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 13, color: theme.hintColor),
                              const SizedBox(width: 6),
                              Text(
                                '$start — ${isCur ? (isRu ? "по наст. время" : "hozirgacha") : (end.isNotEmpty ? end : (isRu ? "по наст. время" : "hozirgacha"))}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.hintColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Description / Comment
                        if (desc.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            desc,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.4,
                              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.85),
                            ),
                          ),
                        ],

                        // Owner Actions: Настроить & Удалить
                        if (widget.isOwner) ...[
                          const SizedBox(height: 8),
                          Divider(height: 16, color: theme.dividerColor.withValues(alpha: 0.2)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Edit button
                              TextButton.icon(
                                onPressed: () => _showWorkExperienceModal(exp is Map ? Map<String, dynamic>.from(exp) : null, i),
                                icon: const Icon(Icons.edit_outlined, size: 15, color: Colors.blue),
                                label: Text(
                                  isRu ? 'Настроить' : 'Sozlash',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Delete button
                              TextButton.icon(
                                onPressed: () => _deleteWorkExperience(i),
                                icon: const Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.error),
                                label: Text(
                                  isRu ? 'Удалить' : 'O\'chirish',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }),

                if (widget.isOwner) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton.icon(
                      onPressed: () => _showWorkExperienceModal(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        side: BorderSide(color: Colors.blue.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        isRu ? 'Добавить опыт работы' : 'Ish tajribasi qo\'shish',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  // Delete work experience with confirmation
  Future<void> _deleteWorkExperience(int index) async {
    final isRu = AppStrings.isRu;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text(isRu ? 'Удалить опыт работы?' : 'Ish tajribasini o\'chirish?'),
          ],
        ),
        content: Text(
          isRu
              ? 'Вы уверены, что хотите удалить эту запись об опыте работы?'
              : 'Ushbu ish tajribasi ma\'lumotlarini o\'chirishni xohlaysizmi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isRu ? 'Отмена' : 'Bekor qilish'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isRu ? 'Удалить' : 'O\'chirish'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final updated = List<dynamic>.from(_workExperienceList);
      updated.removeAt(index);
      setState(() => _workExperienceList = updated);

      if (widget.apiService != null) {
        try {
          await widget.apiService!.updateMasterProfile(workExperience: updated);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isRu ? 'Опыт работы успешно удален' : 'Ish tajribasi muvaffaqiyatli o\'chirildi'),
                backgroundColor: Colors.grey.shade800,
                behavior: SnackBarBehavior.floating,
              ),
            );
            widget.onProfileUpdated?.call();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
            );
          }
        }
      }
    }
  }

  // Add / Edit Work Experience Modal Sheet matching Screenshot
  void _showWorkExperienceModal([Map<String, dynamic>? existingExp, int? index]) {
    final isRu = AppStrings.isRu;
    final theme = Theme.of(context);
    final posController = TextEditingController(text: existingExp?['position'] ?? '');
    final compController = TextEditingController(text: existingExp?['company'] ?? '');
    final descController = TextEditingController(text: existingExp?['description'] ?? existingExp?['comment'] ?? '');
    String? startDate = existingExp?['start_date'];
    String? endDate = existingExp?['end_date'];
    bool isCurrent = existingExp?['is_current'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> pickDate(bool isStart) async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: ctx,
              initialDate: now,
              firstDate: DateTime(1960),
              lastDate: DateTime(2035),
            );
            if (picked != null) {
              final formatted = '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
              setModalState(() {
                if (isStart) startDate = formatted;
                else endDate = formatted;
              });
            }
          }

          final inputBg = theme.dividerColor.withValues(alpha: 0.08);

          return Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modal Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isRu ? 'Опыт работы' : 'Ish tajribasi',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: theme.dividerColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.close_rounded, size: 20),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Должность *
                  RichText(
                    text: TextSpan(
                      text: isRu ? 'Должность ' : 'Lavozim ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      children: const [
                        TextSpan(text: '*', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: posController,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        hintText: isRu ? 'Входить' : 'Kiriting',
                        hintStyle: TextStyle(color: theme.hintColor.withValues(alpha: 0.6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Предприятие *
                  RichText(
                    text: TextSpan(
                      text: isRu ? 'Предприятие ' : 'Korxona ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.textTheme.bodyLarge?.color,
                      ),
                      children: const [
                        TextSpan(text: '*', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: compController,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        hintText: isRu ? 'Входить' : 'Kiriting',
                        hintStyle: TextStyle(color: theme.hintColor.withValues(alpha: 0.6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dates Row: Дата начала * & Дата окончания *
                  Row(
                    children: [
                      // Start Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                text: isRu ? 'Дата начала ' : 'Boshlangan sana ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                                children: const [
                                  TextSpan(text: '*', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => pickDate(true),
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: inputBg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today_outlined, size: 18, color: theme.hintColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        startDate ?? (isRu ? 'Выбрать' : 'Tanlash'),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: startDate != null ? theme.textTheme.bodyLarge?.color : theme.hintColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // End Date
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                text: isRu ? 'Дата окончания ' : 'Tugagan sana ',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.textTheme.bodyLarge?.color,
                                ),
                                children: [
                                  if (!isCurrent) const TextSpan(text: '*', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: isCurrent ? null : () => pickDate(false),
                              child: Container(
                                height: 50,
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                                decoration: BoxDecoration(
                                  color: isCurrent ? inputBg.withValues(alpha: 0.5) : inputBg,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today_outlined, size: 18, color: theme.hintColor),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        isCurrent
                                            ? (isRu ? 'по наст. время' : 'hozirgacha')
                                            : (endDate ?? (isRu ? 'Выбрать' : 'Tanlash')),
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: (isCurrent || endDate != null)
                                              ? theme.textTheme.bodyLarge?.color
                                              : theme.hintColor,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Checkbox: Работаю в настоящее время
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setModalState(() {
                        isCurrent = !isCurrent;
                        if (isCurrent) endDate = null;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isCurrent ? const Color(0xFF22C55E) : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isCurrent ? const Color(0xFF22C55E) : theme.dividerColor,
                                width: 2,
                              ),
                            ),
                            child: isCurrent
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isRu ? 'Работаю в настоящее время' : 'Hozirgi vaqtda ishlayapman',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: theme.textTheme.bodyLarge?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Комментарий
                  Text(
                    isRu ? 'Комментарий' : 'Izoh',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: inputBg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: descController,
                      maxLines: 4,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        hintText: isRu ? 'Входить' : 'Kiriting',
                        hintStyle: TextStyle(color: theme.hintColor.withValues(alpha: 0.6)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Green Save Button matching screenshot
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        final pos = posController.text.trim();
                        final comp = compController.text.trim();

                        if (pos.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isRu ? 'Укажите должность' : 'Lavozimni ko\'rsating'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        if (comp.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isRu ? 'Укажите предприятие' : 'Korxonani ko\'rsating'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }
                        if (startDate == null || startDate!.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isRu ? 'Укажите дату начала' : 'Boshlanish sanasini ko\'rsating'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        final newExp = {
                          'position': pos,
                          'company': comp,
                          'start_date': startDate ?? '',
                          'end_date': isCurrent ? '' : (endDate ?? ''),
                          'is_current': isCurrent,
                          'description': descController.text.trim(),
                        };

                        final updated = List<dynamic>.from(_workExperienceList);
                        if (index != null && index < updated.length) {
                          updated[index] = newExp;
                        } else {
                          updated.add(newExp);
                        }

                        setState(() => _workExperienceList = updated);
                        Navigator.pop(ctx);

                        if (widget.apiService != null) {
                          try {
                            await widget.apiService!.updateMasterProfile(workExperience: updated);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isRu ? 'Опыт работы успешно сохранен!' : 'Ish tajribasi saqlandi!'),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              widget.onProfileUpdated?.call();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
                              );
                            }
                          }
                        }
                      },
                      child: Text(
                        isRu ? 'Сохранить' : 'Saqlash',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // Delete option if editing
                  if (index != null && index < _workExperienceList.length) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                        label: Text(
                          isRu ? 'Удалить этот опыт работы' : 'Ushbu ish tajribasini o\'chirish',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _deleteWorkExperience(index);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== 3. EDUCATION (COLLAPSIBLE & EDITABLE) ====================
  Widget _buildEducationCard(BuildContext context, ThemeData theme, bool isRu) {
    final count = _educationList.length;

    return _collapsibleContainer(
      theme: theme,
      icon: Icons.school_rounded,
      iconColor: Colors.teal,
      title: isRu ? 'Образование' : 'Ta\'lim',
      badgeText: count > 0 ? '$count' : null,
      isExpanded: _isEducationExpanded,
      onToggle: _toggleEducation,
      headerAction: null,
      previewText: (!_isEducationExpanded && count > 0)
          ? _educationList.map((e) => (e is Map ? (e['institution'] ?? '') : '').toString()).where((s) => s.isNotEmpty).join(' • ')
          : null,
      child: count == 0
          ? Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Icon(Icons.school_outlined, size: 36, color: theme.hintColor.withValues(alpha: 0.4)),
                  const SizedBox(height: 8),
                  Text(
                    isRu ? 'Образование не указано' : 'Ta\'lim ko\'rsatilmagan',
                    style: TextStyle(color: theme.hintColor, fontSize: 13),
                  ),
                  if (widget.isOwner) ...[
                    const SizedBox(height: 10),
                    TextButton.icon(
                      onPressed: () => _showEducationEditModal(),
                      icon: const Icon(Icons.add_rounded, size: 16, color: Colors.teal),
                      label: Text(
                        isRu ? 'Добавить образование' : 'Ta\'lim qo\'shish',
                        style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            )
          : Column(
              children: [
                ..._educationList.asMap().entries.map((entry) {
                  final i = entry.key;
                  final edu = entry.value;
                  final inst = edu is Map ? (edu['institution'] ?? '').toString() : '';
                  final spec = edu is Map ? (edu['specialty'] ?? '').toString() : '';
                  final lvl = edu is Map ? (edu['level'] ?? '').toString() : '';
                  final start = edu is Map ? (edu['start_date'] ?? '').toString() : '';
                  final end = edu is Map ? (edu['end_date'] ?? '').toString() : '';
                  final desc = edu is Map ? (edu['description'] ?? '').toString() : '';
                  final isLast = i == _educationList.length - 1;

                  return Container(
                    margin: EdgeInsets.only(bottom: isLast ? 0 : 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.teal.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Institution and Level Badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                inst,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: theme.textTheme.titleMedium?.color,
                                ),
                              ),
                            ),
                            if (lvl.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  lvl,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.teal,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        // Specialty
                        if (spec.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.workspace_premium_rounded, size: 15, color: Colors.teal),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  spec,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.textTheme.bodyMedium?.color,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Dates
                        if (start.isNotEmpty || end.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, size: 13, color: theme.hintColor),
                              const SizedBox(width: 6),
                              Text(
                                '$start — ${end.isNotEmpty ? end : (isRu ? "по наст. время" : "hozirgacha")}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: theme.hintColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],

                        // Description
                        if (desc.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            desc,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                          ),
                        ],

                        // Owner actions: Edit & Delete buttons
                        if (widget.isOwner) ...[
                          const SizedBox(height: 10),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // Edit button
                              TextButton.icon(
                                onPressed: () => _showEducationEditModal(edu is Map ? Map<String, dynamic>.from(edu) : null, i),
                                icon: const Icon(Icons.edit_outlined, size: 15, color: Colors.teal),
                                label: Text(
                                  isRu ? 'Настроить' : 'Tahrirlash',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.teal),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Delete button
                              TextButton.icon(
                                onPressed: () => _deleteEducation(i),
                                icon: const Icon(Icons.delete_outline_rounded, size: 15, color: AppColors.error),
                                label: Text(
                                  isRu ? 'Удалить' : 'O\'chirish',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  );
                }),

                if (widget.isOwner) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: OutlinedButton.icon(
                      onPressed: () => _showEducationEditModal(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.teal,
                        side: BorderSide(color: Colors.teal.withValues(alpha: 0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        isRu ? 'Добавить образование' : 'Ta\'lim qo\'shish',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  // Delete education with confirmation
  Future<void> _deleteEducation(int index) async {
    final isRu = AppStrings.isRu;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            const SizedBox(width: 8),
            Text(isRu ? 'Удалить образование?' : 'Ta\'limni o\'chirish?'),
          ],
        ),
        content: Text(
          isRu
              ? 'Вы уверены, что хотите удалить эту запись об образовании?'
              : 'Ushbu ta\'lim ma\'lumotlarini o\'chirishni xohlaysizmi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(isRu ? 'Отмена' : 'Bekor qilish'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isRu ? 'Удалить' : 'O\'chirish'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final updated = List<dynamic>.from(_educationList);
      updated.removeAt(index);
      setState(() => _educationList = updated);

      if (widget.apiService != null) {
        try {
          await widget.apiService!.updateMasterProfile(education: updated);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(isRu ? 'Образование успешно удалено' : 'Ta\'lim muvaffaqiyatli o\'chirildi'),
                backgroundColor: Colors.grey.shade800,
                behavior: SnackBarBehavior.floating,
              ),
            );
            widget.onProfileUpdated?.call();
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
            );
          }
        }
      }
    }
  }

  // Add / Edit Education Modal Sheet
  void _showEducationEditModal([Map<String, dynamic>? existingEdu, int? index]) {
    final isRu = AppStrings.isRu;
    final theme = Theme.of(context);
    final instController = TextEditingController(text: existingEdu?['institution'] ?? '');
    final specController = TextEditingController(text: existingEdu?['specialty'] ?? '');
    final descController = TextEditingController(text: existingEdu?['description'] ?? '');
    String? selectedLevel = existingEdu?['level'];
    String? startDate = existingEdu?['start_date'];
    String? endDate = existingEdu?['end_date'];

    final levels = isRu
        ? ['Высшее', 'Магистратура', 'Бакалавриат', 'Неоконченное высшее', 'Среднее специальное', 'Среднее']
        : ['Oliy', 'Magistratura', 'Bakalavriat', 'Tugallanmagan oliy', 'O\'rta maxsus', 'O\'rta'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          Future<void> pickDate(bool isStart) async {
            final now = DateTime.now();
            final picked = await showDatePicker(
              context: ctx,
              initialDate: now,
              firstDate: DateTime(1960),
              lastDate: DateTime(2035),
            );
            if (picked != null) {
              final formatted = '${picked.year}-${picked.month.toString().padLeft(2, '0')}';
              setModalState(() {
                if (isStart) startDate = formatted;
                else endDate = formatted;
              });
            }
          }

          return Container(
            padding: EdgeInsets.only(
              top: 20,
              left: 20,
              right: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modal Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isRu
                            ? (index != null ? 'Настроить образование' : 'Добавить образование')
                            : (index != null ? 'Ta\'limni tahrirlash' : 'Ta\'lim qo\'shish'),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.dividerColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, size: 20),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Institution
                  TextField(
                    controller: instController,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      labelText: isRu ? 'Учебное заведение *' : 'Ta\'lim muassasasi *',
                      hintText: isRu ? 'Например: ТАТУ, СамГУ, колледж...' : 'Masalan: TATU, SamDU...',
                      prefixIcon: const Icon(Icons.school_rounded, color: Colors.teal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Specialty
                  TextField(
                    controller: specController,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      labelText: isRu ? 'Специальность / Факультет *' : 'Mutaxassislik / Fakultet *',
                      hintText: isRu ? 'Например: Инженер-строитель, Электрик...' : 'Masalan: Quruvchi-muhandis...',
                      prefixIcon: const Icon(Icons.workspace_premium_rounded, color: Colors.teal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Level dropdown
                  DropdownButtonFormField<String>(
                    value: selectedLevel,
                    dropdownColor: theme.cardTheme.color,
                    decoration: InputDecoration(
                      labelText: isRu ? 'Степень образования' : 'Ta\'lim darajasi',
                      prefixIcon: const Icon(Icons.military_tech_rounded, color: Colors.teal),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    items: levels.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                    onChanged: (val) => setModalState(() => selectedLevel = val),
                  ),
                  const SizedBox(height: 14),

                  // Dates
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => pickDate(true),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.calendar_today_rounded, size: 16),
                          label: Text(
                            startDate ?? (isRu ? 'Начало' : 'Boshlanish'),
                            style: TextStyle(fontSize: 13, color: startDate != null ? theme.textTheme.bodyLarge?.color : theme.hintColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => pickDate(false),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.event_available_rounded, size: 16),
                          label: Text(
                            endDate ?? (isRu ? 'Окончание' : 'Tugash'),
                            style: TextStyle(fontSize: 13, color: endDate != null ? theme.textTheme.bodyLarge?.color : theme.hintColor),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Description
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                    decoration: InputDecoration(
                      labelText: isRu ? 'Дополнительно (курсы, диплом)' : 'Qo\'shimcha (kurslar, diplom)',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Save button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () async {
                        if (instController.text.trim().isEmpty || specController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            SnackBar(
                              content: Text(isRu ? 'Заполните обязательные поля *' : 'Majburiy maydonlarni to\'ldiring *'),
                              backgroundColor: AppColors.error,
                            ),
                          );
                          return;
                        }

                        final eduData = {
                          'institution': instController.text.trim(),
                          'specialty': specController.text.trim(),
                          'level': selectedLevel ?? (isRu ? 'Высшее' : 'Oliy'),
                          'start_date': startDate ?? '',
                          'end_date': endDate ?? '',
                          'description': descController.text.trim(),
                        };

                        final updated = List<dynamic>.from(_educationList);
                        if (index != null && index < updated.length) {
                          updated[index] = eduData;
                        } else {
                          updated.add(eduData);
                        }

                        setState(() => _educationList = updated);
                        Navigator.pop(ctx);

                        if (widget.apiService != null) {
                          try {
                            await widget.apiService!.updateMasterProfile(education: updated);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isRu ? 'Образование успешно сохранено!' : 'Ta\'lim saqlandi!'),
                                  backgroundColor: AppColors.primary,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                              widget.onProfileUpdated?.call();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: AppColors.error),
                              );
                            }
                          }
                        }
                      },
                      child: Text(
                        isRu ? 'Сохранить' : 'Saqlash',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  // Delete button inside modal if editing
                  if (index != null && index < _educationList.length) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                        label: Text(
                          isRu ? 'Удалить это образование' : 'Ushbu ta\'limni o\'chirish',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _deleteEducation(index);
                        },
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== 4. LANGUAGES (COLLAPSIBLE) ====================
  Widget _buildLanguagesCard(BuildContext context, ThemeData theme, bool isRu) {
    final count = widget.master.languages!.length;

    return _collapsibleContainer(
      theme: theme,
      icon: Icons.translate_rounded,
      iconColor: AppColors.primary,
      title: isRu ? 'Владение языками' : 'Til bilish darajasi',
      badgeText: '$count',
      isExpanded: _isLanguagesExpanded,
      onToggle: _toggleLanguages,
      previewText: (!_isLanguagesExpanded && count > 0)
          ? widget.master.languages!.map((l) {
              final lang = l is Map ? (l['language'] ?? '') : l.toString();
              final lvl = l is Map ? (l['level'] ?? '') : '';
              return lvl.isNotEmpty ? '$lang ($lvl)' : lang;
            }).join(' • ')
          : null,
      child: Column(
        children: widget.master.languages!.map((l) {
          final lang = l is Map ? (l['language'] ?? '').toString() : l.toString();
          final lvl = l is Map ? (l['level'] ?? '').toString() : '';
          if (lang.isEmpty) return const SizedBox.shrink();

          Color badgeColor = AppColors.primary;
          if (lvl.toLowerCase().contains('родн') || lvl.toLowerCase().contains('ona')) {
            badgeColor = Colors.green;
          } else if (lvl.contains('C1') || lvl.contains('C2') || lvl.toLowerCase().contains('свобод')) {
            badgeColor = Colors.blue;
          } else if (lvl.contains('B1') || lvl.contains('B2')) {
            badgeColor = Colors.teal;
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(Icons.language_rounded, size: 18, color: badgeColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    lang,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                if (lvl.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      lvl,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: badgeColor,
                      ),
                    ),
                  ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==================== 5. BASIC SKILLS (COLLAPSIBLE) ====================
  Widget _buildBasicSkillsCard(BuildContext context, ThemeData theme, bool isRu) {
    final count = widget.master.basicSkills!.length;

    return _collapsibleContainer(
      theme: theme,
      icon: Icons.psychology_rounded,
      iconColor: AppColors.secondary,
      title: isRu ? 'Базовые навыки' : 'Asosiy ko\'nikmalar',
      badgeText: '$count',
      isExpanded: _isBasicSkillsExpanded,
      onToggle: _toggleBasicSkills,
      previewText: (!_isBasicSkillsExpanded && count > 0)
          ? widget.master.basicSkills!.take(3).join(', ') + (count > 3 ? '...' : '')
          : null,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.master.basicSkills!.map((s) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.secondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.secondary.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, size: 15, color: AppColors.secondary),
                const SizedBox(width: 6),
                Text(
                  s,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==================== 6. CUSTOM / SPECIAL SKILLS ====================
  Widget _buildCustomSkillsCard(BuildContext context, ThemeData theme, bool isRu) {
    final count = widget.master.skills.length;

    return _collapsibleContainer(
      theme: theme,
      icon: Icons.auto_awesome_rounded,
      iconColor: Colors.amber,
      title: isRu ? 'Специализированные навыки' : 'Maxsus ko\'nikmalar',
      badgeText: '$count',
      isExpanded: _isCustomSkillsExpanded,
      onToggle: _toggleCustomSkills,
      previewText: (!_isCustomSkillsExpanded && count > 0)
          ? widget.master.skills.take(3).join(', ') + (count > 3 ? '...' : '')
          : null,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: widget.master.skills.map((s) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.star_rounded, size: 15, color: Colors.amber),
                const SizedBox(width: 6),
                Text(
                  s,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ==================== 7. DRIVER LICENSE & MOBILITY ====================
  Widget _buildDriverLicenseCard(BuildContext context, ThemeData theme, bool isRu) {
    final dl = widget.master.driverLicense;
    final categories = List<String>.from(dl?['categories'] ?? []);
    final hasCar = dl?['has_car'] == true;

    return _collapsibleContainer(
      theme: theme,
      icon: Icons.directions_car_rounded,
      iconColor: Colors.blue,
      title: isRu ? 'Водительские права и транспорт' : 'Haydovchilik guvohnomasi',
      isExpanded: _isDriverLicenseExpanded,
      onToggle: _toggleDriverLicense,
      previewText: !_isDriverLicenseExpanded
          ? (categories.isNotEmpty ? 'Категории: ${categories.join(", ")}' : '') + (hasCar ? ' • Личный авто' : '')
          : null,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          ...categories.map((cat) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.badge_rounded, size: 15, color: Colors.blue),
                const SizedBox(width: 6),
                Text(
                  '"$cat" ${isRu ? "категория" : "toifa"}',
                  style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )),
          if (hasCar)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.directions_car_filled_rounded, size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Text(
                    isRu ? 'Личный автомобиль' : 'Shaxsiy avtomobil',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ==================== 8. DISABILITY / SPECIAL NOTES ====================
  Widget _buildDisabilityCard(BuildContext context, ThemeData theme, bool isRu) {
    final dis = widget.master.disability;
    final type = dis?['type']?.toString() ?? '';
    final comment = dis?['comment']?.toString() ?? '';

    return _collapsibleContainer(
      theme: theme,
      icon: Icons.accessibility_new_rounded,
      iconColor: Colors.orange,
      title: isRu ? 'Особые условия / Здоровье' : 'Maxsus sharoitlar',
      isExpanded: _isDisabilityExpanded,
      onToggle: _toggleDisability,
      previewText: !_isDisabilityExpanded ? '$type${comment.isNotEmpty ? " • $comment" : ""}' : null,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
        ),
        child: Text(
          '$type${comment.isNotEmpty ? " • $comment" : ""}',
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  // ==================== COLLAPSIBLE CONTAINER HELPER ====================
  Widget _collapsibleContainer({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String title,
    String? badgeText,
    required bool isExpanded,
    VoidCallback? onToggle,
    Widget? headerAction,
    String? previewText,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row (clickable to toggle collapse)
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: onToggle,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleMedium?.color,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (badgeText != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: iconColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            badgeText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: iconColor,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (headerAction != null) ...[
                  headerAction,
                  const SizedBox(width: 8),
                ],
                if (onToggle != null)
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: theme.hintColor,
                    size: 22,
                  ),
              ],
            ),
          ),

          // If collapsed and preview text is available
          if (!isExpanded && previewText != null && previewText.isNotEmpty) ...[
            const SizedBox(height: 8),
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: onToggle,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  previewText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.hintColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],

          // Expanded content
          if (isExpanded) ...[
            const SizedBox(height: 14),
            child,
          ],
        ],
      ),
    );
  }

  // ==================== UNIFIED EXECUTIVE PROFILE VIEW ====================
  Widget _buildUnifiedProfileView(BuildContext context, ThemeData theme, bool isRu) {
    final cityText = (widget.master.city != null && widget.master.city!.trim().isNotEmpty)
        ? '${widget.master.city}${widget.master.district != null && widget.master.district!.trim().isNotEmpty ? ", ${widget.master.district}" : ""}'
        : (isRu ? 'Не указан' : 'Ko\'rsatilmagan');

    final rateText = widget.master.hourlyRate != null
        ? '${PriceFormatter.format(widget.master.hourlyRate)} ${isRu ? "сум / час" : "so'm / soat"}'
        : (isRu ? 'По договоренности' : 'Kelishilgan');

    final hasBio = widget.master.description != null && widget.master.description!.trim().isNotEmpty;
    final hasEdu = _educationList.isNotEmpty;
    final hasLang = widget.master.languages != null && widget.master.languages!.isNotEmpty;
    final hasBasicSkills = widget.master.basicSkills != null && widget.master.basicSkills!.isNotEmpty;
    final hasCustomSkills = widget.master.skills.isNotEmpty;
    final hasDriver = widget.master.driverLicense != null;
    final hasDisability = widget.master.disability != null;

    Widget sectionCard({required Widget child}) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.cardTheme.color,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: child,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Key Info Card: Location, Rate, Status
        sectionCard(
          child: Column(
            children: [
              _unifiedInfoRow(
                theme: theme,
                icon: Icons.location_on_rounded,
                iconColor: Colors.redAccent,
                label: isRu ? 'Локация мастера' : 'Mutaxassis manzili',
                value: cityText,
              ),
              const SizedBox(height: 14),
              _unifiedInfoRow(
                theme: theme,
                icon: Icons.payments_rounded,
                iconColor: Colors.green,
                label: isRu ? 'Стоимость работы (Ставка)' : 'Ish haqi (Narx)',
                value: rateText,
                valueColor: Colors.green.shade700,
                valueBold: true,
              ),
              const SizedBox(height: 14),
              _unifiedInfoRow(
                theme: theme,
                icon: widget.master.isAvailable ? Icons.check_circle_rounded : Icons.cancel_rounded,
                iconColor: widget.master.isAvailable ? AppColors.success : AppColors.error,
                label: isRu ? 'Готовность к работе' : 'Ishga tayyorlik',
                value: widget.master.isAvailable
                    ? (isRu ? 'Свободен для заказов' : 'Buyurtmalar uchun bo\'sh')
                    : (isRu ? 'Занят' : 'Band'),
                valueColor: widget.master.isAvailable ? AppColors.success : AppColors.error,
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. Metrics Bar: Experience, Rating, Reviews
        Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: theme.cardTheme.color,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.dividerColor.withValues(alpha: 0.25)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              _metricItem(
                theme: theme,
                icon: Icons.work_history_rounded,
                color: Colors.blue,
                title: isRu ? 'Опыт' : 'Tajriba',
                value: '${widget.master.experienceYears} ${isRu ? "лет" : "yil"}',
              ),
              Container(width: 1, height: 32, color: theme.dividerColor.withValues(alpha: 0.3)),
              _metricItem(
                theme: theme,
                icon: Icons.star_rounded,
                color: Colors.amber,
                title: isRu ? 'Рейтинг' : 'Reyting',
                value: widget.master.rating > 0 ? widget.master.rating.toStringAsFixed(1) : (isRu ? 'Новый' : 'Yangi'),
              ),
              Container(width: 1, height: 32, color: theme.dividerColor.withValues(alpha: 0.3)),
              _metricItem(
                theme: theme,
                icon: Icons.chat_rounded,
                color: Colors.teal,
                title: isRu ? 'Отзывы' : 'Sharhlar',
                value: '${widget.master.reviewsCount}',
              ),
            ],
          ),
        ),

        // 3. Bio / Summary
        if (hasBio) ...[
          const SizedBox(height: 14),
          sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _unifiedSectionHeader(theme, Icons.person_outline_rounded, AppColors.primary, isRu ? 'О специалисте' : 'Mutaxassis haqida'),
                const SizedBox(height: 12),
                Text(
                  widget.master.description!.trim(),
                  style: TextStyle(fontSize: 14, height: 1.5, color: theme.textTheme.bodyLarge?.color),
                ),
              ],
            ),
          ),
        ],

        // 4. Skills (Core & Custom)
        if (hasBasicSkills || hasCustomSkills) ...[
          const SizedBox(height: 14),
          sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _unifiedSectionHeader(theme, Icons.psychology_rounded, Colors.deepPurple, isRu ? 'Профессиональные навыки' : 'Ko\'nikmalar'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (hasBasicSkills)
                      ...widget.master.basicSkills!.map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 6),
                            Text(s, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.primary)),
                          ],
                        ),
                      )),
                    if (hasCustomSkills)
                      ...widget.master.skills.map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: theme.scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
                        ),
                        child: Text(s, style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color)),
                      )),
                  ],
                ),
              ],
            ),
          ),
        ],

        // Work Experience
        if (_workExperienceList.isNotEmpty) ...[
          const SizedBox(height: 14),
          sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _unifiedSectionHeader(theme, Icons.business_center_rounded, Colors.blue, isRu ? 'Опыт работы' : 'Ish tajribasi'),
                const SizedBox(height: 14),
                ..._workExperienceList.asMap().entries.map((entry) {
                  final exp = entry.value;
                  final pos = exp is Map ? (exp['position'] ?? '').toString() : '';
                  final comp = exp is Map ? (exp['company'] ?? '').toString() : '';
                  final start = exp is Map ? (exp['start_date'] ?? '').toString() : '';
                  final end = exp is Map ? (exp['end_date'] ?? '').toString() : '';
                  final isCur = exp is Map ? (exp['is_current'] == true) : false;
                  final desc = exp is Map ? (exp['description'] ?? exp['comment'] ?? '').toString() : '';
                  final isLast = entry.key == _workExperienceList.length - 1;

                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pos, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color)),
                        if (comp.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(comp, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ],
                        if (start.isNotEmpty || end.isNotEmpty || isCur) ...[
                          const SizedBox(height: 4),
                          Text(
                            '$start — ${isCur ? (isRu ? "по наст. время" : "hozirgacha") : (end.isNotEmpty ? end : (isRu ? "по наст. время" : "hozirgacha"))}',
                            style: TextStyle(fontSize: 12, color: theme.hintColor),
                          ),
                        ],
                        if (desc.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(desc, style: TextStyle(fontSize: 13, color: theme.textTheme.bodyMedium?.color)),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],

        // 5. Education
        if (hasEdu) ...[
          const SizedBox(height: 14),
          sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _unifiedSectionHeader(theme, Icons.school_rounded, Colors.teal, isRu ? 'Образование' : 'Ta\'lim'),
                const SizedBox(height: 14),
                ..._educationList.asMap().entries.map((entry) {
                  final edu = entry.value;
                  final inst = edu is Map ? (edu['institution'] ?? '').toString() : '';
                  final spec = edu is Map ? (edu['specialty'] ?? '').toString() : '';
                  final lvl = edu is Map ? (edu['level'] ?? '').toString() : '';
                  final start = edu is Map ? (edu['start_date'] ?? '').toString() : '';
                  final end = edu is Map ? (edu['end_date'] ?? '').toString() : '';
                  final isLast = entry.key == _educationList.length - 1;

                  return Padding(
                    padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                inst,
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: theme.textTheme.titleMedium?.color),
                              ),
                            ),
                            if (lvl.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.teal.withValues(alpha: 0.3)),
                                ),
                                child: Text(lvl, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal)),
                              ),
                          ],
                        ),
                        if (spec.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(spec, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: theme.textTheme.bodyMedium?.color)),
                        ],
                        if (start.isNotEmpty || end.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            '$start — ${end.isNotEmpty ? end : (isRu ? "по наст. время" : "hozirgacha")}',
                            style: TextStyle(fontSize: 12, color: theme.hintColor),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],

        // 6. Languages
        if (hasLang) ...[
          const SizedBox(height: 14),
          sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _unifiedSectionHeader(theme, Icons.translate_rounded, Colors.indigo, isRu ? 'Владение языками' : 'Tillar'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.master.languages!.map((l) {
                    final name = l is Map ? (l['language'] ?? l['name'] ?? l['lang'] ?? '') : l.toString();
                    final lvl = l is Map ? (l['level'] ?? '') : '';
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.indigo.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: theme.textTheme.titleMedium?.color)),
                          if (lvl.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Text('($lvl)', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.indigo)),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],

        // 7. Driver's License & Mobility
        if (hasDriver) ...[
          const SizedBox(height: 14),
          sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _unifiedSectionHeader(theme, Icons.directions_car_rounded, Colors.blue, isRu ? 'Водительские права и транспорт' : 'Haydovchilik guvohnomasi'),
                const SizedBox(height: 12),
                _buildDriverLicenseContent(theme, isRu),
              ],
            ),
          ),
        ],

        // 8. Disability (if any)
        if (hasDisability) ...[
          const SizedBox(height: 14),
          sectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _unifiedSectionHeader(theme, Icons.accessibility_new_rounded, Colors.orange, isRu ? 'Особые условия / Здоровье' : 'Maxsus sharoitlar'),
                const SizedBox(height: 12),
                _buildDisabilityContent(theme, isRu),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _unifiedInfoRow({
    required ThemeData theme,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
    bool valueBold = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.hintColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: valueBold ? FontWeight.bold : FontWeight.w600,
                  color: valueColor ?? theme.textTheme.bodyLarge?.color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _unifiedSectionDivider(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.3)),
    );
  }

  Widget _unifiedSectionHeader(ThemeData theme, IconData icon, Color iconColor, String title) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: iconColor, size: 17),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: theme.textTheme.titleMedium?.color,
          ),
        ),
      ],
    );
  }

  Widget _buildDriverLicenseContent(ThemeData theme, bool isRu) {
    final dl = widget.master.driverLicense;
    final categories = List<String>.from(dl?['categories'] ?? []);
    final hasCar = dl?['has_car'] == true;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...categories.map((cat) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.badge_rounded, size: 15, color: Colors.blue),
              const SizedBox(width: 6),
              Text(
                '"$cat" ${isRu ? "категория" : "toifa"}',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        )),
        if (hasCar)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.directions_car_filled_rounded, size: 16, color: Colors.green),
                const SizedBox(width: 6),
                Text(
                  isRu ? 'Личный автомобиль' : 'Shaxsiy avtomobil',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildDisabilityContent(ThemeData theme, bool isRu) {
    final dis = widget.master.disability;
    final type = dis?['type']?.toString() ?? '';
    final comment = dis?['comment']?.toString() ?? '';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.2)),
      ),
      child: Text(
        '$type${comment.isNotEmpty ? " • $comment" : ""}',
        style: const TextStyle(
          color: Colors.orange,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }
}
