import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/category.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  void _showAddDialog(BuildContext context) {
    final controller = TextEditingController();
    
    // Liste d'icônes prédéfinies
    final List<IconData> icons = [
      Icons.fastfood, Icons.directions_bus, Icons.home, Icons.movie, 
      Icons.shopping_bag, Icons.pets, Icons.child_care, Icons.flight,
      Icons.sports_soccer, Icons.school, Icons.medical_services, Icons.work,
      Icons.local_cafe, Icons.fitness_center, Icons.build, Icons.computer
    ];
    IconData selectedIcon = icons[0];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text("Nouvelle Catégorie"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(labelText: "Nom de la catégorie"),
                ),
                const SizedBox(height: 20),
                const Text("Choisir une icône :"),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: icons.map((icon) => InkWell(
                    onTap: () => setState(() => selectedIcon = icon),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: selectedIcon == icon ? Colors.green.shade100 : null,
                        shape: BoxShape.circle,
                        border: selectedIcon == icon ? Border.all(color: Colors.green) : null,
                      ),
                      child: Icon(icon, color: Colors.green.shade700),
                    ),
                  )).toList(),
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
            ElevatedButton(
              onPressed: () {
                if (controller.text.isNotEmpty) {
                  final newCat = Category(
                    name: controller.text, 
                    iconCode: selectedIcon.codePoint, 
                    colorValue: Colors.blue.value
                  );
                  Hive.box<Category>('categories').add(newCat);
                  Navigator.pop(ctx);
                }
              },
              child: const Text("Ajouter"),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Mes Catégories")),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Category>('categories').listenable(),
        builder: (context, Box<Category> box, _) {
          final categories = box.values.toList();
          
          if (categories.isEmpty) return const Center(child: Text("Aucune catégorie personnalisée."));

          return ListView.builder(
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.shade50,
                  child: Icon(IconData(cat.iconCode, fontFamily: 'MaterialIcons'), color: Colors.blue),
                ),
                title: Text(cat.name),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => cat.delete(),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}