import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../../common/base/data_wrapper.dart';
import '../../common/utils/database_helper.dart';
import '../../domain/entities/http_activity.dart';
import '../../domain/repositories/log_repository.dart';
import '../../domain/usecases/fetch_http_activities.dart';
import '../../infrastructure/datasources/log_datasource.dart';
import '../../infrastructure/datasources/log_datasource_impl.dart';
import '../../infrastructure/repositories/log_repository_impl.dart';
import '../pages/activity_detail_page.dart';
import 'activity_filter_provider.dart';

/// @nodoc
class ActivityProvider extends ChangeNotifier {
  final BuildContext context;

  ActivityProvider({
    required this.context,
  }) {
    injectDependencies().whenComplete(() {
      initState();
    });
  }


  Database? _database;
  FetchHttpActivities? _fetchHttpActivities;
  DataWrapper<List<HttpActivity>> fetchedActivity =
      DataWrapper<List<HttpActivity>>.init();
  ActivityFilterProvider? filterProvider;

  /// Filter variables
  ///
  /// Stores available status code with its amount
  /// Все доступные фильтры (из всех логов)
  Map<int?, int> allStatusCodes = {};
  Map<String, int> allBaseUrls = {};
  Map<String, int> allPaths = {};
  Map<String, int> allMethods = {};

  /// Текущие отфильтрованные данные (для отображения)
  Map<int?, int> filteredStatusCodes = {};
  Map<String, int> filteredBaseUrls = {};
  Map<String, int> filteredPaths = {};
  Map<String, int> filteredMethods = {};



  Future<void> injectDependencies() async {
    _database = await DatabaseHelper.initialize();
    if (_database != null) {
      LogDatasource logDatasource = LogDatasourceImpl(
        database: _database!,
      );
      LogRepository logRepository = LogRepositoryImpl(
        logDatasource: logDatasource,
      );
      _fetchHttpActivities = FetchHttpActivities(
        logRepository: logRepository,
      );
      filterProvider = ActivityFilterProvider();
    }
  }

  Future<void> initState() async {
    fetchActivities();
  }

  void filterHttpActivities({
    List<int?>? statusCodes,
    List<String>? baseUrls,
    List<String>? paths,
    List<String>? methods,
  }) {
    fetchActivities(
      statusCodes: statusCodes,
      baseUrls: baseUrls,
      paths: paths,
      methods: methods,
    );
  }


  Future<void> fetchActivities({
    List<int?>? statusCodes,
    List<String>? baseUrls,
    List<String>? paths,
    List<String>? methods,
  }) async {
    try {
      fetchedActivity = DataWrapper.loading();
      final result = await _fetchHttpActivities?.execute(
        FetchHttpActivitiesParam(
          statusCodes: statusCodes,
          baseUrls: baseUrls,
          paths: paths,
          methods: methods,
        ),
      ) ?? [];

      fetchedActivity = DataWrapper.success(result);

      // Обновляем ВСЕ фильтры при первой загрузке
      if (allStatusCodes.isEmpty) {
        retrieveAllFilterLists(result);
      }

      // Обновляем текущие фильтры (для отображения в шторке)
      retrieveCurrentFilterLists(result);

      notifyListeners();
    } catch (error) {
      fetchedActivity = DataWrapper.error(
        message: error.toString(),
      );
    }
  }

  void retrieveAllFilterLists(List<HttpActivity> httpActivities) {
    // Status Codes
    final statusCodeGroup = httpActivities.groupListsBy((activity) {
      return activity.response?.responseStatusCode;
    });
    allStatusCodes.clear();
    for (final element in statusCodeGroup.entries) {
      allStatusCodes[element.key] = element.value.length;
    }

    // Methods
    final methodGroup = httpActivities.groupListsBy((activity) {
      return activity.request?.method ?? 'Unknown';
    });
    allMethods.clear();
    for (final element in methodGroup.entries) {
      allMethods[element.key] = element.value.length;
    }

    // Base URLs
    final baseUrlGroup = httpActivities.groupListsBy((activity) {
      return activity.request?.baseUrl ?? 'Unknown';
    });
    allBaseUrls.clear();
    for (final element in baseUrlGroup.entries) {
      allBaseUrls[element.key] = element.value.length;
    }

    // Paths
    final pathGroup = httpActivities.groupListsBy((activity) {
      return activity.request?.path ?? 'Unknown';
    });
    allPaths.clear();
    for (final element in pathGroup.entries) {
      allPaths[element.key] = element.value.length;
    }
  }

  void retrieveCurrentFilterLists(List<HttpActivity> httpActivities) {
    // Текущие отфильтрованные данные
    final statusCodeGroup = httpActivities.groupListsBy((activity) {
      return activity.response?.responseStatusCode;
    });
    filteredStatusCodes.clear();
    for (final element in statusCodeGroup.entries) {
      filteredStatusCodes[element.key] = element.value.length;
    }

    final methodGroup = httpActivities.groupListsBy((activity) {
      return activity.request?.method ?? 'Unknown';
    });
    filteredMethods.clear();
    for (final element in methodGroup.entries) {
      filteredMethods[element.key] = element.value.length;
    }

    final baseUrlGroup = httpActivities.groupListsBy((activity) {
      return activity.request?.baseUrl ?? 'Unknown';
    });
    filteredBaseUrls.clear();
    for (final element in baseUrlGroup.entries) {
      filteredBaseUrls[element.key] = element.value.length;
    }

    final pathGroup = httpActivities.groupListsBy((activity) {
      return activity.request?.path ?? 'Unknown';
    });
    filteredPaths.clear();
    for (final element in pathGroup.entries) {
      filteredPaths[element.key] = element.value.length;
    }
  }


  Future<void> deleteActivities() async {
    await _fetchHttpActivities?.deleteHttpActivities();
    fetchActivities();
  }

  Future<void> goToDetailActivity(HttpActivity httpActivity) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ActivityDetailPage(
          httpActivity: httpActivity,
        ),
      ),
    );
  }
}
