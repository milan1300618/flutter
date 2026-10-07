import 'dart:math';

class CycleService {
  final Random _random = Random();

  // --- MIESTO PRE INTEGRÁCIU DATABÁZY A NASTAVENÍ ---
  // Tieto metódy simulujú pôvodné importy z database.py a settings_manager.py
  
  Future<Map<String, dynamic>> _getState() async => {"test_mode": false};
  Future<void> _saveState(Map<String, dynamic> state) async {}
  Future<List<Map<String, dynamic>>> _getStories() async => [];
  Future<void> _clearStories() async {}
  Future<List<Map<String, dynamic>>> _getArchive() async => [];
  Future<void> _saveArchive(List<Map<String, dynamic>> archive) async {}
  Future<List<Map<String, dynamic>>> _getUsers() async => [];
  Future<void> _saveUsers(List<Map<String, dynamic>> users) async {}
  
  int _getWinnersPerCycle() => 12; // Ekvivalent settings_manager.get("WINNERS_PER_CYCLE")
  // --------------------------------------------------

  // ======================================
  // TEST MODE
  // ======================================
  
  Future<bool> isTestMode() async {
    final state = await _getState();
    return state["test_mode"] ?? false;
  }

  Future<void> setTestMode(bool value) async {
    final state = await _getState();
    state["test_mode"] = value;
    await _saveState(state);
  }

  // ======================================
  // IDENTIFIKÁCIA KOLA
  // ======================================
  
  /// Vypočíta aktuálny rok a ISO číslo týždňa (náhrada za Python isocalendar)
  String getCycleId() {
    final DateTime now = DateTime.now();
    
    // Určenie štvrtku v danom týždni
    final DateTime thursday = DateTime(now.year, now.month, now.day + (4 - now.weekday));
    final DateTime firstDayOfYear = DateTime(thursday.year, 1, 1);
    
    // Výpočet počtu dní medzi prvým dňom v roku a štvrtkom
    final int daysBeforeThursday = thursday.difference(firstDayOfYear).inDays;
    final int weekNumber = (daysBeforeThursday / 7).floor() + 1;
    
    return "${thursday.year}-$weekNumber";
  }

  /// Vráti časové pečiatky (timestamp v sekundách) pre začiatok pondelka a nedeľu 16:00
  Map<String, double> getCycleTimes() {
    final DateTime now = DateTime.now();
    
    // Zistenie pondelka aktuálneho týždňa
    final DateTime monday = DateTime(now.year, now.month, now.day - (now.weekday - 1));
    final DateTime start = DateTime(monday.year, monday.month, monday.day, 0, 1, 0, 0);
    
    // Nedeľa (pondelok + 6 dní) o 16:00
    final DateTime sunday = start.add(const Duration(days: 6));
    final DateTime end = DateTime(sunday.year, sunday.month, sunday.day, 16, 0, 0, 0);

    return {
      "start": start.millisecondsSinceEpoch / 1000,
      "end": end.millisecondsSinceEpoch / 1000,
    };
  }

  // ======================================
  // VYTVORENIE NOVÉHO KOLA
  // ======================================
  
  Future<Map<String, dynamic>> startNewCycle() async {
    final String cycleId = getCycleId();
    final Map<String, double> times = getCycleTimes();

    final Map<String, dynamic> state = {
      "cycle_id": cycleId,
      "status": "open",
      "opened_at": times["start"],
      "closes_at": times["end"],
      "fund": 0.0,
    };

    await _saveState(state);
    await resetUserLimits(cycleId);

    return state;
  }

  // ======================================
  // RESET LIMITOV POUŽÍVATEĽOV
  // ======================================
  
  Future<void> resetUserLimits(String cycleId) async {
    final List<Map<String, dynamic>> users = await _getUsers();

    for (var u in users) {
      u["cycle_id"] = cycleId;
      u["stories_count"] = 0;
    }

    await _saveUsers(users);
  }

  // ======================================
  // KONTROLA OTVORENIA
  // ======================================
  
  Future<bool> isOpen() async {
    if (await isTestMode()) {
      return true;
    }

    final state = await _getState();
    final double now = DateTime.now().millisecondsSinceEpoch / 1000;
    final double closesAt = double.tryParse(state["closes_at"]?.toString() ?? "0") ?? 0.0;

    if (now >= closesAt) {
      return false;
    }

    return state["status"] == "open";
  }

  // ======================================
  // AKTUÁLNY STAV
  // ======================================
  
  Future<Map<String, dynamic>> getCurrentState() async {
    final state = await _getState();
    final String currentCycle = getCycleId();

    // Automaticky otvor nové kolo pri zmene týždňa alebo ak stav chýba
    if (state["cycle_id"] != currentCycle || state["cycle_id"] == null || state["cycle_id"].toString().isEmpty) {
      return await startNewCycle();
    }

    return state;
  }

  // ======================================
  // FOND
  // ======================================
  
  Future<void> setFund(double amount) async {
    final state = await getCurrentState();
    state["fund"] = amount;
    await _saveState(state);
  }

  Future<double> getFund() async {
    final state = await getCurrentState();
    return double.tryParse(state["fund"]?.toString() ?? "0.0") ?? 0.0;
  }

  // ======================================
  // MANUÁLNY ZÁPIS MINULÉHO KOLA
  // ======================================
  
  Future<double> recordPreviousCycle(String amountStr, String recipientsStr) async {
    final double amount = double.tryParse(amountStr.replaceAll(",", ".")) ?? 0.0;
    final int recipients = int.tryParse(recipientsStr) ?? 0;

    if (amount < 0) {
      throw ArgumentError("Suma nemôže byť záporná.");
    }
    if (recipients <= 0) {
      throw ArgumentError("Počet príjemcov musí byť väčší ako 0.");
    }

    final double perPerson = amount / recipients;
    final List<Map<String, dynamic>> archive = await _getArchive();

    archive.add({
      "type": "manual_previous_cycle",
      "fund": amount,
      "participants": recipients,
      "winner_count": recipients,
      "winners": [],
      "stories": [],
      "amount_per_person": perPerson,
      "closed_at": DateTime.now().millisecondsSinceEpoch / 1000,
    });

    await _saveArchive(archive);
    return perPerson;
  }

  // ======================================
  // ŽREBOVANIE VÍŤAZOV
  // ======================================
  
  Future<List<String>> drawWinners() async {
    final List<Map<String, dynamic>> stories = await _getStories();
    
    // Získanie unikátnych účastníkov (Set) usporiadaných abecedne
    final List<String> participants = stories
        .map((s) => s["nik"]?.toString() ?? "")
        .where((nik) => nik.isNotEmpty)
        .toSet()
        .toList();
    participants.sort();

    if (participants.isEmpty) {
      return [];
    }

    final int winnerCount = _getWinnersPerCycle();

    if (winnerCount >= participants.length) {
      return participants;
    }

    // Unikátny výber náhodných prvkov (ekvivalent random.sample)
    final List<String> shuffled = List.from(participants)..shuffle(_random);
    return shuffled.sublist(0, winnerCount);
  }

  // ======================================
  // ARCHIVÁCIA
  // ======================================
  
  Future<bool> archiveCycle() async {
    final Map<String, dynamic> state = await getCurrentState();
    final List<Map<String, dynamic>> stories = await _getStories();

    if (stories.isEmpty) {
      return false;
    }

    final List<Map<String, dynamic>> archive = await _getArchive();
    final List<String> winners = await drawWinners();
    
    final int participantsCount = stories.map((s) => s["nik"]?.toString() ?? "").toSet().where((n) => n.isNotEmpty).length;

    archive.add({
      "cycle_id": state["cycle_id"],
      "fund": state["fund"],
      "participants": participantsCount,
      "winner_count": winners.length,
      "winners": winners,
      "stories": stories,
      "closed_at": DateTime.now().millisecondsSinceEpoch / 1000,
    });

    await _saveArchive(archive);
    return true;
  }

  // ======================================
  // NOVÉ KOLO (MANUÁLNE / Z ADMINA)
  // ======================================
  
  Future<Map<String, dynamic>> forceNewCycle() async {
    print("=== force_new_cycle START ===");

    print("Archivujem...");
    await archiveCycle();

    print("Mažem stories...");
    await _clearStories();

    print("Vytváram nové kolo...");
    final Map<String, dynamic> result = await startNewCycle();

    print("=== force_new_cycle END ===");
    return result;
  }

  // ======================================
  // AUTOMATICKÉ UZAVRETIE
  // ======================================
  
  Future<void> checkCycle() async {
    if (await isTestMode()) {
      return;
    }

    final Map<String, dynamic> state = await getCurrentState();
    final double now = DateTime.now().millisecondsSinceEpoch / 1000;
    final double closesAt = double.tryParse(state["closes_at"]?.toString() ?? "0") ?? 0.0;

    if (now >= closesAt) {
      await forceNewCycle();
    }
  }
}
