import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';
import '../widgets/chart_widget.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  DateTime _focusedDate = DateTime.now();

  void _changeMonth(int offset) {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + offset, 1);
    });
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box('settings');
    // On détecte le mode sombre via le contexte ou la boite settings
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Couleurs dynamiques
    final backgroundColor = isDark ? const Color(0xFF121212) : Colors.grey.shade50;
    final cardColor = isDark ? Colors.grey[800] : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: backgroundColor, 
      body: ValueListenableBuilder(
        valueListenable: settingsBox.listenable(), 
        builder: (context, Box settings, _) {
          
          return ValueListenableBuilder(
            valueListenable: Hive.box<Transaction>('transactions_v2').listenable(),
            builder: (context, Box<Transaction> box, _) {
              final allTransactions = box.values.toList().cast<Transaction>();
              
              final monthlyTransactions = allTransactions.where((t) {
                return t.date.year == _focusedDate.year && t.date.month == _focusedDate.month;
              }).toList();

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // --- SÉLECTEUR DE MOIS ---
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: cardColor, // Couleur dynamique
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => _changeMonth(-1)),
                          Text(
                            '${_getMonthName(_focusedDate.month)} ${_focusedDate.year}',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor),
                          ),
                          IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 20), onPressed: () => _changeMonth(1)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- CARTE UNIQUE : RÉPARTITION ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Card(
                        elevation: 4,
                        shadowColor: Colors.black12,
                        color: cardColor, // Couleur dynamique
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Répartition des Dépenses", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
                              const SizedBox(height: 20),
                              if (monthlyTransactions.isNotEmpty)
                                ChartWidget(transactions: monthlyTransactions)
                              else 
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(40.0),
                                    child: Text("Pas assez de données pour ce mois", style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100), 
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}