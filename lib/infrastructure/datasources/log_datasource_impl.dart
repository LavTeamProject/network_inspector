import 'package:collection/collection.dart';
import 'package:sqflite/sqflite.dart';

import '../models/http_activity_model.dart';
import '../models/http_request_model.dart';
import '../models/http_response_model.dart';
import 'log_datasource.dart';

/// @nodoc
class LogDatasourceImpl implements LogDatasource {
  final Database database;

  LogDatasourceImpl({
    required this.database,
  });

  @override
  Future<bool> logHttpRequest({
    required HttpRequestModel httpRequestModel,
  }) async {
    var id = await database.insert(
      HttpRequestModel.tableName,
      httpRequestModel.toJson(),
    );
    return (id != 0);
  }

  @override
  Future<bool> logHttpResponse({
    required HttpResponseModel httpResponseModel,
  }) async {
    var id = await database.insert(
      HttpResponseModel.tableName,
      httpResponseModel.toJson(),
    );
    return (id != 0);
  }

  @override
  Future<List<HttpRequestModel>?> httpRequests({
    int? requestHashCode,
  }) async {
    List<Map<String, Object?>> rows = await database.query(
      HttpRequestModel.tableName,
      where: 'request_hash_code = ?',
      whereArgs: [requestHashCode],
    );
    var models = List<HttpRequestModel>.from(
      rows.map(
        (row) => HttpRequestModel.fromJson(row),
      ),
    );
    return models;
  }

  @override
  Future<List<HttpResponseModel>?> httpResponses({
    int? requestHashCode,
  }) async {
    List<Map<String, Object?>> rows = await database.query(
      HttpResponseModel.tableName,
      where: 'request_hash_code = ?',
      whereArgs: [requestHashCode],
    );
    var models = List<HttpResponseModel>.from(
      rows.map(
        (row) => HttpResponseModel.fromJson(row),
      ),
    );
    return models;
  }
  @override
  Future<List<HttpActivityModel>?> httpActivities({
    int? startDate,
    int? endDate,
    List<int?>? statusCodes,
    List<String>? baseUrls,
    List<String>? paths,
    List<String>? methods,
    String? url,
  }) async {
    // === 1. ЛОГИРОВАНИЕ ПЕРЕДАННЫХ ФИЛЬТРОВ ===
    print('═══════════════════════════════════════════════════');
    print('🔍 [FILTER DEBUG] Начинаем фильтрацию логов');
    print('═══════════════════════════════════════════════════');
    print('📋 Параметры фильтрации, полученные от клиента:');
    print('   • statusCodes: $statusCodes');
    print('   • baseUrls: $baseUrls (кол-во: ${baseUrls?.length ?? 0})');
    print('   • paths: $paths (кол-во: ${paths?.length ?? 0})');
    print('   • methods: $methods (кол-во: ${methods?.length ?? 0})');
    print('   • url: $url');
    print('   • startDate: $startDate');
    print('   • endDate: $endDate');

    final filteredByDate = (startDate != null && endDate != null);

    final whereConditions = <String>[];
    final queryArgs = <dynamic>[];

    // === 2. ФОРМИРОВАНИЕ SQL УСЛОВИЙ ===
    print('\n🔧 Формирование SQL условий:');

    // Фильтр по дате
    if (filteredByDate) {
      whereConditions.add(
          "created_at >= datetime(? / 1000, 'unixepoch')"
              " and created_at <= datetime(? / 1000, 'unixepoch')"
      );
      queryArgs.addAll([startDate, endDate]);
      print('   ✅ Добавлен фильтр по дате: $startDate - $endDate');
    }

    // filter by URL
    if (url != null && url.isNotEmpty) {
      whereConditions.add("(baseUrl LIKE ? OR path LIKE ?)");
      queryArgs.addAll(['%$url%', '%$url%']);
      print('   ✅ Добавлен фильтр по URL: "$url"');
    }

    // filter by baseUrl
    if (baseUrls != null && baseUrls.isNotEmpty) {
      final placeholders = List.filled(baseUrls.length, '?').join(',');
      whereConditions.add("base_url IN ($placeholders)");
      queryArgs.addAll(baseUrls);
      print('   ✅ Добавлен фильтр по baseUrls: $baseUrls');
    }

    // filter by path
    if (paths != null && paths.isNotEmpty) {
      final placeholders = List.filled(paths.length, '?').join(',');
      whereConditions.add("path IN ($placeholders)");
      queryArgs.addAll(paths);
      print('   ✅ Добавлен фильтр по paths: $paths');
    }

    // filter by method
    if (methods != null && methods.isNotEmpty) {
      final placeholders = List.filled(methods.length, '?').join(',');
      whereConditions.add("method IN ($placeholders)");
      queryArgs.addAll(methods);
      print('   ✅ Добавлен фильтр по methods: $methods');
    }

    String whereClause = '';
    if (whereConditions.isNotEmpty) {
      whereClause = whereConditions.join(' AND ');
    }

    print('\n📝 Итоговый SQL WHERE clause:');
    print('   "$whereClause"');
    print('   Аргументы: $queryArgs');

    // === 3. ПОЛУЧЕНИЕ "СЫРЫХ" ДАННЫХ ДО ФИЛЬТРАЦИИ ===
    print('\n📊 Получаем ВСЕ данные из таблицы http_requests для сравнения:');
    try {
      final allRequests = await database.query(
        HttpRequestModel.tableName,
        orderBy: 'created_at DESC',
      );
      print('   📈 Всего записей в таблице: ${allRequests.length}');

      // Логирование уникальных значений для отладки
      if (allRequests.isNotEmpty) {
        final uniqueBaseUrls = allRequests.map((r) => r['baseUrl']).whereType<String>().toSet();
        final uniquePaths = allRequests.map((r) => r['path']).whereType<String>().toSet();
        final uniqueMethods = allRequests.map((r) => r['method']).whereType<String>().toSet();

        print('   🔍 Уникальные baseUrls в базе: $uniqueBaseUrls');
        print('   🔍 Уникальные paths в базе: $uniquePaths');
        print('   🔍 Уникальные methods в базе: $uniqueMethods');
      }
    } catch (e) {
      print('   ❌ Ошибка при получении всех данных: $e');
    }

    // === 4. ВЫПОЛНЕНИЕ ОТФИЛЬТРОВАННОГО ЗАПРОСА ===
    print('\n🚀 Выполняем ОТФИЛЬТРОВАННЫЙ запрос к таблице http_requests:');

    List<Map<String, Object?>> requestRows = await database.query(
      HttpRequestModel.tableName,
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: queryArgs,
      orderBy: 'created_at DESC',
    );

    print('   ✅ Найдено запросов после фильтрации: ${requestRows.length}');

    // Логируем детали найденных запросов
    if (requestRows.isNotEmpty) {
      print('   📋 Детали найденных запросов:');
      for (var i = 0; i < requestRows.length && i < 3; i++) {
        final row = requestRows[i];
        print('     ${i + 1}. baseUrl: "${row['baseUrl']}", path: "${row['path']}", method: "${row['method']}"');
      }
      if (requestRows.length > 3) {
        print('     ... и ещё ${requestRows.length - 3} записей');
      }
    }

    final requestModels = List<HttpRequestModel>.from(
      requestRows.map((row) => HttpRequestModel.fromJson(row)),
    );

    if (requestModels.isEmpty) {
      print('\n⚠️  Нет запросов после фильтрации, возвращаем пустой список');
      print('═══════════════════════════════════════════════════\n');
      return [];
    }

    final requestIds = requestModels
        .map((requestModel) => requestModel.requestHashCode)
        .where((id) => id != null)
        .toList();

    if (requestIds.isEmpty) {
      print('\n⚠️  Не удалось получить requestHashCode из запросов');
      print('═══════════════════════════════════════════════════\n');
      return [];
    }

    // === 5. ФИЛЬТРАЦИЯ ОТВЕТОВ ===
    print('\n🎯 Фильтруем ответы по найденным request_hash_code и statusCodes:');

    final responseWhereConditions = <String>[];
    final responseQueryArgs = <dynamic>[];

    // filter by request_hash_code
    final idPlaceholders = List.filled(requestIds.length, '?').join(',');
    responseWhereConditions.add("request_hash_code IN ($idPlaceholders)");
    responseQueryArgs.addAll(requestIds);
    print('   🔗 Ищем ответы для request_hash_code: $requestIds');

    // filter by statusCodes
    if (statusCodes != null && statusCodes.isNotEmpty) {
      print('   🔍 Применяем фильтр по statusCodes: $statusCodes');

      if (statusCodes.contains(null)) {
        final nonNullCodes = statusCodes.where((code) => code != null).toList();
        if (nonNullCodes.isNotEmpty) {
          final codePlaceholders = List.filled(nonNullCodes.length, '?').join(',');
          responseWhereConditions.add(
              "(response_status_code IN ($codePlaceholders) OR response_status_code IS NULL)"
          );
          responseQueryArgs.addAll(nonNullCodes);
          print('     📌 Включая null значения и коды: $nonNullCodes');
        } else {
          responseWhereConditions.add("response_status_code IS NULL");
          print('     📌 Ищем только null значения статус кодов');
        }
      } else {
        final codePlaceholders = List.filled(statusCodes.length, '?').join(',');
        responseWhereConditions.add("response_status_code IN ($codePlaceholders)");
        responseQueryArgs.addAll(statusCodes.where((code) => code != null));
        print('     📌 Ищем статус коды: ${statusCodes.where((code) => code != null).toList()}');
      }
    }

    final responseWhereClause = responseWhereConditions.join(' AND ');

    print('   📝 SQL WHERE для ответов: "$responseWhereClause"');
    print('   🔢 Аргументы: $responseQueryArgs');

    List<Map<String, Object?>> responseRows = await database.query(
      HttpResponseModel.tableName,
      where: responseWhereClause,
      whereArgs: responseQueryArgs,
    );

    print('   ✅ Найдено ответов: ${responseRows.length}');

    // Логирование найденных ответов
    if (responseRows.isNotEmpty) {
      print('   📋 Статус коды найденных ответов:');
      final statusCodesFound = responseRows.map((r) => r['response_status_code']).toSet();
      print('     $statusCodesFound');
    }

    final responseModels = List<HttpResponseModel>.from(
      responseRows.map((row) => HttpResponseModel.fromJson(row)),
    );

    // === 6. СОЗДАНИЕ АКТИВНОСТЕЙ ===
    print('\n🔗 Связываем запросы с ответами...');

    final activities = <HttpActivityModel>[];
    final matchedHashes = <int>[];
    final unmatchedRequests = <int>[];

    for (final requestModel in requestModels) {
      final response = responseModels.firstWhereOrNull(
            (responseModel) => responseModel.requestHashCode == requestModel.requestHashCode,
      );

      if (response != null) {
        activities.add(HttpActivityModel(
          request: requestModel,
          response: response,
        ));
        matchedHashes.add(requestModel.requestHashCode!);
      } else {
        unmatchedRequests.add(requestModel.requestHashCode!);
      }
    }

    print('   ✅ Успешно создано активностей: ${activities.length}');
    print('   🔗 Сопоставлено request_hash_code: $matchedHashes');
    if (unmatchedRequests.isNotEmpty) {
      print('   ⚠️  Не найдено ответов для request_hash_code: $unmatchedRequests');
    }

    // === 7. ИТОГОВАЯ СТАТИСТИКА ===
    print('\n📊 ИТОГОВАЯ СТАТИСТИКА:');
    print('   🎯 Всего активностей после фильтрации: ${activities.length}');

    if (activities.isNotEmpty) {
      final uniqueStatusCodes = activities.map((a) => a.response?.responseStatusCode).toSet();
      final uniqueBaseUrlsResult = activities.map((a) => a.request?.baseUrl).whereType<String>().toSet();
      final uniqueMethodsResult = activities.map((a) => a.request?.method).whereType<String>().toSet();

      print('   🔍 Уникальные статус коды в результате: $uniqueStatusCodes');
      print('   🔍 Уникальные baseUrls в результате: $uniqueBaseUrlsResult');
      print('   🔍 Уникальные методы в результате: $uniqueMethodsResult');
    }

    print('═══════════════════════════════════════════════════');
    print('✅ [FILTER DEBUG] Фильтрация завершена');
    print('═══════════════════════════════════════════════════\n');

    return activities;
  }

  @override
  Future<bool> deleteHttpActivities() async {
    var id = await database.delete(
      HttpRequestModel.tableName,
    );
    return (id != 0);
  }
}
