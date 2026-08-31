class PrayerItem {
  final String id;
  final String name;
  final String time; // e.g. "04:38"
  final bool isNext;

  PrayerItem({
    required this.id,
    required this.name,
    required this.time,
    this.isNext = false,
  });

  PrayerItem copyWith({bool? isNext}) {
    return PrayerItem(
      id: id,
      name: name,
      time: time,
      isNext: isNext ?? this.isNext,
    );
  }
}

class PrayerTimesData {
  final List<PrayerItem> prayers;
  final String city;
  final String dateStr;
  final String nextPrayerName;
  final String nextPrayerTime;
  final Duration timeRemaining;
  final int hijriMonthNumber;
  final String hijriMonthName;
  final String hijriYear;
  final int hijriDay;

  bool get isRamadhan => hijriMonthNumber == 9;

  String get ramadhanStatusText {
    if (isRamadhan) {
      return 'Ramadhan $hijriYear';
    } else if (hijriMonthNumber == 8) {
      return 'Menuju Ramadhan (Sya\'ban $hijriYear)';
    } else if (hijriMonthNumber == 10) {
      return 'Bulan Syawal $hijriYear';
    } else {
      return '$hijriMonthName $hijriYear';
    }
  }

  PrayerTimesData({
    required this.prayers,
    required this.city,
    required this.dateStr,
    required this.nextPrayerName,
    required this.nextPrayerTime,
    required this.timeRemaining,
    this.hijriMonthNumber = 2,
    this.hijriMonthName = 'Safar',
    this.hijriYear = '1448 H',
    this.hijriDay = 10,
  });
}
