import 'dart:convert';
import 'package:http/http.dart' as http;

class PaymentCheckService {
  static const String accountString = "01491048088";
  static const String entityCodeString = "SK";

  // Nastavenie testovacieho režimu (False = kontroluje sa iba aktuálny týždeň)
  static const bool testAllTransactions = false;

  /// Pomocná funkcia na získanie ISO formátu dátumu (YYYY-MM-DD) pre pondelok a nedeľu aktuálneho týždňa
  static Map<String, String> _getCurrentWeek() {
    final DateTime today = DateTime.now();
    
    // Výpočet pondelka (DateTime.weekday: Pondelok = 1, Nedeľa = 7)
    final DateTime monday = today.subtract(Duration(days: today.weekday - 1));
    final DateTime sunday = monday.add(const Duration(days: 6));

    String formatDate(DateTime dt) {
      return "\${dt.year}-dt.month.toString().padLeft(2, '0')-{dt.day.toString().padLeft(2, '0')}";
    }

    return {
      "from": formatDate(monday),
      "to": formatDate(sunday),
    };
  }

  /// Vyhľadá transakciu na transparentnom účte prislúchajúcu k zadanému Nicku (NIK).
  /// Vráti mapu s detailmi transakcie, alebo null, ak sa platba nenašla.
  static Future<Map<String, dynamic>?> findPayment(String nick) async {
    String dateFrom = "2026-01-01";
    String dateTo = "2030-12-31";

    if (!testAllTransactions) {
      final week = _getCurrentWeek();
      dateFrom = week["from"]!;
      dateTo = week["to"]!;
    }

    final headers = {"User-Agent": "Mozilla/5.0"};
    
    // Príprava URL adresy s query parametrami pre UniCredit API
    final uri = Uri.parse("https://unicreditbank.sk").replace(
      queryParameters: {
        "accountNumber": accountString,
        "entityCode": entityCodeString,
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
        return null;
      }

      final data = jsonDecode(response.body);
      if (data is! Map || !data.containsKey("iHubResponseInfo")) {
        return null;
      }

      // Spracovanie a vyčistenie hľadaného čísla (odrezanie predpony SF)
      String searchNumber = nick.trim();
      if (searchNumber.toUpperCase().startsWith("SF")) {
        searchNumber = searchNumber.substring(2);
      }
      searchNumber = searchNumber.trim();

      final transactions = data["iHubResponseInfo"];
      if (transactions is! List) {
        return null;
      }

      // Prehľadávanie transakcií a porovnávanie Variabilného symbolu (variableCode)
      for (var t in transactions) {
        if (t is! Map) continue;
        
        final String variableCode = (t["variableCode"] ?? "").toString().trim();

        if (variableCode == searchNumber) {
          return Map<String, dynamic>.from(t);
        }
      }

      return null;
    } catch (e) {
      print("Chyba pri kontrole platieb: \$e");
      return null;
    }
  }

  /// Metóda nahrádzajúca block `if __name__ == "__main__":` na testovacie účely v Darte
  static Future<void> testConsoleVerification(String testNick) async {
    print("Overujem platbu pre Nick: \$testNick");
    final result = await findPayment(testNick);

    if (result == null) {
      print("Platba nebola nájdená.");
    } else {
      print("\n=== KĽÚČE ===");
      print(result.keys.toList());

      print("\n=== CELÁ TRANSAKCIA ===");
      print(const JsonEncoder.withIndent('    ').convert(result));
    }
  }
}
