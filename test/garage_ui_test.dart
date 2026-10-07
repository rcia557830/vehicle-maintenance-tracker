import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vehicle_maintenance_tracker/database/database_helper.dart';
import 'package:vehicle_maintenance_tracker/main.dart';
import 'package:vehicle_maintenance_tracker/providers/maintenance_provider.dart';

import 'multi_vehicle_test.dart' show CapturedNotifications;

void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    if (const bool.fromEnvironment('CAPTURE_UI')) {
      final font = FontLoader('Roboto')
        ..addFont(
          File('C:/Windows/Fonts/segoeui.ttf')
              .readAsBytes()
              .then((bytes) => ByteData.sublistView(bytes)),
        );
      await font.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    }
  });
  for (final size in [const Size(360, 800), const Size(1280, 900)]) {
    testWidgets('garage add and switch flow at ${size.width}px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final db = DatabaseHelper(databasePath: inMemoryDatabasePath);
      final p = MaintenanceProvider(db, CapturedNotifications());
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
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: p,
          child: RepaintBoundary(
            key: boundary,
            child: const VehicleMaintenanceApp(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<void> settleDatabase(bool Function() done) async {
        for (var attempt = 0; attempt < 100 && !done(); attempt++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pump();
        }
        await tester.pumpAndSettle();
      }

      Future<void> capture(String name) async {
        if (!const bool.fromEnvironment('CAPTURE_UI')) return;
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory('build/ui').create(recursive: true);
          await File('build/ui/${name}_${size.width.toInt()}.png')
              .writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }

      Finder nav(String label) => find.descendant(
        of: find.byType(size.width >= 1000 ? NavigationRail : NavigationBar),
        matching: find.text(label),
      );
      await capture('dashboard');
      await tester.tap(nav('Garage'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Add vehicle'));
      await tester.pumpAndSettle();
      await capture('vehicle_form');
      // TextFormField exposes its decoration through the descendant TextField.
      Finder field(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
      );
      Future<void> fill(String label, String value) async {
        await tester.scrollUntilVisible(
          field(label),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await tester.enterText(field(label), value);
      }

      await fill('Vehicle name / nickname', 'City Car');
      await fill('Manufacturer / make', 'Honda');
      await fill('Model', 'City');
      await fill('Plate number', 'XYZ 5678');
      await fill('Current odometer (km)', '1200');
      await tester.scrollUntilVisible(
        find.text('Save vehicle'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(ListView).last, const Offset(0, -200));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Save vehicle'));
      await settleDatabase(() => p.vehicle?.nickname == 'City Car');
      expect(p.vehicles.length, 2);
      expect(p.vehicle!.nickname, 'City Car');
      expect(p.records, isEmpty);
      await capture('garage');
      await tester.tap(nav('Dashboard'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('1,200 km'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('1,200 km'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('vehicle-switcher')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Family Car \u00b7 ABC 1234').last);
      await tester.pumpAndSettle();
      await settleDatabase(
        () => p.vehicle?.nickname == 'Family Car' && !p.switching,
      );
      expect(p.vehicle!.nickname, 'Family Car');
      expect(p.totalCost, 12500);
      await tester.tap(nav('Maintenance'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).first, 'ABC Auto');
      await tester.pumpAndSettle();
      expect(find.text('1 record \u00b7 \u20B13,500.00'), findsOneWidget);
      await capture('history');
      await tester.tap(nav('Expenses'));
      await tester.pumpAndSettle();
      await capture('expenses');
      await tester.tap(nav('Settings'));
      await tester.pumpAndSettle();
      await capture('settings');
      expect(tester.takeException(), isNull);
    });
  }
}
