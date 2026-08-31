import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// =====================================================================
/// Background Alarm Service
///
/// Uses android_alarm_manager_plus to schedule alarms that fire even when:
///   - App is in background
///   - Screen is off (Doze mode)
///   - App has been swiped from recent apps
///
/// Each alarm runs a Dart callback in a SEPARATE background isolate.
/// The callback initializes flutter_local_notifications independently
/// and shows the notification.
///
/// Sound playback:
///   The notification itself is SILENT (playSound: false).
///   Adhan sound is played by native AdhanPlayerService via Android Intent,
///   which uses MediaPlayer with USAGE_ALARM to bypass DND and play
///   the full 30-second adhan even when screen is off.
///
/// This is a BACKUP layer on top of flutter_local_notifications'
/// zonedSchedule which already works in foreground.
/// =====================================================================

/// Alarm ID ranges:
///   1000-1099 = 1-minute-before prayer alarms
///   1100-1199 = exact prayer time alarms
const int _preAlarmIdBase = 1000;
const int _exactAlarmIdBase = 1100;

// SharedPreferences keys for passing prayer data to background isolate
const String _keyPrayerCount = 'bg_alarm_prayer_count';
const String _keyPrayerCity = 'bg_alarm_prayer_city';

/// Top-level callback for android_alarm_manager_plus.
/// MUST be top-level or static; MUST have @pragma annotation.
/// This runs in a SEPARATE background isolate — no shared memory with main app.
@pragma('vm:entry-point')
Future<void> backgroundAlarmCallback() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone in this isolate
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
  // Force reload to get latest data written by main isolate
  await prefs.reload();

  final alarmId = prefs.getInt('bg_alarm_current_id');
  if (alarmId == null) {
    debugPrint('[BGAlarm] No alarm ID found in prefs');
    return;
  }

  final title = prefs.getString('bg_alarm_title_$alarmId') ?? 'Waktu Sholat';
  final body = prefs.getString('bg_alarm_body_$alarmId') ?? 'Telah memasuki waktu sholat.';

  debugPrint('[BGAlarm] Callback fired for alarmId=$alarmId');

  await _showNotificationFromBackground(
    id: alarmId,
    title: title,
    body: body,
  );

  // Clean up this alarm's data from prefs
  await prefs.remove('bg_alarm_title_$alarmId');
  await prefs.remove('bg_alarm_body_$alarmId');
  await prefs.remove('bg_alarm_current_id');
}

/// Individual alarm callback — each alarm ID gets its own callback registration
/// via SharedPreferences. The callback reads the alarm ID from SharedPreferences.
@pragma('vm:entry-point')
Future<void> backgroundAlarmCallbackWithId(int alarmId) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone in this isolate
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

  debugPrint('[BGAlarm] Callback fired for alarmId=$alarmId, title=$title');

  await _showNotificationFromBackground(
    id: alarmId,
    title: title,
    body: body,
  );

  // Clean up this alarm's data
  await prefs.remove('bg_alarm_title_$alarmId');
  await prefs.remove('bg_alarm_body_$alarmId');
}

/// Show notification from background isolate.
/// Initializes flutter_local_notifications independently in this isolate.
///
/// Strategy for adzan sound in background:
///   1. The notification itself uses the adzan sound file via notification channel
///      → This is the RELIABLE fallback that always works even in Doze/screen-off
///   2. We also try to start the native AdhanPlayerService via MethodChannel
///      → If successful, the foreground service plays the full-length adzan
///      → If it fails (common in background isolates), the notification sound
///        from step 1 still plays as a shorter but guaranteed fallback
Future<void> _showNotificationFromBackground({
  required int id,
  required String title,
  required String body,
}) async {
  // =====================================================================
  // v7 Channel: WITH adzan sound from notification channel as fallback.
  // This ensures adzan plays even if MethodChannel to AdhanPlayerService
  // fails from the background isolate.
  //
  // Sound file: res/raw/adzan.mp3 (copied from assets/audio/adzan.mp3)
  // =====================================================================
  const String channelId = 'prayer_adhan_alarm_v7';
  const String channelName = 'Adzan & Waktu Sholat';
  const String channelDesc =
      'Pengingat otomatis adzan ketika memasuki waktu sholat & buka puasa';

  final FlutterLocalNotificationsPlugin plugin =
      FlutterLocalNotificationsPlugin();

  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings settings = InitializationSettings(
    android: androidSettings,
  );

  await plugin.initialize(settings);

  // Ensure the notification channel exists in this isolate
  final androidPlugin = plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin != null) {
    // v7: Channel WITH adzan sound — reliable fallback for background
    await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDesc,
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('adzan'),
      enableVibration: true,
      enableLights: true,
    ));

    // Also clean up old v6 channel
    try {
      await androidPlugin.deleteNotificationChannel('prayer_adhan_alarm_v6');
    } catch (_) {}
  }

  final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    channelId,
    channelName,
    channelDescription: channelDesc,
    importance: Importance.max,
    priority: Priority.max,
    visibility: NotificationVisibility.public,
    category: AndroidNotificationCategory.alarm,
    fullScreenIntent: false,
    ticker: 'Pengingat Adzan',
    // v7: Play adzan sound from notification channel as reliable fallback
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

  final NotificationDetails notifDetails = NotificationDetails(
    android: androidDetails,
  );

  try {
    await plugin.show(id, title, body, notifDetails);
    debugPrint('[BGAlarm] ✅ Notification shown (with adzan sound): id=$id, title=$title');
  } catch (e) {
    debugPrint('[BGAlarm] ❌ Failed to show notification: $e');
  }

  // =====================================================================
  // Additionally try to start AdhanPlayerService for full-length playback.
  // If this works, the foreground service will play the complete adzan.
  // If it fails, the notification sound above is already playing as fallback.
  // =====================================================================
  try {
    final platform = MethodChannel('com.ramadhan.app/adhan');
    await platform.invokeMethod('playAdhan');
    debugPrint('[BGAlarm] ✅ AdhanPlayerService started via MethodChannel (full-length)');
  } catch (e) {
    debugPrint('[BGAlarm] ⚠️ MethodChannel playAdhan failed (notification sound is fallback): $e');
  }
}

/// Service class for scheduling background alarms from the main isolate.
class BackgroundAlarmService {
  static final BackgroundAlarmService _instance = BackgroundAlarmService._internal();
  factory BackgroundAlarmService() => _instance;
  BackgroundAlarmService._internal();

  bool _isInitialized = false;

  /// Initialize AndroidAlarmManager. Call once in main().
  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await AndroidAlarmManager.initialize();
      _isInitialized = true;
      debugPrint('[BGAlarm] AndroidAlarmManager initialized');
    } catch (e) {
      debugPrint('[BGAlarm] AndroidAlarmManager init error: $e');
    }
  }

  /// Cancel all background alarms.
  Future<void> cancelAll() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keyPrayerCount) ?? 0;

    // Cancel pre-alarm and exact alarm for each prayer
    for (int i = 0; i < count; i++) {
      try {
        await AndroidAlarmManager.cancel(_preAlarmIdBase + i);
      } catch (_) {}
      try {
        await AndroidAlarmManager.cancel(_exactAlarmIdBase + i);
      } catch (_) {}
    }
    debugPrint('[BGAlarm] Cancelled all background alarms (count=$count)');
  }

  /// Schedule background alarms for all prayer times.
  /// Stores prayer metadata in SharedPreferences so the background
  /// isolate can read it when the alarm fires.
  Future<void> scheduleAllBackgroundAlarms({
    required List<Map<String, String>> prayers,
    required String cityName,
    bool? isAdhanEnabled,
    bool? isIftarEnabled,
    bool? isImsakEnabled,
  }) async {
    await init();
    await cancelAll();

    final prefs = await SharedPreferences.getInstance();
    final masterOn = prefs.getBool('notif_master') ?? true;
    if (!masterOn) {
      debugPrint('[BGAlarm] Master notification OFF — skipping');
      return;
    }

    final imsakOn = isImsakEnabled ?? prefs.getBool('notif_imsak') ?? prefs.getBool('is_imsak_enabled') ?? true;
    final subuhOn = prefs.getBool('notif_subuh') ?? true;
    final dzuhurOn = prefs.getBool('notif_dzuhur') ?? true;
    final asharOn = prefs.getBool('notif_ashar') ?? true;
    final maghribOn = isIftarEnabled ?? prefs.getBool('notif_maghrib') ?? prefs.getBool('is_iftar_enabled') ?? true;
    final isyaOn = prefs.getBool('notif_isya') ?? true;
    final adhanGlobalOn = isAdhanEnabled ?? prefs.getBool('is_adhan_enabled') ?? true;

    // Store prayer count for cleanup
    await prefs.setInt(_keyPrayerCount, prayers.length);
    await prefs.setString(_keyPrayerCity, cityName);

    final location = tz.local;
    final nowTz = tz.TZDateTime.now(location);

    int scheduledCount = 0;

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

        // Calculate exact prayer time
        var exactPrayerTz = tz.TZDateTime(
          location,
          nowTz.year,
          nowTz.month,
          nowTz.day,
          hour,
          minute,
        );

        if (exactPrayerTz.isBefore(nowTz)) {
          exactPrayerTz = exactPrayerTz.add(const Duration(days: 1));
        }

        // 1 minute before prayer time
        final oneMinBeforeTz = exactPrayerTz.subtract(const Duration(minutes: 1));

        // Prepare titles & bodies (same as notification_service.dart)
        String preTitle;
        String preBody;
        String exactTitle;
        String exactBody;

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

        // --- A. Schedule 1 MINUTE BEFORE via AndroidAlarmManager ---
        final preAlarmId = _preAlarmIdBase + i;
        if (oneMinBeforeTz.isAfter(nowTz)) {
          // Store notification data for background isolate
          await prefs.setString('bg_alarm_title_$preAlarmId', preTitle);
          await prefs.setString('bg_alarm_body_$preAlarmId', preBody);

          final scheduled = await _scheduleOneShot(
            id: preAlarmId,
            dateTime: oneMinBeforeTz,
          );
          if (scheduled) scheduledCount++;
        }

        // --- B. Schedule EXACT PRAYER TIME via AndroidAlarmManager ---
        final exactAlarmId = _exactAlarmIdBase + i;
        if (exactPrayerTz.isAfter(nowTz)) {
          await prefs.setString('bg_alarm_title_$exactAlarmId', exactTitle);
          await prefs.setString('bg_alarm_body_$exactAlarmId', exactBody);

          final scheduled = await _scheduleOneShot(
            id: exactAlarmId,
            dateTime: exactPrayerTz,
          );
          if (scheduled) scheduledCount++;
        }
      } catch (e) {
        debugPrint('[BGAlarm] Error scheduling $pName: $e');
      }
    }

    debugPrint('[BGAlarm] === Schedule complete: $scheduledCount background alarms ===');
  }

  /// Schedule a single one-shot alarm using AndroidAlarmManager.
  Future<bool> _scheduleOneShot({
    required int id,
    required tz.TZDateTime dateTime,
  }) async {
    try {
      // Use alarmClock: true for highest priority — this tells Android
      // to treat this as an alarm clock, giving it immunity from Doze
      // and battery optimization.
      final result = await AndroidAlarmManager.oneShotAt(
        dateTime,
        id,
        backgroundAlarmCallbackWithId,
        exact: true,
        wakeup: true,
        alarmClock: true,
        rescheduleOnReboot: true,
      );
      debugPrint('[BGAlarm]   ✅ Scheduled alarm id=$id at $dateTime (result=$result)');
      return result;
    } catch (e) {
      debugPrint('[BGAlarm]   ⚠️ alarmClock failed id=$id: $e — trying without alarmClock');
    }

    // Fallback: without alarmClock but still exact + wakeup
    try {
      final result = await AndroidAlarmManager.oneShotAt(
        dateTime,
        id,
        backgroundAlarmCallbackWithId,
        exact: true,
        wakeup: true,
        alarmClock: false,
        rescheduleOnReboot: true,
      );
      debugPrint('[BGAlarm]   ✅ Scheduled alarm (no-alarmClock) id=$id at $dateTime (result=$result)');
      return result;
    } catch (e2) {
      debugPrint('[BGAlarm]   ❌ All schedule attempts FAILED for id=$id: $e2');
      return false;
    }
  }

  /// Helper to convert PrayerItem list to serializable maps
  /// Call this from main isolate before scheduling
  static List<Map<String, String>> prayerItemsToMaps(List<dynamic> prayers) {
    return prayers.map((p) => {
      'id': p.id.toString(),
      'name': p.name.toString(),
      'time': p.time.toString(),
    }).toList();
  }
}
