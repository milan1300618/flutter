import 'package:flutter/material.dart';

class UserDetailScreen extends StatefulWidget {
  final Object? arguments;

  const UserDetailScreen({super.key, this.arguments});

  @override
  State<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends State<UserDetailScreen> {
  Map<String, dynamic> _userData = {};
  bool _isLoading = false;

  Future<void> _blockUserBackend(String nik) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _unblockUserBackend(String nik) async {
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_userData.isEmpty && widget.arguments is Map<String, dynamic>) {
      _userData = Map<String, dynamic>.from(widget.arguments as Map);
    }
  }

  void _block() async {
    final String nik = _userData["nik"] ?? "";
    if (nik.isEmpty) return;

    setState(() => _isLoading = true);
    await _blockUserBackend(nik);
    
    setState(() {
      _userData["active"] = false;
      _isLoading = false;
    });
  }

  void _unblock() async {
    final String nik = _userData["nik"] ?? "";
    if (nik.isEmpty) return;

    setState(() => _isLoading = true);
    await _unblockUserBackend(nik);
    
    setState(() {
      _userData["active"] = true;
      _userData["active"] = true;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_userData.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text("Detail darcu")),
        body: const Center(child: Text("Neboli odovzdané žiadne údaje o darcovi.")),
      );
    }

    final bool isActive = _userData["active"] ?? true;
    final int storiesCount = _userData["stories_count"] ?? 0;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Darca",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              Text("NIK: ${_userData['nik'] ?? ''}", style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              Text("PIN: ${_userData['pin'] ?? ''}", style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              
              Text(
                "Stav: ${isActive ? 'AKTÍVNY' : 'BLOKOVANÝ'}",
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 8),
              Text("Príbehy v kole: $storiesCount", style: const TextStyle(fontSize: 16)),
              
              const Spacer(),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 15.0),
                    child: CircularProgressIndicator(),
                  ),
                ),

              if (isActive)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red,
                  ),
                  onPressed: _isLoading ? null : _block,
                  child: const Text("🚫 ... Blokovať"),
                )
              else
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade50,
                    foregroundColor: Colors.green,
                  ),
                  onPressed: _isLoading ? null : _unblock,
                  child: const Text("🔓 ... Odblokovať"),
                ),
                
              const SizedBox(height: 10),
              
              OutlinedButton(
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/users');
                },
                child: const Text("⬅ Späť"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
