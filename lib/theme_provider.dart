import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThemeProvider extends ChangeNotifier {
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;

  ThemeData get currentTheme => _isDarkMode ? _darkTheme : _lightTheme;

  // ── Light Theme ──────────────────────────────────────────
  static final _lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: const Color(0xFF1A6BFF),
    scaffoldBackgroundColor: const Color(0xFFF0F4F8),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 1,
    ),
    cardColor: Colors.white,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF1A6BFF),
      secondary: Color(0xFF00C896),
    ),
  );

  // ── Dark Theme ───────────────────────────────────────────
  static final _darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFF1A6BFF),
    scaffoldBackgroundColor: const Color(0xFF0A0E1A),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF0D1F3C),
      foregroundColor: Colors.white,
      elevation: 1,
    ),
    cardColor: const Color(0xFF0D1F3C),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFF1A6BFF),
      secondary: Color(0xFF00C896),
      surface: Color(0xFF0D1F3C),
    ),
  );

  // ── Load dark mode preference from Firestore ─────────────
  Future<void> loadTheme() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists && doc.data()!.containsKey('darkMode')) {
        _isDarkMode = doc.data()!['darkMode'] as bool;
        notifyListeners();
      }
    } catch (_) {}
  }

  // ── Toggle and save to Firestore ─────────────────────────
  Future<void> toggleTheme() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({'darkMode': _isDarkMode});
    } catch (_) {}
  }
}