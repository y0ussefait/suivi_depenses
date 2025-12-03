import 'package:hive/hive.dart';

part 'debt.g.dart';

@HiveType(typeId: 1) // On utilise l'ID 1 car 0 est pris par Transaction
class Debt extends HiveObject {
  @HiveField(0)
  final String person; // Le nom (ex: "Karim")

  @HiveField(1)
  final double amount; // Le montant

  @HiveField(2)
  final bool isOwedToMe; // True = On me doit, False = Je dois

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String? description; // Note optionnelle

  Debt({
    required this.person,
    required this.amount,
    required this.isOwedToMe,
    required this.date,
    this.description,
  });
}