import 'package:flutter/material.dart';

class NewUserScreen extends StatefulWidget {
  const NewUserScreen({super.key});

  @override
  State<NewUserScreen> createState() => _NewUserScreenState();
}

class _NewUserScreenState extends State<NewUserScreen> {
  String _nik = "Načítavam...";
  String _pin = "Načítavam...";
  bool _isLoading = true;

  // --- MIESTO PRE INTEGRÁCIU BACKEND LOGIKY ---
  // Tieto metódy sa prepoja na predošlý súbor backend_service.dart
  
  Future<String> _generateNikBackend() async {
    // TODO: Prepojiť na BackendService().generateNik()
    // Simulácia asynchrónneho generovania:
    await Future.delayed(const Duration(milliseconds: 300));
    final randomDigits = (10000 + (DateTime.now().millisecond % 90000)).toString();
    return "SF$randomDigits";
  }

  String _generatePinBackend() {
    // TODO: Prepojiť na BackendService().generatePin()
    // Simulácia generovania 6-miestneho PIN-u:
    final randomDigits = (100000 + (DateTime.now().millisecond % 900000)).toString();
    return randomDigits;
  }

  Future<Map<String, String>?> _createUserBackend(String nik, String pin) async {
    // TODO: Prepojiť na BackendService().createUser(nik: nik, pin: pin)
    await Future.delayed(const Duration(milliseconds: 500));
    return {"nik": nik, "pin": pin}; // Vrátenie objektu pri úspechu, null pri chybe
  }
  // --------------------------------------------

  @override
  void initState() {
    super.initState();
    _generateCredentials();
  }

  /// Vygeneruje úplne nové prístupové údaje pre darcu
  void _generateCredentials() async {
    setState(() => _isLoading = true);
    
    final generatedNik = await _generateNikBackend();
    final generatedPin = _generatePinBackend();

    setState(() {
      _nik = generatedNik;
      _pin = generatedPin;
      _isLoading = false;
    });
  }

  /// Odošle vygenerované údaje na zápis do databázy a Firebase Auth
  void _saveUser() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);
    final result = await _createUserBackend(_nik, _pin);
    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result == null) {
      // Vykreslenie chybového dialógu v prípade zlyhania zápisu
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Chyba"),
          content: const Text("Používateľa sa nepodarilo vytvoriť."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK"),
            ),
          ],
        ),
      );
      return;
    }

    // Návrat do administrátorského rozhrania pri úspechu
    Navigator.pushReplacementNamed(context, '/admin');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                "Nový darca",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              
              const Text(
                "NIK",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _nik,
                style: const TextStyle(fontSize: 20, letterSpacing: 1.2),
              ),
              const SizedBox(height: 20),
              
              const Text(
                "PIN",
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _pin,
                style: const TextStyle(fontSize: 20, letterSpacing: 1.2),
              ),
              
              // Vytvorí flexibilný odstup (ekvivalent ft.Container(expand=True))
              const Spacer(),
              
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 20.0),
                    child: CircularProgressIndicator(),
                  ),
                ),

              ElevatedButton(
                onPressed: _isLoading ? null : _generateCredentials,
                child: const Text("Generovať znova"),
              ),
              const SizedBox(height: 10),
              
              ElevatedButton(
                onPressed: _isLoading ? null : _saveUser,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade50,
                  foregroundColor: Colors.blue.shade700,
                ),
                child: const Text("Vytvoriť darcu"),
              ),
              const SizedBox(height: 10),
              
              OutlinedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/admin'),
                child: const Text("Zrušiť"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
