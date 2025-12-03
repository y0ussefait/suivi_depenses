import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction.dart';

class AddTransactionScreen extends StatefulWidget {
  final Transaction? transaction;

  const AddTransactionScreen({super.key, this.transaction});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _montantController = TextEditingController();
  
  bool _estDepense = true; 
  DateTime _selectedDate = DateTime.now();
  String _selectedCategory = 'Autre';

  final List<String> _categories = [
    'Nourriture', 'Transport', 'Loisirs', 'Santé', 
    'Maison', 'Salaire', 'Cadeau', 'Autre'
  ];

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      final t = widget.transaction!;
      _descriptionController.text = t.description;
      _montantController.text = t.montant.toString();
      _estDepense = t.estDepense;
      _selectedDate = t.date;
      _selectedCategory = t.category;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _montantController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.green,
            colorScheme: const ColorScheme.light(primary: Colors.green),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _saveTransaction() {
    if (_formKey.currentState!.validate()) {
      final String description = _descriptionController.text;
      final double montant = double.tryParse(_montantController.text) ?? 0.0;
      
      if (montant <= 0) return;

      if (widget.transaction != null) {
        final t = widget.transaction!;
        final updatedTransaction = Transaction(
          description: description,
          montant: montant,
          date: _selectedDate,
          estDepense: _estDepense,
          category: _selectedCategory,
        );
        
        final box = Hive.box<Transaction>('transactions_v2');
        box.put(t.key, updatedTransaction); 

      } else {
        final newTransaction = Transaction(
          description: description,
          montant: montant,
          date: _selectedDate,
          estDepense: _estDepense,
          category: _selectedCategory,
        );
        final box = Hive.box<Transaction>('transactions_v2');
        box.add(newTransaction);
      }
      
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Récupération de la devise dynamique
    final currency = Hive.box('settings').get('currency', defaultValue: '€');
    final isEditing = widget.transaction != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Modifier' : 'Nouvelle Transaction', 
          style: const TextStyle(color: Colors.white)
        ),
        backgroundColor: _estDepense ? Colors.red : Colors.green,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView( 
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(value: true, label: Text('Dépense'), icon: Icon(Icons.money_off)),
                  ButtonSegment(value: false, label: Text('Revenu'), icon: Icon(Icons.attach_money)),
                ],
                selected: {_estDepense},
                onSelectionChanged: (Set<bool> newSelection) {
                  setState(() {
                    _estDepense = newSelection.first;
                  });
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
                    if (states.contains(MaterialState.selected)) {
                      return _estDepense ? Colors.red.shade100 : Colors.green.shade100;
                    }
                    return Colors.transparent;
                  }),
                ),
              ),
              
              const SizedBox(height: 20),

              TextFormField(
                controller: _montantController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Montant ($currency)', // Utilisation de la variable ici
                  prefixIcon: const Icon(Icons.money),
                  border: const OutlineInputBorder(),
                ),
                validator: (val) => val!.isEmpty ? 'Requis' : null,
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _categories.contains(_selectedCategory) ? _selectedCategory : 'Autre',
                items: _categories.map((String category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Row(
                      children: [
                        Icon(Icons.label_outline, color: Colors.grey[600]),
                        const SizedBox(width: 10),
                        Text(category),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newValue) => setState(() => _selectedCategory = newValue!),
                decoration: const InputDecoration(
                  labelText: 'Catégorie',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Note (Optionnel)',
                  prefixIcon: Icon(Icons.edit_note),
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              InkWell(
                onTap: _pickDate,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Date : ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.green),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),
              
              ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: _estDepense ? Colors.red : Colors.green,
                ),
                child: Text(
                  isEditing ? 'METTRE À JOUR' : 'VALIDER', 
                  style: const TextStyle(color: Colors.white, fontSize: 18)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}