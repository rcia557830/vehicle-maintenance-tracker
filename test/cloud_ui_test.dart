import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vehicle_maintenance_tracker/cloud_app.dart';

import 'ui_capture.dart';

import 'package:vehicle_maintenance_tracker/screens/settings_screen.dart';

void main() {
  setUpAll(loadCaptureFonts);
  testWidgets('missing configuration shows a useful setup screen', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(key: boundary, child: const CloudApp()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Your garage. Connected.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await captureUi(tester, boundary, 'supabase_setup_360');
  });
  for (final size in [const Size(360, 800), const Size(1280, 900)]) {
    testWidgets('sign in and sign out replace the workspace at ${size.width}px', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const uid = '11111111-1111-4111-8111-111111111111';
      final jwt =
          '${base64Url.encode(utf8.encode('{"alg":"HS256"}'))}.${base64Url.encode(utf8.encode(jsonEncode({'sub': uid, 'role': 'authenticated', 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600})))}.signature';
      late final SupabaseClient client;
      await tester.runAsync(() async {
        client = SupabaseClient(
          'https://test.supabase.co',
          'public-key',
          authOptions: const AuthClientOptions(autoRefreshToken: false),
          httpClient: MockClient((request) async {
            if (request.url.path.endsWith('/token')) {
              return http.Response(
                jsonEncode({
                  'access_token': jwt,
                  'refresh_token': 'refresh',
                  'token_type': 'bearer',
                  'expires_in': 3600,
                  'user': {
                    'id': uid,
                    'aud': 'authenticated',
                    'role': 'authenticated',
                    'email': 'driver@example.com',
                    'app_metadata': {},
                    'user_metadata': {},
                    'created_at': '2026-01-01T00:00:00Z',
                  },
                }),
                200,
                request: request,
                headers: {'content-type': 'application/json'},
              );
            }
            if (request.url.path.endsWith('/logout')) {
              return http.Response('', 204, request: request);
            }
            return http.Response(
              '[]',
              200,
              request: request,
              headers: {'content-type': 'application/json'},
            );
          }),
        );
      });
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(client.dispose);
      });
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: CloudApp(
            client: client,
            notificationService: NoPlatformNotifications(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await captureUi(tester, boundary, 'signin_${size.width.toInt()}');
      expect(tester.takeException(), isNull);
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'driver@example.com');
      await tester.enterText(fields.at(1), 'password123');
      await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome to your garage'), findsOneWidget);
      final settings = find.descendant(
        of: find.byType(size.width >= 1000 ? NavigationRail : NavigationBar),
        matching: find.text('Settings'),
      );
      await tester.tap(settings);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Sign out'),
        220,
        scrollable: find
            .descendant(
              of: find.byType(SettingsScreen),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.pumpAndSettle();
      await captureUi(tester, boundary, 'cloud_account_${size.width.toInt()}');
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Preferences'), findsNothing);
      expect(find.byType(NavigationRail), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
