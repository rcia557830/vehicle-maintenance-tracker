import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vehicle_maintenance_tracker/screens/auth_screen.dart';
import 'package:vehicle_maintenance_tracker/theme/app_theme.dart';

void main() {
  for (final launched in [true, false]) {
    testWidgets('Google browser launch $launched keeps login session-gated', (
      tester,
    ) async {
      late final SupabaseClient client;
      await tester.runAsync(() async {
        client = SupabaseClient(
          'https://test.supabase.co',
          'public-key',
          authOptions: AuthClientOptions(
            autoRefreshToken: false,
            pkceAsyncStorage: _MemoryStorage(),
          ),
        );
      });
      const channel = MethodChannel('plugins.flutter.io/url_launcher');
      Uri? requested;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(channel, (
        call,
      ) async {
        if (call.method == 'launch') {
          requested = Uri.parse((call.arguments as Map)['url'] as String);
          expect((call.arguments as Map)['useWebView'], isFalse);
          return launched;
        }
        return true;
      });
      addTearDown(() async {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          channel,
          null,
        );
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.runAsync(client.dispose);
      });
      await tester.pumpWidget(
        MaterialApp(
          theme: buildAppTheme(),
          home: AuthScreen(client: client),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('google-sign-in')));
      await tester.pumpAndSettle();
      expect(requested?.host, 'test.supabase.co');
      expect(requested?.path, '/auth/v1/authorize');
      expect(requested?.queryParameters['provider'], 'google');
      expect(requested?.queryParameters['code_challenge'], isNotEmpty);
      expect(requested?.queryParameters['code_challenge_method'], 's256');
      expect(
        requested?.queryParameters['redirect_to'],
        'io.motorcare.app://login-callback/',
      );
      expect(requested?.queryParameters['prompt'], 'select_account');
      expect(client.auth.currentSession, isNull);
      expect(find.text('Enter a valid email address.'), findsNothing);
      expect(
        find.text(
          launched
              ? 'Finish signing in with Google in your browser. If you cancelled, you can try again.'
              : 'Unable to open Google sign-in. Please try again.',
        ),
        findsOneWidget,
      );
      expect(
        tester
            .widget<OutlinedButton>(
              find.byKey(const ValueKey('google-sign-in')),
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    });
  }
}

class _MemoryStorage extends GotrueAsyncStorage {
  final values = <String, String>{};
  @override
  Future<String?> getItem({required String key}) async => values[key];
  @override
  Future<void> setItem({required String key, required String value}) async {
    values[key] = value;
  }

  @override
  Future<void> removeItem({required String key}) async {
    values.remove(key);
  }
}
