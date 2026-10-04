import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseHelper {
  DatabaseHelper._();

  static final DatabaseHelper instance = DatabaseHelper._();

  CollectionReference<Map<String, dynamic>> get _expenses {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw StateError('You must be signed in to access expenses.');
    }

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('expenses');
  }

  // Retained for the existing add-expense flow, which awaits initialization.
  Future<void> get database async {}

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final snapshot = await _expenses.get();
    return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  Future<String> insertExpense(Map<String, dynamic> expense) async {
    final doc = await _expenses.add(expense);
    return doc.id;
  }

  Future<void> updateExpense(
    String id,
    Map<String, dynamic> expense,
  ) async {
    await _expenses.doc(id).update(expense);
  }

  Future<void> deleteExpense(dynamic id) async {
    await _expenses.doc(id.toString()).delete();
  }
}
