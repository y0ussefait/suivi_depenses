import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../main.dart'; 

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  String _inputPin = "";
  String _storedPin = "";
  String _message = "Authentification requise";

  @override
  void initState() {
    super.initState();
    _loadPinAndAuthenticate();
  }

  Future<void> _loadPinAndAuthenticate() async {
    final settingsBox = Hive.box('settings');
    _storedPin = settingsBox.get('userPin', defaultValue: '');

    // Sécurité : Si pas de PIN configuré, on ne peut pas bloquer l'utilisateur -> on ouvre.
    if (_storedPin.isEmpty) {
       _navigateToApp();
       return;
    }

    // On lance la biométrie automatiquement au démarrage pour le confort
    _attemptBiometric();
  }

  Future<void> _attemptBiometric() async {
    try {
      // 1. Vérifier le matériel
      final bool canCheckBiometrics = await auth.canCheckBiometrics;
      final bool isDeviceSupported = await auth.isDeviceSupported();

      if (!canCheckBiometrics || !isDeviceSupported) {
        setState(() {
          _message = "Biométrie indisponible. Utilisez le code PIN.";
        });
        return;
      }

      // 2. Lancer le scan
      final bool didAuthenticate = await auth.authenticate(
        localizedReason: 'Veuillez vous authentifier pour accéder à vos comptes',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true, // Force l'usage du capteur (pas le code PIN du téléphone)
        ),
      );

      if (didAuthenticate) {
        _navigateToApp();
      } else {
        // Si l'utilisateur annule, on lui laisse la main sur le clavier PIN
        setState(() {
          _message = "Utilisez votre code PIN";
        });
      }
    } catch (e) {
      // En cas d'erreur technique, le PIN reste dispo
      setState(() {
        _message = "Erreur biométrie. Utilisez le PIN.";
      });
    }
  }

  // Gestion de la saisie du PIN
  void _onKeyTap(String value) {
    if (_inputPin.length < 4) {
      setState(() {
        _inputPin += value;
        _message = "";
      });
      
      if (_inputPin.length == 4) {
        _checkPin();
      }
    }
  }

  void _onBackspace() {
    if (_inputPin.isNotEmpty) {
      setState(() {
        _inputPin = _inputPin.substring(0, _inputPin.length - 1);
      });
    }
  }

  void _checkPin() {
    if (_inputPin == _storedPin) {
      _navigateToApp();
    } else {
      // Code faux : animation ou message et reset
      setState(() {
        _message = "Code PIN incorrect";
        _inputPin = ""; 
      });
    }
  }

  void _navigateToApp() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green.shade700,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 50),
            const Icon(Icons.lock, size: 80, color: Colors.white),
            const SizedBox(height: 20),
            Text(
              "Budget Pro",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white.withOpacity(0.9)),
            ),
            const SizedBox(height: 10),
            Text(
              _message,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 30),

            // Indicateurs de PIN (les points qui se remplissent)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index < _inputPin.length ? Colors.white : Colors.white.withOpacity(0.3),
                  ),
                );
              }),
            ),

            const Spacer(),

            // CLAVIER NUMÉRIQUE
            Container(
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(
                children: [
                  _buildRow(['1', '2', '3']),
                  _buildRow(['4', '5', '6']),
                  _buildRow(['7', '8', '9']),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // BOUTON BIOMÉTRIE (Le choix de l'utilisateur)
                      IconButton(
                        onPressed: _attemptBiometric,
                        icon: const Icon(Icons.fingerprint, size: 32, color: Colors.white),
                        tooltip: "Utiliser l'empreinte",
                      ),
                      _buildKey('0'),
                      // BOUTON EFFACER
                      IconButton(
                        onPressed: _onBackspace,
                        icon: const Icon(Icons.backspace_outlined, size: 28, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget pour une ligne de touches
  Widget _buildRow(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: keys.map((k) => _buildKey(k)).toList(),
      ),
    );
  }

  // Widget pour une touche individuelle
  Widget _buildKey(String val) {
    return InkWell(
      onTap: () => _onKeyTap(val),
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 80,
        height: 80,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withOpacity(0.1),
        ),
        child: Text(
          val,
          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}