import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/subscription.dart';
import '../models/transaction.dart';

class SubscriptionsScreen extends StatelessWidget {
  const SubscriptionsScreen({super.key});

  void _showAddSubDialog(BuildContext context, {Subscription? sub}) {
    final isEditing = sub != null;
    final nameController = TextEditingController(text: sub?.name ?? '');
    final amountController = TextEditingController(text: sub?.amount.toString() ?? '');
    final dayController = TextEditingController(text: sub?.renewalDay.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? "Modifier l'Abonnement" : "Nouvel Abonnement"),
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
                if (isEditing) {
                  final updated = Subscription(name: nameController.text, amount: amount, renewalDay: day, period: 'Mensuel');
                  Hive.box<Subscription>('subscriptions').put(sub.key, updated);
                } else {
                  final newSub = Subscription(name: nameController.text, amount: amount, renewalDay: day, period: 'Mensuel');
                  Hive.box<Subscription>('subscriptions').add(newSub);
                }
                Navigator.pop(ctx);
              }
            },
            child: const Text("Sauvegarder"),
          )
        ],
      ),
    );
  }

  void _paySubscription(BuildContext context, Subscription sub) {
    final currency = Hive.box('settings').get('currency', defaultValue: '€');
    final boxTrans = Hive.box<Transaction>('transactions_v2');
    final now = DateTime.now();

    final alreadyPaid = boxTrans.values.any((t) {
      return t.description == "Abonnement ${sub.name}" && 
             t.date.month == now.month && 
             t.date.year == now.year;
    });

    if (alreadyPaid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Déjà payé pour ce mois-ci !"), backgroundColor: Colors.orange),
      );
      return;
    }

    final transaction = Transaction(
      description: "Abonnement ${sub.name}",
      montant: sub.amount,
      date: now,
      estDepense: true,
      category: "Abonnement", 
    );
    
    boxTrans.add(transaction);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Dépense de ${sub.amount}$currency ajoutée !"), backgroundColor: Colors.green),
    );
  }

  void _showOptions(BuildContext context, Subscription sub) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.payment, color: Colors.green),
            title: const Text('Payer ce mois-ci'),
            onTap: () { Navigator.pop(ctx); _paySubscription(context, sub); },
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text('Modifier'),
            onTap: () { Navigator.pop(ctx); _showAddSubDialog(context, sub: sub); },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.red),
            title: const Text('Supprimer'),
            onTap: () {
              Navigator.pop(ctx);
              showDialog(
                context: context,
                builder: (dCtx) => AlertDialog(
                  title: const Text("Supprimer ?"),
                  content: const Text("Cette action est irréversible."),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text("Annuler")),
                    TextButton(onPressed: () { sub.delete(); Navigator.pop(dCtx); }, child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
            },
          ),
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
                    Text("${totalMonthly.toStringAsFixed(2)} $currency", style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.purple)),
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
                            ],
                          ),
                          onTap: () => _showOptions(context, sub),
                          onLongPress: () => _showOptions(context, sub),
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