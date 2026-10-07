// ======================================
// StoryFund v0.6
// File: app_config.dart
// Centrálna konfigurácia aplikácie
// ======================================

class AppConfig {
  // Súkromný konštruktor zabraňuje vytváraniu inštancií tejto triedy
  AppConfig._();

  // ======================================
  // APLIKÁCIA
  // ======================================
  static const String appName = "StoryFund";
  static const String appVersion = "0.6";
  static const String appBuild = "2026.07.16";

  static const bool testMode = true;

  // ======================================
  // PRÍBEHY
  // ======================================
  static const int wordsToShow = 8;
  static const int wordsToSelect = 4;

  static const int maxGenerations = 3;
  
  // TIP: Ak budete chcieť hodnotu neskôr prepisovať napr. cez settings_manager.py,
  // zmeňte 'const' na 'static int' a odoberte 'const' z názvu premennej.
  static const int maxStoriesPerCycle = 3;

  // ======================================
  // AI
  // ======================================
  static const int minAiScore = 70;
  static const int maxAiScore = 100;

  static const bool showAiScore = true;

  // ======================================
  // ZOBRAZENIE
  // ======================================
  static const bool showSelectedWords = false;

  // ======================================
  // BUDÚCE FUNKCIE
  // ======================================
  static const bool enableComments = false;

  // ======================================
  // TRANSPARENTNÝ ÚČET
  // ======================================
  static const String transparentAccount =
      "https://unicreditbank.sk";
}
