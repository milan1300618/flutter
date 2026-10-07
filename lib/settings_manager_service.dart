import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_config.dart'; // Import predošlej statickej konfigurácie

class SettingsManagerService {
  // Súkromný konštruktor na zabránenie inštancie
  SettingsManagerService._();

  static const String _storageKey = "storyfund_settings";

  /// Generuje predvolené hodnoty (ekvivalent k _default_settings() z Pythonu)
  static Map<String, dynamic> _defaultSettings() {
    return {
      "APP_NAME": AppConfig.appName,
      "APP_VERSION": AppConfig.appVersion,
      "APP_BUILD": AppConfig.appBuild,
      "TEST_MODE": AppConfig.testMode,
      "WORDS_TO_SHOW": AppConfig.wordsToShow,
      "WORDS_TO_SELECT": AppConfig.wordsToSelect,
      "MAX_GENERATIONS": AppConfig.maxGenerations,
      "MAX_STORIES_PER_CYCLE": AppConfig.maxStoriesPerCycle,
      "MIN_AI_SCORE": AppConfig.minAiScore,
      "MAX_AI_SCORE": AppConfig.maxAiScore,
      "SHOW_AI_SCORE": AppConfig.showAiScore,
      "SHOW_SELECTED_WORDS": AppConfig.showSelectedWords,
      "ENABLE_COMMENTS": AppConfig.enableComments,
      "TRANSPARENT_ACCOUNT": AppConfig.transparentAccount,
    };
  }

  /// Načíta nastavenia z úložiska SharedPreferences a doplní chýbajúce hodnoty z konfigurácie
  static Future<Map<String, dynamic>> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_storageKey);
    final Map<String, dynamic> defaults = _defaultSettings();

    if (jsonString == null) {
      await saveSettings(defaults);
      return defaults;
    }

    Map<String, dynamic> settings;
    try {
      settings = Map<String, dynamic>.from(jsonDecode(jsonString));
    } catch (_) {
      settings = {};
    }

    bool changed = false;

    // Doplnenie chýbajúcich kľúčov, ak sa verzia aplikácie aktualizovala
    for (var entry in defaults.entries) {
      if (!settings.containsKey(entry.key)) {
        settings[entry.key] = entry.value;
        changed = true;
      }
    }

    if (changed) {
      await saveSettings(settings);
    }

    return settings;
  }

  /// Uloží kompletnú mapu nastavení do pamäte zariadenia
  static Future<void> saveSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(settings);
    await prefs.setString(_storageKey, jsonString);
  }

  /// Vráti jednu konkrétnu hodnotu nastavenia (ekvivalent get(key))
  static Future<dynamic> getSetting(String key) async {
    final settings = await loadSettings();
    return settings[key];
  }

  /// Zmení jednu konkrétnu hodnotu nastavenia (ekvivalent set(key, value))
  static Future<void> setSetting(String key, dynamic value) async {
    final settings = await loadSettings();
    settings[key] = value;
    await saveSettings(settings);
  }
}
