import '../../domain/entities/http_activity.dart';
import '../../domain/entities/http_request.dart';
import '../../domain/entities/http_response.dart';
import '../../domain/repositories/log_repository.dart';
import '../datasources/log_datasource.dart';
import '../mappers/http_activity_mapper.dart';
import '../mappers/http_request_mapper.dart';
import '../mappers/http_response_mapper.dart';

/// @nodoc
class LogRepositoryImpl implements LogRepository {
  final LogDatasource logDatasource;

  LogRepositoryImpl({
    required this.logDatasource,
  });

  @override
  Future<List<HttpActivity>?> httpActivities({
    int? startDate,
    int? endDate,
    List<int?>? statusCodes,
    List<String>? baseUrls,
    List<String>? paths,
    List<String>? methods,
    String? url,
  }) async {
    try {
      final result = await logDatasource.httpActivities(
        startDate: startDate,
        endDate: endDate,
        statusCodes: statusCodes,
        baseUrls: baseUrls,
        paths: paths,
        methods: methods,
        url: url,
      );

      if (result == null) {
        return null;
      }

      var entities = List<HttpActivity>.from(
        result.map(
              (model) {
            return HttpActivityMapper.toEntity(model);
          },
        ),
      );

      return entities;
    } catch (e, stackTrace) {
      print('🔴 Error in httpActivities: $e');
      print('🔴 Stack trace: $stackTrace');
      return null;
    }
  }

  @override
  Future<List<HttpRequest>?> httpRequests({
    int? requestHashCode,
  }) async {
    try {
      var models = await logDatasource.httpRequests(
        requestHashCode: requestHashCode,
      );

      var entities = (models != null)
          ? List<HttpRequest>.from(
        models.map(
              (model) {
            return HttpRequestMapper.toEntity(model);
          },
        ),
      )
          : null;

      return entities;
    } catch (e) {
      print('🔴 Error in httpRequests: $e');
      return null;
    }
  }

  @override
  Future<List<HttpResponse>?> httpResponses({
    int? requestHashCode,
  }) async {
    var models = await logDatasource.httpResponses(
      requestHashCode: requestHashCode,
    );
    var entities = (models != null)
        ? List<HttpResponse>.from(
            models.map(
              (model) => HttpResponseMapper.toEntity(
                model,
              ),
            ),
          )
        : null;
    return entities;
  }

  @override
  Future<bool> logHttpRequest({
    required HttpRequest httpRequestModel,
  }) async {
    try {
      var model = HttpRequestMapper.toModel(httpRequestModel);

      var result = await logDatasource.logHttpRequest(
        httpRequestModel: model,
      );

      return result;
    } catch (e, stackTrace) {
      print('🔴 Error in logHttpRequest: $e');
      print('🔴 Stack trace: $stackTrace');
      return false;
    }
  }


  @override
  Future<bool> logHttpResponse({
    required HttpResponse httpResponseModel,
  }) async {
    try {
      var model = HttpResponseMapper.toModel(httpResponseModel);
      var result = await logDatasource.logHttpResponse(
        httpResponseModel: model,
      );

      // После сохранения ответа, проверим, есть ли связанный запрос
      final relatedRequests = await httpRequests(
          requestHashCode: httpResponseModel.requestHashCode
      );
      print('💾 Related requests found: ${relatedRequests?.length ?? 0}');

      return result;
    } catch (e, stackTrace) {
      print('🔴 Error in logHttpResponse: $e');
      print('🔴 Stack trace: $stackTrace');
      return false;
    }
  }

  @override
  Future<bool> deleteHttpActivities() async {
    var result = logDatasource.deleteHttpActivities();
    return result;
  }
}
