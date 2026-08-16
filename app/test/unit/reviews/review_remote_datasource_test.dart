import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// BETA-RELEASE-03: guarda de regressão da causa raiz de BETA-RELEASE-02.
///
/// `ReviewRemoteDatasource` monta suas consultas encadeando métodos de
/// `SupabaseClient` (`PostgrestFilterBuilder`/`PostgrestTransformBuilder`),
/// que não expõem nenhuma forma de inspecionar a query final montada nem
/// têm um double de teste pronto neste projeto (diferente de
/// `GooglePlacesRemoteDatasource`, que usa `package:http` diretamente e por
/// isso é mockável). Testar aqui via leitura do próprio código-fonte é a
/// forma mais direta de travar a regressão sem introduzir uma nova camada
/// de mock só para isto (fora do escopo mínimo autorizado).
void main() {
  late String source;

  setUpAll(() {
    source = File(
      'lib/features/reviews/data/review_remote_datasource.dart',
    ).readAsStringSync();
  });

  test('TESTE 4: a consulta de reviews não usa mais restaurants!inner', () {
    expect(source, isNot(contains('restaurants!inner')));
    expect(source, contains("restaurants(id, name, cover_image)"));
  });

  test('TESTE 5: listByRestaurant continua filtrando restaurant_id/deleted_at, '
      'ordenando por created_at desc e paginando por range', () {
    final start = source.indexOf(
      'Future<List<Map<String, dynamic>>> listByRestaurant',
    );
    final end = source.indexOf('Future<List<Map<String, dynamic>>> listByUser');
    expect(start, greaterThanOrEqualTo(0));
    expect(end, greaterThan(start));
    final method = source.substring(start, end);

    expect(method, contains("eq('restaurant_id', restaurantId)"));
    expect(method, contains("isFilter('deleted_at', null)"));
    expect(method, contains("order('created_at', ascending: false)"));
    expect(method, contains('.range(from, to)'));
  });
}
