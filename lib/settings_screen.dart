import 'package:flutter/material.dart';
import 'settings_manager_service.dart'; // Import predošlého manažéra nastavení

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Ovládacie prvky pre prepínače (Switches)
  bool _testMode = false;
  bool _showAi = true;

  // Ovládače pre textové polia (TextFields)
  final TextEditingController _maxStoriesController = TextEditingController();
  final TextEditingController _winnersController = TextEditingController();
  final TextEditingController _maxGenerationsController = TextEditingController();
  final TextEditingController _wordsToShowController = TextEditingController();
  final TextEditingController _wordsToSelectController = TextEditingController();
  final TextEditingController _minAiController = TextEditingController();
  final TextEditingController _maxAiController = TextEditingController();

  late Future<Map<String, dynamic>> _loadSettingsFuture;

  @override
  void initState() {
    super.initState();
    _loadSettingsFuture = _initSettings();
  }

  @override
  void dispose() {
    _maxStoriesController.dispose();
    _winnersController.dispose();
    _maxGenerationsController.dispose();
    _wordsToShowController.dispose();
    _wordsToSelectController.dispose();
    _minAiController.dispose();
    _maxAiController.dispose();
    super.dispose();
  }

  /// Načíta konfiguráciu a naplní ovládače formulára
  Future<Map<String, dynamic>> _initSettings() async {
    final settings = await SettingsManagerService.loadSettings();

    _testMode = settings["TEST_MODE"] ?? false;
    _showAi = settings["SHOW_AI_SCORE"] ?? true;

    _maxStoriesController.text = (settings["MAX_STORIES_PER_CYCLE"] ?? 3).toString();
    _winnersController.text = (settings["WINNERS_PER_CYCLE"] ?? 12).toString();
    _maxGenerationsController.text = (settings["MAX_GENERATIONS"] ?? 3).toString();
    _wordsToShowController.text = (settings["WORDS_TO_SHOW"] ?? 8).toString();
    _wordsToSelectController.text = (settings["WORDS_TO_SELECT"] ?? 4).toString();
    _minAiController.text = (settings["MIN_AI_SCORE"] ?? 70).toString();
    _maxAiController.text = (settings["MAX_AI_SCORE"] ?? 100).toString();

    return settings;
  }

  /// Zozbiera zmenené dáta, prekonvertuje typy a zapíše ich do úložiska zariadenia
  void _saveSettings() async {
    try {
      await SettingsManagerService.setSetting("TEST_MODE", _testMode);
      await SettingsManagerService.setSetting("MAX_STORIES_PER_CYCLE", int.parse(_maxStoriesController.text));
      await SettingsManagerService.setSetting("WINNERS_PER_CYCLE", int.parse(_winnersController.text));
      await SettingsManagerService.setSetting("MAX_GENERATIONS", int.parse(_maxGenerationsController.text));
      await SettingsManagerService.setSetting("WORDS_TO_SHOW", int.parse(_wordsToShowController.text));
      await SettingsManagerService.setSetting("WORDS_TO_SELECT", int.parse(_wordsToSelectController.text));
      await SettingsManagerService.setSetting("MIN_AI_SCORE", int.parse(_minAiController.text));
      await SettingsManagerService.setSetting("MAX_AI_SCORE", int.parse(_maxAiController.text));
      await SettingsManagerService.setSetting("SHOW_AI_SCORE", _showAi);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Nastavenia boli úspešne uložené.")),
      );
    } catch (ex) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Chyba: Niektoré polia neobsahujú platné čísla. (\$ex)")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _loadSettingsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Chyba inicializácie: \${snapshot.error}"));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Nastavenia",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  SwitchListTile(
                    title: const Text("Testovací režim"),
                    value: _testMode,
                    onChanged: (bool value) => setState(() => _testMode = value),
                  ),
                  TextField(
                    controller: _maxStoriesController,
                    decoration: const InputDecoration(labelText: "Max. príbehov za kolo"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _winnersController,
                    decoration: const InputDecoration(labelText: "Počet podporených autorov"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _maxGenerationsController,
                    decoration: const InputDecoration(labelText: "Max. generácií"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _wordsToShowController,
                    decoration: const InputDecoration(labelText: "Počet zobrazených slov"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _wordsToSelectController,
                    decoration: const InputDecoration(labelText: "Počet vyberaných slov"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _minAiController,
                    decoration: const InputDecoration(labelText: "Min. AI skóre"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _maxAiController,
                    decoration: const InputDecoration(labelText: "Max. AI skóre"),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    title: const Text("Zobraziť AI skóre"),
                    value: _showAi,
                    onChanged: (bool value) => setState(() => _showAi = value),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    spacing: 12.0,
                    children: [
                      ElevatedButton(
                        onPressed: _saveSettings,
                        child: const Text("ULOŽIŤ"),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/admin'),
                        child: const Text("SPÄŤ"),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
