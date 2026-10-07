import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:vehicle_maintenance_tracker/models/driver_license.dart';
import 'package:vehicle_maintenance_tracker/models/maintenance_schedule.dart';
import 'package:vehicle_maintenance_tracker/services/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Android reconciliation schedules four license alerts and cancels old ones',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      AndroidFlutterLocalNotificationsPlugin.registerWith();
      tz_data.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Manila'));
      const channel = MethodChannel(
        'dexterous.com/flutter/local_notifications',
      );
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return null;
          });
      addTearDown(() {
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null);
      });
      final service = NotificationService()..ready = true;
      final now = tz.TZDateTime.now(tz.local);
      final expiry = DateTime(now.year, now.month, now.day + 90);
      final license = DriverLicense(validityYears: 10, expiresOn: expiry);
      final schedule = MaintenanceSchedule(
        id: 7,
        vehicleId: 1,
        type: 'PMS',
        date: expiry,
        odometer: 1000,
        reminder: true,
      );
      await service.synchronize([schedule], true, driverLicense: license);
      expect(calls.first.method, 'cancelAll');
      final alerts = calls
          .where((call) => call.method == 'zonedSchedule')
          .toList();
      expect(alerts.map((c) => c.arguments['id']), [
        -1060,
        -1030,
        -1007,
        -1000,
        7,
      ]);
      for (var i = 0; i < 4; i++) {
        final expected = DateTime(
          expiry.year,
          expiry.month,
          expiry.day - [60, 30, 7, 0][i],
          9,
        );
        expect(
          DateTime.parse(alerts[i].arguments['scheduledDateTime'] as String),
          expected,
        );
      }
      calls.clear();
      await service.synchronize([schedule], true);
      expect(calls.map((c) => c.method), ['cancelAll', 'zonedSchedule']);
      calls.clear();
      await service.synchronize([schedule], false, driverLicense: license);
      expect(calls.map((c) => c.method), ['cancelAll']);
      calls.clear();
      await service.synchronize(
        [],
        true,
        driverLicense: DriverLicense(
          validityYears: 5,
          expiresOn: DateTime(now.year, now.month, now.day - 1),
        ),
      );
      expect(calls.map((c) => c.method), ['cancelAll']);
    },
  );
}
