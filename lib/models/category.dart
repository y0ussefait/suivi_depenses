import 'package:hive/hive.dart';

part 'category.g.dart';

@HiveType(typeId: 4) // ID unique pour Hive
class Category extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int iconCode; // On stocke le code de l'icône (ex: 0xe532)

  @HiveField(2)
  final int colorValue; // On stocke la couleur (ex: 0xFFFF0000)

  Category({
    required this.name,
    required this.iconCode,
    required this.colorValue,
  });
}