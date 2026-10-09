import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vehicle_maintenance_tracker/database/database_helper.dart';
import 'package:vehicle_maintenance_tracker/providers/maintenance_provider.dart';
import 'package:vehicle_maintenance_tracker/screens/add_maintenance_screen.dart';
import 'package:vehicle_maintenance_tracker/screens/maintenance_history_screen.dart';
import 'package:vehicle_maintenance_tracker/screens/maintenance_schedule_screen.dart';
import 'package:vehicle_maintenance_tracker/theme/app_theme.dart';
import 'package:vehicle_maintenance_tracker/widgets/date_picker_field.dart';

import 'ui_capture.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await loadCaptureFonts();
  });
  for (final size in [const Size(360, 800), const Size(1280, 900)]) {
    testWidgets('service date, save, details and edit at ${size.width}px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = DatabaseHelper(databasePath: inMemoryDatabasePath);
      final p = MaintenanceProvider(db, NoPlatformNotifications());
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        p.dispose();
        await tester.runAsync(db.close);
      });
      await tester.runAsync(() async {
        await db.addSampleData();
        await p.load();
      });
      final boundary = GlobalKey();
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: p,
          child: RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              navigatorKey: navigator,
              theme: buildAppTheme(),
              home: const Scaffold(body: MaintenanceHistoryScreen()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> show(Widget screen) async {
        navigator.currentState!.push(
          MaterialPageRoute<void>(builder: (_) => screen),
        );
        await tester.pumpAndSettle();
      }

      Future<void> reveal(Finder finder) async {
        await tester.scrollUntilVisible(
          finder,
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
      }

      Finder field(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
      );
      Future<void> settle(bool Function() done) async {
        for (var i = 0; i < 100 && !done(); i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump();
        }
        await tester.pumpAndSettle();
        expect(done(), isTrue);
      }

      await show(const AddMaintenanceScreen());
      await captureUi(tester, boundary, 'service_form_${size.width.toInt()}');
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Oil Change').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DatePickerField));
      await tester.pumpAndSettle();
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      await reveal(field('Cost (PHP)'));
      await tester.enterText(field('Cost (PHP)'), '1250');
      await tester.enterText(
        field('Service provider / shop (optional)'),
        'Presentation Garage',
      );
      await reveal(find.text('Save record'));
      await tester.tap(find.text('Save record'));
      await settle(() => p.records.any((r) => r.shop == 'Presentation Garage'));
      final record = p.records.firstWhere(
        (r) => r.shop == 'Presentation Garage',
      );
      expect(record.cost, 1250);
      await show(MaintenanceDetailScreen(recordId: record.id!));
      await captureUi(
        tester,
        boundary,
        'service_details_${size.width.toInt()}',
      );
      expect(find.text('Completed'), findsOneWidget);
      await reveal(find.text('Edit record'));
      await tester.tap(find.text('Edit record'));
      await tester.pumpAndSettle();
      await reveal(field('Cost (PHP)'));
      await tester.enterText(field('Cost (PHP)'), '1400');
      await reveal(find.text('Save record'));
      await tester.tap(find.text('Save record'));
      await settle(
        () => p.records.firstWhere((r) => r.id == record.id).cost == 1400,
      );
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      await show(const MaintenanceScheduleScreen());
      await captureUi(tester, boundary, 'schedule_${size.width.toInt()}');
      expect(find.byTooltip('Schedule options'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  }
}
