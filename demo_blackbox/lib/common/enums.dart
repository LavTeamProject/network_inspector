import 'package:flutter/material.dart';
import 'package:network_inspector/network_inspector.dart';

// Тип HTTP клиента
enum HttpClientType {
  dio(name: 'Dio', icon: Icons.flash_on, color: Colors.blue),
  chopper(name: 'Chopper', icon: Icons.cut, color: Colors.green),
  http(name: 'Http Interceptor', icon: Icons.http, color: Color(0xFF28A745));

  const HttpClientType({
    required this.name,
    required this.icon,
    required this.color,
  });

  final String name;
  final IconData icon;
  final Color color;
}

// Окружения приложения
enum AppEnvironment {
  stage(name: 'Stage', baseUrl: 'https://jsonplaceholder.typicode.com', color: Colors.orange),
  production(name: 'Production', baseUrl: 'https://reqres.in/api', color: Colors.green),
  mockApi(name: 'Mock API', baseUrl: 'https://httpbin.org', color: Colors.blue);

  const AppEnvironment({
    required this.name,
    required this.baseUrl,
    required this.color,
  });

  final String name;
  final String baseUrl;
  final Color color;

  EnvironmentConfig toLibraryConfig() => EnvironmentConfig(
    name: name,
    baseUrl: baseUrl,
    color: color,
  );

  static List<EnvironmentConfig> get allConfigs => values.map((e) => e.toLibraryConfig()).toList();
  static AppEnvironment? fromName(String name) => values.firstWhereOrNull((e) => e.name == name);
}

// Модель для сохранения настроек
class AppSettings {
  final HttpClientType httpClient;
  final AppEnvironment environment;

  const AppSettings({
    required this.httpClient,
    required this.environment,
  });

  Map<String, dynamic> toJson() => {
    'http_client': httpClient.name,
    'environment': environment.name,
  };

  static AppSettings fromJson(Map<String, dynamic> json) {
    final httpClient = HttpClientType.values.firstWhere(
          (e) => e.name == json['http_client'],
      orElse: () => HttpClientType.dio,
    );

    final environment = AppEnvironment.values.firstWhere(
          (e) => e.name == json['environment'],
      orElse: () => AppEnvironment.stage,
    );

    return AppSettings(
      httpClient: httpClient,
      environment: environment,
    );
  }
}


extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}