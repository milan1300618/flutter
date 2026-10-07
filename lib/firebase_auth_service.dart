import 'dart:convert';
import 'package:http/http.dart' as http;

class FirebaseAuthService {
  // Súkromný konštruktor na zabránenie vytváraniu inštancií
  FirebaseAuthService._();

  // Firebase Web API key z konfigurácie StoryFund web app
  static const String _firebaseApiKey = "AIzaSyBZieay3c8tiq1ihYfZcolTAkVJoCk21yE";

  static const String _authUrl = "https://googleapis.com";
  static const String _signupUrl = "https://googleapis.com";

  // Aktuálny Firebase ID token uložený v pamäti aplikácie
  static String? _currentIdToken;

  /// Interný identifikátor pre Firebase Authentication (Nie je to skutočný e-mail)
  static String _authEmail(String nik) {
    return "${nik.trim()}@storyfund.local";
  }

  /// Univerzálna privátna metóda na vykonávanie POST požiadaviek na Identity Toolkit API
  static Future<Map<String, dynamic>> _postAuth(String url, Map<String, dynamic> payload) async {
    final uri = Uri.parse("$url?key=$_firebaseApiKey");
    final headers = {"Content-Type": "application/json"};

    try {
      final response = await http.post(
        uri,
        headers: headers,
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 15));

      final Map<String, dynamic> responseData = response.body.isNotEmpty 
          ? jsonDecode(response.body) 
          : {};

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          "ok": true,
          "data": responseData,
        };
      } else {
        return {
          "ok": false,
          "error": responseData,
        };
      }
    } catch (e) {
      return {
        "ok": false,
        "error": {"message": e.toString()},
      };
    }
  }

  /// Vytvorí Firebase Authentication účet pre účastníka
  static Future<Map<String, dynamic>> createUserAuth(String nik, String pin) async {
    final String email = _authEmail(nik);

    final payload = {
      "email": email,
      "password": pin,
      "returnSecureToken": true,
    };

    final result = await _postAuth(_signupUrl, payload);

    if (!result["ok"]) {
      return result;
    }

    final data = result["data"] as Map<String, dynamic>;

    return {
      "ok": true,
      "localId": data["localId"],
      "idToken": data["idToken"],
      "refreshToken": data["refreshToken"],
    };
  }

  /// Prihlási účastníka do Firebase Authentication podľa jeho NIKu a PINu
  static Future<Map<String, dynamic>> loginUserAuth(String nik, String pin) async {
    final String email = _authEmail(nik);

    final payload = {
      "email": email,
      "password": pin,
      "returnSecureToken": true,
    };

    final result = await _postAuth(_authUrl, payload);

    if (!result["ok"]) {
      _currentIdToken = null;
      return result;
    }

    final data = result["data"] as Map<String, dynamic>;
    _currentIdToken = data["idToken"];

    return {
      "ok": true,
      "localId": data["localId"],
      "idToken": data["idToken"],
      "refreshToken": data["refreshToken"],
    };
  }

  /// Vráti aktuálny Firebase ID token (môže byť použitý v database_service.dart)
  static String? getIdToken() {
    return _currentIdToken;
  }

  /// Vymaže aktuálny Firebase ID token pri odhlásení
  static void clearIdToken() {
    _currentIdToken = null;
  }

  /// Overí správcovský (admin) účet pomocou skutočného e-mailu a hesla
  static Future<Map<String, dynamic>> loginAdmin(String email, String password) async {
    final payload = {
      "email": email,
      "password": password,
      "returnSecureToken": true,
    };

    final result = await _postAuth(_authUrl, payload);

    if (!result["ok"]) {
      _currentIdToken = null;
      return {
        "ok": false,
        "error": result["error"],
      };
    }

    final data = result["data"] as Map<String, dynamic>;
    _currentIdToken = data["idToken"];

    return {
      "ok": _currentIdToken != null,
      "idToken": data["idToken"],
      "error": null,
    };
  }
}
