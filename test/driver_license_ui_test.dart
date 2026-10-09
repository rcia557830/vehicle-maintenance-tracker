import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vehicle_maintenance_tracker/database/database_helper.dart';
import 'package:vehicle_maintenance_tracker/providers/maintenance_provider.dart';
import 'package:vehicle_maintenance_tracker/screens/dashboard_screen.dart';
import 'package:vehicle_maintenance_tracker/screens/driver_license_screen.dart';
import 'package:vehicle_maintenance_tracker/theme/app_theme.dart';

import 'ui_capture.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await loadCaptureFonts();
  });
  for (final size in [const Size(360, 800), const Size(1280, 900)]) {
    testWidgets(
      'license add, renew and remove without vehicles at ${size.width}px',
      (tester) async {
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
        await tester.runAsync(p.load);
        final boundary = GlobalKey();
        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: p,
            child: RepaintBoundary(
              key: boundary,
              child: MaterialApp(
                debugShowCheckedModeBanner: false,
                theme: buildAppTheme(),
                home: const Scaffold(body: DashboardScreen()),
              ),
            ),
          ),
        );
        Future<void> tapText(String text) async {
          final target = find.text(text);
          if (target.evaluate().isEmpty) {
            await tester.scrollUntilVisible(
              target,
              180,
              scrollable: find
                  .descendant(
                    of: find.byType(
                      find.byType(DriverLicenseScreen).evaluate().isEmpty
                          ? DashboardScreen
                          : DriverLicenseScreen,
                    ),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            );
          }
          await tester.ensureVisible(target);
          await tester.pumpAndSettle();
          await tester.tap(target);
          // Database work runs outside the test clock. Let finishSave wait for
          // persistence before settling the animated saving indicator.
          if (text == 'Save license' || text == 'Delete') {
            await tester.pump();
          } else {
            await tester.pumpAndSettle();
          }
        }

        Future<void> finishSave() async {
          for (
            var i = 0;
            i < 100 && find.byType(DriverLicenseScreen).evaluate().isNotEmpty;
            i++
          ) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 20)),
            );
            await tester.pump();
          }
          await tester.pumpAndSettle();
          expect(find.byType(DriverLicenseScreen), findsNothing);
          expect(tester.takeException(), isNull);
        }

        await tester.pumpAndSettle();
        await tapText('Add LTO license');
        await tapText('Save license');
        expect(find.text('Select your license expiry date.'), findsOneWidget);
        final dateField = find.byKey(const ValueKey('license-expiry'));
        await tester.ensureVisible(dateField);
        await tester.tap(dateField);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Switch to input'));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.descendant(
            of: find.byType(DatePickerDialog),
            matching: find.byType(TextField),
          ),
          '10/01/2030',
        );
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();
        await tapText('Save license');
        await finishSave();
        expect(p.driverLicense!.expiresOn, DateTime(2030, 10, 1));
        expect(p.driverLicense!.validityYears, 5);
        await tester.tap(find.byTooltip('Edit LTO license'));
        await tester.pumpAndSettle();
        await tapText('10 years');
        // Selecting a different validity never silently changes the printed date.
        expect(p.driverLicense!.expiresOn, DateTime(2030, 10, 1));
        await tapText('Estimate 10-year renewal');
        await tester.drag(find.byType(ListView).last, const Offset(0, 1500));
        await tester.pumpAndSettle();
        await captureUi(tester, boundary, 'license_form_${size.width.toInt()}');
        await tapText('Save license');
        await finishSave();
        expect(p.driverLicense!.expiresOn, DateTime(2040, 10, 1));
        expect(p.driverLicense!.validityYears, 10);
        await captureUi(
          tester,
          boundary,
          'license_dashboard_${size.width.toInt()}',
        );
        await tester.tap(find.byTooltip('Edit LTO license'));
        await tester.pumpAndSettle();
        await tapText('Remove license tracking');
        await tapText('Cancel');
        expect(p.driverLicense, isNotNull);
        await tapText('Remove license tracking');
        await tapText('Delete');
        await finishSave();
        expect(p.driverLicense, isNull);
        expect(find.text('Add LTO license'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
