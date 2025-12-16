import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/savings_goal.dart';

class SavingsScreen extends StatelessWidget {
  const SavingsScreen({super.key});

  void _showAddGoalDialog(BuildContext context, {SavingsGoal? goal}) {
    final isEditing = goal != null;
    final nameController = TextEditingController(text: goal?.name ?? '');
    final amountController = TextEditingController(text: goal?.targetAmount.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? "Modifier l'Objectif" : "Nouvel Objectif"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Nom (ex: PS5)")),
            TextField(controller: amountController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Montant Cible")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              final target = double.tryParse(amountController.text) ?? 0;
              if (nameController.text.isNotEmpty && target > 0) {
                if (isEditing) {
                  // Mise à jour (on garde le montant courant)
                  final updated = SavingsGoal(
                    name: nameController.text,
                    targetAmount: target,
                    currentAmount: goal.currentAmount,
                    colorCode: goal.colorCode,
                  );
                  Hive.box<SavingsGoal>('savings').put(goal.key, updated);
                } else {
                  // Création
                  final newGoal = SavingsGoal(
                    name: nameController.text,
                    targetAmount: target,
                    currentAmount: 0,
                    colorCode: Colors.blue.value,
                  );
                  Hive.box<SavingsGoal>('savings').add(newGoal);
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

  void _addMoneyToGoal(BuildContext context, SavingsGoal goal) {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Ajouter à ${goal.name}"),
        content: TextField(
          controller: amountController,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(labelText: "Montant à ajouter", prefixText: "+ "),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                goal.currentAmount += amount;
                goal.save(); 
                Navigator.pop(ctx);
              }
            },
            child: const Text("Ajouter"),
          )
        ],
      ),
    );
  }

  void _showOptions(BuildContext context, SavingsGoal goal) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.add_circle, color: Colors.green),
            title: const Text('Ajouter de l\'argent'),
            onTap: () { Navigator.pop(ctx); _addMoneyToGoal(context, goal); },
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text('Modifier l\'objectif'),
            onTap: () { Navigator.pop(ctx); _showAddGoalDialog(context, goal: goal); },
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
                    TextButton(onPressed: () { goal.delete(); Navigator.pop(dCtx); }, child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
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
        valueListenable: Hive.box<SavingsGoal>('savings').listenable(),
        builder: (context, Box<SavingsGoal> box, _) {
          final goals = box.values.toList();
          
          if (goals.isEmpty) {
            return const Center(child: Text("Aucun objectif. Créez votre première cagnotte !"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              final progress = (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0);
              final percent = (progress * 100).toStringAsFixed(0);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () => _addMoneyToGoal(context, goal), // Clic simple = Ajouter argent
                  onLongPress: () => _showOptions(context, goal), // Clic long = Menu complet
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(goal.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Icon(Icons.savings, color: Colors.blue.shade300),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 15,
                          backgroundColor: Colors.grey[200],
                          valueColor: const AlwaysStoppedAnimation(Colors.blue),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${goal.currentAmount.toStringAsFixed(0)} $currency / ${goal.targetAmount.toStringAsFixed(0)} $currency"),
                            Text("$percent %", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalDialog(context),
        icon: const Icon(Icons.add),
        label: const Text("Objectif"),
        backgroundColor: Colors.blue,
      ),
    );
  }
}