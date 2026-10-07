import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:vehicle_maintenance_tracker/database/supabase_repository.dart';
import 'package:vehicle_maintenance_tracker/models/maintenance_record.dart';
import 'package:vehicle_maintenance_tracker/models/driver_license.dart';
import 'package:vehicle_maintenance_tracker/models/tire.dart';
import 'package:vehicle_maintenance_tracker/services/cloud_config.dart';

void main() {
  const userId = '11111111-1111-4111-8111-111111111111';
  late SupabaseClient client;
  late SupabaseRepository repo;
  late List<http.Request> requests;
  late Future<http.Response> Function(http.Request) handle;
  String jwt(Map<String, Object> payload) =>
      '${base64Url.encode(utf8.encode('{"alg":"HS256"}'))}.${base64Url.encode(utf8.encode(jsonEncode(payload)))}.signature';
  setUp(() async {
    requests = [];
    handle = (_) async =>
        http.Response('[]', 200, headers: {'content-type': 'application/json'});
    client = SupabaseClient(
      'https://test.supabase.co',
      'public-key',
      authOptions: const AuthClientOptions(autoRefreshToken: false),
      httpClient: MockClient((request) async {
        if (request.url.path == '/auth/v1/token') {
          return http.Response(
            jsonEncode({
              'access_token': jwt({
                'sub': userId,
                'role': 'authenticated',
                'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + 3600,
              }),
              'refresh_token': 'test-refresh',
              'token_type': 'bearer',
              'expires_in': 3600,
              'user': {
                'id': userId,
                'aud': 'authenticated',
                'role': 'authenticated',
                'email': 'test@example.com',
                'app_metadata': {},
                'user_metadata': {},
                'created_at': '2026-01-01T00:00:00Z',
              },
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        }
        requests.add(request);
        final response = await handle(request);
        return http.Response.bytes(
          response.bodyBytes,
          response.statusCode,
          headers: response.headers,
          request: request,
        );
      }),
    );
    await client.auth.signInWithPassword(
      email: 'test@example.com',
      password: 'password',
    );
    repo = SupabaseRepository(client);
  });
  tearDown(() => client.dispose());

  test(
    'license settings use the signed-in owner and the existing cloud table',
    () async {
      final license = DriverLicense(
        validityYears: 10,
        expiresOn: DateTime(2036, 10, 1),
      );
      handle = (_) async => http.Response('', 204);
      await repo.setSetting(DriverLicense.settingKey, license.encode());
      expect(requests.single.url.path, '/rest/v1/settings');
      expect(requests.single.url.queryParameters['on_conflict'], 'user_id,key');
      expect(jsonDecode(requests.single.body), {
        'user_id': userId,
        'key': DriverLicense.settingKey,
        'value': license.encode(),
      });
      handle = (request) async {
        expect(request.url.queryParameters['user_id'], 'eq.$userId');
        return http.Response(
          jsonEncode([
            {'key': DriverLicense.settingKey, 'value': license.encode()},
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      };
      final settings = await repo.getSettings();
      expect(
        DriverLicense.decode(settings[DriverLicense.settingKey])!.expiresOn,
        license.expiresOn,
      );
      requests.clear();
      handle = (_) async => http.Response('', 204);
      await repo.setSetting(DriverLicense.settingKey, '');
      expect(jsonDecode(requests.single.body)['value'], '');
    },
  );

  test('cloud reads page past 500 rows and restrict requests to the signed-in owner', () async {
    final offsets = <String?>[];
    handle = (request) async {
      expect(request.url.queryParameters['user_id'], 'eq.$userId');
      offsets.add(request.url.queryParameters['offset']);
      final offset = int.parse(request.url.queryParameters['offset'] ?? '0');
      final count = offset == 0 ? 500 : 1;
      return http.Response(
        jsonEncode(
          List.generate(
            count,
            (i) => {
              'id': offset + i + 1,
              'vehicle_id': 1,
              'position': 'Front left',
              'brand': '',
              'manufactured_on': '2022-01-01',
              'replacement_years': 6,
              'notes': '',
            },
          ),
        ),
        200,
        headers: {'content-type': 'application/json'},
      );
    };
    expect((await repo.getAllTires()).length, 501);
    expect(offsets, ['0', '500']);
  });
  test(
    'tire insert and update carry the account owner and report server failures',
    () async {
      handle = (request) async => http.Response(
        '{"id":7}',
        200,
        headers: {'content-type': 'application/json'},
      );
      await repo.saveTire(
        Tire(
          vehicleId: 3,
          position: 'Spare',
          manufacturedOn: DateTime(2022, 2),
        ),
      );
      final inserted = jsonDecode(requests.single.body) as Map;
      expect(inserted['user_id'], userId);
      expect(inserted['manufactured_on'], '2022-02-01');
      expect(inserted.containsKey('id'), isFalse);
      expect(requests.single.method, 'POST');
      requests.clear();
      await repo.saveTire(
        Tire(
          id: 7,
          vehicleId: 3,
          position: 'Spare',
          manufacturedOn: DateTime(2023, 2),
        ),
      );
      expect(requests.single.method, 'PATCH');
      expect(requests.single.url.queryParameters['id'], 'eq.7');
      expect(requests.single.url.queryParameters['user_id'], 'eq.$userId');
      handle = (_) async =>
          http.Response('{"message":"permission denied","code":"42501"}', 403);
      await expectLater(repo.deleteTire(7), throwsA(isA<PostgrestException>()));
    },
  );
  test('transaction operations use server RPCs and pass nullable completion records', () async {
    handle = (_) async => http.Response('', 204);
    await repo.completeSchedule(9, null);
    expect(requests.last.url.path, '/rest/v1/rpc/complete_maintenance');
    expect(jsonDecode(requests.last.body), {
      'schedule_id': 9,
      'service_record': null,
    });
    await repo.completeSchedule(
      9,
      MaintenanceRecord(
        vehicleId: 3,
        type: 'PMS',
        date: DateTime(2026, 9, 1),
        odometer: 5000,
        cost: 3500,
      ),
    );
    expect(
      (jsonDecode(requests.last.body)['service_record'] as Map).containsKey(
        'id',
      ),
      isFalse,
    );
    await repo.changeUnit('mi', 'km');
    expect(requests.last.url.path, '/rest/v1/rpc/change_distance_unit');
    expect(jsonDecode(requests.last.body), {'new_unit': 'mi'});
  });
  test(
    'missing, invalid and privileged keys are rejected before initialization',
    () {
      expect(CloudConfig.validate('', ''), isNotNull);
      expect(
        CloudConfig.validate('https://project.supabase.co', 'sb_secret_test'),
        isNotNull,
      );
      expect(
        CloudConfig.validate(
          'https://project.supabase.co',
          jwt({'role': 'service_role'}),
        ),
        isNotNull,
      );
      expect(
        CloudConfig.validate(
          'https://project.supabase.co',
          jwt({'role': 'anon'}),
        ),
        isNull,
      );
      expect(
        CloudConfig.validate(
          'https://project.supabase.co',
          'sb_publishable_test',
        ),
        isNull,
      );
    },
  );
}
