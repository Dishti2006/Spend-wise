import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'database_helper.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {

  final titleController = TextEditingController();
  final amountController = TextEditingController();

  bool necessary = false;
  bool planned = false;
  bool impulsive = false;
  bool regret = false;

  Future<void> saveExpense() async {

    try {

      if (titleController.text.trim().isEmpty || amountController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fill all fields")),
        );
        return;
      }

      double amount = double.tryParse(amountController.text.trim()) ?? 0;

      var expense = {
        "title": titleController.text.trim(),
        "amount": amount,
        "necessary": necessary ? 1 : 0,
        "planned": planned ? 1 : 0,
        "impulsive": impulsive ? 1 : 0,
        "regret": regret ? 1 : 0,
        "date": DateTime.now().toString()
      };

      // ✅ FIX 1: ensure DB initialized
      await DatabaseHelper.instance.database;

      // ✅ FIX 2: catch insert result
      String id = await DatabaseHelper.instance.insertExpense(expense);

      print("Inserted ID: $id");

      // ✅ navigate back
      if (mounted) {
        Navigator.pop(context, true);
      }

    } catch (e) {

      print("ERROR: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      appBar: AppBar(
        title: const Text("Add Expense"),
      ),

      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Expense Name"),
              ),

              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: const InputDecoration(labelText: "Amount"),
              ),

              const SizedBox(height: 20),

              SwitchListTile(
                title: const Text("Is that was Necessary?"),
                value: necessary,
                onChanged: (v) => setState(() => necessary = v),
              ),

              SwitchListTile(
                title: const Text("Is that was Planned?"),
                value: planned,
                onChanged: (v) => setState(() => planned = v),
              ),

              SwitchListTile(
                title: const Text("Is that was Impulsive?"),
                value: impulsive,
                onChanged: (v) => setState(() => impulsive = v),
              ),

              SwitchListTile(
                title: const Text("Are you Regretting for Purchase?"),
                value: regret,
                onChanged: (v) => setState(() => regret = v),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  await saveExpense();
                },
                child: const Text("Save Expense"),
              )
            ],
          ),
        ),
      ),
    );
  }
}
