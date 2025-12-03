import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../models/debt.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Liste des devises courantes
  final List<String> currencies = ['€', '\$', '£', 'DH', 'CHF', 'CFA', '¥'];

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box('settings');
    
    // Récupération des valeurs actuelles (avec valeurs par défaut)
    final isDark = settingsBox.get('isDark', defaultValue: false);
    final currentCurrency = settingsBox.get('currency', defaultValue: '€');
    final isBiometricEnabled = settingsBox.get('isBiometricEnabled', defaultValue: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Paramètres"),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          
          // --- SECTION APPARENCE ---
          _buildSectionHeader("Apparence"),
          SwitchListTile(
            title: const Text("Mode Sombre"),
            subtitle: const Text("Économise la batterie et vos yeux"),
            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            value: isDark,
            activeColor: Colors.green,
            onChanged: (val) {
              settingsBox.put('isDark', val);
              setState(() {}); // Rafraîchir l'écran pour voir l'effet immédiat
            },
          ),

          const Divider(),

          // --- SECTION SÉCURITÉ (NOUVEAU) ---
          _buildSectionHeader("Sécurité"),
          SwitchListTile(
            title: const Text("Verrouillage Biométrique"),
            subtitle: const Text("Demander l'empreinte à l'ouverture"),
            secondary: const Icon(Icons.fingerprint),
            value: isBiometricEnabled,
            activeColor: Colors.green,
            onChanged: (val) {
              settingsBox.put('isBiometricEnabled', val);
              setState(() {});
            },
          ),

          const Divider(),

          // --- SECTION PRÉFÉRENCES ---
          _buildSectionHeader("Préférences"),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text("Devise"),
            subtitle: Text("Actuel : $currentCurrency"),
            trailing: DropdownButton<String>(
              value: currencies.contains(currentCurrency) ? currentCurrency : '€',
              underline: Container(), // Cache la ligne du bas
              items: currencies.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                if (newValue != null) {
                  settingsBox.put('currency', newValue);
                  setState(() {});
                }
              },
            ),
          ),

          const Divider(),

          // --- SECTION DANGER ---
          _buildSectionHeader("Zone de Danger"),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text("Réinitialiser les données", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            subtitle: const Text("Efface toutes les transactions et dettes."),
            onTap: () {
              _showResetConfirmation(context);
            },
          ),
          
          const SizedBox(height: 30),
          const Center(child: Text("Version 2.1.0 - Budget Pro", style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }

  // Widget utilitaire pour les titres de section
  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
      ),
    );
  }

  // Fenêtre de confirmation pour tout effacer
  void _showResetConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Êtes-vous sûr ?"),
        content: const Text("Cette action est irréversible. Toutes vos données seront perdues à jamais."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              // Effacer les boites de données
              Hive.box<Transaction>('transactions_v2').clear();
              Hive.box<Debt>('debts').clear();
              
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Toutes les données ont été effacées.")),
              );
            },
            child: const Text("TOUT EFFACER", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}