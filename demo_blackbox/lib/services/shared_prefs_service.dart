import 'package:shared_preferences/shared_preferences.dart';
import '../common/enums.dart';

class SharedPrefsService {
  static const String _settingsKey = 'app_settings';

  Future<void> saveSettings(AppSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, settings.toJson().toString());
  }

  Future<AppSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_settingsKey);

    if (jsonString != null) {
      try {
        final json = Map<String, dynamic>.from(jsonString as Map);
        return AppSettings.fromJson(json);
      } catch (e) {
        // Если ошибка парсинга, возвращаем настройки по умолчанию
      }
    }

    return const AppSettings(
      httpClient: HttpClientType.dio,
      environment: AppEnvironment.stage,
    );
  }

  Future<void> clearSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_settingsKey);
  }
}