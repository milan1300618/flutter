import 'dart:math';
import 'settings_manager_service.dart'; // Import predošlého správcu nastavení

class WordsService {
  // Súkromný konštruktor na zabránenie vytvárania inštancií
  WordsService._();

  static final Random _random = Random();

  // Databáza slov kompletne prebratá zo špecifikácie projektu
  static const List<String> _wordsDatabase = [
    // EMÓCIE
    "nádej", "smútok", "radosť", "strach", "láska", "osamelosť", "odvaha",

    // RODINA
    "matka", "otec", "dieťa", "rodina", "domov", "brat", "sestra",

    // ŽIVOT
    "práca", "škola", "budúcnosť", "minulosť", "sen", "realita",

    // PRÍRODA
    "les", "rieka", "dážď", "slnko", "noc", "hviezdy", "hory",

    // PROBLÉMY
    "choroba", "hlad", "chudoba", "únava", "boj", "ticho",

    // HODNOTY
    "pravda", "sila", "mier", "priateľstvo", "dôvera"
  ];

  /// Vráti zoznam náhodných a unikátnych slov.
  /// Počet slov je dynamicky riadený nastavením "WORDS_TO_SHOW".
  static Future<List<String>> generateWords() async {
    // Načítanie dynamického limitu z úložiska SharedPreferences
    final dynamic limitSetting = await SettingsManagerService.getSetting("WORDS_TO_SHOW");
    
    // Konverzia na int s bezpečnou záložnou hodnotou (ak by nastavenie zlyhalo alebo chýbalo)
    int wordsToShow = int.tryParse(limitSetting?.toString() ?? "8") ?? 8;

    // Ochrana: Počet požadovaných slov nesmie presiahnuť celkovú veľkosť databázy
    if (wordsToShow > _wordsDatabase.length) {
      wordsToShow = _wordsDatabase.length;
    }

    // Vytvorenie kópie zoznamu slov, aby sme nemenili pôvodnú statickú databázu
    final List<String> shuffledList = List.from(_wordsDatabase);
    
    // Náhodné premiešanie celého zoznamu na disku (ekvivalent in-place shuffle)
    shuffledList.shuffle(_random);

    // Vrátenie požadovaného počtu unikátnych slov od začiatku premiešaného zoznamu
    return shuffledList.sublist(0, wordsToShow);
  }
}
