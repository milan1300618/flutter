import 'dart:async';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_screen.dart'; // Import pre SessionManager.currentUser

const String transparentAccountUrl =
    "https://unicreditbank.sk";

class HomeScreenV5 extends StatefulWidget {
  const HomeScreenV5({super.key});

  @override
  State<HomeScreenV5> createState() => _HomeScreenV5State();
}

class _HomeScreenV5State extends State<HomeScreenV5> {
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  
  // Rýchlosť posunu (zodpovedá step = 0.0005 v Kivy)
  final double _scrollStep = 0.4; 

  // --- MIESTO PRE INTEGRÁCIU BACKENDU ---
  List<Map<String, dynamic>> _loadFeed() {
    // TODO: Prepojiť na BackendService().loadFeed()
    return [
      {"nik": "Marián", "story": "Prvý ranný príbeh o hľadaní stratenej cesty domov...", "score": 85},
      {"nik": "Zuzana", "story": "Umelá inteligencia píše básne oveľa rýchlejšie ako ja, no chýba jej cit.", "score": 92},
      {"nik": "Peter", "story": "Na transparentný účet prichádzajú prvé dary. Ďakujeme všetkým darcom!", "score": 78},
    ];
  }
  // --------------------------------------

  @override
  void initState() {
    super.initState();
    // Spustenie automatického rolovania po vykreslení prvého snímku aplikácie
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startAutoScroll();
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  /// Implementácia Kivy auto_scroll funkcie vo Flutteri
  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      if (!_scrollController.hasClients) return;

      final double maxScroll = _scrollController.position.maxScrollExtent;
      final double currentScroll = _scrollController.position.pixels;

      // Ak sme na konci, skočíme plynule späť na začiatok (scroll_y = 1.0)
      if (currentScroll >= maxScroll) {
        _scrollController.jumpTo(0.0);
      } else {
        _scrollController.jumpTo(currentScroll + _scrollStep);
      }
    });
  }

  Future<void> _openAccount() async {
    final Uri url = Uri.parse(transparentAccountUrl);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nepodarilo sa otvoriť transparentný účet.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String currentUser = SessionManager.currentUser ?? "Hosť";
    final List<Map<String, dynamic>> stories = _loadFeed();

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // =====================================
              // Horná pevná časť (Title & Welcome)
              // =====================================
              const Text(
                "StoryFund",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                "Vitaj, $currentUser 👋",
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),

              // Horné menu s tlačidlami
              Row(
                spacing: 8.0,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/create_story'),
                      child: const Text("NOVÝ PRÍBEH"),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/profile'),
                      child: const Text("PROFIL"),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        SessionManager.setCurrentUser(null);
                        Navigator.pushReplacementNamed(context, '/login');
                      },
                      child: const Text("ODHLÁSIŤ"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              ElevatedButton(
                onPressed: _openAccount,
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(42)),
                child: const Text("TRANSPARENTNÝ ÚČET"),
              ),
              const SizedBox(height: 15),

              // =====================================
              // Feed s automatickým rolovaním
              // =====================================
              Expanded(
                child: stories.isEmpty
                    ? const Center(
                        child: Text(
                          "Zatiaľ nie sú žiadne príbehy.",
                          style: TextStyle(fontSize: 16),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: stories.length,
                        itemBuilder: (context, index) {
                          final s = stories[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 7.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "👤 ${s['nik'] ?? 'Neznámy'}",
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    s['story'] ?? '',
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    "AI index: ${s['score'] ?? 0} %",
                                    style: const TextStyle(color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),

              // =====================================
              // Súhrn posledného kola (pevný spodný panel)
              // =====================================
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Text(
                        "MINULOTÝŽDŇOVÁ ZBIERKA",
                        style: TextStyle(
                          fontWeight: FontWeight.bold, 
                          color: Theme.of(context).colorScheme.onPrimaryContainer
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Vyzbierané: 245,60 €", style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer)),
                          Text("Odmenených: 12", style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer)),
                          Text("13.07.2026", style: TextStyle(color: Theme.of(context).colorScheme.onPrimaryContainer)),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
