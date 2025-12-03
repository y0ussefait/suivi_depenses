import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Modèles
import 'models/transaction.dart';
import 'models/debt.dart';
import 'models/savings_goal.dart';
import 'models/subscription.dart';

// Services
import 'services/pdf_service.dart';
import 'services/notification_service.dart'; // NOUVEAU

// Écrans
import 'screens/add_transaction_screen.dart';
import 'screens/debt_screen.dart'; 
import 'screens/settings_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/onboarding_screen.dart'; 
import 'screens/savings_screen.dart'; 
import 'screens/subscriptions_screen.dart'; 
import 'screens/stats_screen.dart'; // NOUVEAU

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  // Init Notifications
  await NotificationService.init();
  await NotificationService.scheduleDailyReminders(); // Lance les rappels 8h/23h
  
  Hive.registerAdapter(TransactionAdapter()); 
  Hive.registerAdapter(DebtAdapter()); 
  Hive.registerAdapter(SavingsGoalAdapter()); 
  Hive.registerAdapter(SubscriptionAdapter()); 
  
  await Hive.openBox<Transaction>('transactions_v2');
  await Hive.openBox('settings');
  await Hive.openBox<Debt>('debts');
  await Hive.openBox<SavingsGoal>('savings'); 
  await Hive.openBox<Subscription>('subscriptions'); 
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('settings').listenable(),
      builder: (context, Box box, widget) {
        final isDark = box.get('isDark', defaultValue: false);
        final isBiometricEnabled = box.get('isBiometricEnabled', defaultValue: false);
        final hasSeenOnboarding = box.get('hasSeenOnboarding', defaultValue: false);
        
        Widget firstScreen;
        if (!hasSeenOnboarding) {
          firstScreen = const OnboardingScreen();
        } else if (isBiometricEnabled) {
          firstScreen = const AuthScreen();
        } else {
          firstScreen = const MainScreen();
        }

        return MaterialApp(
          title: 'Budget Pro',
          debugShowCheckedModeBanner: false, 
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.light),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green, brightness: Brightness.dark),
            scaffoldBackgroundColor: const Color(0xFF121212),
          ),
          home: firstScreen, 
        );
      }
    );
  }
}

// --- NAVIGATION PRINCIPALE (5 ONGLETS MAINTENANT) ---
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0; 

  final List<Widget> _pages = [
    const BudgetPage(), 
    const StatsScreen(), // NOUVEL ONGLET EN 2ème POSITION
    const DebtScreen(), 
    const SavingsScreen(), 
    const SubscriptionsScreen(), 
  ];

  @override
  void initState() {
    super.initState();
    // Demander la permission de notif au démarrage (Android 13+)
    NotificationService.requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Titres dynamiques
    String title = "Budget";
    if (_currentIndex == 1) title = "Analyses";
    if (_currentIndex == 2) title = "Dettes";
    if (_currentIndex == 3) title = "Épargne";
    if (_currentIndex == 4) title = "Abos";

    // Couleurs dynamiques
    Color appBarColor = Colors.green;
    if (_currentIndex == 1) appBarColor = Colors.blueGrey; // Stats
    if (_currentIndex == 2) appBarColor = Colors.orange;   // Dettes
    if (_currentIndex == 3) appBarColor = Colors.blue;     // Épargne
    if (_currentIndex == 4) appBarColor = Colors.purple;   // Abos
    if (isDark) appBarColor = Colors.grey[900]!;

    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: appBarColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), selectedIcon: Icon(Icons.account_balance_wallet), label: 'Budget'),
          NavigationDestination(icon: Icon(Icons.bar_chart), selectedIcon: Icon(Icons.bar_chart), label: 'Stats'), // NOUVEAU
          NavigationDestination(icon: Icon(Icons.handshake_outlined), selectedIcon: Icon(Icons.handshake), label: 'Dettes'),
          NavigationDestination(icon: Icon(Icons.savings_outlined), selectedIcon: Icon(Icons.savings), label: 'Épargne'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), selectedIcon: Icon(Icons.calendar_month), label: 'Abos'),
        ],
      ),
    );
  }
}

// --- PAGE BUDGET (ALLÉGÉE : PLUS DE CAMEMBERT) ---
class BudgetPage extends StatefulWidget {
  const BudgetPage({super.key});

  @override
  State<BudgetPage> createState() => _BudgetPageState();
}

class _BudgetPageState extends State<BudgetPage> {
  DateTime _focusedDate = DateTime.now();
  String _searchQuery = ""; 
  bool _isSearching = false;

  double _calculateTotal(List<Transaction> transactions) {
    double total = 0.0;
    for (var t in transactions) {
      if (t.estDepense) total -= t.montant;
      else total += t.montant;
    }
    return total;
  }

  double _calculateTotalDepenses(List<Transaction> transactions) {
    double total = 0.0;
    for (var t in transactions) {
      if (t.estDepense) total += t.montant;
    }
    return total;
  }

  IconData _getIconForCategory(String category) {
    switch (category) {
      case 'Nourriture': return Icons.fastfood;
      case 'Transport': return Icons.directions_bus;
      case 'Loisirs': return Icons.sports_esports;
      case 'Santé': return Icons.medical_services;
      case 'Maison': return Icons.home;
      case 'Salaire': return Icons.account_balance_wallet;
      case 'Cadeau': return Icons.card_giftcard;
      default: return Icons.category;
    }
  }

  void _changeMonth(int offset) {
    setState(() {
      _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + offset, 1);
    });
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin', 'Juil', 'Août', 'Sep', 'Oct', 'Nov', 'Déc'];
    return months[month - 1];
  }

  void _setBudgetDialog() {
    final settingsBox = Hive.box('settings');
    final currentBudget = settingsBox.get('budgetLimit', defaultValue: 1000.0);
    final controller = TextEditingController(text: currentBudget.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Définir le budget mensuel"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: "Montant Max"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Annuler")),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(controller.text) ?? 1000.0;
              settingsBox.put('budgetLimit', val);
              Navigator.pop(ctx);
            },
            child: const Text("Sauvegarder"),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsBox = Hive.box<Transaction>('transactions_v2');
    final settingsBox = Hive.box('settings');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: ValueListenableBuilder(
        valueListenable: transactionsBox.listenable(),
        builder: (context, Box<Transaction> box, _) {
          return ValueListenableBuilder(
            valueListenable: settingsBox.listenable(),
            builder: (context, Box settings, _) {
              
              final currency = settings.get('currency', defaultValue: '€');
              final budgetLimit = settings.get('budgetLimit', defaultValue: 1000.0);

              final allTransactions = box.values.toList().cast<Transaction>();
              
              var visibleTransactions = allTransactions.where((t) {
                return t.date.year == _focusedDate.year && t.date.month == _focusedDate.month;
              }).toList();

              if (_searchQuery.isNotEmpty) {
                visibleTransactions = visibleTransactions.where((t) {
                  return t.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                         t.category.toLowerCase().contains(_searchQuery.toLowerCase());
                }).toList();
              }

              final total = _calculateTotal(visibleTransactions);
              final totalDepensesMois = _calculateTotalDepenses(visibleTransactions);
              visibleTransactions.sort((a, b) => b.date.compareTo(a.date));
              
              double progress = (totalDepensesMois / budgetLimit).clamp(0.0, 1.0);
              Color progressColor = progress < 0.5 ? Colors.green : (progress < 0.8 ? Colors.orange : Colors.red);

              return Column(
                children: [
                  // --- Zone Recherche ---
                  if (_isSearching)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: "Rechercher...",
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() {
                              _isSearching = false;
                              _searchQuery = "";
                            }),
                          ),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),

                  // --- Zone Infos ---
                  if (!_isSearching)
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.green.shade50,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(30),
                        bottomRight: Radius.circular(30),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(icon: const Icon(Icons.arrow_back_ios, size: 16), onPressed: () => _changeMonth(-1)),
                            Text(
                              '${_getMonthName(_focusedDate.month)} ${_focusedDate.year}',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Row(
                              children: [
                                IconButton(icon: const Icon(Icons.arrow_forward_ios, size: 16), onPressed: () => _changeMonth(1)),
                                IconButton(
                                  icon: const Icon(Icons.picture_as_pdf, color: Colors.redAccent),
                                  onPressed: () {
                                    if (visibleTransactions.isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rien à exporter.")));
                                    } else {
                                      PdfService.generatePdf(visibleTransactions, currency);
                                    }
                                  },
                                ),
                                IconButton(icon: const Icon(Icons.search), onPressed: () => setState(() => _isSearching = true)),
                              ],
                            ),
                          ],
                        ),
                        Text('Solde du mois', style: TextStyle(color: isDark ? Colors.white70 : Colors.green.shade900)),
                        Text(
                          '${total >= 0 ? '+' : ''}${total.toStringAsFixed(2)} $currency',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: total >= 0 ? (isDark ? Colors.greenAccent : Colors.green.shade800) : Colors.red,
                          ),
                        ),
                        const SizedBox(height: 15),
                        InkWell(
                          onTap: _setBudgetDialog,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text("Budget dépensé", style: TextStyle(fontSize: 12, color: isDark ? Colors.grey : Colors.grey[700])),
                                  Text("${totalDepensesMois.toStringAsFixed(0)} / ${budgetLimit.toStringAsFixed(0)} $currency", 
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 5),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  minHeight: 10,
                                  backgroundColor: isDark ? Colors.grey[700] : Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // PLUS DE CHART WIDGET ICI ! Il a été déplacé dans StatsScreen

                  const SizedBox(height: 10),

                  // --- Liste des Transactions ---
                  Expanded(
                    child: visibleTransactions.isEmpty
                        ? Center(
                            child: Text(
                              _searchQuery.isNotEmpty ? "Aucun résultat" : "Rien à afficher",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            itemCount: visibleTransactions.length,
                            itemBuilder: (context, index) {
                              final transaction = visibleTransactions[index];
                              return Card(
                                elevation: 2,
                                color: isDark ? Colors.grey[800] : Colors.white,
                                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: transaction.estDepense 
                                      ? (isDark ? Colors.red.withOpacity(0.2) : Colors.red.shade50) 
                                      : (isDark ? Colors.green.withOpacity(0.2) : Colors.green.shade50),
                                    child: Icon(
                                      _getIconForCategory(transaction.category),
                                      color: transaction.estDepense ? Colors.red : Colors.green,
                                    ),
                                  ),
                                  title: Text(
                                    transaction.category, 
                                    style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                                  ),
                                  subtitle: Text(
                                    '${transaction.description} • ${transaction.date.day}/${transaction.date.month}',
                                    style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey[600]),
                                  ),
                                  trailing: Text(
                                    '${transaction.estDepense ? '-' : '+'} ${transaction.montant.toStringAsFixed(2)} $currency',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: transaction.estDepense ? Colors.red : Colors.green,
                                    ),
                                  ),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => AddTransactionScreen(transaction: transaction),
                                      ),
                                    );
                                  },
                                  onLongPress: () => transaction.delete(),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              );
            }
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
          );
        },
        backgroundColor: isDark ? Colors.greenAccent : Colors.black,
        icon: Icon(Icons.add, color: isDark ? Colors.black : Colors.white),
        label: Text("Ajouter", style: TextStyle(color: isDark ? Colors.black : Colors.white)),
      ),
    );
  }
}