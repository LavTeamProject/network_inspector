import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:network_inspector/presentation/widgets/floating_circle.dart';
import 'package:network_inspector/presentation/widgets/touch_indicator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:network_inspector/common/utils/dio_interceptor.dart';
import 'package:network_inspector/network_inspector.dart';

// ✅ Extension для firstWhereOrNull
extension ListExtension<T> on List<T> {
  T? firstWhereOrNull(bool Function(T element) test) {
    for (final element in this) {
      if (test(element)) return element;
    }
    return null;
  }
}

enum AppEnvironment {
  stage(name: 'Stage', baseUrl: 'https://jsonplaceholder.typicode.com', color: Colors.orange),
  production(name: 'Production', baseUrl: 'https://reqres.in/api', color: Colors.green);

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

// ✅ Глобальное состояние
Dio? _globalDio;
AppEnvironment currentAppEnv = AppEnvironment.stage;
SharedPreferences? _prefs;

Future<void> saveEnvironment(AppEnvironment env) async {
  _prefs?.setString('selected_environment', env.name);
}

Future<void> loadEnvironment() async {
  _prefs = await SharedPreferences.getInstance();
  final savedEnvName = _prefs?.getString('selected_environment') ?? 'Stage';
  currentAppEnv = AppEnvironment.fromName(savedEnvName) ?? AppEnvironment.stage;
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Загружаем сохраненное окружение
  await loadEnvironment();

  await NetworkInspector.initializeWithEnvironments(
    environments: AppEnvironment.allConfigs,
  );

  // ✅ Восстанавливаем состояние библиотеки
  NetworkInspector.selectedEnvironment = currentAppEnv.toLibraryConfig();

  // ✅ Callback: Библиотека → Приложение + сохранение
  NetworkInspector.onEnvironmentSelected = (config) async {
    print('🎉 Library → App: ${config.name} → ${config.baseUrl}');
    final appEnv = AppEnvironment.fromName(config.name);
    if (appEnv != null) {
      currentAppEnv = appEnv;
      _globalDio?.options.baseUrl = config.baseUrl;
      await saveEnvironment(currentAppEnv); // ✅ Сохраняем!
      print('✅ Saved: ${currentAppEnv.name}');
    }
  };

  runApp(
      MyApp(),
  );
}

// ✅ Функция для ручного переключения (тест)
void switchEnvironment(AppEnvironment newEnv) async {
  currentAppEnv = newEnv;
  NetworkInspector.selectedEnvironment = newEnv.toLibraryConfig();
  _globalDio?.options.baseUrl = newEnv.baseUrl;
  await saveEnvironment(newEnv);
  print('✅ Switched & Saved: ${newEnv.name}');
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'NetworkInspector Demo',
      theme: ThemeData(useMaterial3: true),
        builder: (context, child) => TouchIndicator(child: child!),
        home: HomePage()
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    NetworkInspector.enable();

    _globalDio = Dio(
      BaseOptions(
        baseUrl: currentAppEnv.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    _globalDio!.interceptors.add(
      DioInterceptor(
        logIsAllowed: true,
        networkInspector: NetworkInspector.instance,
        onHttpFinish: (hashCode, title, message) {
          NetworkInspector.showFloatingCircle(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.api, color: currentAppEnv.color),
            const SizedBox(width: 8),
            Text(currentAppEnv.name),
            const Spacer(),
            Text(
              currentAppEnv.baseUrl.split('/').last,
              style: TextStyle(fontSize: 14, color: currentAppEnv.color.withOpacity(0.7)),
            ),
          ],
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        actions: [
          // ✅ Кнопка для тестирования сохранения
          PopupMenuButton<AppEnvironment>(
            icon: const Icon(Icons.settings),
            onSelected: switchEnvironment,
            itemBuilder: (context) => AppEnvironment.values.map((env) => PopupMenuItem(
              value: env,
              child: Row(
                children: [
                  Icon(Icons.circle, color: env.color, size: 16),
                  const SizedBox(width: 12),
                  Text(env.name),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.network_check, size: 80, color: currentAppEnv.color),
            const SizedBox(height: 20),
            Text(
              '🌐 ${currentAppEnv.name}\n${currentAppEnv.baseUrl}\n✅ Persistent!',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () => _testApi('/posts/1'),
              icon: const Icon(Icons.list),
              label: const Text('GET Posts'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => _testApi('/users'),
              icon: const Icon(Icons.person),
              label: const Text('GET Users'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _toggleCircle,
              icon: const Icon(Icons.circle),
              label: const Text('Toggle Circle'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _openNewScreen,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open New Screen'),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
            ),
          ],
        )
      ),
    );
  }

  Future<void> _testApi(String endpoint) async {
    try {
      print('🌐 ${currentAppEnv.name}: $endpoint');
      final response = await _globalDio!.get(endpoint);
      print('✅ ${response.statusCode}: ${response.data}');
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  void _toggleCircle() {
    NetworkInspector.showFloatingCircle(context);
  }

  void _openNewScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NewScreen(),
      ),
    );
  }

}



class NewScreen extends StatelessWidget {
  const NewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Screen'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.open_in_new, size: 80),
            const SizedBox(height: 16),
            const Text(
              'This is a new screen 🚀',
              style: TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),


          ],
        ),
      ),
    );
  }
}
