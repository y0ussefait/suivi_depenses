import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart'; // Nécessite 'flutter pub add path_provider'
import 'package:share_plus/share_plus.dart';
import '../models/transaction.dart';
import '../models/debt.dart';

class BackupService {
  
  static Future<void> createBackup(BuildContext context) async {
    try {
      final transactions = Hive.box<Transaction>('transactions_v2').values.map((e) => {
        'description': e.description,
        'montant': e.montant,
        'date': e.date.toIso8601String(),
        'estDepense': e.estDepense,
        'category': e.category,
      }).toList();

      final debts = Hive.box<Debt>('debts').values.map((e) => {
        'person': e.person,
        'amount': e.amount,
        'isOwedToMe': e.isOwedToMe,
        'date': e.date.toIso8601String(),
        'description': e.description,
      }).toList();

      final backupMap = {
        'version': 1,
        'timestamp': DateTime.now().toIso8601String(),
        'transactions': transactions,
        'debts': debts,
      };

      final jsonString = jsonEncode(backupMap);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/budget_pro_backup.json');
      await file.writeAsString(jsonString);

      // Partage du fichier
      await Share.shareXFiles([XFile(file.path)], text: 'Ma sauvegarde Budget Pro');

    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur Export: $e")));
      }
    }
  }

  static Future<void> restoreBackup(BuildContext context) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String jsonString = await file.readAsString();
        Map<String, dynamic> data = jsonDecode(jsonString);

        final transBox = Hive.box<Transaction>('transactions_v2');
        final debtBox = Hive.box<Debt>('debts');
        await transBox.clear();
        await debtBox.clear();

        if (data['transactions'] != null) {
          for (var item in data['transactions']) {
            transBox.add(Transaction(
              description: item['description'],
              montant: (item['montant'] as num).toDouble(),
              date: DateTime.parse(item['date']),
              estDepense: item['estDepense'],
              category: item['category'],
            ));
          }
        }

        if (data['debts'] != null) {
          for (var item in data['debts']) {
            debtBox.add(Debt(
              person: item['person'],
              amount: (item['amount'] as num).toDouble(),
              isOwedToMe: item['isOwedToMe'],
              date: DateTime.parse(item['date']),
              description: item['description'],
            ));
          }
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Restauration réussie ! Redémarrez l'application.")),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Erreur Import: $e")));
      }
    }
  }
}