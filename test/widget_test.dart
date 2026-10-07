import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vehicle_maintenance_tracker/database/database_helper.dart';
import 'package:vehicle_maintenance_tracker/main.dart';
import 'package:vehicle_maintenance_tracker/models/driver_license.dart';
import 'package:vehicle_maintenance_tracker/models/maintenance_schedule.dart';
import 'package:vehicle_maintenance_tracker/providers/maintenance_provider.dart';
import 'package:vehicle_maintenance_tracker/services/notification_service.dart';

class SilentNotifications extends NotificationService {
  @override
  Future<void> synchronize(
    List<MaintenanceSchedule> schedules,
    bool enabled, {
    Map<int, String> vehicleNames = const {},
    DriverLicense? driverLicense,
  }) async {}
}

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  testWidgets('empty state, navigation and required vehicle fields', (
    tester,
  ) async {
    final db = DatabaseHelper(databasePath: inMemoryDatabasePath);
    final provider = MaintenanceProvider(db, SilentNotifications());
    await tester.runAsync(provider.load);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: provider,
        child: const VehicleMaintenanceApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('A little care. A longer journey.'), findsOneWidget);
    await tester.tap(find.text('Add your vehicle'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Save vehicle'),
      300,
      scrollable: find
          .descendant(of: find.byType(Form), matching: find.byType(Scrollable))
          .first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save vehicle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save vehicle'));
    await tester.pumpAndSettle();
    expect(find.text('This field is required.'), findsWidgets);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Expenses'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('No expenses yet'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('No expenses yet'), findsOneWidget);
    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Preferences'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    provider.dispose();
    await tester.runAsync(db.close);
  });
  testWidgets(
    'populated phone layouts display dashboard, history and expenses',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = DatabaseHelper(databasePath: inMemoryDatabasePath);
      final provider = MaintenanceProvider(db, SilentNotifications());
      await tester.runAsync(() async {
        await db.addSampleData();
        await provider.load();
      });
      final boundary = GlobalKey();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: provider,
          child: RepaintBoundary(
            key: boundary,
            child: const VehicleMaintenanceApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Family Car'), findsOneWidget);
      expect(find.text('48,500 km'), findsOneWidget);
      await tester.tap(find.text('Maintenance'));
      await tester.pumpAndSettle();
      expect(find.text('Service history'), findsOneWidget);
      await tester.tap(find.text('Expenses'));
      await tester.pumpAndSettle();
      expect(find.text('\u20B112,500.00'), findsWidgets);
      await tester.tap(find.text('Garage'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Update odometer'),
        300,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Update odometer'), findsOneWidget);
      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Preferences'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      provider.dispose();
      await tester.runAsync(db.close);
    },
  );
}
