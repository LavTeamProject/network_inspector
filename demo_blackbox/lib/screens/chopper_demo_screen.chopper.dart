// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

part of 'chopper_demo_screen.dart';

// **************************************************************************
// ChopperGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
final class _$JsonPlaceholderService extends JsonPlaceholderService {
  _$JsonPlaceholderService([ChopperClient? client]) {
    if (client == null) return;
    this.client = client;
  }

  @override
  final Type definitionType = JsonPlaceholderService;

  @override
  Future<Response<dynamic>> getPost(int id) {
    final Uri $url = Uri.parse('/posts/${id}');
    final Request $request = Request('GET', $url, client.baseUrl);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> createPost(Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/posts');
    final $body = body;
    final Request $request = Request('POST', $url, client.baseUrl, body: $body);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> updatePost(int id, Map<String, dynamic> body) {
    final Uri $url = Uri.parse('/posts/${id}');
    final $body = body;
    final Request $request = Request('PUT', $url, client.baseUrl, body: $body);
    return client.send<dynamic, dynamic>($request);
  }

  @override
  Future<Response<dynamic>> deletePost(int id) {
    final Uri $url = Uri.parse('/posts/${id}');
    final Request $request = Request('DELETE', $url, client.baseUrl);
    return client.send<dynamic, dynamic>($request);
  }
}
