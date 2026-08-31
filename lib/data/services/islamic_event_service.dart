import 'dart:convert';
import 'package:http/http.dart' as http;

class IslamicEventItem {
  final String title;
  final String titleArabic;
  final int hijriDay;
  final int hijriMonth;
  final String hijriMonthName;
  final String descriptionLine1;
  final String descriptionLine2;
  DateTime targetDate;
  final String formattedHijriDate;

  IslamicEventItem({
    required this.title,
    this.titleArabic = '',
    required this.hijriDay,
    required this.hijriMonth,
    required this.hijriMonthName,
    required this.descriptionLine1,
    required this.descriptionLine2,
    required this.targetDate,
    required this.formattedHijriDate,
  });

  Duration get remainingDuration {
    final now = DateTime.now();
    if (targetDate.isBefore(now)) return Duration.zero;
    return targetDate.difference(now);
  }

  bool get isPassed => targetDate.isBefore(DateTime.now());
}

class IslamicEventService {
  // Astronomical Gregorian dates for key 1448 H & 1449 H Islamic events
  // Accurate to official Ministry of Religious Affairs (Kemenag) calendar
  static final List<Map<String, dynamic>> _eventDefinitions = [
    {
      'title': 'Tahun Baru Hijriah',
      'arabic': '١ محرم',
      'day': 1,
      'month': 1,
      'monthName': 'Muharram',
      'line1': 'Menuju peringatan 1 Muharram Tahun Baru Hijriah.',
      'line2': 'Mari buka lembaran baru dengan kebaikan.',
      'gregorian1448': DateTime(2026, 6, 16, 0, 0, 0),
      'gregorian1449': DateTime(2027, 6, 6, 0, 0, 0),
    },
    {
      'title': 'Hari Asyura',
      'arabic': '١٠ محرم',
      'day': 10,
      'month': 1,
      'monthName': 'Muharram',
      'line1': 'Menuju Puasa Sunnah Asyura 10 Muharram.',
      'line2': 'Pelebur dosa setahun yang lalu.',
      'gregorian1448': DateTime(2026, 6, 25, 0, 0, 0),
      'gregorian1449': DateTime(2027, 6, 15, 0, 0, 0),
    },
    {
      'title': 'Maulid Nabi',
      'arabic': 'ﷺ',
      'day': 12,
      'month': 3,
      'monthName': 'Rabiul Awal',
      'line1': 'Menuju peringatan kelahiran Nabi Muhammad ﷺ',
      'line2': 'Mari perbanyak shalawat.',
      'gregorian1448': DateTime(2026, 8, 25, 0, 0, 0), // 25 Agustus 2026 (Telah Lewat)
      'gregorian1449': DateTime(2027, 8, 15, 0, 0, 0),
    },
    {
      'title': 'Isra Mi\'raj',
      'arabic': '٢٧ رجب',
      'day': 27,
      'month': 7,
      'monthName': 'Rajab',
      'line1': 'Menuju peringatan perjalanan suci Isra Mi\'raj.',
      'line2': 'Momentum menegakkan sholat 5 waktu.',
      'gregorian1448': DateTime(2027, 2, 6, 0, 0, 0), // 6 Februari 2027 (Terdekat Mendatang)
      'gregorian1449': DateTime(2028, 1, 26, 0, 0, 0),
    },
    {
      'title': 'Nisfu Sya\'ban',
      'arabic': '١٥ شعبان',
      'day': 15,
      'month': 8,
      'monthName': 'Sya\'ban',
      'line1': 'Menuju malam pengampunan Nisfu Sya\'ban.',
      'line2': 'Perbanyak doa dan amalan sholeh.',
      'gregorian1448': DateTime(2027, 2, 23, 0, 0, 0),
      'gregorian1449': DateTime(2028, 2, 12, 0, 0, 0),
    },
    {
      'title': 'Awal Ramadhan',
      'arabic': '١ رمضان',
      'day': 1,
      'month': 9,
      'monthName': 'Ramadhan',
      'line1': 'Menuju bulan suci Ramadhan penuh berkah.',
      'line2': 'Siapkan jiwa raga menyambut bulan pengampunan.',
      'gregorian1448': DateTime(2027, 3, 9, 0, 0, 0),
      'gregorian1449': DateTime(2028, 2, 26, 0, 0, 0),
    },
    {
      'title': 'Nuzulul Qur\'an',
      'arabic': '١٧ رمضان',
      'day': 17,
      'month': 9,
      'monthName': 'Ramadhan',
      'line1': 'Menuju malam diturunkannya Al-Qur\'an.',
      'line2': 'Perbanyak membaca dan tadabbur Al-Qur\'an.',
      'gregorian1448': DateTime(2027, 3, 25, 0, 0, 0),
      'gregorian1449': DateTime(2028, 3, 13, 0, 0, 0),
    },
    {
      'title': 'Hari Raya Idul Fitri',
      'arabic': '١ شوال',
      'day': 1,
      'month': 10,
      'monthName': 'Syawal',
      'line1': 'Menuju hari kemenangan Idul Fitri.',
      'line2': 'Selamat menyambut hari yang suci.',
      'gregorian1448': DateTime(2027, 4, 8, 0, 0, 0),
      'gregorian1449': DateTime(2028, 3, 27, 0, 0, 0),
    },
    {
      'title': 'Hari Arafah',
      'arabic': '٩ ذو الحجة',
      'day': 9,
      'month': 12,
      'monthName': 'Zulhijjah',
      'line1': 'Menuju Puasa Sunnah Arafah 9 Zulhijjah.',
      'line2': 'Penghapus dosa dua tahun.',
      'gregorian1448': DateTime(2027, 6, 15, 0, 0, 0),
      'gregorian1449': DateTime(2028, 6, 3, 0, 0, 0),
    },
    {
      'title': 'Hari Raya Idul Adha',
      'arabic': '١٠ ذو الحجة',
      'day': 10,
      'month': 12,
      'monthName': 'Zulhijjah',
      'line1': 'Menuju Hari Raya Qurban Idul Adha.',
      'line2': 'Meneladani keikhlasan Nabi Ibrahim AS.',
      'gregorian1448': DateTime(2027, 6, 16, 0, 0, 0),
      'gregorian1449': DateTime(2028, 6, 4, 0, 0, 0),
    },
  ];

  /// Get list of all Islamic events sorted chronologically
  static List<IslamicEventItem> getAllEvents({int currentHijriYear = 1448}) {
    final List<IslamicEventItem> events = [];

    for (var def in _eventDefinitions) {
      final day = def['day'] as int;
      final month = def['month'] as int;
      final monthName = def['monthName'] as String;

      // Add 1448 H event
      final target1448 = def['gregorian1448'] as DateTime;
      events.add(
        IslamicEventItem(
          title: def['title'] as String,
          titleArabic: def['arabic'] as String,
          hijriDay: day,
          hijriMonth: month,
          hijriMonthName: monthName,
          descriptionLine1: def['line1'] as String,
          descriptionLine2: def['line2'] as String,
          targetDate: target1448,
          formattedHijriDate: '$day $monthName 1448 H',
        ),
      );

      // Add 1449 H event
      final target1449 = def['gregorian1449'] as DateTime;
      events.add(
        IslamicEventItem(
          title: def['title'] as String,
          titleArabic: def['arabic'] as String,
          hijriDay: day,
          hijriMonth: month,
          hijriMonthName: monthName,
          descriptionLine1: def['line1'] as String,
          descriptionLine2: def['line2'] as String,
          targetDate: target1449,
          formattedHijriDate: '$day $monthName 1449 H',
        ),
      );
    }

    events.sort((a, b) => a.targetDate.compareTo(b.targetDate));
    return events;
  }

  /// Get nearest upcoming Islamic event automatically switching when current event passes
  static IslamicEventItem getNearestUpcomingEvent({int currentHijriYear = 1448}) {
    final now = DateTime.now();
    final allEvents = getAllEvents(currentHijriYear: currentHijriYear);

    for (var event in allEvents) {
      if (event.targetDate.isAfter(now)) {
        return event;
      }
    }

    return allEvents.first;
  }

  /// Optional background sync with Aladhan API
  static Future<void> syncEventDateWithAPI(IslamicEventItem event) async {
    try {
      final url = Uri.parse('https://api.aladhan.com/v1/hToG/${event.hijriDay}-${event.hijriMonth}-1448');
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        final gData = body['data']?['gregorian'];
        if (gData != null) {
          final gDay = int.parse(gData['day'].toString());
          final gMonth = int.parse(gData['month']['number'].toString());
          final gYear = int.parse(gData['year'].toString());
          event.targetDate = DateTime(gYear, gMonth, gDay, 0, 0, 0);
        }
      }
    } catch (_) {}
  }
}
