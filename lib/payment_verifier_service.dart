import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentVerifierService {
  static const String accountNumber = "01491048088";
  static const String entityCode = "SK";

  /// Pomocná funkcia na získanie ISO formátu dátumu (YYYY-MM-DD) pre aktuálny kalendárny týždeň
  static Map<String, String> _getCurrentWeek() {
    final DateTime today = DateTime.now();
    
    // Výpočet pondelka aktuálneho týždňa (Pondelok = 1, Nedeľa = 7)
    final DateTime monday = today.subtract(Duration(days: today.weekday - 1));
    final DateTime sunday = monday.add(const Duration(days: 6));

    String formatDate(DateTime dt) {
      return "${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}";
    }

    return {
      "from": formatDate(monday),
      "to": formatDate(sunday),
    };
  }

  /// Skontroluje, či prebehla platba pre daný Nick na transparentnom účte v aktuálnom týždni.
  /// Vráti true, ak sa variabilný symbol zhoduje, inak vráti false.
  static Future<bool> checkPayment(String nick) async {
    final week = _getCurrentWeek();
    final String dateFrom = week["from"]!;
    final String dateTo = week["to"]!;

    final headers = {"User-Agent": "Mozilla/5.0"};
    
    final uri = Uri.parse("https://unicreditbank.sk").replace(
      queryParameters: {
        "accountNumber": accountNumber,
        "entityCode": entityCode,
        "dateFrom": dateFrom,
        "dateTo": dateTo,
        "pageNumber": "1",
      },
    );

    try {
      final response = await http.get(uri, headers: headers).timeout(
            const Duration(seconds: 10),
          );

      if (response.statusCode != 200) {
        return false;
      }

      final data = jsonDecode(response.body);
      if (data is! Map || !data.containsKey("iHubResponseInfo")) {
        return false;
      }

      // Spracovanie a vyčistenie hľadaného čísla (odrezanie predpony SF ak existuje)
      String searchNumber = nick.trim();
      if (searchNumber.toUpperCase().startsWith("SF")) {
        searchNumber = searchNumber.substring(2);
      }
      searchNumber = searchNumber.trim();

      final transactions = data["iHubResponseInfo"];
      if (transactions is! List) {
        return false;
      }

      // Kontrola iba Variabilného symbolu (variableCode)
      for (var t in transactions) {
        if (t is! Map) continue;
        
        final String variableCode = (t["variableCode"] ?? "").toString().trim();

        if (variableCode == searchNumber) {
          return true;
        }
      }

      return false;
    } catch (e) {
      print("Chyba verifikácie platby: $e");
      return false;
    }
  }
}
