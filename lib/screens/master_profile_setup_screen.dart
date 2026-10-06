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

  List<Map<String, String>> _selectedLanguages = [];
  List<String> _selectedBasicSkills = [];
  Map<String, dynamic>? _driverLicense;
  List<Map<String, dynamic>> _educationList = [];
  List<Map<String, dynamic>> _workExperienceList = [];
  Map<String, dynamic>? _disability;

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
        if (profile.languages != null) {
          _selectedLanguages = profile.languages!
              .whereType<Map>()
              .map((m) => {
                    'language': (m['language'] ?? '').toString(),
                    'level': (m['level'] ?? '').toString(),
                  })
              .where((m) => m['language']!.isNotEmpty)
              .toList();
        }
        if (profile.basicSkills != null) {
          _selectedBasicSkills = List<String>.from(profile.basicSkills!);
        }
        if (profile.driverLicense != null) {
          _driverLicense = Map<String, dynamic>.from(profile.driverLicense!);
        }
        if (profile.education != null) {
          _educationList = profile.education!
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        if (profile.workExperience != null) {
          _workExperienceList = profile.workExperience!
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
        if (profile.disability != null) {
          _disability = Map<String, dynamic>.from(profile.disability!);
        }
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
          languages: _selectedLanguages,
          basicSkills: _selectedBasicSkills,
          driverLicense: _driverLicense,
          education: _educationList,
          workExperience: _workExperienceList,
          disability: _disability,
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
          languages: _selectedLanguages,
          basicSkills: _selectedBasicSkills,
          driverLicense: _driverLicense,
          education: _educationList,
          workExperience: _workExperienceList,
          disability: _disability,
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

  static const List<String> _availableLanguagesRu = [
    'Узбекский язык',
    'Русский язык',
    'Английский язык',
    'Таджикский язык',
    'Казахский язык',
    'Кыргызский язык',
    'Турецкий язык',
    'Корейский язык',
    'Немецкий язык',
    'Китайский язык',
    'Арабский язык',
  ];

  static const List<String> _availableLanguagesUz = [
    'O\'zbek tili',
    'Rus tili',
    'Ingliz tili',
    'Tojik tili',
    'Qozoq tili',
    'Qirg\'iz tili',
    'Turk tili',
    'Koreys tili',
    'Nemis tili',
    'Xitoy tili',
    'Arab tili',
  ];

  static const List<String> _languageLevelsRu = [
    'Родной',
    'Начальный (A1-A2)',
    'Базовый (B1)',
    'Разговорный (B2)',
    'Свободный (C1-C2)',
    'Профессиональный',
  ];

  static const List<String> _languageLevelsUz = [
    'Ona tili',
    'Boshlang\'ich (A1-A2)',
    'O\'rta (B1)',
    'So\'zlashuv darajasi (B2)',
    'Erkin (C1-C2)',
    'Professional',
  ];

  static const List<String> _availableBasicSkillsRu = [
    'Быстрая обучаемость',
    'Умение работать самостоятельно',
    'Управление временем',
    'Ответственность',
    'Коммуникация',
    'Навыки командной работы',
    'Решение проблем',
    'Стремление к цели',
    'Адаптивность',
    'Инициативность',
    'Умение работать с людьми',
    'Критическое мышление',
    'Эмоциональная устойчивость',
    'Пунктуальность',
    'Внимание к деталям',
    'Стрессоустойчивость',
    'Клиентоориентированность',
    'Честность и порядочность',
    'Аккуратность',
    'Вежливость и тактичность',
    'Дисциплинированность',
    'Организаторские способности',
    'Грамотная речь',
    'Умение слушать',
    'Аналитическое мышление',
    'Креативность',
    'Трудолюбие',
    'Упорство и настойчивость',
    'Лидерские качества',
    'Нацеленность на результат',
    'Способность к многозадачности',
    'Быстрое принятие решений',
    'Гибкость мышления',
  ];

  static const List<String> _availableBasicSkillsUz = [
    'Tez o\'rganish',
    'Mustaqil ishlash qobiliyati',
    'Vaqtni boshqarish',
    'Mas\'uliyatlilik',
    'Muloqotchanlik',
    'Jamoaviy ishlash ko\'nikmalari',
    'Muammolarni hal qilish',
    'Maqsadga intilish',
    'Moslashuvchanlik',
    'Tashabbuskorlik',
    'Odamlar bilan ishlash qobiliyati',
    'Tanqidiy fikrlash',
    'Hissiy barqarorlik',
    'Vaqtga qat\'iy rioya qilish',
    'Tafsilotlarga e\'tiborli bo\'lish',
    'Stressga chidamlilik',
    'Mijozlarga xushmuomala bo\'lish',
    'Halollik va to\'g\'riso\'zlik',
    'Tartiblilik va saranjomlik',
    'Xushmuomalalik va odoblilik',
    'Intizomlilik',
    'Tashkilotchilik qobiliyati',
    'Ravon va savodli nutq',
    'Tinglash qobiliyati',
    'Tahliliy fikrlash',
    'Ijodkorlik va kreativlik',
    'Mehnatsevarlik',
    'Qat\'iyatlilik va sabot',
    'Yetakchilik qobiliyati',
    'Natijaga yo\'naltirilganlik',
    'Ko\'p vazifalarni bajarish',
    'Tezkor qaror qabul qilish',
    'Moslashuvchan fikrlash',
  ];

  void _showLanguagesModal() {
    final theme = Theme.of(context);
    final isRu = AppStrings.isRu;
    final langList = isRu ? _availableLanguagesRu : _availableLanguagesUz;
    final levelList = isRu ? _languageLevelsRu : _languageLevelsUz;

    List<Map<String, String>> tempLanguages = List<Map<String, String>>.from(
      _selectedLanguages.map((e) => Map<String, String>.from(e)),
    );

    if (tempLanguages.isEmpty) {
      tempLanguages.add({
        'language': langList[0],
        'level': levelList[0],
      });
      if (langList.length > 1) {
        tempLanguages.add({
          'language': langList[1],
          'level': levelList.length > 3 ? levelList[3] : levelList[0],
        });
      }
      if (langList.length > 2) {
        tempLanguages.add({
          'language': langList[2],
          'level': levelList.length > 2 ? levelList[2] : levelList[0],
        });
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isRu ? 'Знание языка' : 'Til bilish darajasi',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 24),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(tempLanguages.length, (index) {
                    final item = tempLanguages[index];
                    String currentLang = item['language'] ?? langList[0];
                    if (!langList.contains(currentLang)) currentLang = langList[0];

                    String currentLevel = item['level'] ?? levelList[0];
                    if (!levelList.contains(currentLevel)) currentLevel = levelList[0];

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.cardTheme.color,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: currentLang,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                      dropdownColor: theme.cardTheme.color,
                                      items: langList.map((l) => DropdownMenuItem(
                                        value: l,
                                        child: Text(l, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 15)),
                                      )).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setModalState(() {
                                            tempLanguages[index]['language'] = val;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.cardTheme.color,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      isExpanded: true,
                                      value: currentLevel,
                                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                                      dropdownColor: theme.cardTheme.color,
                                      items: levelList.map((lvl) => DropdownMenuItem(
                                        value: lvl,
                                        child: Text(lvl, style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontSize: 14)),
                                      )).toList(),
                                      onChanged: (val) {
                                        if (val != null) {
                                          setModalState(() {
                                            tempLanguages[index]['level'] = val;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            height: 104,
                            width: 52,
                            decoration: BoxDecoration(
                              color: theme.cardTheme.color,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: theme.dividerColor.withOpacity(0.5)),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 26),
                              onPressed: () {
                                setModalState(() {
                                  tempLanguages.removeAt(index);
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor.withOpacity(0.12),
                      foregroundColor: theme.primaryColor,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () {
                      setModalState(() {
                        tempLanguages.add({
                          'language': langList[0],
                          'level': levelList[0],
                        });
                      });
                    },
                    child: Text(
                      isRu ? 'Добавить язык' : 'Til qo\'shish',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 18),
                  GradientButton(
                    text: AppStrings.save,
                    onPressed: () {
                      setState(() {
                        _selectedLanguages = tempLanguages;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showBasicSkillsModal() {
    final theme = Theme.of(context);
    final isRu = AppStrings.isRu;
    final skillsList = isRu ? _availableBasicSkillsRu : _availableBasicSkillsUz;

    List<String> tempSkills = List<String>.from(_selectedBasicSkills);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardTheme.color,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isRu ? 'Базовые навыки' : 'Asosiy ko\'nikmalar',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 24),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    isRu
                        ? 'Выберите до 10. Мы рекомендуем вакансию тем, кто обладает этими навыками.'
                        : '10 tagacha tanlang. Ushbu ko\'nikmalarga ega bo\'lganlarga tavsiya etiladi.',
                    style: TextStyle(
                      color: theme.textTheme.bodySmall?.color,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Wrap(
                    spacing: 8,
                    runSpacing: 10,
                    children: skillsList.map((skill) {
                      final isSelected = tempSkills.contains(skill);
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            if (isSelected) {
                              tempSkills.remove(skill);
                            } else {
                              if (tempSkills.length >= 10) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(isRu ? 'Максимум 10 навыков' : 'Ko\'pi bilan 10 ta ko\'nikma'),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                                return;
                              }
                              tempSkills.add(skill);
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : theme.cardTheme.color,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : theme.dividerColor.withOpacity(0.4),
                              width: isSelected ? 1.5 : 1.0,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (isSelected) ...[
                                const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                skill,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : theme.textTheme.bodyLarge?.color,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  GradientButton(
                    text: AppStrings.save,
                    onPressed: () {
                      setState(() {
                        _selectedBasicSkills = tempSkills;
                      });
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ==================== DRIVER LICENSE MODAL ====================
  void _showDriverLicenseModal() {
    final isRu = AppStrings.isRu;
    final theme = Theme.of(context);
    final categories = ['A', 'B', 'BC', 'C', 'D', 'E'];
    final currentCats = List<String>.from(_driverLicense?['categories'] ?? []);
    bool hasCar = _driverLicense?['has_car'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Close
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isRu ? 'Водительские права' : 'Haydovchilik guvohnomasi',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: theme.textTheme.titleLarge?.color,
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: theme.dividerColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.close_rounded, size: 20),
                      ),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Category Buttons Grid (2 columns)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 2.8,
                  ),
                  itemCount: categories.length,
                  itemBuilder: (ctx, i) {
                    final cat = categories[i];
                    final isSelected = currentCats.contains(cat);
                    return InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setModalState(() {
                          if (isSelected) {
                            currentCats.remove(cat);
                          } else {
                            currentCats.add(cat);
                          }
                        });
                      },
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withOpacity(0.12)
                              : theme.cardTheme.color,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.primary : theme.dividerColor.withOpacity(0.3),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Text(
                          '"$cat" ${isRu ? "категория" : "toifa"}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected ? AppColors.primary : theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // Personal Car Checkbox
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setModalState(() => hasCar = !hasCar),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Checkbox(
                          value: hasCar,
                          activeColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          onChanged: (val) => setModalState(() => hasCar = val ?? false),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isRu ? 'Личный автомобиль' : 'Shaxsiy avtomobil',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Save Button (Bright Green)
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4ADE80), // Neon light green as in screenshot
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      setState(() {
                        if (currentCats.isEmpty && !hasCar) {
                          _driverLicense = null;
                        } else {
                          _driverLicense = {
                            'categories': currentCats,
                            'has_car': hasCar,
                          };
                        }
                      });
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      isRu ? 'Сохранить' : 'Saqlash',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ==================== WORK EXPERIENCE MODAL ====================
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

                  // Dates Row
                  Row(
                    children: [
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

                  // Green Save Button
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
                      onPressed: () {
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

                        setState(() {
                          if (index != null && index < _workExperienceList.length) {
                            _workExperienceList[index] = newExp;
                          } else {
                            _workExperienceList.add(newExp);
                          }
                        });

                        Navigator.pop(ctx);
                      },
                      child: Text(
                        isRu ? 'Сохранить' : 'Saqlash',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

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
                          setState(() {
                            _workExperienceList.removeAt(index);
                          });
                          Navigator.pop(ctx);
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

  // ==================== EDUCATION MODAL ====================
  void _showEducationModal([Map<String, dynamic>? existingEdu, int? index]) {
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
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isRu ? 'Добавить образование' : 'Ta\'lim qo\'shish',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.dividerColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, size: 20),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Institution
                  RichText(
                    text: TextSpan(
                      text: isRu ? 'Учебное заведение ' : 'Ta\'lim muassasasi ',
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600, fontSize: 14),
                      children: const [TextSpan(text: '*', style: TextStyle(color: Colors.red))],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: instController,
                    decoration: InputDecoration(
                      hintText: isRu ? 'Входить' : 'Kiritish',
                      filled: true,
                      fillColor: theme.cardTheme.color,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.3))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Specialty
                  RichText(
                    text: TextSpan(
                      text: isRu ? 'Специальность ' : 'Mutaxassislik ',
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600, fontSize: 14),
                      children: const [TextSpan(text: '*', style: TextStyle(color: Colors.red))],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: specController,
                    decoration: InputDecoration(
                      hintText: isRu ? 'Входить' : 'Kiritish',
                      filled: true,
                      fillColor: theme.cardTheme.color,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.3))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Level Dropdown
                  RichText(
                    text: TextSpan(
                      text: isRu ? 'Уровень образования ' : 'Ta\'lim darajasi ',
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600, fontSize: 14),
                      children: const [TextSpan(text: '*', style: TextStyle(color: Colors.red))],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedLevel,
                        isExpanded: true,
                        hint: Text(isRu ? 'Выбирать' : 'Tanlash', style: TextStyle(color: theme.hintColor)),
                        items: levels.map((lvl) => DropdownMenuItem(value: lvl, child: Text(lvl))).toList(),
                        onChanged: (val) => setModalState(() => selectedLevel = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Dates Row
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                text: isRu ? 'Дата начала ' : 'Boshlanish sanasi ',
                                style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600, fontSize: 14),
                                children: const [TextSpan(text: '*', style: TextStyle(color: Colors.red))],
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => pickDate(true),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  color: theme.cardTheme.color,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today_rounded, size: 18, color: theme.hintColor),
                                    const SizedBox(width: 8),
                                    Text(startDate ?? (isRu ? 'Выбрать' : 'Tanlash'), style: TextStyle(color: startDate != null ? theme.textTheme.bodyLarge?.color : theme.hintColor)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                text: isRu ? 'Дата окончания ' : 'Tugash sanasi ',
                                style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600, fontSize: 14),
                                children: const [TextSpan(text: '*', style: TextStyle(color: Colors.red))],
                              ),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () => pickDate(false),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                                decoration: BoxDecoration(
                                  color: theme.cardTheme.color,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.calendar_today_rounded, size: 18, color: theme.hintColor),
                                    const SizedBox(width: 8),
                                    Text(endDate ?? (isRu ? 'Выбрать' : 'Tanlash'), style: TextStyle(color: endDate != null ? theme.textTheme.bodyLarge?.color : theme.hintColor)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Description
                  Text(
                    isRu ? 'Описание' : 'Tavsif',
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: isRu ? 'Напишите подробно об образовании' : 'Ta\'lim haqida batafsil yozing',
                      filled: true,
                      fillColor: theme.cardTheme.color,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.3))),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4ADE80),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () {
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
                        setState(() {
                          if (index != null && index < _educationList.length) {
                            _educationList[index] = eduData;
                          } else {
                            _educationList.add(eduData);
                          }
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        isRu ? 'Сохранить' : 'Saqlash',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),

                  // Delete button when editing
                  if (index != null && index < _educationList.length) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                        label: Text(
                          isRu ? 'Удалить это образование' : 'Ushbu ta\'limni o\'chirish',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        onPressed: () {
                          setState(() {
                            _educationList.removeAt(index);
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(isRu ? 'Образование удалено' : 'Ta\'lim o\'chirildi'),
                              backgroundColor: Colors.grey.shade800,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
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

  // ==================== DISABILITY MODAL ====================
  void _showDisabilityModal() {
    final isRu = AppStrings.isRu;
    final theme = Theme.of(context);
    final commentController = TextEditingController(text: _disability?['comment'] ?? '');
    String? selectedType = _disability?['type'];

    final types = isRu
        ? ['Нет', 'I группа', 'II группа', 'III группа', 'С детства']
        : ['Mavjud emas', 'I guruh', 'II guruh', 'III guruh', 'Bolalikdan'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
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
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isRu ? 'Инвалидность' : 'Nogironlik',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleLarge?.color,
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.dividerColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, size: 20),
                        ),
                        onPressed: () => Navigator.pop(ctx),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Type Dropdown
                  RichText(
                    text: TextSpan(
                      text: isRu ? 'Тип инвалидности ' : 'Nogironlik turi ',
                      style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600, fontSize: 14),
                      children: const [TextSpan(text: '*', style: TextStyle(color: Colors.red))],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: theme.cardTheme.color,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedType,
                        isExpanded: true,
                        hint: Text(isRu ? 'Выбирать' : 'Tanlash', style: TextStyle(color: theme.hintColor)),
                        items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                        onChanged: (val) => setModalState(() => selectedType = val),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Comment
                  Text(
                    isRu ? 'Комментарий' : 'Izoh',
                    style: TextStyle(color: theme.textTheme.bodyLarge?.color, fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: isRu ? 'Входить' : 'Kiritish',
                      filled: true,
                      fillColor: theme.cardTheme.color,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.3))),
                      contentPadding: const EdgeInsets.all(14),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4ADE80),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        setState(() {
                          if (selectedType == null || selectedType == (isRu ? 'Нет' : 'Mavjud emas')) {
                            _disability = null;
                          } else {
                            _disability = {
                              'type': selectedType,
                              'comment': commentController.text.trim(),
                            };
                          }
                        });
                        Navigator.pop(ctx);
                      },
                      child: Text(
                        isRu ? 'Сохранить' : 'Saqlash',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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

                    // Languages Tile
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.translate_rounded, color: AppColors.primary, size: 22),
                        ),
                        title: Text(
                          AppStrings.isRu ? 'Знание языка' : 'Til bilish darajasi',
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _selectedLanguages.isEmpty
                              ? (AppStrings.isRu ? 'Нажмите, чтобы указать' : 'Ko\'rsatish uchun bosing')
                              : _selectedLanguages
                                  .map((e) => '${e['language']} (${e['level']})')
                                  .join(', '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _selectedLanguages.isEmpty ? theme.hintColor : theme.textTheme.bodyMedium?.color,
                            fontSize: 13,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: _showLanguagesModal,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Basic Skills Tile
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.psychology_rounded, color: AppColors.secondary, size: 22),
                        ),
                        title: Text(
                          AppStrings.isRu ? 'Базовые навыки' : 'Asosiy ko\'nikmalar',
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _selectedBasicSkills.isEmpty
                              ? (AppStrings.isRu ? 'Нажмите, чтобы выбрать' : 'Tanlash uchun bosing')
                              : (AppStrings.isRu
                                  ? 'Выбрано: ${_selectedBasicSkills.length} из 10'
                                  : 'Tanlangan: ${_selectedBasicSkills.length} / 10'),
                          style: TextStyle(
                            color: _selectedBasicSkills.isEmpty ? theme.hintColor : AppColors.secondary,
                            fontSize: 13,
                            fontWeight: _selectedBasicSkills.isEmpty ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: _showBasicSkillsModal,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Driver License Tile
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.directions_car_rounded, color: Colors.blue, size: 22),
                        ),
                        title: Text(
                          AppStrings.isRu ? 'Водительские права' : 'Haydovchilik guvohnomasi',
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _driverLicense == null
                              ? (AppStrings.isRu ? 'Нажмите, чтобы указать' : 'Ko\'rsatish uchun bosing')
                              : () {
                                  final cats = List<String>.from(_driverLicense!['categories'] ?? []);
                                  final hasCar = _driverLicense!['has_car'] == true;
                                  final parts = <String>[];
                                  if (cats.isNotEmpty) parts.add(cats.join(', '));
                                  if (hasCar) parts.add(AppStrings.isRu ? 'Личный автомобиль' : 'Shaxsiy avtomobil');
                                  return parts.join(' • ');
                                }(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _driverLicense == null ? theme.hintColor : Colors.blue,
                            fontSize: 13,
                            fontWeight: _driverLicense == null ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: _showDriverLicenseModal,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Work Experience Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.business_center_rounded, color: Colors.blue, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      AppStrings.isRu ? 'Опыт работы' : 'Ish tajribasi',
                                      style: TextStyle(
                                        color: theme.textTheme.bodyLarge?.color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (_workExperienceList.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${_workExperienceList.length}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blue),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _showWorkExperienceModal(),
                                icon: const Icon(Icons.add_rounded, size: 16, color: Colors.blue),
                                label: Text(
                                  AppStrings.isRu ? 'Добавить' : 'Qo\'shish',
                                  style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          if (_workExperienceList.isEmpty) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => _showWorkExperienceModal(),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                                ),
                                child: Center(
                                  child: Text(
                                    AppStrings.isRu ? '+ Нажмите, чтобы добавить опыт работы' : '+ Ish tajribasi qo\'shish uchun bosing',
                                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 12),
                            ..._workExperienceList.asMap().entries.map((entry) {
                              final i = entry.key;
                              final exp = entry.value;
                              final pos = (exp['position'] ?? '').toString();
                              final comp = (exp['company'] ?? '').toString();
                              final start = (exp['start_date'] ?? '').toString();
                              final end = (exp['end_date'] ?? '').toString();
                              final isCur = exp['is_current'] == true;
                              final desc = (exp['description'] ?? exp['comment'] ?? '').toString();

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pos,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                          if (comp.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              comp,
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary),
                                            ),
                                          ],
                                          if (start.isNotEmpty || end.isNotEmpty || isCur) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              '$start — ${isCur ? (AppStrings.isRu ? "по наст. время" : "hozirgacha") : (end.isNotEmpty ? end : (AppStrings.isRu ? "по наст. время" : "hozirgacha"))}',
                                              style: TextStyle(fontSize: 11, color: theme.hintColor),
                                            ),
                                          ],
                                          if (desc.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              desc,
                                              style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.blue),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _showWorkExperienceModal(exp, i),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            setState(() {
                                              _workExperienceList.removeAt(i);
                                            });
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(AppStrings.isRu ? 'Опыт работы удален' : 'Ish tajribasi o\'chirildi'),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Education Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.school_rounded, color: Colors.teal, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Row(
                                  children: [
                                    Text(
                                      AppStrings.isRu ? 'Образование' : 'Ta\'lim',
                                      style: TextStyle(
                                        color: theme.textTheme.bodyLarge?.color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    if (_educationList.isNotEmpty) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.teal.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '${_educationList.length}',
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.teal),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              TextButton.icon(
                                onPressed: () => _showEducationModal(),
                                icon: const Icon(Icons.add_rounded, size: 16, color: Colors.teal),
                                label: Text(
                                  AppStrings.isRu ? 'Добавить' : 'Qo\'shish',
                                  style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                          if (_educationList.isEmpty) ...[
                            const SizedBox(height: 8),
                            InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: () => _showEducationModal(),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
                                ),
                                child: Center(
                                  child: Text(
                                    AppStrings.isRu ? '+ Нажмите, чтобы добавить образование' : '+ Ta\'lim qo\'shish uchun bosing',
                                    style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 12),
                            ..._educationList.asMap().entries.map((entry) {
                              final i = entry.key;
                              final edu = entry.value;
                              final inst = (edu['institution'] ?? '').toString();
                              final spec = (edu['specialty'] ?? '').toString();
                              final lvl = (edu['level'] ?? '').toString();
                              final start = (edu['start_date'] ?? '').toString();
                              final end = (edu['end_date'] ?? '').toString();

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.teal.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  inst,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                                ),
                                              ),
                                              if (lvl.isNotEmpty)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.teal.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    lvl,
                                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          if (spec.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              spec,
                                              style: TextStyle(fontSize: 12, color: theme.textTheme.bodyMedium?.color),
                                            ),
                                          ],
                                          if (start.isNotEmpty || end.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              '$start — ${end.isNotEmpty ? end : (AppStrings.isRu ? "по наст. время" : "hozirgacha")}',
                                              style: TextStyle(fontSize: 11, color: theme.hintColor),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Action buttons: Edit & Delete
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 18, color: Colors.teal),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => _showEducationModal(edu, i),
                                        ),
                                        const SizedBox(width: 8),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                                          visualDensity: VisualDensity.compact,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () {
                                            setState(() {
                                              _educationList.removeAt(i);
                                            });
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text(AppStrings.isRu ? 'Образование удалено' : 'Ta\'lim o\'chirildi'),
                                                backgroundColor: Colors.grey.shade800,
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Disability Tile
                    Container(
                      decoration: BoxDecoration(
                        color: theme.cardTheme.color,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: theme.dividerColor.withOpacity(0.4)),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.accessibility_new_rounded, color: Colors.orange, size: 22),
                        ),
                        title: Text(
                          AppStrings.isRu ? 'Инвалидность' : 'Nogironlik',
                          style: TextStyle(
                            color: theme.textTheme.bodyLarge?.color,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          _disability == null
                              ? (AppStrings.isRu ? 'Нажмите, чтобы указать' : 'Ko\'rsatish uchun bosing')
                              : '${_disability!['type']}${(_disability!['comment'] != null && _disability!['comment']!.isNotEmpty) ? ' • ${_disability!['comment']}' : ''}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _disability == null ? theme.hintColor : Colors.orange,
                            fontSize: 13,
                            fontWeight: _disability == null ? FontWeight.normal : FontWeight.w600,
                          ),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                        onTap: _showDisabilityModal,
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
