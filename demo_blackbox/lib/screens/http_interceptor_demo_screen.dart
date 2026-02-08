import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:network_inspector/network_inspector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http_parser/http_parser.dart';
import '../common/enums.dart';
import 'package:network_inspector/common/utils/http_interceptor.dart';

import '../services/shared_prefs_service.dart';
import 'client_selection_screen.dart';

class HttpInterceptorDemoScreen extends StatefulWidget {
  const HttpInterceptorDemoScreen({super.key});

  @override
  State<HttpInterceptorDemoScreen> createState() => _HttpInterceptorDemoScreenState();
}

class _HttpInterceptorDemoScreenState extends State<HttpInterceptorDemoScreen> {
  late http.Client _client;
  AppEnvironment _currentEnv = AppEnvironment.stage;
  final SharedPrefsService _prefsService = SharedPrefsService();
  bool _isLoading = false;
  String _lastResponse = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _initializeClient();
  }

  Future<void> _loadSettings() async {
    final settings = await _prefsService.loadSettings();
    setState(() {
      _currentEnv = settings.environment;
    });
  }

  void _initializeClient() {
    _client = HttpInterceptor(
      logIsAllowed: true,
      client: http.Client(),
      baseUrl: Uri.parse(_currentEnv.baseUrl),
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

  void _updateResponse(String message) {
    setState(() {
      _lastResponse = message;
    });
  }

  Future<void> _testGetRequest() async {
    setState(() => _isLoading = true);
    _updateResponse('Выполняем GET запрос...');

    try {
      final response = await _client.get(
        Uri.parse('${_currentEnv.baseUrl}/posts/1'),
      );

      _updateResponse('✅ Успешно!\nСтатус: ${response.statusCode}\nДанные: ${response.body}');
    } on HttpException catch (e) {
      _updateResponse('❌ Ошибка: ${e.message}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testPostRequest() async {
    setState(() => _isLoading = true);
    _updateResponse('Выполняем POST запрос...');

    try {
      final data = {
        'title': 'Http Interceptor Test Post',
        'body': 'This is a test post from Http Interceptor',
        'userId': 1,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final response = await _client.post(
        Uri.parse('${_currentEnv.baseUrl}/posts'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      final responseData = jsonDecode(response.body);
      _updateResponse('✅ Успешно!\nСтатус: ${response.statusCode}\nID: ${responseData['id']}');
    } on HttpException catch (e) {
      _updateResponse('❌ Ошибка: ${e.message}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testPutRequest() async {
    setState(() => _isLoading = true);
    _updateResponse('Выполняем PUT запрос...');

    try {
      final data = {
        'id': 1,
        'title': 'Updated via Http Interceptor',
        'body': 'Updated content',
        'userId': 1,
      };

      final response = await _client.put(
        Uri.parse('${_currentEnv.baseUrl}/posts/1'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      _updateResponse('✅ Успешно!\nСтатус: ${response.statusCode}');
    } on HttpException catch (e) {
      _updateResponse('❌ Ошибка: ${e.message}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testDeleteRequest() async {
    setState(() => _isLoading = true);
    _updateResponse('Выполняем DELETE запрос...');

    try {
      final response = await _client.delete(
        Uri.parse('${_currentEnv.baseUrl}/posts/1'),
      );

      _updateResponse('✅ Успешно!\nСтатус: ${response.statusCode}');
    } on HttpException catch (e) {
      _updateResponse('❌ Ошибка: ${e.message}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testPatchRequest() async {
    setState(() => _isLoading = true);
    _updateResponse('Выполняем PATCH запрос...');

    try {
      final data = {
        'title': 'Patched via Http Interceptor',
      };

      final response = await _client.patch(
        Uri.parse('${_currentEnv.baseUrl}/posts/1'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      _updateResponse('✅ Успешно!\nСтатус: ${response.statusCode}');
    } on HttpException catch (e) {
      _updateResponse('❌ Ошибка: ${e.message}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _testMultipleRequests() async {
    setState(() => _isLoading = true);
    _updateResponse('Выполняем несколько запросов...');

    try {
      final requests = [
        _client.get(Uri.parse('${_currentEnv.baseUrl}/posts/1')),
        _client.get(Uri.parse('${_currentEnv.baseUrl}/posts/2')),
        _client.get(Uri.parse('${_currentEnv.baseUrl}/posts/3')),
      ];

      final responses = await Future.wait(requests);
      final successCount = responses.where((r) => r.statusCode == 200).length;

      _updateResponse('✅ Завершено! Успешных: $successCount из ${responses.length}');
    } on HttpException catch (e) {
      _updateResponse('❌ Ошибка: ${e.message}');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _switchEnvironment(AppEnvironment env) async {
    setState(() {
      _currentEnv = env;
      _client = HttpInterceptor(
        logIsAllowed: true,
        client: http.Client(),
        baseUrl: Uri.parse(env.baseUrl),
        networkInspector: NetworkInspector.instance,
        onHttpFinish: (hashCode, title, message) {
          NetworkInspector.showFloatingCircle(context);
        },
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
    });

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            // Icon(Icons.http, color: _currentEnv.color),
            // const SizedBox(width: 8),
            const Text('Http Interceptor Demo'),
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
        backgroundColor: const Color(0xFF28A745),
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
          // Кнопки запросов
          Expanded(
            flex: 2,
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
                    icon: Icons.edit_note,
                    label: 'PATCH запрос',
                    color: Colors.purple,
                    onPressed: _testPatchRequest,
                  ),
                  _buildRequestButton(
                    icon: Icons.list,
                    label: 'Множественные\nзапросы',
                    color: Colors.brown,
                    onPressed: _testMultipleRequests,
                  ),
                ],
              ),
            ),
          ),

          // Область ответа
          Expanded(
            flex: 1,
            child: Container(
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
                  const SizedBox(height: 12),
                  Text(
                    'Base URL: ${_currentEnv.baseUrl}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}