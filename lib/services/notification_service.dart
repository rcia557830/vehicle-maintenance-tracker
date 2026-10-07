import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/maintenance_schedule.dart';
import '../models/driver_license.dart';

class NotificationService {
  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  final plugin = FlutterLocalNotificationsPlugin();
  bool ready = false;
  Future<void> _pending = Future.value();
  Future<void> initialize() async {
    if (!supported) return;
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
      ),
    );
    ready = true;
  }

  Future<bool> requestPermission() async {
    if (!supported) return false;
    if (!ready) await initialize();
    return await plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.requestNotificationsPermission() ??
        false;
  }

  Future<void> synchronize(
    List<MaintenanceSchedule> schedules,
    bool enabled, {
    Map<int, String> vehicleNames = const {},
    DriverLicense? driverLicense,
  }) {
    // Serializing reconciliations ensures logout cancellation runs after any
    // pending schedule update, including a slow platform notification call.
    final operation = _pending
        .catchError((Object _) {})
        .then(
          (_) => _synchronize(
            schedules,
            enabled,
            vehicleNames: vehicleNames,
            driverLicense: driverLicense,
          ),
        );
    _pending = operation;
    return operation;
  }

  Future<void> _synchronize(
    List<MaintenanceSchedule> schedules,
    bool enabled, {
    Map<int, String> vehicleNames = const {},
    DriverLicense? driverLicense,
  }) async {
    if (!supported) return;
    if (!ready) await initialize();
    await plugin.cancelAll();
    if (!enabled) return;
    if (driverLicense != null) {
      for (final days in [60, 30, 7, 0]) {
        final expiry = driverLicense.expiresOn;
        // Subtract calendar days, then construct 9 AM in the device zone.
        final day = DateTime.utc(expiry.year, expiry.month, expiry.day - days);
        final when = tz.TZDateTime(tz.local, day.year, day.month, day.day, 9);
        if (!when.isAfter(tz.TZDateTime.now(tz.local))) continue;
        await plugin.zonedSchedule(
          // Service rows have positive IDs; reserve negative IDs for licenses.
          id: -1000 - days,
          title: 'LTO license expiry reminder',
          body: days == 0
              ? 'Your saved license expiry date is today. Update it after renewal.'
              : 'Your saved license expiry date is in $days days. Plan your renewal.',
          scheduledDate: when,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'license_reminders',
              'License expiry reminders',
              channelDescription:
                  'Reminders before your saved LTO license expiry',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      }
    }
    for (final s in schedules.where((s) => s.reminder && !s.completed)) {
      final when = tz.TZDateTime(
        tz.local,
        s.date.year,
        s.date.month,
        s.date.day,
        9,
      );
      if (!when.isAfter(tz.TZDateTime.now(tz.local))) continue;
      await plugin.zonedSchedule(
        id: s.id!,
        title: 'Vehicle Maintenance Reminder',
        body:
            '${vehicleNames[s.vehicleId] ?? 'Your vehicle'}: ${s.type} is scheduled for today.',
        scheduledDate: when,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'maintenance_reminders',
            'Maintenance reminders',
            channelDescription: 'Reminders for scheduled vehicle services',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
