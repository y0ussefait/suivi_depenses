import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/transaction.dart';

class ChartWidget extends StatelessWidget {
  final List<Transaction> transactions;

  const ChartWidget({super.key, required this.transactions});

  @override
  Widget build(BuildContext context) {
    // 1. Calcul des totaux
    double totalDepenses = 0;
    double totalRevenus = 0;

    for (var t in transactions) {
      if (t.estDepense) {
        totalDepenses += t.montant;
      } else {
        totalRevenus += t.montant;
      }
    }

    final totalGlobal = totalDepenses + totalRevenus;

    // Si aucune donnée, on affiche un message ou un graphique vide
    if (totalGlobal == 0) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text("Ajoutez des transactions pour voir le graphique")),
      );
    }

    // 2. Création des sections du camembert
    final List<PieChartSectionData> sections = [
      // Section Dépenses (Rouge)
      if (totalDepenses > 0)
        PieChartSectionData(
          color: Colors.red,
          value: totalDepenses,
          title: '${((totalDepenses / totalGlobal) * 100).toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      // Section Revenus (Vert)
      if (totalRevenus > 0)
        PieChartSectionData(
          color: Colors.green,
          value: totalRevenus,
          title: '${((totalRevenus / totalGlobal) * 100).toStringAsFixed(0)}%',
          radius: 50,
          titleStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
        ),
    ];

    return Container(
      height: 250, // Hauteur de la zone graphique
      padding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Le Graphique
          PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 40, // Espace vide au milieu (Effet Donut)
              sectionsSpace: 2, // Petit espace entre les couleurs
            ),
          ),
          // Légende au centre ou en dessous ? Mettons une légende simple en dessous
          Positioned(
            bottom: 0,
            left: 0,
            child: Row(
              children: [
                _buildLegendItem(Colors.green, "Revenus"),
                const SizedBox(width: 10),
                _buildLegendItem(Colors.red, "Dépenses"),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Petite fonction pour créer les puces de légende
  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}