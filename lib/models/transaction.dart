import 'package:hive/hive.dart';

part 'transaction.g.dart'; 

@HiveType(typeId: 0) 
// AJOUT IMPORTANT ICI : "extends HiveObject"
class Transaction extends HiveObject {
  @HiveField(0)
  final String description;

  @HiveField(1)
  final double montant;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final bool estDepense;

  @HiveField(4)
  final String category;

  Transaction({
    required this.description,
    required this.montant,
    required this.date,
    required this.estDepense,
    required this.category,
  });
}