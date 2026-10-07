import 'package:flutter/material.dart';
import 'app.dart'; // Import konfigurácie (pôvodne config.py)
import 'backend.dart'; // Import backend logiky (pôvodne backend.py)
import 'firebase_auth.dart'; // Import autentifikácie (pôvodne firebase_auth.py)
import 'balance.dart'; // Import sťahovania zostatku (pôvodne balance.py)

// Globálne premenné a funkcie presne podľa login.py predlohy
String? currentUser;
const String adminEmail = "storyfundreg@gmail.com";

String? getCurrentUser() {
  return currentUser;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Ovládače textových polí a správ pre UI komponenty
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _infoController = TextEditingController();
  
  String _infoText = "";
  bool _obscurePin = true;

  @override
  void initState() {
    super.initState();
    // Naviazanie on_change funkcie na sledovanie zadávania textu admina
    _nikController.addListener(_autoCompleteAdmin);
  }

  @override
  void dispose() {
    _nikController.dispose();
    _pinController.dispose();
    _infoController.dispose();
    super.dispose();
  }

  // Funkcia auto_complete_admin prebratá z tvojej Flet predlohy
  void _autoCompleteAdmin() {
    final String value = _nikController.text.trim();
    if (value.toLowerCase() == "stor") {
      _nikController.removeListener(_autoCompleteAdmin);
      
      setState(() {
        _nikController.text = adminEmail;
        // Nastavenie označenia textu a pozície kurzora (ft.TextSelection)
        _nikController.selection = TextSelection.fromPosition(
          TextPosition(offset: adminEmail.length),
        );
      });
      
      _nikController.addListener(_autoCompleteAdmin);
    }
  }

  // Hlavná funkcia login (on_click tvojho tlačidla)
  void _login() async {
    final String nik = _nikController.text.trim();
    final String pin = _pinController.text.trim();

    if (nik.isEmpty || pin.isEmpty) {
      setState(() => _infoText = "Zadaj NIK a PIN.");
      return;
    }

    // --- PRIHLÁSENIE ADMINISTRÁTORA ---
    if (nik.toLowerCase() == adminEmail.toLowerCase()) {
      // Volanie pôvodnej funkcie login_admin z firebase_auth.py
      final Map<String, dynamic> authResult = await FirebaseAuthService.loginAdmin(nik, pin);
      
      if (authResult["ok"] == true) {
        currentUser = "ADMIN";
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/admin');
        return;
      }
      
      final error = authResult["error"];
      setState(() => _infoText = "Firebase: ${error.toString()}");
      return;
    }

    // --- PRIHLÁSENIE BEŽNÉHO DARCU ---
    // Volanie pôvodnej funkcie login_user_auth z firebase_auth.py
    final Map<String, dynamic> authResult = await FirebaseAuthService.loginUserAuth(nik, pin);
    if (authResult["ok"] != true) {
      setState(() => _infoText = "Nesprávny NIK alebo PIN");
      return;
    }

    // Volanie overenia aktivity z backend.py -> login_user(nik, pin)
    final bool isActive = await BackendService.loginUser(nik, pin);
    if (!isActive) {
      setState(() => _infoText = "Používateľ nie je aktívny");
      return;
    }

    currentUser = nik;
    
    try {
      // Volanie update_balance_if_needed() z balance.py
      await BalanceService.updateBalanceIfNeeded();
    } catch (_) {
      // Prázdny block 'except Exception: pass' z tvojej predlohy
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Presná Flet farba pozadia #0F172A
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  AppConfig.appName, // Prístup cez tvoj súbor app.dart
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  "Tvorme príbehy. Pomáhajme.",
                  style: TextStyle(color: Color(0xFFCCD4E5)), // Farba #CCD4E5
                ),
                const SizedBox(height: 25),
                
                // Karta s formulárom (ft.Card)
                Card(
                  elevation: 4,
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 500),
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _nikController,
                          autofocus: true,
                          decoration: const InputDecoration(
                            labelText: "NIK",
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 15),
                        TextField(
                          controller: _pinController,
                          obscureText: _obscurePin,
                          decoration: InputDecoration(
                            labelText: "PIN",
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePin ? Icons.visibility : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() => _obscurePin = !_obscurePin);
                              },
                            ),
                          ),
                        ),
                        if (_infoText.isNotEmpty) ...[
                          const SizedBox(height: 15),
                          Text(
                            _infoText,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 15),
                        SizedBox(
                          width: double.infinity,
                          height: 45,
                          child: ElevatedButton(
                            onPressed: _login,
                            child: const Text("PRIHLÁSIŤ SA"),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 35),
                
                // Pätička verzie aplikácie
                Text(
                  "${AppConfig.appName} v${AppConfig.appVersion}",
                  style: const TextStyle(color: Color(0xFF94A3B8)), // Farba #94A3B8
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
