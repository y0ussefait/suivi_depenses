import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../main.dart'; // Pour aller au MainScreen

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _pages = [
    {
      "title": "Gérez votre Argent",
      "desc": "Suivez vos dépenses et revenus simplement. Gardez le contrôle sur votre budget mensuel.",
      "icon": "money",
    },
    {
      "title": "Suivez vos Dettes",
      "desc": "N'oubliez plus jamais qui vous doit de l'argent ou à qui vous devez rembourser.",
      "icon": "handshake",
    },
    {
      "title": "Épargnez & Prévoyez",
      "desc": "Créez des cagnottes pour vos rêves et suivez vos abonnements Netflix, Spotify, etc.",
      "icon": "savings",
    },
  ];

  void _finishOnboarding() {
    Hive.box('settings').put('hasSeenOnboarding', true);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          index == 0 ? Icons.account_balance_wallet 
                          : index == 1 ? Icons.handshake 
                          : Icons.rocket_launch,
                          size: 150,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 40),
                        Text(
                          _pages[index]['title']!,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          _pages[index]['desc']!,
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _pages.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  height: 10,
                  width: _currentPage == index ? 20 : 10,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? Colors.green : Colors.grey[300],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage == _pages.length - 1) {
                      _finishOnboarding();
                    } else {
                      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.ease);
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: const StadiumBorder()),
                  child: Text(
                    _currentPage == _pages.length - 1 ? "C'est parti !" : "Suivant",
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}