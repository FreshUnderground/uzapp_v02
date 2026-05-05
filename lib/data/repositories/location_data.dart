/// DRC cities and communes for location-based features
class LocationData {
  static const Map<String, List<String>> cities = {
    'Butembo': ['Butembo', 'Vulamba', 'Kimemi', 'Mususa', 'vulengera'],
    'Beni': ['Beni', 'Mulekera', 'Beu', 'Ruwenzori'],
    'Goma': ['Goma', 'Karisimbi'],
    'Bukavu': ['Ibanda', 'Kadutu', 'Bagira'],
    'Bunia': ['Bunia', 'Nyakasanza', 'Shari', 'Mbogi', 'Rwambuzi'],
    'Kinshasa': [
      'Bandalungwa',
      'Barumbu',
      'Bumbu',
      'Gombe',
      'Kalamu',
      'Kasa-Vubu',
      'Kimbanseke',
      'Kinshasa',
      'Kintambo',
      'Kisenso',
      'Lemba',
      'Limete',
      'Lingwala',
      'Makala',
      'Maluku',
      'Masina',
      'Matete',
      'Mont-Ngafula',
      'Ndjili',
      'Ngaba',
      'Ngaliema',
      'Ngiri-Ngiri',
      'Nsele',
      'Selembao',
    ],
    'Lubumbashi': [
      'Lubumbashi',
      'Kamalondo',
      'Kenya',
      'Katuba',
      'Kampemba',
      'Ruashi',
      'Annexe',
    ],
    'Mbuji-Mayi': ['Kanshi', 'Dibindi', 'Bipemba', 'Muya', 'Diulu'],
    'Kananga': ['Kananga', 'Katoka', 'Ndesha', 'Lukonga', 'Nganza'],
    'Kisangani': [
      'Makiso',
      'Mangobo',
      'Tshopo',
      'Kabondo',
      'Kisangani',
      'Lubunga',
    ],
    'Likasi': ['Likasi', 'Panda', 'Shituru', 'Kikula'],
    'Kolwezi': ['Dilala', 'Manika', 'Lucapa'],
    'Tshikapa': ['Tshikapa', 'Kandjaji'],
    'Matadi': ['Matadi', 'Mvuzi', 'Nzanza'],
    'Uvira': ['Uvira', 'Mulongwe', 'Kavimvira'],
    'Kikwit': ['Kikwit', 'Lukemi', 'Kazamba', 'Nzinda'],
    'Mbandaka': ['Mbandaka', 'Wangata'],
    'Mwene-Ditu': ['Mwene-Ditu', 'Bonzola'],
    'Inongo': ['Inongo'],
    'Bandundu': ['Bandundu', 'Basoko', 'Mayoyo', 'Disasi'],
    'Gemena': ['Gemena'],
    'Gbadolite': ['Gbadolite'],
    'Isiro': ['Isiro'],
    'Kindu': ['Kindu', 'Mikelenge', 'Alunguli', 'Kasuku'],
    'Kalemie': ['Kalemie', 'Kataki', 'Lac'],
    'Kipushi': ['Kipushi'],
    'Fungurume': ['Fungurume'],
    'Kamina': ['Kamina'],
    'Kabinda': ['Kabinda'],
    'Lodja': ['Lodja'],
    'Lubao': ['Lubao'],
  };

  /// Get neighboring communes (communes in the same city)
  static List<String> getNeighboringCommunes(String commune) {
    for (final city in cities.entries) {
      if (city.value.contains(commune)) {
        return city.value.where((c) => c != commune).toList();
      }
    }
    return [];
  }

  /// Get city for a commune
  static String? getCityForCommune(String commune) {
    for (final city in cities.entries) {
      if (city.value.contains(commune)) return city.key;
    }
    return null;
  }

  /// Get all communes flat
  static List<String> getAllCommunes() {
    return cities.values.expand((c) => c).toList();
  }
}
