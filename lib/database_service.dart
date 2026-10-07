import 'dart:convert';
import 'package:http/http.dart' as http;

class DatabaseService {
  static const String firebaseUrl = "https://firebasedatabase.app";

  // Predvolené hodnoty pre stav databázy (DEFAULTS z Pythonu)
  static const Map<String, dynamic> defaultState = {
    "cycle_id": 1,
    "year": 0,
    "week": 0,
    "fund": 0,
    "status": "open"
  };

  // --- MIESTO PRE INTEGRÁCIU AUTENTIFIKÁCIE ---
  String? _getIdToken() {
    // TODO: Prepojiť na vašu Firebase Auth implementáciu (pôvodne firebase_auth.py -> get_id_token)
    return null;
  }
  // ---------------------------------------------

  /// Vytvorí kompletnú URL adresu s prípadným overovacím tokenom
  Uri _buildUri(String path) {
    String cleanPath = path.replaceAll(RegExp(r'^/|/$'), '');
    final urlString = "$firebaseUrl/$cleanPath.json";
    
    final token = _getIdToken();
    if (token != null && token.isNotEmpty) {
      // Bezpečné pridanie query parametra pre Firebase autentifikáciu
      return Uri.parse(urlString).replace(queryParameters: {"auth": token});
    }
    
    return Uri.parse(urlString);
  }

  /// Univerzálna metóda na vykonávanie sieťových HTTP požiadaviek na Firebase REST API
  Future<dynamic> _request(String path, {required String method, dynamic data}) async {
    final uri = _buildUri(path);
    final headers = {"Content-Type": "application/json"};
    
    String? body;
    if (data != null) {
      body = jsonEncode(data);
    }

    try {
      http.Response response;
      
      switch (method.toUpperCase()) {
        case "GET":
          response = await http.get(uri, headers: headers).timeout(const Duration(seconds: 15));
          break;
        case "PUT":
          response = await http.put(uri, headers: headers, body: body).timeout(const Duration(seconds: 15));
          break;
        default:
          throw Exception("Unsupported HTTP method: $method");
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (response.body.isEmpty || response.body == "null") {
          return null;
        }
        return jsonDecode(response.body);
      } else {
        throw Exception("Firebase chyba HTTP ${response.statusCode}: ${response.body}");
      }
    } catch (e) {
      throw Exception("Firebase chyba: $e");
    }
  }

  /// Pomocná funkcia na bezpečné načítanie uzla alebo uloženie predvolenej hodnoty
  Future<dynamic> _load(String path, dynamic defaultValue) async {
    final data = await _request(path, method: "GET");
    if (data == null) {
      await _save(path, defaultValue);
      return defaultValue;
    }
    return data;
  }

  /// Pomocná funkcia na uloženie kompletných dát do uzla (prepísanie databázy)
  Future<void> _save(String path, dynamic data) async {
    await _request(path, method: "PUT", data: data);
  }

  // ======================================
  // POUŽÍVATELIA (Users)
  // ======================================
  
  Future<List<dynamic>> getUsers() async {
    final data = await _load("users", []);
    return data is List ? data : [];
  }

  Future<void> saveUsers(List<dynamic> data) async {
    await _save("users", data);
  }

  // ======================================
  // PRÍBEHY (Stories)
  // ======================================
  
  Future<List<dynamic>> getStories() async {
    final data = await _load("stories", []);
    return data is List ? data : [];
  }

  Future<void> saveStories(List<dynamic> data) async {
    await _save("stories", data);
  }

  Future<void> clearStories() async {
    await _save("stories", []);
  }

  // ======================================
  // ARCHÍV (Archive)
  // ======================================
  
  Future<List<dynamic>> getArchive() async {
    final data = await _load("archive", []);
    return data is List ? data : [];
  }

  Future<void> saveArchive(List<dynamic> data) async {
    await _save("archive", data);
  }

  // ======================================
  // STAV CYKLU (State)
  // ======================================
  
  Future<Map<String, dynamic>> getState() async {
    // Vytvorenie kópie predvolených nastavení pre prípad, že v DB uzol neexistuje
    final data = await _load("state", Map<String, dynamic>.from(defaultState));
    return data is Map<String, dynamic> ? data : Map<String, dynamic>.from(defaultState);
  }

  Future<void> saveState(Map<String, dynamic> data) async {
    await _save("state", data);
  }
}
