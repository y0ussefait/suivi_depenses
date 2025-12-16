import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/backup_service.dart';
import 'categories_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<String> currencies = ['€', '\$', '£', 'DH', 'CHF', 'CFA', '¥'];

  void _showSetPinDialog(BuildContext context, Box settingsBox) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Définir un Code PIN"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Choisissez un code à 4 chiffres."),
            const SizedBox(height: 10),
            TextField(controller: pinController, keyboardType: TextInputType.number, maxLength: 4, obscureText: true),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              if (pinController.text.length == 4) {
                settingsBox.put('userPin', pinController.text);
                setState(() {});
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Code PIN enregistré.")));
              }
            },
            child: const Text("Sauvegarder"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box('settings');
    final isDark = settingsBox.get('isDark', defaultValue: false);
    final currentCurrency = settingsBox.get('currency', defaultValue: '€');
    final isBiometricEnabled = settingsBox.get('isBiometricEnabled', defaultValue: false);
    final userPin = settingsBox.get('userPin', defaultValue: '');

    return Scaffold(
      appBar: AppBar(title: const Text("Paramètres"), centerTitle: true),
      body: ListView(
        children: [
          const SizedBox(height: 20),
          _buildSectionHeader("Apparence"),
          SwitchListTile(
            title: const Text("Mode Sombre"),
            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            value: isDark,
            activeTrackColor: Colors.green, // Remplacement de activeColor
            onChanged: (val) { settingsBox.put('isDark', val); setState(() {}); },
          ),
          
          const Divider(),
          _buildSectionHeader("Personnalisation"),
          ListTile(
            leading: const Icon(Icons.category, color: Colors.orange),
            title: const Text("Gérer les Catégories"),
            subtitle: const Text("Ajouter ou supprimer des catégories"),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const CategoriesScreen()));
            },
          ),

          const Divider(),
          _buildSectionHeader("Données & Sauvegarde"),
          ListTile(
            leading: const Icon(Icons.upload_file, color: Colors.blue),
            title: const Text("Exporter les données"),
            subtitle: const Text("Sauvegarder en fichier JSON"),
            onTap: () => BackupService.createBackup(context),
          ),
          ListTile(
            leading: const Icon(Icons.download, color: Colors.green),
            title: const Text("Importer une sauvegarde"),
            subtitle: const Text("Restaurer depuis un fichier"),
            onTap: () => BackupService.restoreBackup(context),
          ),

          const Divider(),
          _buildSectionHeader("Sécurité"),
          ListTile(
            title: Text(userPin.isEmpty ? "Créer un code PIN" : "Changer le code PIN"),
            leading: const Icon(Icons.lock),
            onTap: () => _showSetPinDialog(context, settingsBox),
          ),
          SwitchListTile(
            title: const Text("Biométrie"),
            secondary: const Icon(Icons.fingerprint),
            value: isBiometricEnabled,
            activeTrackColor: Colors.green, // Remplacement de activeColor
            onChanged: (val) {
              if (val == true && userPin.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez d'abord définir un Code PIN.")));
                _showSetPinDialog(context, settingsBox);
              } else {
                settingsBox.put('isBiometricEnabled', val);
                setState(() {});
              }
            },
          ),

          const Divider(),
          _buildSectionHeader("Préférences"),
          ListTile(
            leading: const Icon(Icons.currency_exchange),
            title: const Text("Devise"),
            trailing: DropdownButton<String>(
              value: currencies.contains(currentCurrency) ? currentCurrency : '€',
              underline: Container(),
              items: currencies.map((String value) => DropdownMenuItem<String>(value: value, child: Text(value))).toList(),
              onChanged: (val) { if (val != null) { settingsBox.put('currency', val); setState(() {}); } },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(title.toUpperCase(), style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
    );
  }
}