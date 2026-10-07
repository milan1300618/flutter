import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Potrebné pre prácu so schránkou (Clipboard)

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  
  // --- MIESTO PRE INTEGRÁCIU BACKENDU ---
  // Pôvodne importované z backend.py, cycle.py, database.py
  
  Future<void> _forceNewCycle() async {
    // TODO: Implementovať API volanie pre vynútenie nového kola
  }

  Future<List<Map<String, dynamic>>> _getArchive() async {
    // TODO: Implementovať API volanie na získanie archívu
    return [];
  }

  Future<double> _recordPreviousCycle(String amount, String recipients) async {
    // TODO: Implementovať API volanie pre uloženie minulého kola
    // Má vrátiť prepočítanú sumu na jedného (per_person)
    double amt = double.tryParse(amount) ?? 0.0;
    int rec = int.tryParse(recipients) ?? 1;
    return amt / rec;
  }
  // --------------------------------------

  // Pomocná funkcia na zobrazenie klasického informačného dialógu
  void _showSimpleDialog(BuildContext context, String title, String text) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(text),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _logout() {
    // Pôvodná logout logika
    // login.current_user = None
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _closeCycle() async {
    try {
      await _forceNewCycle();
      final archive = await _getArchive();
      
      List<String> winners = [];
      if (archive.isNotEmpty) {
        var lastWinners = archive.last['winners'];
        if (lastWinners is List) {
          winners = lastWinners.map((w) => w.toString().trim()).where((w) => w.isNotEmpty).toList();
        }
      }

      if (!mounted) return;

      if (winners.isNotEmpty) {
        _showWinners(winners);
      } else {
        _showSimpleDialog(
          context, 
          "Kolo uzavreté", 
          "Kolo bolo úspešne uzavreté a otvorilo sa nové kolo.\n\nV tomto kole neboli vyžrebovaní žiadni výhercovia."
        );
      }
    } catch (ex) {
      _showSimpleDialog(context, "Chyba pri uzatváraní kola", ex.toString());
    }
  }

  void _showWinners(List<String> winners) {
    final String text = winners.join("\n");
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("VÝHERCI (${winners.length})"),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: TextEditingController(text: text),
            maxLines: 12,
            minLines: 8,
            readOnly: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => _copyWinners(text),
            child: const Text("KOPÍROVAŤ ZOZNAM"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ZAVRIEŤ"),
          ),
        ],
      ),
    );
  }

  void _copyWinners(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    Navigator.pop(context); // Zavrie dialóg výhercov
    _showSimpleDialog(context, "Skopírované", "Zoznam výhercov bol skopírovaný do schránky.");
  }

  void _previousCycle() {
    final amountController = TextEditingController();
    final recipientsController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Minulé kolo"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                decoration: const InputDecoration(labelText: "Vyzbieraná suma (€)"),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: recipientsController,
                decoration: const InputDecoration(labelText: "Počet príjemcov"),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("ZRUŠIŤ"),
          ),
          TextButton(
            onPressed: () => _savePreviousCycle(
              amountController.text, 
              recipientsController.text
            ),
            child: const Text("ULOŽIŤ"),
          ),
        ],
      ),
    );
  }

  void _savePreviousCycle(String amount, String recipients) async {
    try {
      if (amount.trim().isEmpty || recipients.trim().isEmpty) {
        throw Exception("Vyplň sumu aj počet príjemcov.");
      }
      
      String normalizedAmount = amount.replaceAll(",", ".");
      double perPerson = await _recordPreviousCycle(normalizedAmount, recipients);
      
      if (!mounted) return;
      Navigator.pop(context); // Zavrie zadávací dialóg
      
      _showSimpleDialog(
        context, 
        "Minulé kolo uložené", 
        "Vyzbierané: ${double.parse(normalizedAmount).toStringAsFixed(2)} €\n"
        "Príjemcov: ${int.parse(recipients)}\n"
        "Na jedného: ${perPerson.toStringAsFixed(2)} €"
      );
    } catch (ex) {
      _showSimpleDialog(context, "Chyba", ex.toString().replaceAll("Exception: ", ""));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "ADMIN PANEL",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/users'),
                child: const Text("Používatelia"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/new_user'),
                child: const Text("➕ Nový používateľ"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/settings'),
                child: const Text("Nastavenia"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _closeCycle,
                child: const Text("Uzavrieť kolo"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _previousCycle,
                child: const Text("Minulé kolo"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/history'),
                child: const Text("História"),
              ),
              const Spacer(), // Roztiahne kontajner a posunie Odhlásiť na spodok
              ElevatedButton(
                onPressed: _logout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade50,
                  foregroundColor: Colors.red,
                ),
                child: const Text("Odhlásiť"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
