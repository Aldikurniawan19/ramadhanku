import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'core/theme/app_theme.dart';
import 'data/services/firebase_service.dart';
import 'data/services/notification_service.dart';
import 'data/services/background_alarm_service.dart';
import 'data/services/background_scheduler_service.dart';
import 'data/services/prayer_cache_service.dart';
import 'providers/prayer_provider.dart';
import 'providers/quran_provider.dart';
import 'providers/doa_provider.dart';
import 'providers/fasting_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/hadits_provider.dart';
import 'features/splash/screens/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // FIX #6: Initialize timezone data EARLY, before any service uses it.
  // This ensures tz.local is correct when NotificationProvider starts scheduling.
  tz.initializeTimeZones();

  try {
    await initializeDateFormatting('id_ID', null);
  } catch (_) {}

  try {
    await FirebaseService.initializeFirebase();
  } catch (_) {}

  // Pre-initialize notification service so timezone & channels are ready
  try {
    await NotificationService().init();
  } catch (_) {}

  // Initialize AndroidAlarmManager for background alarm scheduling
  try {
    await AndroidAlarmManager.initialize();
    await BackgroundAlarmService().init();
  } catch (_) {}

  // Initialize background scheduler for auto-refresh & inactivity reminders
  try {
    final bgScheduler = BackgroundSchedulerService();
    await bgScheduler.init();

    // Schedule recurring background auto-refresh (every 12 hours)
    // This ensures prayer schedules are always fresh even if app isn't opened
    await bgScheduler.scheduleAutoRefresh();

    // Schedule inactivity reminder (checks every 24 hours)
    // Sends a gentle reminder if user hasn't opened app for 4+ days
    await bgScheduler.scheduleInactivityReminder();

    debugPrint('[main] Background scheduler initialized and alarms scheduled');
  } catch (e) {
    debugPrint('[main] Background scheduler init error: $e');
  }

  // Record that the user opened the app
  try {
    await PrayerCacheService.recordAppOpened();
  } catch (_) {}

  runApp(const RamadanApp());
}

class RamadanApp extends StatelessWidget {
  const RamadanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PrayerProvider()),
        ChangeNotifierProvider(create: (_) => QuranProvider()),
        ChangeNotifierProvider(create: (_) => DoaProvider()),
        ChangeNotifierProvider(create: (_) => FastingProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
        ChangeNotifierProvider(create: (_) => HaditsProvider()),
      ],
      child: MaterialApp(
        title: 'Aplikasi Ramadhan',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
