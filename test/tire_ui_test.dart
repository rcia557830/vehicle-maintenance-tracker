import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vehicle_maintenance_tracker/database/database_helper.dart';
import 'package:vehicle_maintenance_tracker/models/tire.dart';
import 'package:vehicle_maintenance_tracker/providers/maintenance_provider.dart';
import 'package:vehicle_maintenance_tracker/screens/tires_screen.dart';
import 'package:vehicle_maintenance_tracker/theme/app_theme.dart';

import 'ui_capture.dart';

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    await loadCaptureFonts();
  });
  for (final size in [const Size(360, 800), const Size(1280, 900)]) {
    testWidgets('tire add, edit, delete and estimates at ${size.width}px', (
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
        final id = (await db.getVehicles()).single.id!;
        await db.saveTire(
          Tire(
            vehicleId: id,
            position: 'Front left',
            manufacturedOn: DateTime(2020, 1),
            brand: 'Michelin Primacy',
          ),
        );
        await db.saveTire(
          Tire(
            vehicleId: id,
            position: 'Front right',
            manufacturedOn: DateTime(2022, 6),
            brand: 'Michelin Primacy',
          ),
        );
        await p.load();
      });
      final boundary = GlobalKey();
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: p,
          child: RepaintBoundary(
            key: boundary,
            child: MaterialApp(
              debugShowCheckedModeBanner: false,
              theme: buildAppTheme(),
              home: const TiresScreen(standalone: true),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await captureUi(tester, boundary, 'tires_${size.width.toInt()}');
      await tester.tap(find.widgetWithText(FilledButton, 'Add tire'));
      await tester.pumpAndSettle();
      final yearField = find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == 'Manufacture year',
      );
      await tester.scrollUntilVisible(
        yearField,
        180,
        scrollable: find
            .descendant(
              of: find.byType(TireFormScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.enterText(yearField, '2022');
      await tester.pumpAndSettle();
      await captureUi(tester, boundary, 'tire_form_${size.width.toInt()}');
      await tester.scrollUntilVisible(
        find.text('Save tire'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(TireFormScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save tire'));
      Future<void> settle(bool Function() done) async {
        for (var i = 0; i < 100 && !done(); i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump();
        }
        await tester.pumpAndSettle();
      }

      await settle(() => find.byType(TireFormScreen).evaluate().isEmpty);
      expect(
        p.tires.singleWhere((t) => t.position == 'Rear left').replacementYear,
        2028,
      );
      expect(find.byType(TireFormScreen), findsNothing);
      expect(tester.takeException(), isNull);
      // The positional map opens the matching current entry for editing.
      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Rear left'),
      );
      await tester.tap(find.widgetWithText(OutlinedButton, 'Rear left'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        yearField,
        180,
        scrollable: find
            .descendant(
              of: find.byType(TireFormScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.enterText(yearField, '2024');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Save tire'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(TireFormScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save tire'));
      await settle(() => find.byType(TireFormScreen).evaluate().isEmpty);
      expect(
        p.tires.singleWhere((t) => t.position == 'Rear left').replacementYear,
        2030,
      );
      await tester.ensureVisible(
        find.widgetWithText(OutlinedButton, 'Rear left'),
      );
      await tester.tap(find.widgetWithText(OutlinedButton, 'Rear left'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Delete tire'),
        240,
        scrollable: find
            .descendant(
              of: find.byType(TireFormScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete tire'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
      await settle(() => find.byType(TireFormScreen).evaluate().isEmpty);
      expect(p.tires.any((t) => t.position == 'Rear left'), isFalse);
      expect(tester.takeException(), isNull);
    });
  }
}
