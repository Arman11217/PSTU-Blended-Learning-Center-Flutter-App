import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

class FileStorageService {
  static const String _supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://rnaqqjwvntgvkaiueghq.supabase.co',
  );
  static const String _supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJuYXFxand2bnRndmthaXVlZ2hxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzUzMjc0MDgsImV4cCI6MjA5MDkwMzQwOH0.zh4puxgw3uj1EsSDmRQIG9R4WyN2e01aUo_UxT0GjNA',
  );
  static const String _supabaseBucket = String.fromEnvironment('SUPABASE_BUCKET', defaultValue: 'assignment-files');

  bool get isConfigured =>
      _supabaseUrl.trim().isNotEmpty &&
      _supabaseAnonKey.trim().isNotEmpty &&
      _supabaseBucket.trim().isNotEmpty;

  SupabaseClient _client() {
    if (!isConfigured) {
      throw StateError(
        'Supabase is not configured. Pass --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=... --dart-define=SUPABASE_BUCKET=assignment-files',
      );
    }
    return SupabaseClient(_supabaseUrl, _supabaseAnonKey);
  }

  Future<String> uploadBinary({
    required Uint8List bytes,
    required String path,
    String contentType = 'application/octet-stream',
    bool upsert = true,
  }) async {
    final client = _client();
    final bucket = client.storage.from(_supabaseBucket);

    await bucket.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        contentType: contentType,
        upsert: upsert,
      ),
    );

    return bucket.getPublicUrl(path);
  }
}
