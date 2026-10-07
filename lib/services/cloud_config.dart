import 'dart:convert';

abstract final class CloudConfig {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const key = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_ANON_KEY'),
  );
  static String? validate(String url, String key) {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host.isEmpty ||
        url.contains('YOUR_PROJECT') ||
        key.isEmpty ||
        key.contains('YOUR_')) {
      return 'Add your Supabase project URL and public client key to config/supabase.json.';
    }
    if (key.startsWith('sb_secret_')) {
      return 'Use a publishable key, never a secret key.';
    }
    if (key.startsWith('sb_publishable_')) return null;
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(key.split('.')[1]))),
      ) as Map;
      if (payload['role'] == 'anon') return null;
    } catch (_) {
      // Invalid keys belong on the setup screen, not in a failing client.
    }
    return 'Use a Supabase publishable key or legacy anon key.';
  }
}
