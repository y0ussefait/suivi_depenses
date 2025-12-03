import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../main.dart'; // Nécessaire pour naviguer vers MainScreen

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  String _authorized = 'Authentification nécessaire';
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    // On lance l'authentification dès que l'écran s'ouvre
    _authenticate();
  }

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
        _authorized = 'Analyse biométrique...';
      });
      
      // 1. Vérifier si le téléphone a un capteur
      final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await auth.isDeviceSupported();

      if (!canAuthenticate) {
        // Pas de capteur ? On laisse passer (ou on pourrait bloquer)
        _navigateToApp();
        return;
      }

      // 2. Demander l'empreinte / le visage
      authenticated = await auth.authenticate(
        localizedReason: 'Scannez votre empreinte pour accéder à votre Budget',
        options: const AuthenticationOptions(
          stickyAuth: true, // Reste actif même si une notif arrive
          biometricOnly: true, // Force la biométrie (pas de code PIN)
        ),
      );
    } on PlatformException catch (e) {
      print(e);
      setState(() {
        _authorized = "Erreur : ${e.message}";
        _isAuthenticating = false;
      });
      return;
    }

    if (!mounted) return;

    if (authenticated) {
      _navigateToApp();
    } else {
      setState(() {
        _authorized = 'Échec de l\'authentification';
        _isAuthenticating = false;
      });
    }
  }

  void _navigateToApp() {
    // On remplace l'écran de login par l'écran principal
    // (pushReplacement empêche de faire "Retour" pour revenir au login)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              "Budget Pro Sécurisé",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 40),
            
            // Affichage conditionnel
            if (_isAuthenticating)
              const CircularProgressIndicator(color: Colors.white)
            else
              Column(
                children: [
                  Text(_authorized, style: const TextStyle(color: Colors.white70)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.fingerprint),
                    label: const Text("Réessayer"),
                    onPressed: _authenticate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                    ),
                  ),
                ],
              )
          ],
        ),
      ),
    );
  }
}