import 'package:flutter/material.dart';

import '../../common/utils/use_case.dart';
import '../entities/http_activity.dart';
import '../repositories/log_repository.dart';

/// @nodoc
class FetchHttpActivities
    extends UseCase<List<HttpActivity>?, FetchHttpActivitiesParam?> {
  final LogRepository logRepository;

  FetchHttpActivities({
    required this.logRepository,
  });

  @override
  Future<List<HttpActivity>?> build(FetchHttpActivitiesParam? param) async {
    var result = await logRepository.httpActivities(
      statusCodes: param?.statusCodes,
      baseUrls: param?.baseUrls,
      paths: param?.paths,
      methods: param?.methods,
    );
    return result;
  }

  Future<bool> deleteHttpActivities() async {
    var result = await logRepository.deleteHttpActivities();
    return result;
  }

  @override
  Future<void> handleError(error) async {
    debugPrint('$error');
  }
}

class FetchHttpActivitiesParam {
  final List<int?>? statusCodes;
  final List<String>? baseUrls;
  final List<String>? paths;
  final List<String>? methods;

  FetchHttpActivitiesParam({
    this.statusCodes,
    this.baseUrls,
    this.paths,
    this.methods,
  });
}
