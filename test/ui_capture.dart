import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vehicle_maintenance_tracker/services/notification_service.dart';

class NoPlatformNotifications extends NotificationService {
  @override
  bool get supported => false;
}

Future<void> loadCaptureFonts() async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  final font = FontLoader('Roboto')
    ..addFont(
      File('C:/Windows/Fonts/segoeui.ttf')
          .readAsBytes()
          .then(ByteData.sublistView),
    );
  await font.load();
  final mono = FontLoader('monospace')
    ..addFont(
      File('C:/Windows/Fonts/consola.ttf')
          .readAsBytes()
          .then(ByteData.sublistView),
    );
  await mono.load();
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}

Future<void> captureUi(
  WidgetTester tester,
  GlobalKey boundary,
  String name,
) async {
  if (!const bool.fromEnvironment('CAPTURE_UI')) return;
  await tester.runAsync(() async {
    final image =
        await (boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary)
            .toImage();
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory('build/ui').create(recursive: true);
    await File('build/ui/$name.png').writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
