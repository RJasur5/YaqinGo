import '../config/localization.dart';

class RegionsConfig {
  // Internal keys (used for storage and API)
  static const List<String> regionKeys = [
    'toshkent_shahar',
    'toshkent_viloyati',
    'namangan_viloyati',
    'andijon_viloyati',
    'fargona_viloyati',
    'buxoro_viloyati',
    'jizzax_viloyati',
    'xorazm_viloyati',
    'navoiy_viloyati',
    'qashqadaryo_viloyati',
    'samarqand_viloyati',
    'sirdaryo_viloyati',
    'surxondaryo_viloyati',
    'qoraqalpogiston',
  ];

  static const Map<String, String> _regionNamesRu = {
    'toshkent_shahar': 'Ташкент',
    'toshkent_viloyati': 'Ташкентская область',
    'namangan_viloyati': 'Наманганская область',
    'andijon_viloyati': 'Андижанская область',
    'fargona_viloyati': 'Ферганская область',
    'buxoro_viloyati': 'Бухарская область',
    'jizzax_viloyati': 'Джизакская область',
    'xorazm_viloyati': 'Хорезмская область',
    'navoiy_viloyati': 'Навоийская область',
    'qashqadaryo_viloyati': 'Кашкадарьинская область',
    'samarqand_viloyati': 'Самаркандская область',
    'sirdaryo_viloyati': 'Сырдарьинская область',
    'surxondaryo_viloyati': 'Сурхандарьинская область',
    'qoraqalpogiston': 'Каракалпакстан',
  };

  static const Map<String, String> _regionNamesUz = {
    'toshkent_shahar': 'Toshkent shahar',
    'toshkent_viloyati': 'Toshkent viloyati',
    'namangan_viloyati': 'Namangan viloyati',
    'andijon_viloyati': 'Andijon viloyati',
    'fargona_viloyati': 'Farg\'ona viloyati',
    'buxoro_viloyati': 'Buxoro viloyati',
    'jizzax_viloyati': 'Jizzax viloyati',
    'xorazm_viloyati': 'Xorazm viloyati',
    'navoiy_viloyati': 'Navoiy viloyati',
    'qashqadaryo_viloyati': 'Qashqadaryo viloyati',
    'samarqand_viloyati': 'Samarqand viloyati',
    'sirdaryo_viloyati': 'Sirdaryo viloyati',
    'surxondaryo_viloyati': 'Surxondaryo viloyati',
    'qoraqalpogiston': 'Qoraqalpog\'iston',
  };

  /// Returns display-friendly region names in current language
  static List<String> get regions {
    if (AppStrings.isRu) {
      return regionKeys.map((k) => _regionNamesRu[k] ?? k).toList();
    }
    return regionKeys.map((k) => _regionNamesUz[k] ?? k).toList();
  }

  /// Get the display name for a region key
  static String getDisplayName(String keyOrName) {
    // If it's already a key
    if (_regionNamesRu.containsKey(keyOrName)) {
      return AppStrings.isRu ? _regionNamesRu[keyOrName]! : _regionNamesUz[keyOrName]!;
    }
    // If it's a display name (Uz), find the key
    for (final entry in _regionNamesUz.entries) {
      if (entry.value == keyOrName) {
        return AppStrings.isRu ? _regionNamesRu[entry.key]! : entry.value;
      }
    }
    // If it's a display name (Ru), find the key
    for (final entry in _regionNamesRu.entries) {
      if (entry.value == keyOrName) {
        return AppStrings.isRu ? entry.value : _regionNamesUz[entry.key]!;
      }
    }
    return keyOrName; // Fallback
  }

  /// Get the storage key for a display name
  static String getKey(String displayName) {
    for (final entry in _regionNamesRu.entries) {
      if (entry.value == displayName) return entry.key;
    }
    for (final entry in _regionNamesUz.entries) {
      if (entry.value == displayName) return entry.key;
    }
    if (regionKeys.contains(displayName)) return displayName;
    return displayName;
  }

  // ==================== DISTRICTS ====================
  
  static const Map<String, Map<String, String>> _districtNamesRu = {
    'toshkent_shahar': {
      'barcha': 'Все районы',
      'yunusobod': 'Юнусабадский',
      'mirzo_ulugbek': 'Мирзо-Улугбекский',
      'yashnobod': 'Яшнабадский',
      'mirobod': 'Мирабадский',
      'yakkasaroy': 'Яккасарайский',
      'chilonzor': 'Чиланзарский',
      'uchtepa': 'Учтепинский',
      'shayxontohur': 'Шайхантахурский',
      'olmazor': 'Алмазарский',
      'sergeli': 'Сергелийский',
      'yangihayot': 'Янгихаётский',
      'bektemir': 'Бектемирский',
    },
  };

  static const Map<String, Map<String, String>> _districtNamesUz = {
    'toshkent_shahar': {
      'barcha': 'Barcha tumanlar',
      'yunusobod': 'Yunusobod',
      'mirzo_ulugbek': 'Mirzo Ulug\'bek',
      'yashnobod': 'Yashnobod',
      'mirobod': 'Mirobod',
      'yakkasaroy': 'Yakkasaroy',
      'chilonzor': 'Chilonzor',
      'uchtepa': 'Uchtepa',
      'shayxontohur': 'Shayxontohur',
      'olmazor': 'Olmazor',
      'sergeli': 'Sergeli',
      'yangihayot': 'Yangihayot',
      'bektemir': 'Bektemir',
    },
  };

  // Uz→Ru translation map for ALL district names
  static const Map<String, String> _districtUzToRu = {
    'Barcha tumanlar': 'Все районы',
    'Bekobod': 'Бекабад', 'Bo\'ka': 'Бука', 'Bo\'stonliq': 'Бостанлык',
    'Chinoz': 'Чиноз', 'Qibray': 'Кибрай', 'Ohangaron': 'Ахангаран',
    'Oqqo\'rg\'on': 'Аккурган', 'Parkent': 'Паркент', 'Piskent': 'Пскент',
    'Quyi Chirchiq': 'Нижнечирчикский', 'O\'rta Chirchiq': 'Среднечирчикский',
    'Yuqori Chirchiq': 'Верхнечирчикский', 'Zangiota': 'Зангиата',
    'Chirchiq': 'Чирчик', 'Angren': 'Ангрен', 'Yangiyo\'l': 'Янгиюль',
    'Buxoro': 'Бухара', 'G\'ijduvon': 'Гиждуван', 'Jondor': 'Жондор',
    'Kogon': 'Каган', 'Olot': 'Алат', 'Peshku': 'Пешку',
    'Qorako\'l': 'Каракуль', 'Qorovulbozor': 'Каравулбазар',
    'Romitan': 'Ромитан', 'Shofirkon': 'Шафиркан', 'Vobkent': 'Вабкент',
    'Arnasoy': 'Арнасай', 'Baxmal': 'Бахмал', 'Do\'stlik': 'Дустлик',
    'Forish': 'Фориш', 'G\'allaorol': 'Галляарал',
    'Sharof Rashidov': 'Шароф Рашидов', 'Mirzacho\'l': 'Мирзачуль',
    'Paxtakor': 'Пахтакор', 'Yangiobod': 'Янгиобод',
    'Zomin': 'Зомин', 'Zafarobod': 'Зафарабад', 'Zarbdor': 'Зарбдор',
    'Pop': 'Поп', 'To\'raqo\'rg\'on': 'Туракурган',
    'Namangan tumani': 'Наманганский район', 'Mingbuloq': 'Мингбулак',
    'Namangan shahar': 'г. Наманган', 'Kosonsoy': 'Касансай',
    'Uchqo\'rg\'on': 'Учкурган', 'Uychi': 'Уйчи',
    'Yangiqo\'rg\'on': 'Янгикурган', 'Chortoq': 'Чартак',
    'Chust': 'Чуст', 'Norin': 'Нарын',
    'Andijon': 'Андижан', 'Asaka': 'Асака', 'Baliqchi': 'Балыкчи',
    'Bo\'ston': 'Бустон', 'Buloqboshi': 'Булакбаши',
    'Jalolquduq': 'Джалалкудук', 'Marhamat': 'Мархамат',
    'Qo\'rg\'ontepa': 'Кургантепа', 'Shahrixon': 'Шахрихан',
    'Xo\'jaobod': 'Ходжаабад', 'Izboskan': 'Избаскан',
    'Oltinko\'l': 'Алтынкуль', 'Paxtaobod': 'Пахтаабад',
    'Oltiariq': 'Алтыарык', 'Bag\'dod': 'Багдад', 'Beshariq': 'Бешарык',
    'Dang\'ara': 'Дангара', 'Farg\'ona': 'Фергана',
    'Qo\'shtepa': 'Куштепа', 'Quva': 'Кува', 'Rishton': 'Риштан',
    'So\'x': 'Сох', 'Toshloq': 'Ташлак', 'Yozyovon': 'Язъяван',
    'Furqat': 'Фуркат', 'O\'zbekiston': 'Узбекистан', 'Buvayda': 'Бувайда',
    'Uchko\'prik': 'Учкуприк', 'Qo\'qon': 'Коканд', 'Marg\'ilon': 'Маргилан',
    'Gurlan': 'Гурлен', 'Xonqa': 'Ханка', 'Tuproqqal\'a': 'Тупроккала',
    'Xiva': 'Хива', 'Qo\'shko\'pir': 'Кошкупыр', 'Urganch': 'Ургенч',
    'Yangiariq': 'Янгиарык', 'Yangibozor': 'Янгибазар',
    'Hazorasp': 'Хазарасп', 'Bog\'ot': 'Богот', 'Shovot': 'Шават',
    'Navoiy': 'Навои', 'Zarafshon': 'Зарафшан', 'G\'ozg\'on': 'Газган',
    'Karmana': 'Кармана', 'Konimex': 'Конимех', 'Navbahor': 'Навбахор',
    'Nurota': 'Нурата', 'Qiziltepa': 'Кызылтепа', 'Tomdi': 'Тамды',
    'Uchquduq': 'Учкудук', 'Xatirchi': 'Хатырчи',
    'Chiroqchi': 'Чиракчи', 'Dehqonobod': 'Дехканабад', 'G\'uzor': 'Гузар',
    'Qamashi': 'Камаши', 'Qarshi': 'Карши', 'Koson': 'Касан',
    'Kasbi': 'Касби', 'Kitob': 'Китаб', 'Mirishkor': 'Миришкор',
    'Nishon': 'Нишан', 'Shahrisabz': 'Шахрисабз', 'Yakkabog\'': 'Яккабаг',
    'Ko\'kdala': 'Кукдала', 'Muborak': 'Мубарек',
    'Bulung\'ur': 'Булунгур', 'Ishtixon': 'Иштихан',
    'Kattaqo\'rg\'on': 'Каттакурган', 'Narpay': 'Нарпай', 'Nurobod': 'Нурабад',
    'Oqdaryo': 'Акдарья', 'Paxtachi': 'Пахтачи', 'Payariq': 'Пайарык',
    'Pastdarg\'om': 'Пастдаргом', 'Qo\'shrabot': 'Кушрабат',
    'Samarqand': 'Самарканд', 'Toyloq': 'Тайлак', 'Urgut': 'Ургут', 'Jomboy': 'Джамбай',
    'Boyovut': 'Баяут', 'Mirzaobod': 'Мирзаабад', 'Oqoltin': 'Акалтын',
    'Sardoba': 'Сардоба', 'Sayxunobod': 'Сайхунабад',
    'Sirdaryo': 'Сырдарья', 'Xovos': 'Хавос', 'Guliston': 'Гулистан',
    'Termiz': 'Термез', 'Angor': 'Ангор', 'Bandixon': 'Бандихан',
    'Boysun': 'Байсун', 'Denov': 'Денау', 'Jarqo\'rg\'on': 'Джаркурган',
    'Muzrabot': 'Музрабад', 'Oltinsoy': 'Алтынсай', 'Qiziriq': 'Кизирик',
    'Qumqo\'rg\'on': 'Кумкурган', 'Sariosiyo': 'Сариосиё',
    'Sherobod': 'Шерабад', 'Sho\'rchi': 'Шурчи', 'Uzun': 'Узун',
    'Amudaryo': 'Амударья', 'Beruniy': 'Беруни', 'Chimboy': 'Чимбай',
    'Kegeyli': 'Кегейли', 'Mo\'ynoq': 'Муйнак', 'Nukus': 'Нукус',
    'Qanliko\'l': 'Канлыкуль', 'Qo\'ng\'irot': 'Кунград',
    'Qorao\'zak': 'Караузяк', 'Shumanay': 'Шуманай',
    'Taxtako\'pir': 'Тахтакупыр', 'To\'rtko\'l': 'Турткуль',
    'Taxiatosh': 'Тахиаташ', 'Bo\'zatov': 'Бозатау',
    'Xo\'jayli': 'Ходжейли', 'Ellikqal\'a': 'Элликкала',
  };

  // Reverse map: Ru→Uz
  static Map<String, String>? _districtRuToUz;
  static Map<String, String> get _ruToUz {
    _districtRuToUz ??= {for (final e in _districtUzToRu.entries) e.value: e.key};
    return _districtRuToUz!;
  }

  // Districts with Uzbek names as canonical keys
  static const Map<String, List<String>> _districtListsUz = {
    'toshkent_viloyati': [
      'Barcha tumanlar',
      'Bekobod', 'Bo\'ka', 'Bo\'stonliq', 'Chinoz', 'Qibray',
      'Ohangaron', 'Oqqo\'rg\'on', 'Parkent', 'Piskent',
      'Quyi Chirchiq', 'O\'rta Chirchiq', 'Yuqori Chirchiq',
      'Zangiota', 'Chirchiq', 'Angren', 'Yangiyo\'l'
    ],
    'buxoro_viloyati': [
      'Barcha tumanlar',
      'Buxoro', 'G\'ijduvon', 'Jondor', 'Kogon', 'Olot',
      'Peshku', 'Qorako\'l', 'Qorovulbozor', 'Romitan',
      'Shofirkon', 'Vobkent'
    ],
    'jizzax_viloyati': [
      'Barcha tumanlar',
      'Arnasoy', 'Baxmal', 'Do\'stlik', 'Forish', 'G\'allaorol',
      'Sharof Rashidov', 'Mirzacho\'l', 'Paxtakor', 'Yangiobod',
      'Zomin', 'Zafarobod', 'Zarbdor'
    ],
    'namangan_viloyati': [
      'Barcha tumanlar',
      'Pop', 'To\'raqo\'rg\'on', 'Namangan tumani', 'Mingbuloq', 
      'Namangan shahar', 'Kosonsoy', 'Uchqo\'rg\'on', 'Uychi', 
      'Yangiqo\'rg\'on', 'Chortoq', 'Chust', 'Norin'
    ],
    'andijon_viloyati': [
      'Barcha tumanlar',
      'Andijon', 'Asaka', 'Baliqchi', 'Bo\'ston', 'Buloqboshi',
      'Jalolquduq', 'Marhamat', 'Qo\'rg\'ontepa', 'Shahrixon',
      'Xo\'jaobod', 'Izboskan', 'Oltinko\'l', 'Paxtaobod'
    ],
    'fargona_viloyati': [
      'Barcha tumanlar',
      'Oltiariq', 'Bag\'dod', 'Beshariq', 'Dang\'ara', 'Farg\'ona',
      'Qo\'shtepa', 'Quva', 'Rishton', 'So\'x', 'Toshloq', 'Yozyovon',
      'Furqat', 'O\'zbekiston', 'Buvayda', 'Uchko\'prik', 'Qo\'qon',
      'Marg\'ilon'
    ],
    'xorazm_viloyati': [
      'Barcha tumanlar',
      'Gurlan', 'Xonqa', 'Tuproqqal\'a', 'Xiva', 'Qo\'shko\'pir', 
      'Urganch', 'Yangiariq', 'Yangibozor', 'Hazorasp', 'Bog\'ot', 'Shovot'
    ],
    'navoiy_viloyati': [
      'Barcha tumanlar',
      'Navoiy', 'Zarafshon', 'G\'ozg\'on', 'Karmana', 'Konimex',
      'Navbahor', 'Nurota', 'Qiziltepa', 'Tomdi', 'Uchquduq',
      'Xatirchi'
    ],
    'qashqadaryo_viloyati': [
      'Barcha tumanlar',
      'Chiroqchi', 'Dehqonobod', 'G\'uzor', 'Qamashi', 'Qarshi', 'Koson', 
      'Kasbi', 'Kitob', 'Mirishkor', 'Nishon', 'Shahrisabz', 'Yakkabog\'', 
      'Ko\'kdala', 'Muborak'
    ],
    'samarqand_viloyati': [
      'Barcha tumanlar',
      'Bulung\'ur', 'Ishtixon', 'Kattaqo\'rg\'on', 'Narpay', 'Nurobod', 
      'Oqdaryo', 'Paxtachi', 'Payariq', 'Pastdarg\'om', 'Qo\'shrabot', 
      'Samarqand', 'Toyloq', 'Urgut', 'Jomboy'
    ],
    'sirdaryo_viloyati': [
      'Barcha tumanlar',
      'Boyovut', 'Mirzaobod', 'Oqoltin', 'Sardoba', 'Sayxunobod', 
      'Sirdaryo', 'Xovos', 'Guliston'
    ],
    'surxondaryo_viloyati': [
      'Barcha tumanlar',
      'Termiz', 'Angor', 'Bandixon', 'Boysun', 'Denov', 'Jarqo\'rg\'on',
      'Muzrabot', 'Oltinsoy', 'Qiziriq', 'Qumqo\'rg\'on', 'Sariosiyo',
      'Sherobod', 'Sho\'rchi', 'Uzun'
    ],
    'qoraqalpogiston': [
      'Barcha tumanlar',
      'Amudaryo', 'Beruniy', 'Chimboy', 'Kegeyli', 'Mo\'ynoq', 'Nukus',
      'Qanliko\'l', 'Qo\'ng\'irot', 'Qorao\'zak', 'Shumanay', 'Taxtako\'pir',
      'To\'rtko\'l', 'Taxiatosh', 'Bo\'zatov', 'Xo\'jayli', 'Ellikqal\'a'
    ],
  };

  /// Get districts for a region (accepts display name or key)
  static List<String> getDistricts(String? regionDisplayNameOrKey) {
    if (regionDisplayNameOrKey == null) return [];
    String key = getKey(regionDisplayNameOrKey);

    // Tashkent city has full Ru/Uz translations
    if (key == 'toshkent_shahar') {
      if (AppStrings.isRu) {
        return _districtNamesRu['toshkent_shahar']!.values.toList();
      }
      return _districtNamesUz['toshkent_shahar']!.values.toList();
    }

    // All other regions: Uz names are the source, translate to Ru if needed
    final list = _districtListsUz[key];
    if (list == null) return [];
    if (!AppStrings.isRu) return list;
    return list.map((d) => _districtUzToRu[d] ?? d).toList();
  }

  /// Convert a district display name to a stable key for storage
  static String getDistrictKey(String district, String? regionDisplayNameOrKey) {
    if (regionDisplayNameOrKey == null) return district;
    String regionKey = getKey(regionDisplayNameOrKey);

    // For Tashkent, look up the key from Ru or Uz maps
    if (regionKey == 'toshkent_shahar') {
      final ruMap = _districtNamesRu['toshkent_shahar']!;
      final uzMap = _districtNamesUz['toshkent_shahar']!;
      for (final e in ruMap.entries) {
        if (e.value == district) return e.key;
      }
      for (final e in uzMap.entries) {
        if (e.value == district) return e.key;
      }
    }
    // If it's a Russian name, convert to Uz key
    if (_ruToUz.containsKey(district)) return _ruToUz[district]!;
    return district; // Already Uz = already the key
  }

  /// Convert a stored district key to display name
  static String getDistrictDisplay(String districtKey, String? regionDisplayNameOrKey) {
    if (regionDisplayNameOrKey == null) return districtKey;
    String regionKey = getKey(regionDisplayNameOrKey);

    if (regionKey == 'toshkent_shahar') {
      if (AppStrings.isRu) {
        return _districtNamesRu['toshkent_shahar']?[districtKey] ?? districtKey;
      }
      return _districtNamesUz['toshkent_shahar']?[districtKey] ?? districtKey;
    }
    // For other regions: key is the Uz name
    if (AppStrings.isRu) return _districtUzToRu[districtKey] ?? districtKey;
    return districtKey;
  }
}
