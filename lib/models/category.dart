class CategoryModel {
  final int id;
  final String nameRu;
  final String nameUz;
  final String icon;
  final String color;
  final List<SubcategoryModel> subcategories;

  CategoryModel({
    required this.id,
    required this.nameRu,
    required this.nameUz,
    required this.icon,
    required this.color,
    this.subcategories = const [],
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'],
      nameRu: json['name_ru'] ?? '',
      nameUz: json['name_uz'] ?? '',
      icon: json['icon'] ?? 'category',
      color: json['color'] ?? '#FF6B35',
      subcategories: (json['subcategories'] as List? ?? [])
          .map((s) => SubcategoryModel.fromJson(s))
          .toList(),
    );
  }

  String name(String lang) => lang == 'ru' ? nameRu : nameUz;
}

class SubcategoryModel {
  final int id;
  final String nameRu;
  final String nameUz;

  SubcategoryModel({
    required this.id,
    required this.nameRu,
    required this.nameUz,
  });

  factory SubcategoryModel.fromJson(Map<String, dynamic> json) {
    return SubcategoryModel(
      id: json['id'],
      nameRu: json['name_ru'] ?? '',
      nameUz: json['name_uz'] ?? '',
    );
  }

  String name(String lang) => lang == 'ru' ? nameRu : nameUz;
}
