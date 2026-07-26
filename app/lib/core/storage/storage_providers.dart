import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/supabase_client_provider.dart';
import 'storage_repository.dart';
import 'storage_service.dart';
import 'supabase_storage_service.dart';

/// Providers de acesso ao Storage (RC-04B) — para features que já usam
/// Riverpod e preferem injeção via `ref` em vez da fachada estática
/// `AppStorage`. Nenhuma tela consome estes providers ainda nesta
/// rodada (só infraestrutura, ver RC-04B §Escopo).
final storageRepositoryProvider = Provider<StorageRepository>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return SupabaseStorageService(client);
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(ref.watch(storageRepositoryProvider));
});
