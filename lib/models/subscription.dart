import 'package:hive/hive.dart';

part 'subscription.g.dart';

@HiveType(typeId: 3) // ID 3
class Subscription extends HiveObject {
  @HiveField(0)
  final String name; // Ex: Netflix

  @HiveField(1)
  final double amount; // Ex: 12.99

  @HiveField(2)
  final int renewalDay; // Le jour du prélèvement (ex: le 15 du mois)

  @HiveField(3)
  final String period; // "Mensuel" ou "Annuel"

  Subscription({
    required this.name,
    required this.amount,
    required this.renewalDay,
    required this.period,
  });
}