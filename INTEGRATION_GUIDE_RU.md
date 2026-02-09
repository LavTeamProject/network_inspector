# Руководство по интеграции Network Inspector

**Network Inspector** — это библиотека для логирования и отладки HTTP-запросов в приложениях Flutter. Поддерживает клиенты **Dio**, **Chopper** и стандартный **HTTP** (пакет `http`). Позволяет в реальном времени просматривать запросы и ответы, переключать окружения, визуализировать касания и сохранять логи в SQLite.

---

## 1. Добавление зависимости

В файл `pubspec.yaml` вашего проекта добавьте:

```yaml
dependencies:
  flutter:
    sdk: flutter
  network_inspector: ^1.1.4   # актуальная версия из CHANGELOG.md

  # Выберите нужные HTTP-клиенты (одну или несколько):
  dio: ^5.9.0                 # для Dio
  chopper: ^8.5.0             # для Chopper
  http: ^1.6.0                # для стандартного HTTP

dev_dependencies:
  build_runner: ^2.10.4       # для кодогенерации Chopper
  chopper_generator: ^8.5.0   # генератор кода Chopper
```

Выполните `flutter pub get`.

---

## 2. Инициализация в main()

В функции `main()` вашего приложения инициализируйте Network Inspector **до** запуска приложения:

```dart
import 'package:flutter/material.dart';
import 'package:network_inspector/network_inspector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация с конфигурацией окружений (обязательно)
  // Если окружения не нужны, передайте пустой список
  await NetworkInspector.initializeWithEnvironments(
    environments: [
      EnvironmentConfig(
        name: 'Stage',
        baseUrl: 'https://jsonplaceholder.typicode.com',
        color: Colors.orange,
      ),
      EnvironmentConfig(
        name: 'Production',
        baseUrl: 'https://reqres.in/api',
        color: Colors.green,
      ),
      EnvironmentConfig(
        name: 'Mock API',
        baseUrl: 'https://httpbin.org',
        color: Colors.blue,
      ),
    ],
  );

  // Включение мониторинга сети (показывает плавающий круг)
  NetworkInspector.enable();

  runApp(const MyApp());
}
```

**Важно:** Метод `NetworkInspector.initialize()` отсутствует в текущей версии библиотеки. Используйте только `initializeWithEnvironments`. Если окружения не требуются, передайте пустой список `environments: []`.

---

## 3. Настройка окружений (опционально)

Если вы используете несколько API-окружений (stage, production, mock), определите перечисление и конвертацию в `EnvironmentConfig`. Пример из `demo_blackbox`:

```dart
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

  static List<EnvironmentConfig> get allConfigs =>
      values.map((e) => e.toLibraryConfig()).toList();
}
```

Затем передайте `allConfigs` в `initializeWithEnvironments`.

---

## 4. Интеграция с Dio

Создайте экземпляр `Dio` и добавьте интерцептор `DioInterceptor`.

```dart
import 'package:dio/dio.dart';
import 'package:network_inspector/common/utils/dio_interceptor.dart';
import 'package:network_inspector/network_inspector.dart';

Dio createDioClient(String baseUrl) {
  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    DioInterceptor(
      logIsAllowed: true,            // включить логирование
      isConsoleLogAllowed: true,     // вывод в консоль
      networkInspector: NetworkInspector.instance,
      onHttpFinish: (hashCode, title, message) {
      },
    ),
  );

  return dio;
}
```

Используйте клиент как обычно:

```dart
final dio = createDioClient('https://jsonplaceholder.typicode.com');
final response = await dio.get('/posts/1');
```

---

## 5. Интеграция с Chopper

Chopper требует кодогенерации. Опишите API-сервис с аннотациями, затем создайте клиент с интерцептором `PrettyChopperLogger`.

### 5.1. Определение сервиса (например, `json_placeholder_service.dart`):

```dart
import 'package:chopper/chopper.dart';
import 'package:network_inspector/common/utils/chopper_interceptor.dart';
import 'package:network_inspector/network_inspector.dart';

part 'json_placeholder_service.chopper.dart';

@ChopperApi(baseUrl: '/')
abstract class JsonPlaceholderService extends ChopperService {
  @Get(path: 'posts/{id}')
  Future<Response> getPost(@Path('id') int id);

  @Post(path: 'posts')
  Future<Response> createPost(@Body() Map<String, dynamic> body);

  static JsonPlaceholderService create([ChopperClient? client]) =>
      _$JsonPlaceholderService(client ?? ChopperClient());
}
```

### 5.2. Создание клиента с интерцептором:

```dart
ChopperClient createChopperClient(String baseUrl) {
  return ChopperClient(
    baseUrl: Uri.parse(baseUrl),
    interceptors: [
      PrettyChopperLogger(
        networkInspector: NetworkInspector.instance,
      ),
      HttpLoggingInterceptor(), // стандартный логгер Chopper
    ],
    converter: const JsonConverter(),
    errorConverter: const JsonConverter(),
  );
}
```

### 5.3. Генерация кода:

Запустите в терминале:
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 5.4. Использование:

```dart
final client = createChopperClient('https://jsonplaceholder.typicode.com');
final service = JsonPlaceholderService.create(client);
final response = await service.getPost(1);
```

---

## 6. Интеграция с HTTP (пакет `http`)

Используйте класс `HttpInterceptor`, который оборачивает стандартный `Client`.

```dart
import 'package:http/http.dart' as http;
import 'package:network_inspector/common/utils/http_interceptor.dart';
import 'package:network_inspector/network_inspector.dart';

http.Client createHttpClient(String baseUrl) {
  return HttpInterceptor(
    logIsAllowed: true,
    client: http.Client(),
    baseUrl: Uri.parse(baseUrl),
    networkInspector: NetworkInspector.instance,
    onHttpFinish: (hashCode, title, message) {
      NetworkInspector.showFloatingCircle(context);
    },
    headers: {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
  );
}
```

Использование:

```dart
final client = createHttpClient('https://jsonplaceholder.typicode.com');
final response = await client.get(Uri.parse('${baseUrl}/posts/1'));
```

---

## 7. Доступ к UI (страница активностей)

Чтобы открыть интерфейс Network Inspector, используйте `ActivityPage`:

```dart
import 'package:flutter/material.dart';
import 'package:network_inspector/presentation/pages/activity_page.dart';

void openNetworkInspector(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => const ActivityPage()),
  );
}
```

Либо используйте плавающий круг (`FloatingCircle`), который появляется автоматически после вызова `NetworkInspector.enable()`. Круг можно перетаскивать, при нажатии открывается `ActivityPage`.

---

## 8. Дополнительные возможности

### Визуализация касаний (Touch Indicator)

Оберните ваше приложение в `TouchIndicator` для отладки касаний:

```dart
MaterialApp(
  builder: (context, child) => TouchIndicator(child: child!),
  home: MyHomePage(),
);
```

Включить/выключить индикаторы можно через `NetworkInspector.toggleTouchIndicators()`.

### Синхронизация окружений

Если вы настроили несколько окружений, можно синхронизировать выбор между приложением и Network Inspector:

```dart
// Установить текущее окружение в библиотеку
NetworkInspector.selectedEnvironment = currentEnv.toLibraryConfig();

// Слушать изменения окружения из UI Network Inspector
NetworkInspector.onEnvironmentSelected = (EnvironmentConfig config) {
  print('Пользователь выбрал окружение: ${config.name}');
  // Обновите базовый URL в ваших клиентах
  dio.options.baseUrl = config.baseUrl;
  // Сохраните выбор в SharedPreferences
};
```


---

## 9. Пример из demo_blackbox

В папке `demo_blackbox` находится полный пример использования всех трёх клиентов с переключением окружений и сохранением настроек в `SharedPreferences`. Ключевые файлы:

- `lib/main.dart` – инициализация и настройка окружений
- `lib/common/enums.dart` – определения окружений и типов клиентов
- `lib/screens/dio_demo_screen.dart` – работа с Dio
- `lib/screens/chopper_demo_screen.dart` – работа с Chopper
- `lib/screens/http_interceptor_demo_screen.dart` – работа с HTTP

Чтобы запустить пример:
```bash
cd demo_blackbox
flutter run
```

---

## 10. Частые проблемы

### 1. Интерцептор не логирует запросы
- Убедитесь, что вызваны `NetworkInspector.initializeWithEnvironments()` и `NetworkInspector.enable()`.
- Проверьте, что `logIsAllowed: true` и `NetworkInspector.isEnabled` возвращает `true`.

### 2. Плавающий круг не появляется
- Круг показывается после первого запроса или при вызове `NetworkInspector.showFloatingCircle(context)`.
- Убедитесь, что в `onHttpFinish` передан корректный `BuildContext` (можно использовать `Navigator.of(context).rootNavigator.context`).
- Проверьте, что `NetworkInspector.enable()` вызван до любого запроса.

### 3. Ошибки кодогенерации Chopper
- Запустите `flutter pub run build_runner build --delete-conflicting-outputs`.
- Убедитесь, что в `pubspec.yaml` добавлены `build_runner` и `chopper_generator` в `dev_dependencies`.
- Проверьте, что все аннотации `@ChopperApi`, `@Get`, `@Post` импортированы из пакета `chopper`.

### 4. Не сохраняются логи в SQLite
- Проверьте разрешения на запись в базу данных (на iOS/Android они есть по умолчанию).
- Убедитесь, что не происходит исключений в интерцепторе.
- Убедитесь, что `networkInspector` не `null` и передан в интерцептор.

---

## 11. Полезные ссылки

- [Официальный README](README.md) (англ.)
- [Пример использования](EXAMPLE.md)
- [Changelog](CHANGELOG.md)
- [Исходный код](https://github.com/meruya-technology/network_inspector)

---

**Успешной отладки!** 🚀