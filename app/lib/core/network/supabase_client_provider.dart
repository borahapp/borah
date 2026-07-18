import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../environment/app_environment.dart';

/// Initializes Supabase. Must be awaited before [runApp] (AR-06).
Future<void> initializeSupabase() {
  return Supabase.initialize(
    url: AppEnvironment.supabaseUrl,
    publishableKey: AppEnvironment.supabaseAnonKey,
  );
}

/// Exposes the initialized [SupabaseClient] to the Provider layer.
/// Repositories/datasources depend on this, never on Flutter widgets
/// (AR-02: Domain não depende de Flutter nem de Supabase).
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
