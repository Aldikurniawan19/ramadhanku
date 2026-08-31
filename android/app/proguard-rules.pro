# Flutter Local Notifications - keep scheduled notification receivers
-keep class com.dexterous.flutterlocalnotifications.** { *; }

# Keep Gson models used by flutter_local_notifications
-keepattributes Signature
-keepattributes *Annotation*

# Prevent stripping of notification-related classes
-keep class android.app.AlarmManager { *; }
-keep class android.app.NotificationManager { *; }
-keep class android.app.NotificationChannel { *; }

# android_alarm_manager_plus - keep background alarm service & receivers
-keep class dev.fluttercommunity.plus.androidalarmmanager.** { *; }
