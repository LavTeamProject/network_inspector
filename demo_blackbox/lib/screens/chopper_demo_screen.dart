import 'package:flutter/material.dart';
import 'package:chopper/chopper.dart';
import 'package:network_inspector/common/utils/chopper_interceptor.dart';
import 'package:network_inspector/network_inspector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../common/enums.dart';
import '../services/shared_prefs_service.dart';
import 'client_selection_screen.dart';
part 'chopper_demo_screen.chopper.dart';


@ChopperApi(baseUrl: '/')
abstract class JsonPlaceholderService extends ChopperService {
  @Get(path: 'posts/{id}')
  Future<Response> getPost(@Path('id') int id);

  @Post(path: 'posts')
  Future<Response> createPost(@Body() Map<String, dynamic> body);

  @Put(path: 'posts/{id}')
  Future<Response> updatePost(
      @Path('id') int id,
      @Body() Map<String, dynamic> body,
      );

  @Delete(path: 'posts/{id}')
  Future<Response> deletePost(@Path('id') int id);

  static JsonPlaceholderService create([ChopperClient? client]) =>
      _$JsonPlaceholderService(client ?? ChopperClient());
}

class ChopperDemoScreen extends StatefulWidget {
  const ChopperDemoScreen({super.key});

  @override
  State<ChopperDemoScreen> createState() => _ChopperDemoScreenState();
}

class _ChopperDemoScreenState extends State<ChopperDemoScreen> {
  late ChopperClient _chopperClient;
  late JsonPlaceholderService _chopperService;
  AppEnvironment _currentEnv = AppEnvironment.stage;
  final SharedPrefsService _prefsService = SharedPrefsService();
  bool _isLoading = false;
  String _lastResponse = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeChopper();
  }

  Future<void> _loadSettings() async {
    final settings = await _prefsService.loadSettings();
    setState(() {
      _currentEnv = settings.environment;
    });
  }

  void _initializeChopper() {
    // Создаем интерсепторы
    final requestInterceptor = (Request request) async {
      print('🌐 Chopper Request: ${request.method} ${request.url}');
      return request;
    };

    final responseInterceptor = (Response response) async {
      if (response.isSuccessful) {
        print('✅ Chopper Response: ${response.statusCode}');
      } else {
        print('❌ Chopper Error: ${response.statusCode} ${response.error}');
      }
      return response;
    };

    // Создаем клиент
    _chopperClient = ChopperClient(
      baseUrl: Uri.parse(_currentEnv.baseUrl),
      interceptors: [
        PrettyChopperLogger(
          networkInspector: NetworkInspector.instance,
        ),
        HttpLoggingInterceptor(),
      ],
      converter: const JsonConverter(),
      errorConverter: const JsonConverter(),
    );

    _chopperService = JsonPlaceholderService.create(_chopperClient);
  }

  void _updateResponse(String message) {
    setState(() {
      _lastResponse = message;
    });
  }

  Future<void> _testGetRequest() async {
    setState(() => _isLoading = true);
    _updateResponse('Выполняем GET запрос через Chopper...');

    try {
      final response = await _chopperService.getPost(1);

      if (response.isSuccessful) {
        _updateResponse('✅ Успешно!\nСтатус: ${response.statusCode}\nДанные: ${response.body}');
      } else {
        _updateResponse('❌ Ошибка: ${response.statusCode}\n${response.error}');
      }
    } catch (e) {
      _updateResponse('❌ Исключение: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testPostRequest() async {
    setState(() => _isLoading = true);
    _updateResponse('Выполняем POST запрос через Chopper...');

    try {
      final data = {
        'title': 'Chopper Test Post',
        'body': 'This is a test post from Chopper',
        'userId': 1,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await _chopperService.createPost(data);

      if (response.isSuccessful) {
        _updateResponse('✅ Успешно!\nСтатус: ${response.statusCode}\nID: ${response.body['id']}');
      } else {
        _updateResponse('❌ Ошибка: ${response.statusCode}');
      }
    } catch (e) {
      _updateResponse('❌ Исключение: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testPutRequest() async {
    setState(() => _isLoading = true);
    _updateResponse('Выполняем PUT запрос через Chopper...');

    try {
      final data = {
        'id': 1,
        'title': 'Updated via Chopper',
        'body': 'Updated content via Chopper',
        'userId': 1,
      };

      final response = await _chopperService.updatePost(1, data);

      if (response.isSuccessful) {
        _updateResponse('✅ Успешно!\nСтатус: ${response.statusCode}');
      } else {
        _updateResponse('❌ Ошибка: ${response.statusCode}');
      }
    } catch (e) {
      _updateResponse('❌ Исключение: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testDeleteRequest() async {
    setState(() => _isLoading = true);
    _updateResponse('Выполняем DELETE запрос через Chopper...');

    try {
      final response = await _chopperService.deletePost(1);

      if (response.isSuccessful) {
        _updateResponse('✅ Успешно!\nСтатус: ${response.statusCode}');
      } else {
        _updateResponse('❌ Ошибка: ${response.statusCode}');
      }
    } catch (e) {
      _updateResponse('❌ Исключение: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _switchEnvironment(AppEnvironment env) async {
    setState(() {
      _currentEnv = env;
    });

    // Пересоздаем клиент с новым baseUrl
    // _chopperClient.close();
    _initializeChopper();

    final settings = await _prefsService.loadSettings();
    await _prefsService.saveSettings(
      AppSettings(
        httpClient: settings.httpClient,
        environment: env,
      ),
    );

    _updateResponse('✅ Переключено на ${env.name}');
  }

  @override
  void dispose() {
    // _chopperClient.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Icon(Icons.cut, color: _currentEnv.color),
            // const SizedBox(width: 8),
            const Text('Chopper Demo'),
            // const Spacer(),
            // Container(
            //   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            //   decoration: BoxDecoration(
            //     color: _currentEnv.color.withOpacity(0.1),
            //     borderRadius: BorderRadius.circular(20),
            //   ),
            //   child: Text(
            //     _currentEnv.name,
            //     style: TextStyle(
            //       color: _currentEnv.color,
            //       fontWeight: FontWeight.w600,
            //     ),
            //   ),
            // ),
          ],
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          // PopupMenuButton<AppEnvironment>(
          //   icon: const Icon(Icons.settings),
          //   onSelected: _switchEnvironment,
          //   itemBuilder: (context) => AppEnvironment.values.map((env) => PopupMenuItem(
          //     value: env,
          //     child: Row(
          //       children: [
          //         Icon(Icons.circle, color: env.color, size: 16),
          //         const SizedBox(width: 12),
          //         Text(env.name),
          //       ],
          //     ),
          //   )).toList(),
          // ),
          // IconButton(
          //   icon: const Icon(Icons.swap_horiz),
          //   onPressed: () {
          //     Navigator.of(context).pushReplacement(
          //       MaterialPageRoute(builder: (_) => const ClientSelectionScreen()),
          //     );
          //   },
          //   tooltip: 'Сменить клиент',
          // ),
        ],
      ),
      body: Column(
        children: [
          // Информация о Chopper
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.green[50],
            child: Column(
              children: [
                const Icon(Icons.code, size: 48, color: Colors.green),
                const SizedBox(height: 12),
                const Text(
                  'Chopper - HTTP клиент с кодогенерацией',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'API описывается аннотациями, код генерируется автоматически',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),

          // Кнопки запросов
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
                children: [
                  _buildRequestButton(
                    icon: Icons.download,
                    label: 'GET запрос',
                    color: Colors.blue,
                    onPressed: _testGetRequest,
                  ),
                  _buildRequestButton(
                    icon: Icons.upload,
                    label: 'POST запрос',
                    color: Colors.green,
                    onPressed: _testPostRequest,
                  ),
                  _buildRequestButton(
                    icon: Icons.edit,
                    label: 'PUT запрос',
                    color: Colors.orange,
                    onPressed: _testPutRequest,
                  ),
                  _buildRequestButton(
                    icon: Icons.delete,
                    label: 'DELETE запрос',
                    color: Colors.red,
                    onPressed: _testDeleteRequest,
                  ),
                  _buildRequestButton(
                    icon: Icons.api,
                    label: 'Тест аннотаций',
                    color: Colors.purple,
                    onPressed: () {
                      _updateResponse('Chopper использует аннотации для описания API\n\n'
                          '@Get(path: "posts/{id}")\n'
                          'Future<Response> getPost(@Path("id") int id);\n\n'
                          'Код генерируется автоматически через build_runner');
                    },
                  ),
                  _buildRequestButton(
                    icon: Icons.compare,
                    label: 'Сравнить с Dio',
                    color: Colors.brown,
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const ClientSelectionScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),

          // Область ответа
          Container(
            height: 200,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Результат:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _isLoading ? 'Загрузка...' : _lastResponse,
                        style: TextStyle(
                          color: _lastResponse.startsWith('✅')
                              ? Colors.green
                              : _lastResponse.startsWith('❌')
                              ? Colors.red
                              : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: _isLoading ? null : onPressed,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}