import 'package:flutter/material.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  
  List<Map<String, dynamic>> _allUsers = [];
  List<Map<String, dynamic>> _filteredUsers = [];
  bool _isLoading = true;
  int _maxStoriesLimit = 3; // Predvolená záložná hodnota

  // --- MIESTO PRE INTEGRÁCIU BACKEND LOGIKY ---
  // Tieto metódy prepojte na súbory backend_service.dart a settings_manager_service.dart
  
  Future<List<Map<String, dynamic>>> _listUsersBackend() async {
    // TODO: Prepojiť na BackendService().listUsers()
    await Future.delayed(const Duration(milliseconds: 400)); // Simulácia načítania
    return [
      {"nik": "SF12345", "pin": "998877", "active": true, "stories_count": 1},
      {"nik": "SF54321", "pin": "112233", "active": false, "stories_count": 3},
      {"nik": "SF98765", "pin": "556677", "active": true, "stories_count": 0},
    ];
  }

  Future<int> _getMaxStoriesLimit() async {
    // TODO: Prepojiť na SettingsManagerService.getSetting("MAX_STORIES_PER_CYCLE")
    return 3;
  }
  // --------------------------------------------

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Inicializačné asynchrónne stiahnutie dát z Firebase databázy
  void _fetchData() async {
    try {
      final users = await _listUsersBackend();
      final limit = await _getMaxStoriesLimit();
      
      setState(() {
        _allUsers = users;
        _maxStoriesLimit = limit;
        _isLoading = false;
        _filterUsers(_searchController.text); // Prvotné naplnenie zoznamu
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Chyba pri načítaní zoznamu darcov: $e");
    }
  }

  /// Filtračná logika spúšťaná na každú zmenu textu vo vyhľadávači (on_change z Fletu)
  void _filterUsers(String query) {
    final text = query.toUpperCase().trim();
    
    setState(() {
      if (text.isEmpty) {
        _filteredUsers = List.from(_allUsers);
      } else {
        _filteredUsers = _allUsers.where((user) {
          final String nik = (user["nik"] ?? "").toString().toUpperCase();
          return nik.contains(text);
        }).toList();
      }
    });
  }

  /// Otvorenie detailu darcu s bezpečným odovzdaním dát cez argumenty trasy
  void _openUser(Map<String, dynamic> user) {
    Navigator.pushReplacementNamed(
      context, 
      '/user_detail', 
      arguments: user,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Darcovia",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    
                    // Vyhľadávacie pole naviazané na reaktívny filter
                    TextField(
                      controller: _searchController,
                      onChanged: _filterUsers,
                      decoration: const InputDecoration(
                        labelText: "Hľadať podľa NIK...",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Informačný štítok o počte zobrazených položiek
                    Text(
                      "Darcov: ${_allUsers.length} | Zobrazených: ${_filteredUsers.length}",
                      style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    
                    // Výkonnostne optimalizovaný zoznam darcov
                    Expanded(
                      child: _filteredUsers.isEmpty
                          ? const Center(child: Text("Nenašli sa žiadni darcovia."))
                          : ListView.builder(
                              itemCount: _filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = _filteredUsers[index];
                                final bool isActive = user["active"] ?? true;
                                final String statusText = isActive ? "AKTÍVNY" : "BLOKOVANÝ";
                                final int count = user["stories_count"] ?? 0;

                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: ListTile(
                                    title: Text(
                                      "${user['nik'] ?? ''}   ($statusText)",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isActive ? Colors.black : Colors.red.shade700,
                                      ),
                                    ),
                                    subtitle: Text("Príbehy: $count / $_maxStoriesLimit"),
                                    trailing: const Icon(Icons.chevron_right),
                                    onTap: () => _openUser(user),
                                  ),
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 12),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 45,
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
