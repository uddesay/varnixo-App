// Live data-path test: real backend -> real ApiClient/Dio -> real model
// parsing. Guards the class of bug that made every home section render
// "Could not load this section" while the API itself was fine (a dead Redis
// made the rate limiter hang past Dio's timeout on every /api/v1 request).
//
// Unit tests over hand-written JSON fixtures cannot catch that, because the
// failure lived in the request path, not the parsing. Skips itself when the
// backend is unreachable so it never breaks CI or an offline checkout.

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:varnixo/features/catalog/domain/category.dart';
import 'package:varnixo/features/catalog/domain/product_card.dart';

const String _baseUrl = 'http://localhost:4000/api/v1';

Future<bool> _backendReachable() async {
  try {
    final res = await Dio().get<dynamic>(
      'http://localhost:4000/healthz',
      options: Options(receiveTimeout: const Duration(seconds: 3)),
    );
    return res.statusCode == 200;
  } catch (_) {
    return false;
  }
}

void main() {
  late Dio dio;
  late bool reachable;

  setUpAll(() async {
    dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      // Deliberately tight: the bug this test exists to catch showed up as
      // multi-second latency on every request, so a generous timeout here
      // would let the regression pass unnoticed.
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
    ),);
    reachable = await _backendReachable();
    if (!reachable) {
      // ignore: avoid_print
      print('Backend not reachable at $_baseUrl — skipping live API tests.');
    }
  });

  test('GET /categories parses into a non-empty Category tree', () async {
    if (!reachable) return;
    final res = await dio.get<dynamic>('/categories');
    final List<dynamic> data =
        (res.data as Map<String, dynamic>)['data'] as List<dynamic>;

    final categories =
        data.map((e) => Category.fromJson(e as Map<String, dynamic>)).toList();

    expect(categories, isNotEmpty,
        reason: 'Home category strip would render empty',);
    expect(categories.first.name, isNotEmpty);
    expect(categories.first.slug, isNotEmpty);
  });

  test('GET /products (sort=newest) parses into non-empty ProductCards',
      () async {
    if (!reachable) return;
    final res = await dio.get<dynamic>(
      '/products',
      queryParameters: {'page': 1, 'limit': 8, 'sort': 'newest'},
    );
    final List<dynamic> data =
        (res.data as Map<String, dynamic>)['data'] as List<dynamic>;

    final products = data
        .map((e) => ProductCard.fromJson(e as Map<String, dynamic>))
        .toList();

    expect(products, isNotEmpty,
        reason: '"New Arrivals" rail would render empty',);
    expect(products.first.title, isNotEmpty);
    // rating_avg arrives as a JSON string ("3.80") from Postgres NUMERIC —
    // asserting it parsed proves the string->double coercion still works.
    expect(products.first.ratingAvg, greaterThanOrEqualTo(0));
    expect(products.first.priceMinor, greaterThan(0));
  });

  test('GET /products (sort=popularity) parses into non-empty ProductCards',
      () async {
    if (!reachable) return;
    final res = await dio.get<dynamic>(
      '/products',
      queryParameters: {'page': 1, 'limit': 8, 'sort': 'popularity'},
    );
    final List<dynamic> data =
        (res.data as Map<String, dynamic>)['data'] as List<dynamic>;

    final products = data
        .map((e) => ProductCard.fromJson(e as Map<String, dynamic>))
        .toList();

    expect(products, isNotEmpty,
        reason: '"Trending Now" rail would render empty',);
  });

  test('public catalog endpoints respond well under Dio timeout', () async {
    if (!reachable) return;
    final stopwatch = Stopwatch()..start();
    await dio.get<dynamic>('/categories');
    await dio.get<dynamic>(
      '/products',
      queryParameters: {'page': 1, 'limit': 8, 'sort': 'newest'},
    );
    stopwatch.stop();

    // A healthy local stack answers both in well under a second. The Redis
    // rate-limiter regression pushed a single call past 10s.
    expect(
      stopwatch.elapsed,
      lessThan(const Duration(seconds: 3)),
      reason: 'Catalog latency regressed — check Redis fail-open path',
    );
  });
}
