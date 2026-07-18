import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/network/supabase_client_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeSupabase();

  runApp(const ProviderScope(child: BorahApp()));
}
