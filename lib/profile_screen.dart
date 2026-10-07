import 'package:flutter/material.dart';
import 'login_screen.dart'; // Import pre SessionManager.currentUser

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  
  // --- MIESTO PRE INTEGRÁCIU DATABÁZY ---
  // Tieto metódy sa prepoja na predošlé súbory database_service.dart a backend_service.dart
  Future<List<dynamic>> _getUsers() async => []; // TODO: Prepojiť na DatabaseService().getUsers()
  Future<List<dynamic>> _getStories() async => []; // TODO: Prepojiť na DatabaseService().getStories()
  Future<List<dynamic>> _getArchive() async => []; // TODO: Prepojiť na DatabaseService().getArchive()
  // --------------------------------------

  /// Načíta všetky potrebné uzly z databázy naraz a vypočíta štatistiky
  Future<Map<String, dynamic>> _loadProfileData() async {
    final String? currentNik = SessionManager.currentUser;

    // Paralelné spustenie všetkých troch sieťových dopytov pre optimálny výkon
    final results = await Future.wait([
      _getUsers(),
      _getStories(),
      _getArchive(),
    ]);

    final List<dynamic> users = results[0];
    final List<dynamic> stories = results[1];
    final List<dynamic> history = results[2];

    // 1. Nájdeme aktuálneho používateľa v zozname
    final Map<String, dynamic> user = users.firstWhere(
      (u) => u is Map && u["nik"] == currentNik,
      orElse: () => <String, dynamic>{},
    );

    // 2. Filtrujeme príbehy prihláseného používateľa a počítame AI skóre
    final mine = stories.where((s) => s is Map && s["nik"] == currentNik).toList();
    final List<num> scores = mine
        .map((s) => s["score"])
        .where((score) => score is num)
        .cast<num>()
        .toList();

    double avg = 0.0;
    num best = 0;
    if (scores.isNotEmpty) {
      final num sum = scores.reduce((a, b) => a + b);
      avg = double.parse((sum / scores.length).toStringAsFixed(1));
      best = scores.reduce((a, b) => a > b ? a : b);
    }

    // 3. Agregácia dát z archívu uzavretých kôl
    int winnersCount = 0;
    double totalFund = 0.0;

    for (var h in history) {
      if (h is! Map) continue;
      
      var wl = h["winners"];
      if (wl is List) {
        winnersCount += wl.length;
      } else if (wl is Map) {
        winnersCount += wl.length;
      }

      final double fund = double.tryParse(h["fund"]?.toString() ?? "0") ?? 0.0;
      totalFund += fund;
    }

    return {
      "nik": currentNik ?? "-",
      "registered": user["registered"] ?? "-",
      "myStoriesCount": mine.length,
      "avgScore": avg,
      "bestScore": best,
      "totalUsers": users.length,
      "totalStories": stories.length,
      "totalCycles": history.length,
      "totalWinners": winnersCount,
      "totalFund": totalFund,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _loadProfileData(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (snapshot.hasError) {
              return Center(child: Text("Chyba načítania štatistík: ${snapshot.error}"));
            }

            final data = snapshot.data!;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Section: Môj Profil
                  const Text(
                    "MÔJ PROFIL",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text("Nick: ${data['nik']}", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 6),
                  Text("Darca registrovaný: ${data['registered']}", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 6),
                  const Text("Blokovaný pre aktuálne kolo: NIE", style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 6),
                  Text("Počet mojich príbehov: ${data['myStoriesCount']}", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 6),
                  Text("Priemerné AI skóre: ${data['avgScore']} %", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 6),
                  Text("Najvyššie AI skóre: ${data['bestScore']} %", style: const TextStyle(fontSize: 16)),
                  
                  const SizedBox(height: 30),

                  // Section: Globálne štatistiky
                  const Text(
                    "ŠTATISTIKY STORYFUNDU",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.1),
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  Text("Registrovaných darcov: ${data['totalUsers']}", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 6),
                  Text("Vytvorených príbehov: ${data['totalStories']}", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 6),
                  Text("Uzavretých kôl: ${data['totalCycles']}", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 6),
                  Text("Podporených darcov: ${data['totalWinners']}", style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 6),
                  Text(
                    "Celkovo vyzbierané dary: ${(data['totalFund'] as double).toStringAsFixed(2)} €", 
                    style: const TextStyle(fontSize: 16),
                  ),
                  
                  const SizedBox(height: 35),

                  // Tlačidlo Späť
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                      child: const Text("SPÄŤ"),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
