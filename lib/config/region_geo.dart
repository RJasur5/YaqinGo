import 'package:latlong2/latlong.dart';
import 'regions.dart';

/// Approximate area (center + radius) used to highlight a city / region / district
/// on the map when an order has no exact point (user didn't open the map picker).
class GeoArea {
  final LatLng center;
  final double radiusMeters;
  final bool isDistrict;
  final String key; // stable id used to de-duplicate highlighted areas

  const GeoArea(this.center, this.radiusMeters, {required this.isDistrict, required this.key});
}

class RegionGeo {
  // ─── Regions ("Все районы") : [lat, lon, radiusKm] ───
  static const Map<String, List<double>> _regions = {
    'toshkent_shahar': [41.2995, 69.2401, 12],
    'toshkent_viloyati': [41.1000, 69.7000, 55],
    'namangan_viloyati': [41.0500, 71.4500, 45],
    'andijon_viloyati': [40.7800, 72.3500, 35],
    'fargona_viloyati': [40.4500, 71.4000, 55],
    'buxoro_viloyati': [40.2000, 64.0000, 100],
    'jizzax_viloyati': [40.2500, 67.9000, 70],
    'xorazm_viloyati': [41.4500, 60.6500, 45],
    'navoiy_viloyati': [40.8000, 65.0000, 110],
    'qashqadaryo_viloyati': [38.8500, 66.0000, 80],
    'samarqand_viloyati': [39.8000, 66.6000, 70],
    'sirdaryo_viloyati': [40.4500, 68.7000, 40],
    'surxondaryo_viloyati': [37.9500, 67.6000, 70],
    'qoraqalpogiston': [43.0000, 59.5000, 200],
  };

  // ─── Tashkent city districts (keys from RegionsConfig) ───
  static const Map<String, List<double>> _tashkentDistricts = {
    'yunusobod': [41.3640, 69.2870, 3.5],
    'mirzo_ulugbek': [41.3300, 69.3400, 4],
    'yashnobod': [41.2950, 69.3400, 4],
    'mirobod': [41.2850, 69.2700, 3],
    'yakkasaroy': [41.2850, 69.2400, 2.5],
    'chilonzor': [41.2750, 69.2000, 3.5],
    'uchtepa': [41.2950, 69.1650, 3.5],
    'shayxontohur': [41.3270, 69.2300, 3],
    'olmazor': [41.3550, 69.2150, 3.5],
    'sergeli': [41.2250, 69.2250, 4],
    'yangihayot': [41.2050, 69.2000, 4],
    'bektemir': [41.2100, 69.3350, 3.5],
  };

  // ─── Regional districts (canonical Uzbek names) : [lat, lon, radiusKm] ───
  static const Map<String, List<double>> _districts = {
    // Toshkent viloyati
    'Bekobod': [40.2200, 69.2700, 8], 'Bo\'ka': [40.8100, 69.1950, 10],
    'Bo\'stonliq': [41.5600, 69.7700, 12], 'Chinoz': [40.9400, 68.7600, 10],
    'Qibray': [41.3900, 69.4650, 8], 'Ohangaron': [40.9100, 69.6400, 8],
    'Oqqo\'rg\'on': [40.8700, 69.0400, 10], 'Parkent': [41.2950, 69.6750, 10],
    'Piskent': [40.9000, 69.3500, 10], 'Quyi Chirchiq': [40.9900, 69.1000, 10],
    'O\'rta Chirchiq': [41.1500, 69.3500, 10], 'Yuqori Chirchiq': [41.2300, 69.4700, 10],
    'Zangiota': [41.2000, 69.1500, 9], 'Chirchiq': [41.4689, 69.5822, 6],
    'Angren': [41.0167, 70.1436, 6], 'Yangiyo\'l': [41.1120, 69.0470, 6],
    // Buxoro
    'Buxoro': [39.7747, 64.4286, 6], 'G\'ijduvon': [40.1000, 64.6800, 12],
    'Jondor': [39.7300, 64.1800, 12], 'Kogon': [39.7220, 64.5510, 6],
    'Olot': [39.4200, 63.8000, 15], 'Peshku': [40.0800, 64.0800, 15],
    'Qorako\'l': [39.5000, 63.8500, 15], 'Qorovulbozor': [39.5000, 64.8000, 15],
    'Romitan': [39.9300, 64.3800, 10], 'Shofirkon': [40.1200, 64.5000, 10],
    'Vobkent': [40.0300, 64.5200, 10],
    // Jizzax
    'Arnasoy': [40.5500, 67.7500, 15], 'Baxmal': [39.7500, 67.6500, 15],
    'Do\'stlik': [40.5200, 68.0400, 10], 'Forish': [40.4500, 66.8000, 18],
    'G\'allaorol': [40.0200, 67.6000, 12], 'Sharof Rashidov': [40.1200, 67.8300, 12],
    'Mirzacho\'l': [40.6800, 68.1500, 12], 'Paxtakor': [40.3200, 67.9600, 10],
    'Yangiobod': [39.9000, 68.8000, 12], 'Zomin': [39.9600, 68.4000, 15],
    'Zafarobod': [40.3500, 68.2000, 10], 'Zarbdor': [40.0800, 68.1700, 10],
    // Namangan
    'Pop': [40.8730, 71.1090, 12], 'To\'raqo\'rg\'on': [41.0000, 71.5100, 8],
    'Namangan tumani': [40.9500, 71.5500, 8], 'Mingbuloq': [40.7500, 71.4500, 12],
    'Namangan shahar': [40.9983, 71.6726, 6], 'Kosonsoy': [41.2500, 71.5500, 10],
    'Uchqo\'rg\'on': [41.1100, 72.0800, 9], 'Uychi': [41.0800, 71.9200, 8],
    'Yangiqo\'rg\'on': [41.1900, 71.7300, 9], 'Chortoq': [41.0700, 71.8200, 8],
    'Chust': [41.0000, 71.2400, 10], 'Norin': [40.9100, 72.1200, 9],
    // Andijon
    'Andijon': [40.7821, 72.3442, 6], 'Asaka': [40.6400, 72.2400, 8],
    'Baliqchi': [40.9000, 71.9300, 8], 'Bo\'ston': [40.6900, 71.9100, 8],
    'Buloqboshi': [40.6200, 72.5000, 8], 'Jalolquduq': [40.7300, 72.6500, 8],
    'Marhamat': [40.5000, 72.3300, 9], 'Qo\'rg\'ontepa': [40.7300, 72.7600, 8],
    'Shahrixon': [40.7100, 72.0600, 8], 'Xo\'jaobod': [40.6700, 72.5600, 8],
    'Izboskan': [40.9200, 72.2400, 8], 'Oltinko\'l': [40.8000, 72.1800, 7],
    'Paxtaobod': [40.9300, 72.5000, 8],
    // Farg'ona
    'Oltiariq': [40.3900, 71.4800, 9], 'Bag\'dod': [40.4500, 71.2200, 8],
    'Beshariq': [40.4400, 70.6000, 10], 'Dang\'ara': [40.5800, 70.9100, 8],
    'Farg\'ona': [40.3864, 71.7864, 6], 'Qo\'shtepa': [40.5000, 71.6500, 8],
    'Quva': [40.5200, 72.0700, 9], 'Rishton': [40.3600, 71.2800, 8],
    'So\'x': [39.9600, 71.1300, 9], 'Toshloq': [40.4800, 71.7600, 7],
    'Yozyovon': [40.6500, 71.6900, 9], 'Furqat': [40.5400, 70.9400, 7],
    'O\'zbekiston': [40.3700, 70.8200, 9], 'Buvayda': [40.6000, 71.0700, 8],
    'Uchko\'prik': [40.5300, 71.0500, 7], 'Qo\'qon': [40.5286, 70.9425, 6],
    'Marg\'ilon': [40.4711, 71.7247, 5],
    // Xorazm
    'Gurlan': [41.8400, 60.3900, 10], 'Xonqa': [41.4700, 60.7800, 9],
    'Tuproqqal\'a': [41.1000, 61.2000, 15], 'Xiva': [41.3783, 60.3639, 6],
    'Qo\'shko\'pir': [41.5300, 60.3500, 10], 'Urganch': [41.5500, 60.6333, 6],
    'Yangiariq': [41.3500, 60.6000, 9], 'Yangibozor': [41.7300, 60.5500, 9],
    'Hazorasp': [41.3200, 61.0700, 10], 'Bog\'ot': [41.3500, 60.8300, 9],
    'Shovot': [41.6500, 60.3000, 9],
    // Navoiy
    'Navoiy': [40.0844, 65.3792, 6], 'Zarafshon': [41.5800, 64.2000, 6],
    'G\'ozg\'on': [40.5900, 65.4900, 6], 'Karmana': [40.1400, 65.3500, 10],
    'Konimex': [40.2800, 65.1500, 20], 'Navbahor': [40.2500, 65.6000, 12],
    'Nurota': [40.5600, 65.6900, 15], 'Qiziltepa': [40.0300, 64.8500, 12],
    'Tomdi': [41.7300, 64.6200, 30], 'Uchquduq': [42.1600, 63.5500, 20],
    'Xatirchi': [40.0300, 65.9600, 12],
    // Qashqadaryo
    'Chiroqchi': [39.0300, 66.5700, 12], 'Dehqonobod': [38.3500, 66.5000, 15],
    'G\'uzor': [38.6200, 66.2500, 12], 'Qamashi': [38.8100, 66.4600, 12],
    'Qarshi': [38.8606, 65.7891, 6], 'Koson': [39.0400, 65.5800, 10],
    'Kasbi': [38.9500, 65.4000, 10], 'Kitob': [39.1200, 66.8800, 9],
    'Mirishkor': [38.9000, 65.2000, 15], 'Nishon': [38.6500, 65.6700, 12],
    'Shahrisabz': [39.0578, 66.8342, 6], 'Yakkabog\'': [38.9800, 66.6800, 10],
    'Ko\'kdala': [38.7800, 65.9000, 10], 'Muborak': [39.2600, 65.1500, 12],
    // Samarqand
    'Bulung\'ur': [39.7600, 67.2700, 10], 'Ishtixon': [39.9700, 66.4900, 10],
    'Kattaqo\'rg\'on': [39.9000, 66.2600, 9], 'Narpay': [39.9300, 65.9700, 10],
    'Nurobod': [39.6100, 66.2900, 15], 'Oqdaryo': [39.8400, 66.8000, 9],
    'Paxtachi': [40.1700, 65.8000, 12], 'Payariq': [39.9900, 66.9200, 10],
    'Pastdarg\'om': [39.7200, 66.6600, 10], 'Qo\'shrabot': [40.2700, 66.6600, 15],
    'Samarqand': [39.6542, 66.9597, 6], 'Toyloq': [39.5800, 67.0500, 8],
    'Urgut': [39.4000, 67.2500, 10], 'Jomboy': [39.7000, 67.0900, 8],
    // Sirdaryo
    'Boyovut': [40.3900, 69.0000, 10], 'Mirzaobod': [40.5600, 68.9300, 10],
    'Oqoltin': [40.5500, 68.5500, 12], 'Sardoba': [40.4000, 68.3500, 12],
    'Sayxunobod': [40.6700, 68.8300, 9], 'Sirdaryo': [40.8400, 68.6600, 9],
    'Xovos': [40.2200, 68.8300, 10], 'Guliston': [40.4897, 68.7842, 6],
    // Surxondaryo
    'Termiz': [37.2242, 67.2783, 6], 'Angor': [37.4800, 67.0000, 10],
    'Bandixon': [37.8500, 67.3800, 10], 'Boysun': [38.2000, 67.2000, 15],
    'Denov': [38.2700, 67.9000, 9], 'Jarqo\'rg\'on': [37.5000, 67.4200, 10],
    'Muzrabot': [37.4000, 66.9000, 12], 'Oltinsoy': [38.1500, 68.0000, 10],
    'Qiziriq': [37.6500, 67.2500, 10], 'Qumqo\'rg\'on': [37.8300, 67.5800, 10],
    'Sariosiyo': [38.4200, 67.9600, 10], 'Sherobod': [37.6700, 67.0000, 12],
    'Sho\'rchi': [38.0000, 67.7900, 9], 'Uzun': [38.3700, 68.0000, 9],
    // Qoraqalpog'iston
    'Amudaryo': [42.1200, 60.0600, 15], 'Beruniy': [41.6900, 60.7500, 12],
    'Chimboy': [42.9300, 59.7700, 12], 'Kegeyli': [42.7800, 59.6100, 12],
    'Mo\'ynoq': [43.7700, 59.0200, 15], 'Nukus': [42.4600, 59.6100, 7],
    'Qanliko\'l': [42.8300, 59.0000, 12], 'Qo\'ng\'irot': [43.0700, 58.9000, 15],
    'Qorao\'zak': [43.0300, 60.0000, 12], 'Shumanay': [42.7100, 58.9200, 12],
    'Taxtako\'pir': [43.0200, 60.2900, 15], 'To\'rtko\'l': [41.5500, 61.0000, 12],
    'Taxiatosh': [42.3200, 59.6000, 6], 'Bo\'zatov': [43.0000, 59.4000, 15],
    'Xo\'jayli': [42.4000, 59.4500, 10], 'Ellikqal\'a': [41.8500, 60.9300, 15],
  };

  static bool _isAllDistricts(String? d) {
    if (d == null) return true;
    final v = d.trim().toLowerCase();
    return v.isEmpty || v == 'barcha' || v == 'barcha tumanlar' || v == 'все районы';
  }

  static const Map<String, String> _cityAliases = {
    'toshkent': 'toshkent_shahar', 'tashkent': 'toshkent_shahar', 'ташкент': 'toshkent_shahar',
    'г. ташкент': 'toshkent_shahar', 'namangan': 'namangan_viloyati', 'наманган': 'namangan_viloyati',
    'andijon': 'andijon_viloyati', 'андижан': 'andijon_viloyati',
    'farg\'ona': 'fargona_viloyati', 'фергана': 'fargona_viloyati',
    'buxoro': 'buxoro_viloyati', 'бухара': 'buxoro_viloyati',
    'samarqand': 'samarqand_viloyati', 'самарканд': 'samarqand_viloyati',
    'jizzax': 'jizzax_viloyati', 'джизак': 'jizzax_viloyati',
    'navoiy': 'navoiy_viloyati', 'навои': 'navoiy_viloyati',
    'qarshi': 'qashqadaryo_viloyati', 'карши': 'qashqadaryo_viloyati',
    'termiz': 'surxondaryo_viloyati', 'термез': 'surxondaryo_viloyati',
    'urganch': 'xorazm_viloyati', 'ургенч': 'xorazm_viloyati',
    'guliston': 'sirdaryo_viloyati', 'гулистан': 'sirdaryo_viloyati',
    'nukus': 'qoraqalpogiston', 'нукус': 'qoraqalpogiston',
  };

  /// Resolves the highlight area for an order by its city + district.
  /// Returns null if the city is unknown.
  static GeoArea? areaFor(String? city, String? district) {
    if (city == null || city.trim().isEmpty) return null;
    var regionKey = RegionsConfig.getKey(city.trim());
    if (!_regions.containsKey(regionKey)) {
      regionKey = _cityAliases[city.trim().toLowerCase()] ?? regionKey;
    }
    final region = _regions[regionKey];
    if (region == null) return null;

    if (!_isAllDistricts(district)) {
      final dKey = RegionsConfig.getDistrictKey(district!.trim(), regionKey);
      final d = regionKey == 'toshkent_shahar' ? _tashkentDistricts[dKey] : _districts[dKey];
      if (d != null) {
        return GeoArea(
          LatLng(d[0], d[1]),
          d[2] * 1000,
          isDistrict: true,
          key: '${regionKey}_$dKey',
        );
      }
    }

    return GeoArea(
      LatLng(region[0], region[1]),
      region[2] * 1000,
      isDistrict: false,
      key: regionKey,
    );
  }
}
