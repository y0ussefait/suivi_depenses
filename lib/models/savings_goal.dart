  import 'package:hive/hive.dart';

  part 'savings_goal.g.dart';

  @HiveType(typeId: 2) // ID 2
  class SavingsGoal extends HiveObject {
    @HiveField(0)
    final String name; // Ex: PS5, Voyage

    @HiveField(1)
    final double targetAmount; // Objectif: 500€

    @HiveField(2)
    double currentAmount; // Actuel: 120€

    @HiveField(3)
    final int colorCode; // Pour la couleur de la carte

    @HiveField(4)
    final String iconCode; // Pour l'icône (optionnel)

    SavingsGoal({
      required this.name,
      required this.targetAmount,
      required this.currentAmount,
      required this.colorCode,
      this.iconCode = '',
    });
  }