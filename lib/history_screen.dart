import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  
  // --- MIESTO PRE INTEGRÁCIU DATABÁZY ---
  // Tieto metódy simulujú pôvodné importy z database.py (už skonvertované do Dartu)
  Future<List<dynamic>> _getArchive() async {
    // TODO: Prepojiť na vašu DatabaseService().getArchive()
    // Ukážkové dáta pre zobrazenie štruktúry:
    return [
      {"fund": 150.0, "people": 10},
      {"fund": 240.50, "users": 12},
      {"fund": 0.0, "count": "0"}
    ];
  }
  // --------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "História kôl",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              const Text(
                "Uzavreté kolá",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 12),
              
              // Dynamické a asynchrónne načítanie histórie z Firebase
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: _getArchive(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    
                    if (snapshot.hasError) {
                      return Center(child: Text("Chyba pri načítaní: ${snapshot.error}"));
                    }
                    
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("Žiadna história nie je k dispozícii."));
                    }

                    // Otočenie poradia zoznamu (list(reversed(...)))
                    final archive = snapshot.data!.reversed.toList();

                    return ListView.builder(
                      itemCount: archive.length,
                      itemBuilder: (context, index) {
                        final cycle = archive[index];
                        if (cycle is! Map) return const SizedBox.shrink();

                        // Parsovanie vyzbieranej sumy
                        final double fund = double.tryParse(cycle["fund"]?.toString() ?? "0") ?? 0.0;
                        
                        // Hľadanie kľúča pre počet ľudí (people -> users -> count)
                        var peopleRaw = cycle["people"] ?? cycle["users"] ?? cycle["count"] ?? 0;
                        final int people = int.tryParse(peopleRaw.toString()) ?? 0;
                        
                        // Výpočet podielu na osobu
                        final double per = people > 0 ? fund / people : 0.0;

                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: const Icon(Icons.history, color: Colors.blue),
                            title: const Text(
                              "Minulé kolo",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              "Vyzbierané: ${fund.toStringAsFixed(2)} € | Ľudí: $people | Na osobu: ${per.toStringAsFixed(2)} €",
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Tlačidlo Späť
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/admin'),
                  child: const Text("Späť do Admin panela"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
