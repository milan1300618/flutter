import 'dart:math';

// ======================================
// DÁTOVÉ MODELY (Silná typovosť pre Dart)
// ======================================

class User {
  String nik;
  String pin;
  String registered;
  bool active;
  String cycleId;
  int storiesCount;

  User({
    required this.nik,
    required this.pin,
    required this.registered,
    this.active = true,
    this.cycleId = "",
    this.storiesCount = 0,
  });

  // Pomocné metódy pre prípadnú konverziu z/do JSON (pre API / Firebase)
  factory User.fromJson(Map<String, dynamic> json) => User(
        nik: json['nik'] ?? '',
        pin: json['pin'] ?? '',
        registered: json['registered'] ?? '',
        active: json['active'] ?? true,
        cycleId: json['cycle_id'] ?? '',
        storiesCount: json['stories_count'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'nik': nik,
        'pin': pin,
        'registered': registered,
        'active': active,
        'cycle_id': cycleId,
        'stories_count': storiesCount,
      };
}

class Story {
  String nik;
  int words;
  String story;
  int score;
  int time; // Ukladané ako unix timestamp v milisekundách

  Story({
    required this.nik,
    required this.words,
    required this.story,
    required this.score,
    required this.time,
  });

  factory Story.fromJson(Map<String, dynamic> json) => Story(
        nik: json['nik'] ?? '',
        words: json['words'] ?? 0,
        story: json['story'] ?? '',
        score: json['score'] ?? 0,
        time: json['time'] ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'nik': nik,
        'words': words,
        'story': story,
        'score': score,
        'time': time,
      };
}

// ======================================
// BACKEND SLUŽBA (BackendService)
// ======================================

class BackendService {
  final Random _random = Random();

  // --- MIESTO PRE INTEGRÁCIU DATABÁZY A NASTAVENÍ ---
  // Tieto metódy simulujú pôvodné importy z database.py, settings_manager.py a cycle.py

  Future<List<User>> _getUsers() async {
    // TODO: Implementovať reálne načítanie používateľov (napr. z Firestore / API)
    return [];
  }

  Future<void> _saveUsers(List<User> users) async {
    // TODO: Implementovať reálne uloženie zoznamu používateľov
  }

  Future<List<Story>> _getStories() async {
    // TODO: Implementovať reálne načítanie príbehov
    return [];
  }

  Future<void> _saveStories(List<Story> stories) async {
    // TODO: Implementovať reálne uloženie zoznamu príbehov
  }

  int _getMaxStoriesPerCycle() {
    // Pôvodne: settings_manager.get("MAX_STORIES_PER_CYCLE")
    return 3; // Ukážková statická hodnota
  }

  Future<Map<String, dynamic>> _getCurrentState() async {
    // Pôvodne z cycle.py -> get_current_state()
    return {"cycle_id": "aktualne_kolo_123"};
  }

  Future<Map<String, dynamic>> _createUserAuth(String nik, String pin) async {
    // Pôvodne z firebase_auth.py -> create_user_auth(nik, pin)
    // Simulácia úspešného vytvorenia účtu
    return {"ok": true};
  }
  // --------------------------------------------------

  // ======================================
  // GENEROVANIE ÚČTOV
  // ======================================
  
  Future<String> generateNik() async {
    List<User> users = await _getUsers();

    while (true) {
      // Vygeneruje 5 náhodných číslic
      String digits = '';
      for (int i = 0; i < 5; i++) {
        digits += _random.nextInt(10).toString();
      }
      String nik = "SF$digits";

      // Kontrola unikátnosti NIK-u
      bool exists = users.any((u) => u.nik == nik);
      if (!exists) {
        return nik;
      }
    }
  }

  String generatePin() {
    // Vygeneruje 6 náhodných číslic
    String pin = '';
    for (int i = 0; i < 6; i++) {
      pin += _random.nextInt(10).toString();
    }
    return pin;
  }

  // ======================================
  // VYTVORENIE POUŽÍVATEĽA
  // ======================================
  
  Future<Map<String, String>?> createUser({String? nik, String? pin}) async {
    List<User> users = await _getUsers();

    nik ??= await generateNik();
    pin ??= generatePin();

    // Vytvorenie Firebase Auth účtu
    Map<String, dynamic> authResult = await _createUserAuth(nik, pin);

    if (authResult['ok'] != true) {
      return null;
    }

    // Formátovanie aktuálneho času do stringu (Y-m-d H:i:s)
    DateTime now = DateTime.now();
    String formattedDate = 
        "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} "
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";

    users.add(User(
      nik: nik,
      pin: pin,
      registered: formattedDate,
      active: true,
      cycleId: "",
      storiesCount: 0,
    ));

    await _saveUsers(users);

    return {
      "nik": nik,
      "pin": pin,
    };
  }

  // ======================================
  // LOGIN
  // ======================================
  
  Future<bool> loginUser(String nik, String pin) async {
    List<User> users = await _getUsers();

    for (var u in users) {
      if (u.nik == nik && u.pin == pin) {
        if (!u.active) {
          return false;
        }
        return true;
      }
    }
    return false;
  }

  // ======================================
  // KONTROLA LIMITU
  // ======================================
  
  Future<bool> canAddStory(String nik) async {
    List<User> users = await _getUsers();
    Map<String, dynamic> state = await _getCurrentState();
    String currentCycleId = state["cycle_id"] ?? "";

    for (var u in users) {
      if (u.nik == nik) {
        // Zistené nové kolo aplikácie
        if (u.cycleId != currentCycleId) {
          u.cycleId = currentCycleId;
          u.storiesCount = 0;
          await _saveUsers(users);
        }

        return u.storiesCount < _getMaxStoriesPerCycle();
      }
    }
    return false;
  }

  // ======================================
  // ULOŽENIE PRÍBEHU
  // ======================================
  
  Future<bool> saveStory({
    required String nik,
    required int words,
    required String storyText,
    required int score,
  }) async {
    bool allowed = await canAddStory(nik);
    if (!allowed) {
      return false;
    }

    List<Story> stories = await _getStories();

    stories.add(Story(
      nik: nik,
      words: words,
      story: storyText,
      score: score,
      time: DateTime.now().millisecondsSinceEpoch,
    ));

    await _saveStories(stories);

    List<User> users = await _getUsers();
    Map<String, dynamic> state = await _getCurrentState();
    String currentCycleId = state["cycle_id"] ?? "";

    for (var u in users) {
      if (u.nik == nik) {
        u.cycleId = currentCycleId;
        u.storiesCount += 1;
      }
    }

    await _saveUsers(users);
    return true;
  }

  // ======================================
  // FEED
  // ======================================
  
  Future<List<Story>> loadFeed() async {
    List<Story> stories = await _getStories();
    
    // Usporiadanie príbehov od najnovšieho po najstarší
    stories.sort((a, b) => b.time.compareTo(a.time));
    
    return stories;
  }

  // ======================================
  // ADMIN FUNKCIE
  // ======================================
  
  Future<bool> blockUser(String nik) async {
    List<User> users = await _getUsers();

    for (var u in users) {
      if (u.nik == nik) {
        u.active = false;
        await _saveUsers(users);
        return true;
      }
    }
    return false;
  }

  Future<bool> unblockUser(String nik) async {
    List<User> users = await _getUsers();

    for (var u in users) {
      if (u.nik == nik) {
        u.active = true;
        await _saveUsers(users);
        return true;
      }
    }
    return false;
  }

  Future<List<User>> listUsers() async {
    return await _getUsers();
  }
}
