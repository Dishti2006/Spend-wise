import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'add_expense.dart';
import 'database_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> expenses = [];

  @override
  void initState() {
    super.initState();
    loadExpenses();
  }

  Future<void> loadExpenses() async {
    try {
      final data = await DatabaseHelper.instance.getExpenses();
      if (mounted) setState(() => expenses = data);
    } catch (e) {
      if (mounted) setState(() => expenses = []);
    }
  }

  double getTotalExpense() {
    return expenses.fold(
        0, (sum, e) => sum + (double.tryParse(e['amount'].toString()) ?? 0));
  }

  String getExpenseType(Map<String, dynamic> expense) {
    bool necessary = expense['necessary'] == 1 || expense['necessary'] == true;
    bool planned   = expense['planned']   == 1 || expense['planned']   == true;
    bool impulsive = expense['impulsive'] == 1 || expense['impulsive'] == true;
    bool regret    = expense['regret']    == 1 || expense['regret']    == true;

    if ( necessary &&  planned && !impulsive && !regret) return "Smart Spending";
    if ( necessary &&  planned &&  impulsive && !regret) return "Urgent Planned Purchase";
    if ( necessary &&  planned && !impulsive &&  regret) return "Overplanned Regret";
    if ( necessary &&  planned &&  impulsive &&  regret) return "Conflicted Spending";
    if ( necessary && !planned && !impulsive && !regret) return "Basic Need";
    if ( necessary && !planned &&  impulsive && !regret) return "Urgent Need";
    if ( necessary && !planned && !impulsive &&  regret) return "Necessary but Regretted";
    if ( necessary && !planned &&  impulsive &&  regret) return "Unplanned Necessary";
    if (!necessary &&  planned && !impulsive && !regret) return "Planned Luxury";
    if (!necessary &&  planned &&  impulsive && !regret) return "Excited Planned Purchase";
    if (!necessary &&  planned && !impulsive &&  regret) return "Planned but Regretted";
    if (!necessary &&  planned &&  impulsive &&  regret) return "Luxury Regret Purchase";
    if (!necessary && !planned && !impulsive && !regret) return "Random Spending";
    if (!necessary && !planned &&  impulsive && !regret) return "Impulse Fun";
    if (!necessary && !planned && !impulsive &&  regret) return "Pointless Spending";
    if (!necessary && !planned &&  impulsive &&  regret) return "Impulse Regret";
    return "Other Expense";
  }

  // ── Edit popup ───────────────────────────────────────────
  void showEditDialog(Map<String, dynamic> expense) {
    final titleController =
        TextEditingController(text: expense['title']?.toString() ?? "");
    final amountController =
        TextEditingController(text: expense['amount']?.toString() ?? "");

    bool necessary = expense['necessary'] == 1 || expense['necessary'] == true;
    bool planned   = expense['planned']   == 1 || expense['planned']   == true;
    bool impulsive = expense['impulsive'] == 1 || expense['impulsive'] == true;
    bool regret    = expense['regret']    == 1 || expense['regret']    == true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text("Edit Expense",
                  style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: "Expense Name",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.title),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      decoration: const InputDecoration(
                        labelText: "Amount (₹)",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      dense: true,
                      title: const Text("Necessary"),
                      value: necessary,
                      onChanged: (v) => setDialogState(() => necessary = v),
                    ),
                    SwitchListTile(
                      dense: true,
                      title: const Text("Planned"),
                      value: planned,
                      onChanged: (v) => setDialogState(() => planned = v),
                    ),
                    SwitchListTile(
                      dense: true,
                      title: const Text("Impulsive"),
                      value: impulsive,
                      onChanged: (v) => setDialogState(() => impulsive = v),
                    ),
                    SwitchListTile(
                      dense: true,
                      title: const Text("Regret"),
                      value: regret,
                      onChanged: (v) => setDialogState(() => regret = v),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A6BFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () async {
                    if (titleController.text.trim().isEmpty ||
                        amountController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Fill all fields")));
                      return;
                    }
                    await DatabaseHelper.instance.updateExpense(
                      expense['id'].toString(),
                      {
                        'title': titleController.text.trim(),
                        'amount': double.tryParse(amountController.text.trim()) ?? 0,
                        'necessary': necessary ? 1 : 0,
                        'planned': planned ? 1 : 0,
                        'impulsive': impulsive ? 1 : 0,
                        'regret': regret ? 1 : 0,
                      },
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      await loadExpenses();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("✅ Expense updated!")));
                    }
                  },
                  child: const Text("Save", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Delete confirmation ───────────────────────────────────
  void showDeleteDialog(Map<String, dynamic> expense) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Delete Expense",
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
            "Are you sure you want to delete \"${expense['title']}\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              await DatabaseHelper.instance.deleteExpense(expense['id']);
              if (mounted) {
                Navigator.pop(context);
                await loadExpenses();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("🗑️ Expense deleted!")));
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SpendSense Dashboard"), centerTitle: true),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(15),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.purple, borderRadius: BorderRadius.circular(15)),
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet, color: Colors.white, size: 40),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Total Expenses",
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                    Text("₹${getTotalExpense().toStringAsFixed(2)}",
                        style: const TextStyle(
                            color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: expenses.isEmpty
                ? const Center(child: Text("No Expenses Added Yet", style: TextStyle(fontSize: 18)))
                : ListView.builder(
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const Icon(Icons.account_balance_wallet, color: Colors.purple),
                          title: Text(expense['title']?.toString() ?? "No Title",
                              style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(getExpenseType(expense)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                "₹${expense['amount']?.toString() ?? '0'}",
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                              ),
                              const SizedBox(width: 6),
                              // ✅ Edit button
                              GestureDetector(
                                onTap: () => showEditDialog(expense),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A6BFF).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.edit, size: 18, color: Color(0xFF1A6BFF)),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // ✅ Delete button
                              GestureDetector(
                                onTap: () => showDeleteDialog(expense),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(Icons.delete, size: 18, color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          final result = await Navigator.push(
              context, MaterialPageRoute(builder: (_) => const AddExpensePage()));
          if (result == true) await loadExpenses();
        },
      ),
    );
  }
}