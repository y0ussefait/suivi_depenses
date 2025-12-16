import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/debt.dart';
import '../models/transaction.dart';

class DebtScreen extends StatefulWidget {
  const DebtScreen({super.key});

  @override
  State<DebtScreen> createState() => _DebtScreenState();
}

class _DebtScreenState extends State<DebtScreen> {
  bool _showOwedToMe = true; 

  void _showAddDebtDialog(BuildContext context, {Debt? debt}) {
    final isEditing = debt != null;
    final personController = TextEditingController(text: debt?.person ?? '');
    final amountController = TextEditingController(text: debt?.amount.toString() ?? '');
    final descController = TextEditingController(text: debt?.description ?? '');
    bool isOwedToMeLocal = debt?.isOwedToMe ?? _showOwedToMe;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(isEditing ? 'Modifier' : 'Ajouter une dette'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('On me doit', style: TextStyle(fontSize: 12)),
                            selected: isOwedToMeLocal,
                            selectedColor: Colors.green.shade100,
                            checkmarkColor: Colors.green,
                            onSelected: (val) => setStateDialog(() => isOwedToMeLocal = true),
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Je dois', style: TextStyle(fontSize: 12)),
                            selected: !isOwedToMeLocal,
                            selectedColor: Colors.red.shade100,
                            checkmarkColor: Colors.red,
                            onSelected: (val) => setStateDialog(() => isOwedToMeLocal = false),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    TextField(controller: personController, decoration: const InputDecoration(labelText: 'Personne', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextField(controller: amountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Montant', border: OutlineInputBorder())),
                    const SizedBox(height: 10),
                    TextField(controller: descController, decoration: const InputDecoration(labelText: 'Note (Optionnel)', border: OutlineInputBorder())),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
                ElevatedButton(
                  onPressed: () {
                    final person = personController.text;
                    final amount = double.tryParse(amountController.text) ?? 0.0;
                    if (person.isEmpty || amount <= 0) return;
                    final newDebt = Debt(person: person, amount: amount, isOwedToMe: isOwedToMeLocal, date: DateTime.now(), description: descController.text);
                    final box = Hive.box<Debt>('debts');
                    if (isEditing) { box.put(debt.key, newDebt); } else { box.add(newDebt); }
                    Navigator.pop(ctx);
                  },
                  child: const Text('Sauvegarder'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _settleDebt(BuildContext context, Debt debt) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Dette réglée ?"),
        content: Text("Confirmer que ${debt.person} a tout réglé ?\nCela créera une transaction."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Non")),
          TextButton(
            onPressed: () {
              final isRevenue = debt.isOwedToMe;
              final transaction = Transaction(
                description: isRevenue ? "Remboursement de ${debt.person}" : "Remboursement à ${debt.person}",
                montant: debt.amount,
                date: DateTime.now(),
                estDepense: !isRevenue,
                category: "Dettes", 
              );
              Hive.box<Transaction>('transactions_v2').add(transaction);
              debt.delete();
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Dette réglée !"), backgroundColor: Colors.green));
            },
            child: const Text("Oui, réglé !", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context, Debt debt) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: const Text('Marquer comme réglée'),
            onTap: () { Navigator.pop(ctx); _settleDebt(context, debt); },
          ),
          ListTile(
            leading: const Icon(Icons.edit, color: Colors.blue),
            title: const Text('Modifier'),
            onTap: () { Navigator.pop(ctx); _showAddDebtDialog(context, debt: debt); },
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
                  content: const Text("Attention : La dette sera effacée SANS créer de transaction."),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text("Annuler")),
                    TextButton(onPressed: () { debt.delete(); Navigator.pop(dCtx); }, child: const Text("Supprimer", style: TextStyle(color: Colors.red))),
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
    final debtBox = Hive.box<Debt>('debts');
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currency = Hive.box('settings').get('currency', defaultValue: '€');

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: true, label: Text('On me doit'), icon: Icon(Icons.arrow_downward)),
                ButtonSegment(value: false, label: Text('Je dois'), icon: Icon(Icons.arrow_upward)),
              ],
              selected: {_showOwedToMe},
              onSelectionChanged: (Set<bool> newSelection) => setState(() => _showOwedToMe = newSelection.first),
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                  if (states.contains(WidgetState.selected)) {
                    return _showOwedToMe ? Colors.green.shade100 : Colors.red.shade100;
                  }
                  return Colors.transparent;
                }),
                foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                   if (states.contains(WidgetState.selected)) return Colors.black;
                   return isDark ? Colors.white : Colors.black;
                }),
              ),
            ),
          ),

          Expanded(
            child: ValueListenableBuilder(
              valueListenable: debtBox.listenable(),
              builder: (context, Box<Debt> box, _) {
                final debts = box.values.where((d) => d.isOwedToMe == _showOwedToMe).toList();
                double total = 0;
                for (var d in debts) total += d.amount;

                if (debts.isEmpty) {
                  return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.check_circle_outline, size: 60, color: Colors.grey[300]), const SizedBox(height: 10), Text("Aucune dette ici !", style: TextStyle(color: Colors.grey[600]))]));
                }

                return Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      decoration: BoxDecoration(color: _showOwedToMe ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
                      child: Text("Total : ${total.toStringAsFixed(2)} $currency", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _showOwedToMe ? Colors.green : Colors.red)),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: debts.length,
                        itemBuilder: (context, index) {
                          final debt = debts[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            color: isDark ? Colors.grey[800] : Colors.white,
                            elevation: 2,
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _showOwedToMe ? Colors.green.shade50 : Colors.red.shade50,
                                child: Text(debt.person.isNotEmpty ? debt.person.substring(0, 1).toUpperCase() : "?", style: TextStyle(fontWeight: FontWeight.bold, color: _showOwedToMe ? Colors.green : Colors.red)),
                              ),
                              title: Text(debt.person, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text(debt.description != null && debt.description!.isNotEmpty ? debt.description! : "Pas de note"),
                              trailing: Text("${debt.amount.toStringAsFixed(2)} $currency", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              onTap: () => _showOptions(context, debt),
                              onLongPress: () => _showOptions(context, debt),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDebtDialog(context),
        backgroundColor: _showOwedToMe ? Colors.green : Colors.red,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Ajouter", style: TextStyle(color: Colors.white)),
      ),
    );
  }
}