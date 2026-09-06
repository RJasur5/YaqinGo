import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../config/localization.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import '../widgets/gradient_button.dart';
import '../models/category.dart';
import 'package:flutter/services.dart';
import '../utils/formatters.dart';
import '../config/regions.dart';

class MasterProfileSetupScreen extends StatefulWidget {
  final ApiService apiService;
  final AuthService authService;

  const MasterProfileSetupScreen({
    super.key,
    required this.apiService,
    required this.authService,
  });

  @override
  State<MasterProfileSetupScreen> createState() => _MasterProfileSetupScreenState();
}

class _MasterProfileSetupScreenState extends State<MasterProfileSetupScreen> {
  final _descController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  final _experienceController = TextEditingController();
  final _skillsController = TextEditingController();
  final _addressController = TextEditingController();
  
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isEditing = false;
  String? _error;

  List<CategoryModel> _categories = [];
  int? _selectedCategoryId;
  int? _selectedSubcategoryId;

  String? _selectedCityKey; // stores key like 'toshkent_shahar'
  String? _selectedDistrictKey; // stores key like 'mirobod'

  @override
  void initState() {
    super.initState();
    _loadData();
    final userCity = widget.authService.currentUser?.city;
    if (userCity != null) {
      _selectedCityKey = RegionsConfig.getKey(userCity);
      if (!RegionsConfig.regionKeys.contains(_selectedCityKey)) {
        _selectedCityKey = null;
      }
    }
  }

  Future<void> _loadData() async {
    try {
      final cats = await widget.apiService.getCategories();
      _categories = cats;
      
      // Try to load existing profile
      final profile = await widget.apiService.getMyMasterProfile();
      if (profile != null) {
        _isEditing = true;
        _descController.text = profile.description ?? '';
        _hourlyRateController.text = profile.hourlyRate?.toStringAsFixed(0) ?? '';
        _experienceController.text = profile.experienceYears.toString();
        _skillsController.text = profile.skills.join(', ');
        _addressController.text = profile.address ?? '';
        if (profile.city != null) {
          _selectedCityKey = RegionsConfig.getKey(profile.city!.trim());
        }
        if (profile.district != null && _selectedCityKey != null) {
          _selectedDistrictKey = RegionsConfig.getDistrictKey(profile.district!.trim(), _selectedCityKey);
        }
        _selectedSubcategoryId = profile.subcategoryId;
        
        // Find category ID
        for (var cat in _categories) {
          if (cat.subcategories.any((s) => s.id == _selectedSubcategoryId)) {
            _selectedCategoryId = cat.id;
            break;
          }
        }
      }

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load data';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _save() async {
    print('DEBUG: SAVE BUTTON CLICKED');
    if (_selectedSubcategoryId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Пожалуйста, выберите специализацию'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }
    
    if (_selectedCityKey != null && _selectedDistrictKey == null) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Пожалуйста, выберите район'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      return;
    }

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      final skillsText = _skillsController.text.trim();
      List<String> skills = [];
      if (skillsText.isNotEmpty) {
        skills = skillsText.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      }

      // Convert keys to display names for API
      final cityForApi = _selectedCityKey != null ? RegionsConfig.getDisplayName(_selectedCityKey!) : null;
      final districtForApi = _selectedDistrictKey != null ? RegionsConfig.getDistrictDisplay(_selectedDistrictKey!, _selectedCityKey) : null;

      String? addressToSend = _addressController.text.trim();
      if (_selectedCityKey != null && _selectedDistrictKey != null) {
        addressToSend = '';
      }

      if (_isEditing) {
        await widget.apiService.updateMasterProfile(
          subcategoryId: _selectedSubcategoryId!,
          description: _descController.text.trim(),
          experienceYears: int.tryParse(_experienceController.text) ?? 0,
          hourlyRate: double.tryParse(_hourlyRateController.text.replaceAll(' ', '')),
          city: cityForApi,
          district: districtForApi,
          address: addressToSend,
          skills: skills,
        );
      } else {
        await widget.apiService.createMasterProfile(
          subcategoryId: _selectedSubcategoryId!,
          description: _descController.text.trim(),
          experienceYears: int.tryParse(_experienceController.text) ?? 0,
          hourlyRate: double.tryParse(_hourlyRateController.text.replaceAll(' ', '')),
          city: cityForApi,
          district: districtForApi,
          address: addressToSend,
          skills: skills,
        );
      }

      // also update user city if needed
      if (cityForApi != null && cityForApi != widget.authService.currentUser?.city) {
        await widget.apiService.updateProfile(city: cityForApi);
      }

      if (mounted) {
        // Refresh local user state so isMaster becomes true immediately
        await widget.authService.refreshUser();
        
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('ERROR SAVING PROFILE: $e');
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = ThemeService().currentMode != AppThemeMode.light;

    return Container(
      decoration: BoxDecoration(gradient: AppTheme.currentGradient(context)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(AppStrings.isRu ? 'Профиль мастера' : 'Mutaxassis profili'),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: theme.textTheme.titleLarge?.color,
        ),
        body: _isLoading 
            ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
            : SingleChildScrollView(
                padding: const EdgeInsets.only(top: 8, left: 20, right: 20, bottom: 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_error != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                        ),
                        child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // --- 1. Category Dropdown ---
                    Text(
                      AppStrings.isRu ? 'Сфера деятельности' : 'Faoliyat sohasi',
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: _selectedCategoryId,
                          hint: Text(
                            AppStrings.isRu ? 'Выберите категорию' : 'Kategoriyani tanlang',
                            style: TextStyle(color: theme.hintColor),
                          ),
                          dropdownColor: theme.cardTheme.color,
                          items: _categories.map((c) {
                            return DropdownMenuItem<int>(
                              value: c.id,
                              child: Text(c.name(AppStrings.lang), style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _selectedCategoryId = val;
                              _selectedSubcategoryId = null; // reset subcategory
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // --- 2. Subcategory Dropdown ---
                    if (_selectedCategoryId != null) ...[
                      Text(
                        AppStrings.isRu ? 'Специализация' : 'Mutaxassislik',
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isExpanded: true,
                            value: _selectedSubcategoryId,
                            hint: Text(
                              AppStrings.isRu ? 'Выберите специализацию' : 'Mutaxassislikni tanlang',
                              style: TextStyle(color: theme.hintColor),
                            ),
                            dropdownColor: theme.cardTheme.color,
                            items: _categories.firstWhere((c) => c.id == _selectedCategoryId).subcategories.map((sub) {
                              return DropdownMenuItem<int>(
                                value: sub.id,
                                child: Text(sub.name(AppStrings.lang), style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              setState(() => _selectedSubcategoryId = val);
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // City Override
                    Text(
                      AppStrings.city,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _selectedCityKey,
                          hint: Text(AppStrings.city, style: TextStyle(color: theme.hintColor)),
                          dropdownColor: theme.cardTheme.color,
                          items: RegionsConfig.regionKeys.map((key) {
                            return DropdownMenuItem<String>(
                              value: key,
                              child: Text(RegionsConfig.getDisplayName(key), style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() { _selectedCityKey = val; _selectedDistrictKey = null; });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_selectedCityKey != null && RegionsConfig.getDistricts(_selectedCityKey).isNotEmpty) ...[
                      Text(
                        AppStrings.isRu ? 'Район' : 'Tuman',
                        style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedDistrictKey,
                            hint: Text(AppStrings.isRu ? 'Выберите район' : 'Tumanni tanlang', style: TextStyle(color: theme.hintColor)),
                            dropdownColor: theme.cardTheme.color,
                            items: RegionsConfig.getDistricts(_selectedCityKey).map((displayName) {
                              final key = RegionsConfig.getDistrictKey(displayName, _selectedCityKey);
                              return DropdownMenuItem<String>(
                                value: key,
                                child: Text(displayName, style: TextStyle(color: theme.textTheme.bodyLarge?.color)),
                              );
                            }).toList(),
                            onChanged: (val) => setState(() => _selectedDistrictKey = val),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 20),

                    // Experience
                    TextField(
                      controller: _experienceController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(2),
                      ],
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        labelText: AppStrings.isRu ? 'Опыт (в годах)' : 'Tajriba (yillarda)',
                        labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                        filled: true,
                        fillColor: theme.cardTheme.color,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Hourly rate
                    TextField(
                      controller: _hourlyRateController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        ThousandsSeparatorInputFormatter(),
                      ],
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        labelText: AppStrings.isRu ? 'Ставка в час (сум)' : 'Soatlik to\'lov (so\'m)',
                        labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                        filled: true,
                        fillColor: theme.cardTheme.color,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Skills
                    TextField(
                      controller: _skillsController,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        labelText: AppStrings.isRu ? 'Навыки (через запятую)' : 'Ko\'nikmalar (vergul bilan)',
                        labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                        hintText: 'Сантехника, Электрика...',
                        hintStyle: TextStyle(color: theme.hintColor),
                        filled: true,
                        fillColor: theme.cardTheme.color,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Description
                    TextField(
                      controller: _descController,
                      minLines: 4,
                      maxLines: null,
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color),
                      decoration: InputDecoration(
                        labelText: AppStrings.description,
                        labelStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: theme.cardTheme.color,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 32),

                    GradientButton(
                      text: AppStrings.save,
                      isLoading: _isSaving,
                      onPressed: _save,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _descController.dispose();
    _hourlyRateController.dispose();
    _experienceController.dispose();
    _skillsController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
