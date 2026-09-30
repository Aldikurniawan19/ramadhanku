import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../core/constants/api_constants.dart';
import 'prayer_cache_service.dart';

/// =====================================================================
/// Background Scheduler Service
///
/// This service manages two critical background tasks:
///
/// 1. AUTO-DOWNLOAD PRAYER SCHEDULES:
///    Uses AndroidAlarmManager to schedule a daily background check
///    that downloads 7-day prayer schedules and schedules notifications
///    for all of them. This ensures notifications work even if the user
///    hasn't opened the app for days.
///
/// 2. APP INACTIVITY REMINDER:
///    If the user hasn't opened the app for 4+ days, sends a gentle
///    reminder notification encouraging them to come back (continue
///    tadarus, check on their sholat routine, etc.)
///
/// 3. MULTI-DAY NOTIFICATION SCHEDULING:
///    Schedules prayer notifications for ALL cached days (up to 7 days),
///    so notifications continue to fire even without opening the app.
///
/// Alarm IDs:
///   2000 = Daily auto-refresh alarm (repeating every ~12 hours)
///   2001 = App inactivity reminder alarm (repeating every ~24 hours)
///   3000-3699 = Multi-day prayer notification alarms
///     3000-3011 = Day 0 (today): 6 prayers × 2 notifications each
///     3012-3023 = Day 1 (tomorrow)
///     ... up to Day 6
/// =====================================================================

/// Alarm IDs
const int _dailyRefreshAlarmId = 2000;
const int _inactivityReminderAlarmId = 2001;
const int _multiDayAlarmIdBase = 3000;
const int _alarmsPerDay = 12; // 6 prayers × 2 (pre + exact)

/// Notification channel for reminder notifications (separate from prayer channel)
const String _reminderChannelId = 'app_reminder_v1';
const String _reminderChannelName = 'Pengingat Aplikasi';
const String _reminderChannelDesc = 'Notifikasi pengingat untuk kembali menggunakan aplikasi';

/// =====================================================================
/// Top-level callback: Daily auto-refresh of prayer schedules.
/// Runs in a SEPARATE background isolate.
///
/// This callback:
///   1. Downloads prayer times for the next 7 days
///   2. Caches them in SharedPreferences
///   3. Schedules notifications for all cached days
/// =====================================================================
@pragma('vm:entry-point')
Future<void> backgroundAutoRefreshCallback() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone
  tz_data.initializeTimeZones();
  try {
    final deviceTzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(deviceTzInfo.identifier));
  } catch (_) {
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {}
  }

  debugPrint('[BGScheduler] Auto-refresh callback fired');

  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();

  // Get saved city
  final uid = prefs.getString('firebase_uid') ?? 'default';
  final city = prefs.getString('selected_city_$uid') ??
      prefs.getString('cached_prayers_city') ??
      ApiConstants.defaultCity;
  const country = ApiConstants.defaultCountry;

  // Check if refresh is needed
  final needsRefresh = await PrayerCacheService.needsRefresh();
  if (!needsRefresh) {
    debugPrint('[BGScheduler] Cache is still valid, skipping download');
    // But still re-schedule notifications from cache for today and tomorrow
    await _scheduleNotificationsFromCache();
    return;
  }

  debugPrint('[BGScheduler] Refreshing prayer schedules for $city...');

  // Download prayer times for the next 7 days
  try {
    final client = http.Client();
    final now = DateTime.now();

    for (int i = 0; i < 7; i++) {
      final date = now.add(Duration(days: i));
      final dateStr = DateFormat('dd-MM-yyyy').format(date);
      final dateKey = PrayerCacheService.getDateString(i);

      // Check if already cached
      final existing = await PrayerCacheService.getPrayersForDate(dateKey);
      if (existing != null) continue;

      // Try Aladhan API
      List<Map<String, String>>? prayers;

      try {
        final addressQuery = Uri.encodeComponent('$city, $country');
        final url = Uri.parse(
          '${ApiConstants.aladhanBaseUrl}/timingsByAddress/$dateStr?address=$addressQuery&method=${ApiConstants.kemenagMethodId}',
        );

        final response = await client.get(url).timeout(const Duration(seconds: 10));
        if (response.statusCode == 200) {
          final Map<String, dynamic> body = jsonDecode(response.body);
          if (body['code'] == 200 && body['data']?['timings'] != null) {
            prayers = _extractTimings(body['data']['timings']);
          }
        }
      } catch (e) {
        debugPrint('[BGScheduler] API address failed for $dateStr: $e');
      }

      // Fallback by city
      if (prayers == null) {
        try {
          final encodedCity = Uri.encodeComponent(city);
          final encodedCountry = Uri.encodeComponent(country);
          final url = Uri.parse(
            '${ApiConstants.aladhanBaseUrl}/timingsByCity/$dateStr?city=$encodedCity&country=$encodedCountry&method=${ApiConstants.kemenagMethodId}',
          );

          final response = await client.get(url).timeout(const Duration(seconds: 10));
          if (response.statusCode == 200) {
            final Map<String, dynamic> body = jsonDecode(response.body);
            if (body['code'] == 200 && body['data']?['timings'] != null) {
              prayers = _extractTimings(body['data']['timings']);
            }
          }
        } catch (e) {
          debugPrint('[BGScheduler] API city failed for $dateStr: $e');
        }
      }

      // Fallback: static defaults
      prayers ??= [
        {'id': 'imsak', 'name': 'Imsak', 'time': '04:28'},
        {'id': 'subuh', 'name': 'Subuh', 'time': '04:38'},
        {'id': 'dzuhur', 'name': 'Dzuhur', 'time': '11:57'},
        {'id': 'ashar', 'name': 'Ashar', 'time': '15:13'},
        {'id': 'maghrib', 'name': 'Maghrib (Buka Puasa)', 'time': '18:02'},
        {'id': 'isya', 'name': 'Isya', 'time': '19:12'},
      ];

      await PrayerCacheService.savePrayersForDate(dateKey, prayers, city);

      // Small delay between API calls
      if (i < 6) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    client.close();

    await PrayerCacheService.recordScheduleRefresh();
    await PrayerCacheService.cleanupOldDates();

    debugPrint('[BGScheduler] Successfully downloaded 7-day schedule');
  } catch (e) {
    debugPrint('[BGScheduler] Error downloading schedules: $e');
  }

  // Schedule notifications from the refreshed cache
  await _scheduleNotificationsFromCache();
}

/// Extract timings from Aladhan API response (used in background isolate).
List<Map<String, String>> _extractTimings(Map<String, dynamic> t) {
  String cleanTime(dynamic val) {
    if (val == null) return '00:00';
    final str = val.toString();
    return str.length >= 5 ? str.substring(0, 5) : str;
  }

  return [
    {'id': 'imsak', 'name': 'Imsak', 'time': cleanTime(t['Imsak'])},
    {'id': 'subuh', 'name': 'Subuh', 'time': cleanTime(t['Fajr'])},
    {'id': 'dzuhur', 'name': 'Dzuhur', 'time': cleanTime(t['Dhuhr'])},
    {'id': 'ashar', 'name': 'Ashar', 'time': cleanTime(t['Asr'])},
    {'id': 'maghrib', 'name': 'Maghrib (Buka Puasa)', 'time': cleanTime(t['Maghrib'])},
    {'id': 'isya', 'name': 'Isya', 'time': cleanTime(t['Isha'])},
  ];
}

/// Schedule notifications for all cached prayer days from the background isolate.
Future<void> _scheduleNotificationsFromCache() async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();

  final masterOn = prefs.getBool('notif_master') ?? true;
  if (!masterOn) {
    debugPrint('[BGScheduler] Master notification OFF — skipping notifications');
    return;
  }

  final imsakOn = prefs.getBool('notif_imsak') ?? prefs.getBool('is_imsak_enabled') ?? true;
  final subuhOn = prefs.getBool('notif_subuh') ?? true;
  final dzuhurOn = prefs.getBool('notif_dzuhur') ?? true;
  final asharOn = prefs.getBool('notif_ashar') ?? true;
  final maghribOn = prefs.getBool('notif_maghrib') ?? prefs.getBool('is_iftar_enabled') ?? true;
  final isyaOn = prefs.getBool('notif_isya') ?? true;
  final adhanGlobalOn = prefs.getBool('is_adhan_enabled') ?? true;

  final city = prefs.getString('cached_prayers_city') ?? ApiConstants.defaultCity;

  // Initialize notification plugin in this isolate
  final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings settings = InitializationSettings(android: androidSettings);
  await plugin.initialize(settings);

  // Ensure notification channel exists
  final androidPlugin = plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
      'prayer_adhan_alarm_v7',
      'Adzan & Waktu Sholat',
      description: 'Pengingat otomatis adzan ketika memasuki waktu sholat & buka puasa',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adzan'),
      enableVibration: true,
      enableLights: true,
    ));
  }

  final location = tz.local;
  final nowTz = tz.TZDateTime.now(location);
  int scheduledCount = 0;

  // Get cached dates
  final cachedDates = await PrayerCacheService.getCachedDates();
  debugPrint('[BGScheduler] Scheduling notifications for ${cachedDates.length} cached days');

  for (int dayIdx = 0; dayIdx < cachedDates.length && dayIdx < 7; dayIdx++) {
    final dateStr = cachedDates[dayIdx];
    final prayers = await PrayerCacheService.getPrayersForDate(dateStr);
    if (prayers == null) continue;

    // Parse date
    final dateParts = dateStr.split('-');
    if (dateParts.length != 3) continue;
    final year = int.tryParse(dateParts[0]);
    final month = int.tryParse(dateParts[1]);
    final day = int.tryParse(dateParts[2]);
    if (year == null || month == null || day == null) continue;

    for (int i = 0; i < prayers.length; i++) {
      final prayer = prayers[i];
      final pId = (prayer['id'] ?? '').toLowerCase();
      final pName = prayer['name'] ?? '';
      final pTime = prayer['time'] ?? '';

      // Check toggle settings per prayer
      if (pId.contains('imsak') && !imsakOn) continue;
      if (pId.contains('subuh') && (!subuhOn || !adhanGlobalOn)) continue;
      if (pId.contains('dzuhur') && (!dzuhurOn || !adhanGlobalOn)) continue;
      if (pId.contains('ashar') && (!asharOn || !adhanGlobalOn)) continue;
      if (pId.contains('maghrib') && !maghribOn) continue;
      if (pId.contains('isya') && (!isyaOn || !adhanGlobalOn)) continue;

      try {
        final timeClean = pTime.replaceAll(RegExp(r'[^\d:]'), '').trim();
        final parts = timeClean.split(':');
        if (parts.length < 2) continue;

        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) continue;

        var exactPrayerTz = tz.TZDateTime(location, year, month, day, hour, minute);
        if (exactPrayerTz.isBefore(nowTz)) continue;

        final oneMinBeforeTz = exactPrayerTz.subtract(const Duration(minutes: 1));

        // Prepare titles & bodies
        String preTitle, preBody, exactTitle, exactBody;

        if (pId == 'imsak') {
          preTitle = 'Waktu Imsak 1 Menit Lagi';
          preBody = 'Pengingat ($city): 1 menit lagi memasuki waktu Imsak.';
          exactTitle = 'Waktu Imsak Telah Tiba';
          exactBody = 'Telah memasuki waktu Imsak untuk wilayah $city dan sekitarnya. Segera selesaikan sahur.';
        } else if (pId == 'maghrib') {
          preTitle = 'Buka Puasa 1 Menit Lagi';
          preBody = 'Pengingat ($city): 1 menit lagi memasuki waktu Maghrib & berbuka puasa.';
          exactTitle = 'Waktu Buka Puasa Telah Tiba!';
          exactBody = 'Selamat berbuka puasa untuk wilayah $city dan sekitarnya. Selamat menunaikan ibadah sholat Maghrib.';
        } else {
          preTitle = 'Waktu Sholat $pName 1 Menit Lagi';
          preBody = 'Pengingat ($city): 1 menit lagi memasuki waktu sholat $pName.';
          exactTitle = 'Waktu Sholat $pName Telah Tiba';
          exactBody = 'Telah memasuki waktu sholat $pName untuk wilayah $city dan sekitarnya. Mari bersiap wudhu dan sholat.';
        }

        // Alarm IDs: base + (dayIdx * 12) + (prayer * 2) + offset
        final baseId = _multiDayAlarmIdBase + (dayIdx * _alarmsPerDay) + (i * 2);

        // Schedule 1 minute before
        if (oneMinBeforeTz.isAfter(nowTz)) {
          final preAlarmId = baseId;
          await prefs.setString('bg_alarm_title_$preAlarmId', preTitle);
          await prefs.setString('bg_alarm_body_$preAlarmId', preBody);

          try {
            await AndroidAlarmManager.oneShotAt(
              oneMinBeforeTz,
              preAlarmId,
              _multiDayAlarmCallback,
              exact: true,
              wakeup: true,
              alarmClock: true,
              rescheduleOnReboot: true,
            );
            scheduledCount++;
          } catch (_) {
            try {
              await AndroidAlarmManager.oneShotAt(
                oneMinBeforeTz,
                preAlarmId,
                _multiDayAlarmCallback,
                exact: true,
                wakeup: true,
                alarmClock: false,
                rescheduleOnReboot: true,
              );
              scheduledCount++;
            } catch (_) {}
          }
        }

        // Schedule exact prayer time
        if (exactPrayerTz.isAfter(nowTz)) {
          final exactAlarmId = baseId + 1;
          await prefs.setString('bg_alarm_title_$exactAlarmId', exactTitle);
          await prefs.setString('bg_alarm_body_$exactAlarmId', exactBody);

          try {
            await AndroidAlarmManager.oneShotAt(
              exactPrayerTz,
              exactAlarmId,
              _multiDayAlarmCallback,
              exact: true,
              wakeup: true,
              alarmClock: true,
              rescheduleOnReboot: true,
            );
            scheduledCount++;
          } catch (_) {
            try {
              await AndroidAlarmManager.oneShotAt(
                exactPrayerTz,
                exactAlarmId,
                _multiDayAlarmCallback,
                exact: true,
                wakeup: true,
                alarmClock: false,
                rescheduleOnReboot: true,
              );
              scheduledCount++;
            } catch (_) {}
          }
        }
      } catch (e) {
        debugPrint('[BGScheduler] Error scheduling $pName for $dateStr: $e');
      }
    }
  }

  debugPrint('[BGScheduler] Scheduled $scheduledCount multi-day notifications');
}

/// Callback for multi-day prayer alarms (fires from background).
@pragma('vm:entry-point')
Future<void> _multiDayAlarmCallback(int alarmId) async {
  WidgetsFlutterBinding.ensureInitialized();

  tz_data.initializeTimeZones();
  try {
    final deviceTzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(deviceTzInfo.identifier));
  } catch (_) {
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {}
  }

  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();

  final title = prefs.getString('bg_alarm_title_$alarmId') ?? 'Waktu Sholat';
  final body = prefs.getString('bg_alarm_body_$alarmId') ?? 'Telah memasuki waktu sholat.';

  debugPrint('[BGScheduler] Multi-day alarm fired: id=$alarmId, title=$title');

  // Show notification
  final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings settings = InitializationSettings(android: androidSettings);
  await plugin.initialize(settings);

  final androidPlugin = plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
      'prayer_adhan_alarm_v7',
      'Adzan & Waktu Sholat',
      description: 'Pengingat otomatis adzan ketika memasuki waktu sholat & buka puasa',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adzan'),
      enableVibration: true,
      enableLights: true,
    ));
  }

  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    'prayer_adhan_alarm_v7',
    'Adzan & Waktu Sholat',
    channelDescription: 'Pengingat otomatis adzan ketika memasuki waktu sholat & buka puasa',
    importance: Importance.max,
    priority: Priority.max,
    visibility: NotificationVisibility.public,
    category: AndroidNotificationCategory.alarm,
    fullScreenIntent: false,
    ticker: 'Pengingat Adzan',
    playSound: true,
    sound: const RawResourceAndroidNotificationSound('adzan'),
    enableVibration: true,
    enableLights: true,
    channelShowBadge: true,
    icon: '@mipmap/ic_launcher_round',
    largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    color: const Color(0xFF1B5E20),
    styleInformation: BigTextStyleInformation(body),
    autoCancel: true,
    ongoing: false,
    actions: const [
      AndroidNotificationAction(
        'dismiss_action',
        '✖ Tutup',
        cancelNotification: true,
        showsUserInterface: false,
      ),
    ],
  );

  final notifDetails = NotificationDetails(android: androidDetails);

  try {
    await plugin.show(alarmId, title, body, notifDetails);
    debugPrint('[BGScheduler] ✅ Notification shown: id=$alarmId');
  } catch (e) {
    debugPrint('[BGScheduler] ❌ Failed to show notification: $e');
  }

  // Try to play adhan sound via native service
  try {
    const platform = MethodChannel('com.ramadhan.app/adhan');
    await platform.invokeMethod('playAdhan');
    debugPrint('[BGScheduler] ✅ AdhanPlayerService started');
  } catch (e) {
    debugPrint('[BGScheduler] ⚠️ AdhanPlayerService failed (notification sound is fallback): $e');
  }

  // Clean up
  await prefs.remove('bg_alarm_title_$alarmId');
  await prefs.remove('bg_alarm_body_$alarmId');
}

/// =====================================================================
/// Top-level callback: App inactivity reminder.
/// Checks if user hasn't opened the app for 4+ days and sends a
/// gentle reminder notification with Islamic-themed messages.
/// =====================================================================
@pragma('vm:entry-point')
Future<void> backgroundInactivityReminderCallback() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz_data.initializeTimeZones();
  try {
    final deviceTzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(deviceTzInfo.identifier));
  } catch (_) {
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
    } catch (_) {}
  }

  final prefs = await SharedPreferences.getInstance();
  await prefs.reload();

  // Check if user has NOT opened the app for 4+ days
  final hasNotOpened = await PrayerCacheService.hasNotOpenedForDays(4);
  if (!hasNotOpened) {
    debugPrint('[BGScheduler] User opened app recently, no reminder needed');
    return;
  }

  // Check if master notifications are on
  final masterOn = prefs.getBool('notif_master') ?? true;
  if (!masterOn) return;

  // Check if we already sent a reminder recently (don't spam)
  final lastReminder = prefs.getString('last_inactivity_reminder');
  if (lastReminder != null) {
    try {
      final lastTime = DateTime.parse(lastReminder);
      if (DateTime.now().difference(lastTime).inDays < 2) {
        debugPrint('[BGScheduler] Reminder already sent recently, skipping');
        return;
      }
    } catch (_) {}
  }

  debugPrint('[BGScheduler] Sending inactivity reminder notification');

  // Pick a random Islamic-themed reminder message
  final lastOpened = await PrayerCacheService.getLastAppOpened();
  final daysSinceOpened = lastOpened != null
      ? DateTime.now().difference(lastOpened).inDays
      : 7;

  final messages = [
    {
      'title': '📖 Sudah lama tidak tadarus...',
      'body': 'Sudah $daysSinceOpened hari tidak membuka Al-Qur\'an. Yuk lanjutkan tadarus! Setiap huruf yang dibaca adalah pahala. "Sesungguhnya Al-Qur\'an ini memberi petunjuk kepada yang lebih lurus" (QS. Al-Isra: 9)',
    },
    {
      'title': '🤲 Bagaimana sholat kamu hari ini?',
      'body': 'Sudah $daysSinceOpened hari kami belum bertemu. Apakah sholat 5 waktu kamu sudah lengkap? Yuk buka app untuk cek jadwal sholat dan lanjutkan ibadahmu. "Sesungguhnya sholat itu mencegah dari perbuatan keji dan munkar" (QS. Al-Ankabut: 45)',
    },
    {
      'title': '🕌 Kami rindu kehadiranmu!',
      'body': 'Sudah $daysSinceOpened hari tidak membuka aplikasi. Jangan lupa sholat 5 waktu ya! Buka app untuk melihat jadwal sholat, membaca Al-Qur\'an, dan berdoa.',
    },
    {
      'title': '💚 Jangan lupa ibadah hari ini',
      'body': 'Hai, sudah $daysSinceOpened hari kamu tidak membuka aplikasi. Yuk kembali baca Al-Qur\'an dan jaga sholat 5 waktumu. "Bacalah Al-Qur\'an, sesungguhnya ia datang memberi syafa\'at pada hari kiamat" (HR. Muslim)',
    },
    {
      'title': '⏰ Pengingat Ibadah',
      'body': 'Assalamualaikum! Sudah $daysSinceOpened hari tidak membuka aplikasi. Jangan sampai terlewat waktu sholat dan tadarus Al-Qur\'an hari ini. Yuk buka aplikasi sekarang!',
    },
  ];

  // Pick message based on day modulo
  final msgIdx = daysSinceOpened % messages.length;
  final msg = messages[msgIdx];

  // Show reminder notification
  final FlutterLocalNotificationsPlugin plugin = FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings settings = InitializationSettings(android: androidSettings);
  await plugin.initialize(settings);

  final androidPlugin = plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin != null) {
    await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
      _reminderChannelId,
      _reminderChannelName,
      description: _reminderChannelDesc,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    ));
  }

  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    _reminderChannelId,
    _reminderChannelName,
    channelDescription: _reminderChannelDesc,
    importance: Importance.high,
    priority: Priority.high,
    visibility: NotificationVisibility.public,
    category: AndroidNotificationCategory.reminder,
    ticker: 'Pengingat Ibadah',
    playSound: true,
    enableVibration: true,
    enableLights: true,
    channelShowBadge: true,
    icon: '@mipmap/ic_launcher_round',
    largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
    color: const Color(0xFF1B5E20),
    styleInformation: BigTextStyleInformation(msg['body']!),
    autoCancel: true,
    ongoing: false,
  );

  final notifDetails = NotificationDetails(android: androidDetails);

  try {
    await plugin.show(
      _inactivityReminderAlarmId,
      msg['title'],
      msg['body'],
      notifDetails,
    );
    debugPrint('[BGScheduler] ✅ Inactivity reminder shown');

    // Record that we sent a reminder
    await prefs.setString('last_inactivity_reminder', DateTime.now().toIso8601String());
  } catch (e) {
    debugPrint('[BGScheduler] ❌ Failed to show inactivity reminder: $e');
  }
}

/// =====================================================================
/// BackgroundSchedulerService — called from the main isolate to set up
/// the recurring background alarms.
/// =====================================================================
class BackgroundSchedulerService {
  static final BackgroundSchedulerService _instance = BackgroundSchedulerService._internal();
  factory BackgroundSchedulerService() => _instance;
  BackgroundSchedulerService._internal();

  bool _isInitialized = false;

  /// Initialize and schedule the recurring background alarms.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      await AndroidAlarmManager.initialize();
      _isInitialized = true;
      debugPrint('[BGScheduler] Initialized');
    } catch (e) {
      debugPrint('[BGScheduler] Init error: $e');
    }
  }

  /// Schedule the daily auto-refresh alarm.
  /// This repeats approximately every 12 hours to ensure prayer schedules
  /// are always fresh and notifications are re-scheduled.
  Future<void> scheduleAutoRefresh() async {
    await init();

    try {
      // Cancel existing alarm first
      await AndroidAlarmManager.cancel(_dailyRefreshAlarmId);

      // Schedule repeating alarm every ~12 hours
      final result = await AndroidAlarmManager.periodic(
        const Duration(hours: 12),
        _dailyRefreshAlarmId,
        backgroundAutoRefreshCallback,
        exact: true,
        wakeup: true,
        rescheduleOnReboot: true,
      );

      debugPrint('[BGScheduler] Auto-refresh alarm scheduled (result=$result)');
    } catch (e) {
      debugPrint('[BGScheduler] Error scheduling auto-refresh: $e');

      // Fallback: try without exact
      try {
        final result = await AndroidAlarmManager.periodic(
          const Duration(hours: 12),
          _dailyRefreshAlarmId,
          backgroundAutoRefreshCallback,
          exact: false,
          wakeup: true,
          rescheduleOnReboot: true,
        );
        debugPrint('[BGScheduler] Auto-refresh alarm scheduled (inexact, result=$result)');
      } catch (e2) {
        debugPrint('[BGScheduler] All auto-refresh scheduling FAILED: $e2');
      }
    }
  }

  /// Schedule the inactivity reminder alarm.
  /// Repeats approximately every 24 hours.
  Future<void> scheduleInactivityReminder() async {
    await init();

    try {
      await AndroidAlarmManager.cancel(_inactivityReminderAlarmId);

      final result = await AndroidAlarmManager.periodic(
        const Duration(hours: 24),
        _inactivityReminderAlarmId,
        backgroundInactivityReminderCallback,
        exact: false,
        wakeup: true,
        rescheduleOnReboot: true,
      );

      debugPrint('[BGScheduler] Inactivity reminder alarm scheduled (result=$result)');
    } catch (e) {
      debugPrint('[BGScheduler] Error scheduling inactivity reminder: $e');
    }
  }

  /// Perform an initial download + cache of 7-day prayer schedules.
  /// Called from the main isolate (e.g., when app opens).
  Future<void> performInitialScheduleDownload({
    required String city,
    String country = ApiConstants.defaultCountry,
  }) async {
    debugPrint('[BGScheduler] Performing initial 7-day schedule download for $city');

    try {
      final client = http.Client();
      final now = DateTime.now();

      for (int i = 0; i < 7; i++) {
        final date = now.add(Duration(days: i));
        final dateKey = PrayerCacheService.getDateString(i);

        // Skip if already cached
        final existing = await PrayerCacheService.getPrayersForDate(dateKey);
        if (existing != null) continue;

        final dateStr = DateFormat('dd-MM-yyyy').format(date);

        List<Map<String, String>>? prayers;

        // Try Aladhan API by Address
        try {
          final addressQuery = Uri.encodeComponent('$city, $country');
          final url = Uri.parse(
            '${ApiConstants.aladhanBaseUrl}/timingsByAddress/$dateStr?address=$addressQuery&method=${ApiConstants.kemenagMethodId}',
          );

          final response = await client.get(url).timeout(const Duration(seconds: 8));
          if (response.statusCode == 200) {
            final Map<String, dynamic> body = jsonDecode(response.body);
            if (body['code'] == 200 && body['data']?['timings'] != null) {
              prayers = _extractTimingsMain(body['data']['timings']);
            }
          }
        } catch (_) {}

        // Fallback by city
        if (prayers == null) {
          try {
            final encodedCity = Uri.encodeComponent(city);
            final encodedCountry = Uri.encodeComponent(country);
            final url = Uri.parse(
              '${ApiConstants.aladhanBaseUrl}/timingsByCity/$dateStr?city=$encodedCity&country=$encodedCountry&method=${ApiConstants.kemenagMethodId}',
            );

            final response = await client.get(url).timeout(const Duration(seconds: 8));
            if (response.statusCode == 200) {
              final Map<String, dynamic> body = jsonDecode(response.body);
              if (body['code'] == 200 && body['data']?['timings'] != null) {
                prayers = _extractTimingsMain(body['data']['timings']);
              }
            }
          } catch (_) {}
        }

        // Fallback defaults
        prayers ??= [
          {'id': 'imsak', 'name': 'Imsak', 'time': '04:28'},
          {'id': 'subuh', 'name': 'Subuh', 'time': '04:38'},
          {'id': 'dzuhur', 'name': 'Dzuhur', 'time': '11:57'},
          {'id': 'ashar', 'name': 'Ashar', 'time': '15:13'},
          {'id': 'maghrib', 'name': 'Maghrib (Buka Puasa)', 'time': '18:02'},
          {'id': 'isya', 'name': 'Isya', 'time': '19:12'},
        ];

        await PrayerCacheService.savePrayersForDate(dateKey, prayers, city);

        // Small delay between API calls
        if (i < 6) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }

      client.close();
      await PrayerCacheService.recordScheduleRefresh();
      await PrayerCacheService.cleanupOldDates();

      debugPrint('[BGScheduler] Initial 7-day download complete');
    } catch (e) {
      debugPrint('[BGScheduler] Error in initial download: $e');
    }
  }

  /// Schedule multi-day notifications from cached data.
  /// This uses AndroidAlarmManager for maximum reliability even when app is killed.
  Future<void> scheduleMultiDayNotifications({required String cityName}) async {
    await init();

    final prefs = await SharedPreferences.getInstance();
    final masterOn = prefs.getBool('notif_master') ?? true;
    if (!masterOn) return;

    final imsakOn = prefs.getBool('notif_imsak') ?? prefs.getBool('is_imsak_enabled') ?? true;
    final subuhOn = prefs.getBool('notif_subuh') ?? true;
    final dzuhurOn = prefs.getBool('notif_dzuhur') ?? true;
    final asharOn = prefs.getBool('notif_ashar') ?? true;
    final maghribOn = prefs.getBool('notif_maghrib') ?? prefs.getBool('is_iftar_enabled') ?? true;
    final isyaOn = prefs.getBool('notif_isya') ?? true;
    final adhanGlobalOn = prefs.getBool('is_adhan_enabled') ?? true;

    // Initialize timezone
    tz_data.initializeTimeZones();
    try {
      final deviceTzInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(deviceTzInfo.identifier));
    } catch (_) {
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      } catch (_) {}
    }

    final location = tz.local;
    final nowTz = tz.TZDateTime.now(location);
    int scheduledCount = 0;

    // Cancel old multi-day alarms
    for (int id = _multiDayAlarmIdBase; id < _multiDayAlarmIdBase + (7 * _alarmsPerDay); id++) {
      try {
        await AndroidAlarmManager.cancel(id);
      } catch (_) {}
    }

    final cachedDates = await PrayerCacheService.getCachedDates();

    for (int dayIdx = 0; dayIdx < cachedDates.length && dayIdx < 7; dayIdx++) {
      final dateStr = cachedDates[dayIdx];
      final prayers = await PrayerCacheService.getPrayersForDate(dateStr);
      if (prayers == null) continue;

      final dateParts = dateStr.split('-');
      if (dateParts.length != 3) continue;
      final year = int.tryParse(dateParts[0]);
      final month = int.tryParse(dateParts[1]);
      final day = int.tryParse(dateParts[2]);
      if (year == null || month == null || day == null) continue;

      for (int i = 0; i < prayers.length; i++) {
        final prayer = prayers[i];
        final pId = (prayer['id'] ?? '').toLowerCase();
        final pName = prayer['name'] ?? '';
        final pTime = prayer['time'] ?? '';

        // Check toggle settings
        if (pId.contains('imsak') && !imsakOn) continue;
        if (pId.contains('subuh') && (!subuhOn || !adhanGlobalOn)) continue;
        if (pId.contains('dzuhur') && (!dzuhurOn || !adhanGlobalOn)) continue;
        if (pId.contains('ashar') && (!asharOn || !adhanGlobalOn)) continue;
        if (pId.contains('maghrib') && !maghribOn) continue;
        if (pId.contains('isya') && (!isyaOn || !adhanGlobalOn)) continue;

        try {
          final timeClean = pTime.replaceAll(RegExp(r'[^\d:]'), '').trim();
          final parts = timeClean.split(':');
          if (parts.length < 2) continue;

          final hour = int.tryParse(parts[0]);
          final minute = int.tryParse(parts[1]);
          if (hour == null || minute == null) continue;

          var exactPrayerTz = tz.TZDateTime(location, year, month, day, hour, minute);
          if (exactPrayerTz.isBefore(nowTz)) continue;

          final oneMinBeforeTz = exactPrayerTz.subtract(const Duration(minutes: 1));

          String preTitle, preBody, exactTitle, exactBody;

          if (pId == 'imsak') {
            preTitle = 'Waktu Imsak 1 Menit Lagi';
            preBody = 'Pengingat ($cityName): 1 menit lagi memasuki waktu Imsak.';
            exactTitle = 'Waktu Imsak Telah Tiba';
            exactBody = 'Telah memasuki waktu Imsak untuk wilayah $cityName dan sekitarnya. Segera selesaikan sahur.';
          } else if (pId == 'maghrib') {
            preTitle = 'Buka Puasa 1 Menit Lagi';
            preBody = 'Pengingat ($cityName): 1 menit lagi memasuki waktu Maghrib & berbuka puasa.';
            exactTitle = 'Waktu Buka Puasa Telah Tiba!';
            exactBody = 'Selamat berbuka puasa untuk wilayah $cityName dan sekitarnya. Selamat menunaikan ibadah sholat Maghrib.';
          } else {
            preTitle = 'Waktu Sholat $pName 1 Menit Lagi';
            preBody = 'Pengingat ($cityName): 1 menit lagi memasuki waktu sholat $pName.';
            exactTitle = 'Waktu Sholat $pName Telah Tiba';
            exactBody = 'Telah memasuki waktu sholat $pName untuk wilayah $cityName dan sekitarnya. Mari bersiap wudhu dan sholat.';
          }

          final baseId = _multiDayAlarmIdBase + (dayIdx * _alarmsPerDay) + (i * 2);

          // 1 minute before
          if (oneMinBeforeTz.isAfter(nowTz)) {
            final preAlarmId = baseId;
            await prefs.setString('bg_alarm_title_$preAlarmId', preTitle);
            await prefs.setString('bg_alarm_body_$preAlarmId', preBody);

            try {
              await AndroidAlarmManager.oneShotAt(
                oneMinBeforeTz,
                preAlarmId,
                _multiDayAlarmCallbackFromMain,
                exact: true,
                wakeup: true,
                alarmClock: true,
                rescheduleOnReboot: true,
              );
              scheduledCount++;
            } catch (_) {
              try {
                await AndroidAlarmManager.oneShotAt(
                  oneMinBeforeTz,
                  preAlarmId,
                  _multiDayAlarmCallbackFromMain,
                  exact: true,
                  wakeup: true,
                  alarmClock: false,
                  rescheduleOnReboot: true,
                );
                scheduledCount++;
              } catch (_) {}
            }
          }

          // Exact prayer time
          if (exactPrayerTz.isAfter(nowTz)) {
            final exactAlarmId = baseId + 1;
            await prefs.setString('bg_alarm_title_$exactAlarmId', exactTitle);
            await prefs.setString('bg_alarm_body_$exactAlarmId', exactBody);

            try {
              await AndroidAlarmManager.oneShotAt(
                exactPrayerTz,
                exactAlarmId,
                _multiDayAlarmCallbackFromMain,
                exact: true,
                wakeup: true,
                alarmClock: true,
                rescheduleOnReboot: true,
              );
              scheduledCount++;
            } catch (_) {
              try {
                await AndroidAlarmManager.oneShotAt(
                  exactPrayerTz,
                  exactAlarmId,
                  _multiDayAlarmCallbackFromMain,
                  exact: true,
                  wakeup: true,
                  alarmClock: false,
                  rescheduleOnReboot: true,
                );
                scheduledCount++;
              } catch (_) {}
            }
          }
        } catch (e) {
          debugPrint('[BGScheduler] Error scheduling $pName: $e');
        }
      }
    }

    debugPrint('[BGScheduler] Scheduled $scheduledCount multi-day alarms from main isolate');
  }

  /// Helper to extract timings (usable from main isolate).
  static List<Map<String, String>> _extractTimingsMain(Map<String, dynamic> t) {
    String cleanTime(dynamic val) {
      if (val == null) return '00:00';
      final str = val.toString();
      return str.length >= 5 ? str.substring(0, 5) : str;
    }

    return [
      {'id': 'imsak', 'name': 'Imsak', 'time': cleanTime(t['Imsak'])},
      {'id': 'subuh', 'name': 'Subuh', 'time': cleanTime(t['Fajr'])},
      {'id': 'dzuhur', 'name': 'Dzuhur', 'time': cleanTime(t['Dhuhr'])},
      {'id': 'ashar', 'name': 'Ashar', 'time': cleanTime(t['Asr'])},
      {'id': 'maghrib', 'name': 'Maghrib (Buka Puasa)', 'time': cleanTime(t['Maghrib'])},
      {'id': 'isya', 'name': 'Isya', 'time': cleanTime(t['Isha'])},
    ];
  }
}

/// Top-level static callback for multi-day alarms (must be top-level for AndroidAlarmManager).
@pragma('vm:entry-point')
Future<void> _multiDayAlarmCallbackFromMain(int alarmId) async {
  // Delegate to the same callback logic
  await _multiDayAlarmCallback(alarmId);
}
