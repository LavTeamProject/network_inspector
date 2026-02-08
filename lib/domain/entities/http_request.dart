/// @nodoc
class HttpRequest {
  final int? id;
  final int? createdAt;
  final String? baseUrl;
  final String? path;
  final String? params;
  final String? method;
  final String? requestHeader;
  final String? requestBody;
  final int? requestSize;
  final int? requestHashCode;
  final String? cUrl;

  HttpRequest({
    this.id,
    this.createdAt,
    this.baseUrl,
    this.path,
    this.params,
    this.method,
    this.requestHeader,
    this.requestBody,
    this.requestSize,
    this.requestHashCode,
    this.cUrl,
  });
}


extension HttpRequestUrlExtension on HttpRequest {
  String get fullUrl {
    final baseUrl = this.baseUrl ?? '';
    final path = this.path ?? '';
    final params = this.params;

    if (params == null || params.isEmpty) {
      return baseUrl + path;
    }

    if (params.startsWith('{') && params.endsWith('}')) {
      final cleaned = params.substring(1, params.length - 1)
          .replaceAll('"', '')
          .replaceAll("'", '');

      final pairs = cleaned.split(',');
      final queryParts = <String>[];

      for (final pair in pairs) {
        final parts = pair.trim().split(':');
        if (parts.length == 2) {
          final key = parts[0].trim();
          final value = parts[1].trim();
          queryParts.add('${Uri.encodeQueryComponent(key)}=${Uri.encodeQueryComponent(value)}');
        }
      }

      final queryString = queryParts.join('&');
      if (queryString.isNotEmpty) {
        return '$baseUrl$path?$queryString';
      }
    }

    final cleanParams = params.startsWith('?') ? params.substring(1) : params;
    return '$baseUrl$path?$cleanParams';
  }
}
