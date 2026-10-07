import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;

class StoryEngineService {
  // Súkromný konštruktor na zabránenie vytváraniu inštancií
  StoryEngineService._();

  static final Random _random = Random();

  /// Pomocná funkcia na načítanie riadkov z textového súboru v assets (náhrada za load_lines)
  static Future<List<String>> _loadLines(String assetPath) async {
    try {
      // Načíta celý súbor ako jeden reťazec
      final String fileContent = await rootBundle.loadString(assetPath);
      
      // Rozdelí text podľa konca riadkov, oreže biele znaky a odfiltruje prázdne riadky
      return fileContent
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
    } catch (e) {
      print("StoryEngine error pri načítaní assetu (\$assetPath): \$e");
      return [];
    }
  }

  /// Náhodne vyberie jeden prvok zo zoznamu textov
  static String _choice(List<String> list) {
    if (list.isEmpty) return "";
    return list[_random.nextInt(list.length)];
  }

  /// Spojí náhodné časti do jedného uceleného príbehu
  static Future<String> generateStory(List<String> words) async {
    if (words.length != 4) {
      return "Vyber presne 4 slová.";
    }

    // Načítanie súborov z assets (cesty musíte zaregistrovať v pubspec.yaml)
    final List<String> intros = await _loadLines("assets/intro.txt");
    final List<String> middles = await _loadLines("assets/middle.txt");
    final List<String> endings = await _loadLines("assets/ending.txt");

    // Ochrana pre prípad, že by boli textové súbory prázdne
    if (intros.isEmpty || middles.isEmpty || endings.isEmpty) {
      return "Chyba: Chýbajú textové šablóny v zložke assets aplikácie.";
    }

    final String intro = _choice(intros);
    final String middle = _choice(middles);
    final String ending = _choice(endings);

    // Vytvorenie výsledného príbehu s formátovaním riadkov presne podľa Python predlohy
    final String story = "\$intro\n\n\$middle\n\n\$ending";

    return story.trim();
  }
}
