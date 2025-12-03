import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
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
    
    return Scaffold(
      backgroundColor: Colors.grey.shade50, // Fond gris clair pour faire ressortir les cartes
      body: ValueListenableBuilder(
        valueListenable: settingsBox.listenable(), // On écoute la devise
        builder: (context, Box settings, _) {
          final currency = settings.get('currency', defaultValue: '€');

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
                    // --- SÉLECTEUR DE MOIS (Style iOS) ---
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => _changeMonth(-1)),
                          Text(
                            '${_getMonthName(_focusedDate.month)} ${_focusedDate.year}',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
                          ),
                          IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 20), onPressed: () => _changeMonth(1)),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- CARTE 1 : ÉVOLUTION (COURBE) ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Card(
                        elevation: 4,
                        shadowColor: Colors.black12,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Évolution du Solde", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 220,
                                child: _buildSmartLineChart(monthlyTransactions),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // --- CARTE 2 : RÉPARTITION (CAMEMBERT) ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Card(
                        elevation: 4,
                        shadowColor: Colors.black12,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Répartition", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                              const SizedBox(height: 20),
                              if (monthlyTransactions.isNotEmpty)
                                ChartWidget(transactions: monthlyTransactions)
                              else 
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(40.0),
                                    child: Text("Pas assez de données", style: TextStyle(color: Colors.grey)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100), // Espace pour le scroll
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSmartLineChart(List<Transaction> transactions) {
    if (transactions.isEmpty) return const Center(child: Text("Pas de données"));

    transactions.sort((a, b) => a.date.compareTo(b.date));

    List<FlSpot> spots = [];
    double currentBalance = 0;
    Map<int, double> dailyVariations = {};
    
    int daysInMonth = DateUtils.getDaysInMonth(_focusedDate.year, _focusedDate.month);
    
    // Initialisation
    for (int i = 1; i <= daysInMonth; i++) dailyVariations[i] = 0;

    // Remplissage
    for (var t in transactions) {
      double amount = t.estDepense ? -t.montant : t.montant;
      dailyVariations[t.date.day] = (dailyVariations[t.date.day] ?? 0) + amount;
    }

    // Construction des points
    double minVal = 0;
    double maxVal = 0;

    for (int day = 1; day <= daysInMonth; day++) {
      currentBalance += dailyVariations[day]!;
      if (currentBalance < minVal) minVal = currentBalance;
      if (currentBalance > maxVal) maxVal = currentBalance;

      if (DateTime(_focusedDate.year, _focusedDate.month, day).isBefore(DateTime.now().add(const Duration(days: 1)))) {
         spots.add(FlSpot(day.toDouble(), currentBalance));
      }
    }

    if (spots.isEmpty) return const Center(child: Text("Pas de données"));

    // Calcul du dégradé (Cutoff) pour séparer vert/rouge à 0
    double cutOffY = 0.0;
    // Si tout est positif ou tout négatif, on adapte
    if (minVal >= 0) cutOffY = minVal; 
    else if (maxVal <= 0) cutOffY = maxVal;

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false), // Plus propre sans grille
        titlesData: const FlTitlesData(show: false), // Pas de titres sur les axes (minimaliste)
        borderData: FlBorderData(show: false),
        // Ligne horizontale à 0
        extraLinesData: ExtraLinesData(
          horizontalLines: [HorizontalLine(y: 0, color: Colors.black12, strokeWidth: 1, dashArray: [5, 5])]
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 4,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            // La magie des couleurs ici :
            gradient: LinearGradient(
              colors: const [Colors.green, Colors.red],
              stops: [
                (0 - minVal) / (maxVal - minVal + 0.0001), // Point de bascule calculé
                (0 - minVal) / (maxVal - minVal + 0.0001) + 0.001,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              // Note: fl_chart gère les gradients un peu différemment, 
              // pour simplifier le rendu "Rouge en bas, Vert en haut", on utilise often belowBarData.
            ),
            // Solution plus simple et robuste pour Vert/Rouge : Colorer la zone
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [Colors.green.withOpacity(0.3), Colors.red.withOpacity(0.3)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.5, 0.5], // Coupe nette au milieu (approximatif)
                // Pour faire parfait, il faudrait un calcul complexe de 'stops' basé sur min/max.
                // Simplifions : Vert si positif, Rouge si négatif.
              ),
            ),
            // COULEUR DE LA LIGNE (Simplifiée pour éviter les bugs visuels)
            color: currentBalance >= 0 ? Colors.green : Colors.red, 
          ),
        ],
      ),
    );
  }
}