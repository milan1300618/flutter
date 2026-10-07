import 'dart:convert';
import 'package:http/http.dart' as http;

class BalanceService {
  static const String transparentAccountsUrl =
      "https://unicreditbank.sk";

  static const String accountIban = "SK5611110000001491048088";
  static const String entityCode = "SK";

  // 1 hodina v milisekundách (1 * 60 * 60 * 1000)
  static const int updateIntervalMs = 3600000;

  // --- MIESTO PRE INTEGRÁCIU STATE MANAGEMENTU / DATABÁZY ---
  // Tieto metódy simulujú pôvodné importy z database.py
  
  Future<Map<String, dynamic>> _getState() async {
    // TODO: Implementovať reálne načítanie lokálneho/vzdialeného stavu (napr. cez SharedPreferences alebo API)
    return {
      "fund": 0.0,
      "balance_updated_at": 0,
    };
  }

  Future<void> _saveState(Map<String, dynamic> state) async {
    // TODO: Implementovať uloženie zmeneného stavu
  }
  // ----------------------------------------------------------

  /// Získa aktuálny zostatok priamo z UniCredit banky pomocou HTTP requestu.
  Future<double> _getBalanceFromUniCredit() async {
    final headers = {
      "User-Agent": "Mozilla/5.0 (Linux; Android 13)",
      "Accept": "application/json, text/javascript, */*; q=0.01",
      "Referer": "https://unicreditbank.sk",
      "X-Requested-With": "XMLHttpRequest",
    };

    // Príprava URL s query parametrami
    final uri = Uri.parse(transparentAccountsUrl).replace(queryParameters: {
      "iban": accountIban,
      "entityCode": entityCode,
      "pageNumber": "1",
    });

    final response = await http.get(uri, headers: headers).timeout(
          const Duration(seconds: 15),
        );

    if (response.statusCode != 200) {
      throw Exception("Chyba siete: Kód odpovede ${response.statusCode}");
    }

    final data = jsonDecode(response.body);
    if (data is! Map || !data.containsKey("iHubResponseInfo")) {
      throw Exception("UniCredit nevrátil platnú iHubResponseInfo štruktúru.");
    }

    final accounts = data["iHubResponseInfo"] as List;
    if (accounts.isEmpty) {
      throw Exception("UniCredit nevrátil žiadne údaje o účte.");
    }

    final firstAccount = accounts[0];
    final balance = firstAccount["balance"];

    if (balance == None || balance == null) {
      throw Exception("UniCredit nevrátil zostatok účtu.");
    }

    // Bezpečný prevod na double (ak by banka vrátila int alebo string)
    return double.parse(balance.toString());
  }

  /// Skontroluje čas poslednej aktualizácie a v prípade potreby stiahne nový zostatok.
  Future<double> updateBalanceIfNeeded() async {
    final state = await _getState();
    final now = DateTime.now().millisecondsSinceEpoch;

    final double lastUpdate = double.tryParse(state["balance_updated_at"]?.toString() ?? "0") ?? 0.0;
    final double currentFund = double.tryParse(state["fund"]?.toString() ?? "0") ?? 0.0;

    // Ak bol zostatok aktualizovaný počas poslednej hodiny, nič nerobíme.
    if (lastUpdate > 0) {
      if ((now - lastUpdate) < updateIntervalMs) {
        return currentFund;
      }
    }

    try {
      final balance = await _getBalanceFromUniCredit();

      state["fund"] = balance;
      state["balance_updated_at"] = now;

      await _saveState(state);

      print("StoryFund: zostatok aktualizovaný: ${balance.toStringAsFixed(2)} EUR");
      return balance;
    } catch (e) {
      print("StoryFund: aktualizácia zostatku zlyhala: $e");
      
      // Pri chybe vrátime pôvodnú hodnotu
      return currentFund;
    }
  }
}
