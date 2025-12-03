import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/subscription.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  void _showAddSubDialog(BuildContext context) {
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final dayController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Nouvel Abonnement"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nom (Netflix, Salle...)")),
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Prix Mensuel")),
            TextField(controller: dayController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Jour du prélèvement (ex: 15)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              final day = int.tryParse(dayController.text) ?? 1;
              if (nameController.text.isNotEmpty && amount > 0) {
                final sub = Subscription(name: nameController.text, amount: amount, renewalDay: day, period: 'Mensuel');
                Hive.box<Subscription>('subscriptions').add(sub);
                Navigator.pop(ctx);
              }
            },
            child: const Text("Ajouter"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = Hive.box('settings').get('currency', defaultValue: '€');

    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Subscription>('subscriptions').listenable(),
        builder: (context, Box<Subscription> box, _) {
          final subs = box.values.toList();
          
          double totalMonthly = 0;
          for (var s in subs) totalMonthly += s.amount;

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                color: Colors.purple.shade50,
                child: Column(
                  children: [
                    const Text("Coût mensuel fixe", style: TextStyle(color: Colors.purple)),
                    Text(
                      "${totalMonthly.toStringAsFixed(2)} $currency",
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.purple),
                    ),
                    Text("${(totalMonthly * 12).toStringAsFixed(0)} $currency / an", style: const TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
              Expanded(
                child: subs.isEmpty 
                  ? const Center(child: Text("Aucun abonnement."))
                  : ListView.builder(
                      itemCount: subs.length,
                      itemBuilder: (context, index) {
                        final sub = subs[index];
                        return ListTile(
                          leading: CircleAvatar(backgroundColor: Colors.purple.shade100, child: const Icon(Icons.calendar_today, color: Colors.purple)),
                          title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Prélevé le ${sub.renewalDay} du mois"),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text("-${sub.amount.toStringAsFixed(2)} $currency", style: const TextStyle(fontWeight: FontWeight.bold)),
                              IconButton(icon: const Icon(Icons.delete, size: 20, color: Colors.grey), onPressed: () => sub.delete()),
                            ],
                          ),
                        );
                      },
                    ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSubDialog(context),
        icon: const Icon(Icons.add),
        label: const Text("Abonnement"),
        backgroundColor: Colors.purple,
      ),
    );
  }
}