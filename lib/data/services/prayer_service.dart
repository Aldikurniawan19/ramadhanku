import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../core/constants/api_constants.dart';
import '../models/prayer_time_model.dart';

class PrayerService {
  final http.Client client;
  PrayerService({http.Client? client}) : client = client ?? http.Client();

  Future<PrayerTimesData> fetchPrayerTimes({
    String city = ApiConstants.defaultCity,
    String country = ApiConstants.defaultCountry,
  }) async {
    final now = DateTime.now();
    final dateStr = DateFormat('dd-MM-yyyy').format(now);

    // 1. Try Aladhan API by Address (Works for ALL Kota, Kabupaten, Kecamatan in Indonesia & Worldwide)
    try {
      final addressQuery = Uri.encodeComponent('$city, $country');
      final url = Uri.parse(
        '${ApiConstants.aladhanBaseUrl}/timingsByAddress/$dateStr?address=$addressQuery&method=${ApiConstants.kemenagMethodId}',
      );

      final response = await client.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['code'] == 200 && body['data'] != null && body['data']['timings'] != null) {
          return _parseAladhanResponse(body['data'], city, country, now);
        }
      }
    } catch (_) {}

    // 2. Fallback: Try Aladhan API by City
    try {
      final encodedCity = Uri.encodeComponent(city);
      final encodedCountry = Uri.encodeComponent(country);
      final url = Uri.parse(
        '${ApiConstants.aladhanBaseUrl}/timingsByCity/$dateStr?city=$encodedCity&country=$encodedCountry&method=${ApiConstants.kemenagMethodId}',
      );

      final response = await client.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        if (body['code'] == 200 && body['data'] != null && body['data']['timings'] != null) {
          return _parseAladhanResponse(body['data'], city, country, now);
        }
      }
    } catch (_) {}

    // 3. Fallback timings (Jakarta / Standard WIB defaults)
    final fallbackTimings = {
      'Imsak': '04:28',
      'Fajr': '04:38',
      'Dhuhr': '11:57',
      'Asr': '15:13',
      'Maghrib': '18:02',
      'Isha': '19:12',
    };

    final realHijri = calculateCurrentHijriDate(now);
    return _processTimings(
      fallbackTimings,
      '$city, $country',
      now,
      hijriMonthNumber: realHijri['monthNumber'] as int,
      hijriMonthName: realHijri['monthName'] as String,
      hijriYear: realHijri['year'] as String,
      hijriDay: realHijri['day'] as int,
    );
  }

  PrayerTimesData _parseAladhanResponse(
    Map<String, dynamic> data,
    String city,
    String country,
    DateTime now,
  ) {
    final timings = data['timings'];
    final dateData = data['date'];

    final realHijriDefault = calculateCurrentHijriDate(now);
    int hijriMonthNum = realHijriDefault['monthNumber'] as int;
    String hijriMonthName = realHijriDefault['monthName'] as String;
    String hijriYear = realHijriDefault['year'] as String;
    int hijriDay = realHijriDefault['day'] as int;

    if (dateData != null && dateData['hijri'] != null) {
      final hijri = dateData['hijri'];
      hijriDay = int.tryParse(hijri['day']?.toString() ?? '10') ?? hijriDay;
      if (hijri['month'] != null) {
        hijriMonthNum = int.tryParse(hijri['month']['number'].toString()) ?? hijriMonthNum;
        final rawName = hijri['month']['en']?.toString() ?? hijriMonthName;
        hijriMonthName = mapHijriMonthName(hijriMonthNum, rawName);
      }
      if (hijri['year'] != null) {
        hijriYear = '${hijri['year']} H';
      }
    }

    return _processTimings(
      timings,
      '$city, $country',
      now,
      hijriMonthNumber: hijriMonthNum,
      hijriMonthName: hijriMonthName,
      hijriYear: hijriYear,
      hijriDay: hijriDay,
    );
  }

  static Map<String, dynamic> calculateCurrentHijriDate([DateTime? date]) {
    final now = date ?? DateTime.now();
    int day = now.day;
    int month = now.month;
    int year = now.year;

    if (month <= 2) {
      year -= 1;
      month += 12;
    }

    double a = (year / 100).floorToDouble();
    double b = 2 - a + (a / 4).floorToDouble();
    double jd = (365.25 * (year + 4716)).floorToDouble() +
        (30.6001 * (month + 1)).floorToDouble() +
        day +
        b -
        1524.5;

    double l = jd - 1948440 + 10632;
    double n = ((l - 1) / 10631).floorToDouble();
    l = l - 10631 * n + 354;
    double j = (((10985 - l) / 5316).floorToDouble()) *
            (((50 * l) / 17719).floorToDouble()) +
        (((l / 5670).floorToDouble()) * (((43 * l) / 15238).floorToDouble()));
    l = l -
        (((30 - j) / 15).floorToDouble()) * (((17719 * j) / 50).floorToDouble()) -
        ((j / 16).floorToDouble()) * (((15238 * j) / 43).floorToDouble()) +
        29;

    int hMonth = ((24 * l) / 709).floor();
    int hDay = (l - ((709 * hMonth) / 24).floor()).toInt();
    int hYear = (30 * n + j - 30).toInt();

    final monthName = mapHijriMonthName(hMonth, 'Sya\'ban');

    return {
      'day': hDay.clamp(1, 30),
      'monthNumber': hMonth.clamp(1, 12),
      'monthName': monthName,
      'year': '$hYear H',
    };
  }

  static String mapHijriMonthName(int monthNum, String defaultName) {
    const months = {
      1: 'Muharram',
      2: 'Safar',
      3: 'Rabiul Awal',
      4: 'Rabiul Akhir',
      5: 'Jumadil Awal',
      6: 'Jumadil Akhir',
      7: 'Rajab',
      8: 'Sya\'ban',
      9: 'Ramadhan',
      10: 'Syawal',
      11: 'Zulqa\'dah',
      12: 'Zulhijjah',
    };
    return months[monthNum] ?? defaultName;
  }

  PrayerTimesData _processTimings(
    Map<String, dynamic> t,
    String locationName,
    DateTime now, {
    int hijriMonthNumber = 2,
    String hijriMonthName = 'Safar',
    String hijriYear = '1448 H',
    int hijriDay = 10,
  }) {
    String cleanTime(dynamic val) {
      if (val == null) return '00:00';
      final str = val.toString();
      return str.length >= 5 ? str.substring(0, 5) : str;
    }

    final rawList = [
      {'id': 'imsak', 'name': 'Imsak', 'time': cleanTime(t['Imsak'])},
      {'id': 'subuh', 'name': 'Subuh', 'time': cleanTime(t['Fajr'])},
      {'id': 'dzuhur', 'name': 'Dzuhur', 'time': cleanTime(t['Dhuhr'])},
      {'id': 'ashar', 'name': 'Ashar', 'time': cleanTime(t['Asr'])},
      {'id': 'maghrib', 'name': 'Maghrib (Buka Puasa)', 'time': cleanTime(t['Maghrib'])},
      {'id': 'isya', 'name': 'Isya', 'time': cleanTime(t['Isha'])},
    ];

    int nextIndex = 0;
    Duration minDiff = const Duration(days: 99);

    for (int i = 0; i < rawList.length; i++) {
      final parts = rawList[i]['time']!.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);

      var pTime = DateTime(now.year, now.month, now.day, hour, minute);
      if (pTime.isBefore(now)) {
        pTime = pTime.add(const Duration(days: 1));
      }

      final diff = pTime.difference(now);
      if (diff < minDiff) {
        minDiff = diff;
        nextIndex = i;
      }
    }

    final List<PrayerItem> prayers = [];
    for (int i = 0; i < rawList.length; i++) {
      prayers.add(PrayerItem(
        id: rawList[i]['id']!,
        name: rawList[i]['name']!,
        time: rawList[i]['time']!,
        isNext: i == nextIndex,
      ));
    }

    String dateReadable;
    try {
      dateReadable = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
    } catch (_) {
      dateReadable = DateFormat('EEEE, d MMMM yyyy').format(now);
    }

    return PrayerTimesData(
      prayers: prayers,
      city: locationName,
      dateStr: dateReadable,
      nextPrayerName: prayers[nextIndex].name,
      nextPrayerTime: prayers[nextIndex].time,
      timeRemaining: minDiff,
      hijriMonthNumber: hijriMonthNumber,
      hijriMonthName: hijriMonthName,
      hijriYear: hijriYear,
      hijriDay: hijriDay,
    );
  }
}
