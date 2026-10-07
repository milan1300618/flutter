import 'package:flutter/material.dart';
import 'app_config.dart'; // Načítanie globálnej konfigurácie názvu a verzie
import 'firebase_auth_service.dart'; // Načítanie overenia cez Firebase

// ======================================
// SPRÁVCA RELÁCIE (SessionManager)
// Nahrádza pôvodnú globálnu premennú current_user z Pythonu
// ======================================
class SessionManager {
  SessionManager._();
  
  static String? _currentUser;

  static String? get currentUser => _currentUser;
  
  static void setCurrentUser(String? user) {
    _currentUser = user;
  }

  static bool isAdmin() => _currentUser == "ADMIN";
}

// ======================================
// PRIHLASOVACIA OBRAZOVKA (LoginScreen)
// ======================================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String adminEmail = "storyfundreg@gmail.com";

  // Ovládače textových polí a správ
  final TextEditingController _nikController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  String _infoMessage = "";
  bool _obscurePin = true;

  // --- MIESTO PRE INTEGRÁCIU BACKENDU ---
  Future<bool> _loginUserBackend(String nik, String pin) async {
    // TODO: Prepojiť na vaša BackendService.loginUser(nik, pin)
    return true; // Predvolene simulujeme aktívneho používateľa
  }

  Future<void> _updateBalanceIfNeeded() async {
    // TODO: Prepojiť na vaša BalanceService.updateBalanceIfNeeded()
  }
  // --------------------------------------

  @override
  void initState() {
    super.initState();
    // Automatické dopĺňanie administrátorského emailu po napísaní "stor"
    _nikController.addListener(_autoCompleteAdmin);
  }

  @override
  void dispose() {
    _nikController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _autoCompleteAdmin() {
    final String value = _nikController.text.trim();
    if (value.toLowerCase() == "stor") {
      _nikController.removeListener(_autoCompleteAdmin);
      
      setState(() {
        _nikController.text = adminEmail;
        _nikController.selection = TextSelection.fromPosition(
          TextPosition(offset: adminEmail.length),
        );
      });
      
      _nikController.addListener(_autoCompleteAdmin);
    }
  }

  void _login() async {
    final String nik = _nikController.text.trim();
    final String pin = _pinController.text.trim();

    if (nik.isEmpty || pin.isEmpty) {
      setState(() => _infoMessage = "Zadaj NIK a PIN.");
      return;
    }

    // --- PRIHLÁSENIE ADMINISTRÁTORA ---
    if (nik.toLowerCase() == adminEmail.toLowerCase()) {
      final authResult = await FirebaseAuthService.loginAdmin(nik, pin);
      
      if (authResult["ok"] == true) {
        SessionManager.setCurrentUser("ADMIN");
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/admin');
        return;
      }
      
      final error = authResult["error"];
      setState(() => _infoMessage = "Firebase: ${error.toString()}");
      return;
    }

    // --- PRIHLÁSENIE BEŽNÉHO DARCU ---
    final authResult = await FirebaseAuthService.loginUserAuth(nik, pin);
    if (authResult["ok"] != true) {
      setState(() => _infoMessage = "Nesprávny NIK alebo PIN");
      return;
    }

    final bool isActive = await _loginUserBackend(nik, pin);
    if (!isActive) {
      setState(() => _infoMessage = "Používateľ nie je aktívny");
      return;
    }

    SessionManager.setCurrentUser(nik);
    
    try {
      await _updateBalanceIfNeeded();
    } catch (_) {
      // Ignorovanie prípadnej chyby siete na pozadí, presne podľa Flet predlohy
    }

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Opravená Flet tmavomodrá
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  AppConfig.appName,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Text(
                  "Tvorme príbehy. Pomáhajme.",
                  style: TextStyle(color: Color(0xFFCCD4E5)), // Opravená strieborná
                ),
                const SizedBox(height: 25),
                
                // Prihlasovacia karta formulára
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
                        if (_infoMessage.isNotEmpty) ...[
                          const SizedBox(height: 15),
                          Text(
                            _infoMessage,
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
                
                // Verzia aplikácie
                Text(
                  "${AppConfig.appName} v${AppConfig.appVersion}",
                  style: const TextStyle(color: Color(0xFF94A3B8)), // Opravená sivá
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
