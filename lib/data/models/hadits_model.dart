class HaditsModel {
  final String id;
  final String book;
  final int number;
  final String arab;
  final String idTranslation;
  final String title;
  final String category;

  HaditsModel({
    required this.id,
    required this.book,
    required this.number,
    required this.arab,
    required this.idTranslation,
    required this.title,
    required this.category,
  });

  String get arabicText => arab;

  factory HaditsModel.fromJson(Map<String, dynamic> json, {String defaultBook = 'HR. Bukhari'}) {
    final int hadithNum = json['hadithnumber'] is int
        ? json['hadithnumber']
        : (json['number'] is int
            ? json['number']
            : int.tryParse(json['hadithnumber']?.toString() ?? json['number']?.toString() ?? '1') ?? 1);

    final String bookName = json['book']?.toString() ?? defaultBook;
    final String arabText = json['arab']?.toString() ??
        json['arabic']?.toString() ??
        json['ar']?.toString() ??
        '';

    final String translation = json['text']?.toString() ??
        json['idTranslation']?.toString() ??
        json['id']?.toString() ??
        json['tr']?.toString() ??
        '';

    final String rawTitle = json['title']?.toString() ?? '';
    final String titleText = rawTitle.isNotEmpty
        ? rawTitle
        : _extractTitleFromText(translation, bookName, hadithNum);

    final String rawCat = json['category']?.toString() ?? '';
    final String categoryText = rawCat.isNotEmpty
        ? rawCat
        : _inferCategoryFromText(translation);

    return HaditsModel(
      id: json['id']?.toString() ?? '${bookName}_$hadithNum',
      book: bookName,
      number: hadithNum,
      arab: arabText,
      idTranslation: translation,
      title: titleText,
      category: categoryText,
    );
  }

  static String _extractTitleFromText(String text, String book, int number) {
    if (text.isEmpty) return 'Hadits $book No. $number';
    final lower = text.toLowerCase();
    if (lower.contains('ramadhan') || lower.contains('puasa')) return 'Keutamaan & Hukum Puasa';
    if (lower.contains('sahur')) return 'Keberkahan Sahur';
    if (lower.contains('lailatul qadar')) return 'Keutamaan Lailatul Qadar';
    if (lower.contains('niat')) return 'Niat & Keikhlasan Amalan';
    if (lower.contains('shalat') || lower.contains('sholat')) return 'Keutamaan & Tata Cara Sholat';
    if (lower.contains('sedekah') || lower.contains('zakat')) return 'Keutamaan Sedekah & Zakat';
    if (lower.contains('qur\'an') || lower.contains('quran')) return 'Keutamaan Al-Qur\'an';
    if (lower.contains('ilmu')) return 'Keutamaan Menuntut Ilmu';
    if (lower.contains('dzikir') || lower.contains('istighfar')) return 'Anjuran Dzikir & Istighfar';
    if (lower.contains('akhlak') || lower.contains('saudara') || lower.contains('orang tua')) return 'Kemuliaan Akhlak & Silaturahmi';

    // Extract first sentence as title if short
    final firstPeriod = text.indexOf('.');
    if (firstPeriod > 10 && firstPeriod < 60) {
      return text.substring(0, firstPeriod).trim();
    }
    return 'Hadits $book No. $number';
  }

  static String _inferCategoryFromText(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('puasa') || lower.contains('fithr') || lower.contains('buka')) return 'Puasa';
    if (lower.contains('sahur')) return 'Sahur';
    if (lower.contains('ramadhan') || lower.contains('lailatul')) return 'Ramadhan';
    if (lower.contains('shalat') || lower.contains('sholat') || lower.contains('sujud') || lower.contains('adzan')) return 'Sholat';
    if (lower.contains('qur\'an') || lower.contains('quran') || lower.contains('ayat')) return 'Al-Qur\'an';
    if (lower.contains('sedekah') || lower.contains('zakat') || lower.contains('infaq') || lower.contains('harta')) return 'Sedekah';
    if (lower.contains('ilmu') || lower.contains('belajar') || lower.contains('mengajar')) return 'Ilmu';
    if (lower.contains('niat') || lower.contains('amalan')) return 'Niat';
    if (lower.contains('dzikir') || lower.contains('istighfar') || lower.contains('tasbih') || lower.contains('taubat')) return 'Dzikir';
    if (lower.contains('senyum') || lower.contains('saudara') || lower.contains('orang tua') || lower.contains('tetangga') || lower.contains('silaturahmi') || lower.contains('akhlak')) return 'Akhlak';
    return 'Akhlak';
  }
}
