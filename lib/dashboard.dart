import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'history_screen.dart';
import 'insights_screen.dart';
import 'smart_analyse.dart';
import 'settings_screen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  int currentIndex = 0;
  final List<Widget> pages = [
    HomeScreen(),
    SmartAnalysisScreen(),
    InsightsScreen(),
    HistoryScreen(),
    SettingsScreen(), // ✅ NEW
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F0F7),
      body: pages[currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 182, 182, 235).withOpacity(0.2),
              blurRadius: 10,
            )
          ],
        ),
        child: BottomNavigationBar(
          backgroundColor: const Color.fromARGB(255, 215, 223, 223),
          currentIndex: currentIndex,
          selectedItemColor: const Color(0xFF2AA6A6),
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          onTap: (index) => setState(() => currentIndex = index),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
            BottomNavigationBarItem(icon: Icon(Icons.psychology), label: "Smart Analyse"),
            BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Insights"),
            BottomNavigationBarItem(icon: Icon(Icons.history), label: "History"),
            BottomNavigationBarItem(icon: Icon(Icons.settings), label: "Settings"), // ✅ NEW
          ],
        ),
      ),
    );
  }
}