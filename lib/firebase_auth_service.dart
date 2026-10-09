// ======================================
// StoryFund - Firebase Authentication
// ======================================

import 'dart:convert';
import 'package:http/http.dart' as http;

class FirebaseAuthService {
  // Súkromný konštruktor na zabránenie vytváraniu inštancií.
  FirebaseAuthService._();

  // Firebase Web API key z konfigurácie StoryFund web app.
  static const String _firebaseApiKey =
      "AIzaSyBZieay3c8tiq1ihYfZcolTAkVJoCk21yE";

  static const String _authUrl =
      "https://identitytoolkit.googleapis.com/v1/"
      "accounts:signInWithPassword";

  static const String _signupUrl =
      "https://identitytoolkit.googleapis.com/v1/"
      "accounts:signUp";

  // Aktuálny Firebase ID token.
  static String? _currentIdToken;

  // Interný identifikátor pre Firebase Authentication.
  // Nie je to skutočný e-mail.
  static String _authEmail(String nik) {
    return "${nik.trim()}@storyfund.local";
  }

  // ======================================
  // Firebase POST požiadavka
  // ======================================

  static Future<Map<String, dynamic>> _postAuth(
    String url,
    Map<String, dynamic> payload,
  ) async {
    final uri = Uri.parse("$url?key=$_firebaseApiKey");

    try {
      final response = await http
          .post(
            uri,
            headers: {
              "Content-Type": "application/json",
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      // Úspešná odpoveď Firebase.
      if (response.statusCode >= 200 &&
          response.statusCode < 300) {
        try {
          return {
            "ok": true,
            "data": jsonDecode(response.body),
          };
        } catch (e) {
          return {
            "ok": false,
            "error": {
              "message":
                  "Firebase vrátil neplatnú JSON odpoveď."
            },
          };
        }
      }

      // HTTP chyba – pokúsime sa zachovať skutočnú
      // Firebase chybovú odpoveď.
      try {
        final detail = jsonDecode(response.body);

        return {
          "ok": false,
          "error": detail,
        };
      } catch (e) {
        return {
          "ok": false,
          "error": {
            "message":
                "Firebase HTTP chyba ${response.statusCode}",
          },
        };
      }
    } catch (e) {
      return {
        "ok": false,
        "error": e.toString(),
      };
    }
  }

  // ======================================
  // Vytvorenie Firebase účtu
  // ======================================

  static Future<Map<String, dynamic>> createUserAuth(
    String nik,
    String pin,
  ) async {
    final email = _authEmail(nik);

    final payload = {
      "email": email,
      "password": pin,
      "returnSecureToken": true,
    };

    final result = await _postAuth(
      _signupUrl,
      payload,
    );

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

  // ======================================
  // Prihlásenie účastníka
  // ======================================

  static Future<Map<String, dynamic>> loginUserAuth(
    String nik,
    String pin,
  ) async {
    final email = _authEmail(nik);

    final payload = {
      "email": email,
      "password": pin,
      "returnSecureToken": true,
    };

    final result = await _postAuth(
      _authUrl,
      payload,
    );

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

  // ======================================
  // Aktuálny ID token
  // ======================================

  static String? getIdToken() {
    return _currentIdToken;
  }

  // ======================================
  // Odhlásenie
  // ======================================

  static void clearIdToken() {
    _currentIdToken = null;
  }

  // ======================================
  // Admin login
  // ======================================

  static Future<Map<String, dynamic>> loginAdmin(
    String email,
    String password,
  ) async {
    final payload = {
      "email": email,
      "password": password,
      "returnSecureToken": true,
    };

    final result = await _postAuth(
      _authUrl,
      payload,
    );

    if (!result["ok"]) {
      _currentIdToken = null;

      // Zachováme skutočnú Firebase chybu.
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
