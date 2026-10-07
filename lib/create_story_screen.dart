import 'dart:math';
import 'package:flutter/material.dart';
import 'app_config.dart';

class CreateStoryScreen extends StatefulWidget {
  const CreateStoryScreen({super.key});

  @override
  State<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends State<CreateStoryScreen> {
  final Random _random = Random();
  
  List<String> _words = [];
  final List<String> _selected = [];
  String _story = "";
  int? _score;
  int _attempts = 0;
  
  String _infoText = "Vybrané: 0 / ${AppConfig.wordsToSelect}";
  String _storyDisplayText = "";
  bool _isGenerateBtnDisabled = true;
  bool _isSaveBtnDisabled = true;
  String _generateBtnText = "GENEROVAŤ PRÍBEH";

  String _getCurrentUser() => "SF12345";

  List<String> _generateWords() {
    return ["Svetlo", "Počítač", "Kniha", "Cesta", "Radosť", "Strom", "Dážď", "Slovo"];
  }

  Future<String> _generateStoryEngine(List<String> selectedWords) async {
    return "Bol raz jeden príbeh, v ktorom hrali hlavnú úlohu slová: ${selectedWords.join(', ')}.";
  }

  Future<bool> _canAddStory(String nik) async {
    return true;
  }

  Future<bool> _checkPayment(String nik) async {
    return true;
  }

  Future<bool> _saveStoryBackend(String nik, List<String> words, String story, int? score) async {
    return true;
  }

  @override
  void initState() {
    super.initState();
    _words = _generateWords();
    _checkInitialLimits();
  }

  void _checkInitialLimits() async {
    if (!AppConfig.testMode) {
      bool allowed = await _canAddStory(_getCurrentUser());
      if (!allowed) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            content: const Text("V tomto kole už máš vytvorený maximálny počet príbehov."),
            actions: [
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                child: const Text("SPÄŤ"),
              )
            ],
          ),
        );
      }
    }
  }

  void _selectWord(String word) {
    setState(() {
      if (_selected.contains(word)) {
        _selected.remove(word);
      } else if (_selected.length < AppConfig.wordsToSelect) {
        _selected.add(word);
      }
      
      _infoText = "Vybrané: ${_selected.length} / ${AppConfig.wordsToSelect}";
      _isGenerateBtnDisabled = _selected.length != AppConfig.wordsToSelect;
      
      if (_attempts >= AppConfig.maxGenerations) {
        _isGenerateBtnDisabled = true;
      }
    });
  }

  void _generate() async {
    if (_selected.length != AppConfig.wordsToSelect || _attempts >= AppConfig.maxGenerations) {
      return;
    }

    _attempts++;
    String generatedResult = await _generateStoryEngine(_selected);
    
    int randomScore = AppConfig.minAiScore + _random.nextInt(AppConfig.maxAiScore - AppConfig.minAiScore + 1);

    setState(() {
      _story = generatedResult;
      _score = randomScore;
      
      _storyDisplayText = _story;
      if (AppConfig.showAiScore) {
        _storyDisplayText += "\n\nAI index: $_score%";
      }
      
      _isSaveBtnDisabled = false;
      
      if (_attempts >= AppConfig.maxGenerations) {
        _isGenerateBtnDisabled = true;
        _generateBtnText = "GENEROVAŤ PRÍBEH";
      } else {
        _generateBtnText = "GENEROVAŤ ZNOVA (${AppConfig.maxGenerations - _attempts})";
      }
    });
  }

  void _save() async {
    final String nik = _getCurrentUser();

    if (_story.isEmpty) {
      setState(() => _storyDisplayText = "Najprv vygeneruj príbeh.");
      return;
    }

    if (!AppConfig.testMode) {
      bool allowed = await _canAddStory(nik);
      if (!allowed) {
        setState(() => _storyDisplayText = "V tomto kole už máš vytvorený maximálny počet príbehov.");
        return;
      }

      bool paymentOk = await _checkPayment(nik);
      if (!paymentOk) {
        setState(() => _storyDisplayText = "Neregistruje sa dar (2 €) na účte s týmto nickom za aktuálne koleso.");
        return;
      }
    }

    bool success = await _saveStoryBackend(nik, _selected, _story, _score);

    setState(() {
      if (success) {
        _storyDisplayText = "Príbeh bol uložený.";
        _isSaveBtnDisabled = true;
        _isGenerateBtnDisabled = true;
      } else {
        _storyDisplayText = "Príbeh sa nepodarilo uložiť.";
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                "Vyber ${AppConfig.wordsToSelect} slová a vytvor príbeh",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_infoText, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              
              Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: _words.map((word) {
                  final bool isSelected = _selected.contains(word);
                  return ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSelected ? Colors.blue.shade800 : null,
                      foregroundColor: isSelected ? Colors.white : null,
                    ),
                    onPressed: () => _selectWord(word),
                    child: Text(word),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              
              ElevatedButton(
                onPressed: _isGenerateBtnDisabled ? null : _generate,
                child: Text(_generateBtnText),
              ),
              const SizedBox(height: 15),
              
              SelectableText(
                _storyDisplayText,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 15),
              
              ElevatedButton(
                onPressed: _isSaveBtnDisabled ? null : _save,
                child: const Text("ULOŽIŤ"),
              ),
              const SizedBox(height: 12),
              
              OutlinedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                child: const Text("SPÄŤ"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
