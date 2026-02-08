import 'package:demo_blackbox/screens/http_interceptor_demo_screen.dart';
import 'package:flutter/material.dart';
import 'package:network_inspector/network_inspector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../common/enums.dart';
import '../services/shared_prefs_service.dart';
import 'dio_demo_screen.dart';
import 'chopper_demo_screen.dart';

class ClientSelectionScreen extends StatefulWidget {
  const ClientSelectionScreen({super.key});

  @override
  State<ClientSelectionScreen> createState() => _ClientSelectionScreenState();
}

class _ClientSelectionScreenState extends State<ClientSelectionScreen> {
  HttpClientType? _selectedClient;
  final SharedPrefsService _prefsService = SharedPrefsService();

  @override
  void initState() {
    super.initState();
    _loadSelectedClient();
  }

  Future<void> _loadSelectedClient() async {
    final settings = await _prefsService.loadSettings();
    setState(() {
      _selectedClient = settings.httpClient;
    });
  }

  Future<void> _saveSelectedClient(HttpClientType client) async {
    final settings = await _prefsService.loadSettings();
    final newSettings = AppSettings(
      httpClient: client,
      environment: settings.environment,
    );
    await _prefsService.saveSettings(newSettings);
  }



  void _navigateToDemoScreen() {
    NetworkInspector.showFloatingCircle(context);
    if (_selectedClient == null) return;

    final route = MaterialPageRoute(
      builder: (_) {
        switch (_selectedClient!) {
          case HttpClientType.dio:
            return const DioDemoScreen();
          case HttpClientType.chopper:
            return const ChopperDemoScreen();
          case HttpClientType.http:
            return const HttpInterceptorDemoScreen();
        }
      },
    );
    Navigator.of(context).push(route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Заголовок
              const SizedBox(height: 40),
              const Text(
                'Выберите HTTP-клиент',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Сравните возможности Dio и Chopper',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 40),

              // Карточки выбора
              Expanded(
                child: ListView(
                  children: [
                    _buildClientCard(HttpClientType.dio),
                    const SizedBox(height: 20),
                    _buildClientCard(HttpClientType.chopper),
                    const SizedBox(height: 20),
                    _buildClientCard(HttpClientType.http),
                  ],
                ),
              ),

              // Кнопка продолжения
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedClient != null ? _navigateToDemoScreen : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedClient?.color ?? Colors.grey,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _selectedClient != null
                        ? 'Продолжить с ${_selectedClient!.name}'
                        : 'Выберите клиент',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Ссылка для сброса
              Center(
                child: TextButton(
                  onPressed: () async {
                    await _prefsService.clearSettings();
                    setState(() {
                      _selectedClient = null;
                    });
                  },
                  child: const Text(
                    'Сбросить настройки',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClientCard(HttpClientType client) {
    final isSelected = _selectedClient == client;

    return Card(
      elevation: isSelected ? 8 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? client.color : Colors.transparent,
          width: isSelected ? 3 : 0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          setState(() {
            _selectedClient = client;
          });
          _saveSelectedClient(client);
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Иконка
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: client.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(client.icon, color: client.color, size: 36),
              ),
              const SizedBox(width: 20),

              // Информация
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          client.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: client.color,
                          ),
                        ),
                        const Spacer(),
                        if (isSelected)
                          Icon(Icons.check_circle, color: client.color, size: 28),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getClientDescription(client),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getClientDescription(HttpClientType client) {
    switch (client) {
      case HttpClientType.dio:
        return 'Мощный HTTP-клиент для Dart с поддержкой интерсепторов, FormData, отмены запросов, прогресса загрузки и множества других функций.';
      case HttpClientType.chopper:
        return 'HTTP-клиент с кодогенерацией, вдохновленный Retrofit. Использует аннотации для создания типизированных API клиентов.';
      case HttpClientType.http:
        return 'Легковесный HTTP-клиент с собственным интерсептором. Использует стандартный http пакет с возможностью перехвата запросов и ответов.';
    }
  }

}