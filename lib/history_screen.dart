import 'package:flutter/material.dart';
import 'database_helper.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> expenses = [];
  List<Map<String, dynamic>> filteredExpenses = [];
  String selectedFilter = "All";
  final List<String> filters = ["All","Today","Weekly","Monthly","Yearly"];

  @override
  void initState() { super.initState(); loadExpenses(); }

  @override
  void didChangeDependencies() { super.didChangeDependencies(); loadExpenses(); }

  Future<void> loadExpenses() async {
    final data = await DatabaseHelper.instance.getExpenses();
    setState(() { expenses=data; applyFilter(selectedFilter); });
  }

  void applyFilter(String filter) {
    final now = DateTime.now();
    setState(() {
      selectedFilter = filter;
      if (filter=="All") {
        filteredExpenses = expenses;
      } else if (filter=="Today") {
        filteredExpenses = expenses.where((e) {
          DateTime? d = DateTime.tryParse(e['date']?.toString()??"");
          return d!=null&&d.day==now.day&&d.month==now.month&&d.year==now.year;
        }).toList();
      } else if (filter=="Weekly") {
        filteredExpenses = expenses.where((e) {
          DateTime? d = DateTime.tryParse(e['date']?.toString()??"");
          return d!=null&&now.difference(d).inDays<=7;
        }).toList();
      } else if (filter=="Monthly") {
        filteredExpenses = expenses.where((e) {
          DateTime? d = DateTime.tryParse(e['date']?.toString()??"");
          return d!=null&&d.month==now.month&&d.year==now.year;
        }).toList();
      } else if (filter=="Yearly") {
        filteredExpenses = expenses.where((e) {
          DateTime? d = DateTime.tryParse(e['date']?.toString()??"");
          return d!=null&&d.year==now.year;
        }).toList();
      }
    });
  }

  double get filteredTotal => filteredExpenses.fold(
      0,(sum,e)=>sum+(double.tryParse(e['amount'].toString())??0));

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? Colors.grey.shade900 : const Color(0xFFF0F4F8);
    final cardColor = isDark ? Colors.grey.shade800 : Colors.white;
    final barColor  = isDark ? Colors.grey.shade900 : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor  = isDark ? Colors.grey.shade400 : Colors.grey.shade500;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Expense History"),
        backgroundColor: isDark?Colors.grey.shade900:Colors.white,
        foregroundColor: isDark?Colors.white:Colors.black,
        elevation: 1,
      ),
      body: Column(children:[

        // Filter buttons
        Container(
          color: barColor,
          padding: const EdgeInsets.symmetric(vertical:12,horizontal:8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((f) {
                final bool isSelected = selectedFilter==f;
                return GestureDetector(
                  onTap: ()=>applyFilter(f),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds:200),
                    margin: const EdgeInsets.symmetric(horizontal:5),
                    padding: const EdgeInsets.symmetric(horizontal:20,vertical:10),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF1A6BFF)
                          : (isDark?Colors.grey.shade700:Colors.grey.shade100),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF1A6BFF)
                            : (isDark?Colors.grey.shade600:Colors.grey.shade300),
                      ),
                      boxShadow: isSelected?[BoxShadow(
                          color:const Color(0xFF1A6BFF).withOpacity(0.3),
                          blurRadius:8,offset:const Offset(0,3))]:[]
                    ),
                    child: Text(f, style:TextStyle(
                      color: isSelected?Colors.white:(isDark?Colors.white70:Colors.grey.shade700),
                      fontWeight: isSelected?FontWeight.bold:FontWeight.normal,
                      fontSize: 14,
                    )),
                  ),
                );
              }).toList(),
            ),
          ),
        ),

        // Summary card
        Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(horizontal:20,vertical:14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors:[Color(0xFF1A6BFF),Color(0xFF00C896)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children:[
              Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                Text("$selectedFilter Expenses",
                    style:const TextStyle(color:Colors.white70,fontSize:13)),
                Text("${filteredExpenses.length} transactions",
                    style:const TextStyle(color:Colors.white,fontSize:16,fontWeight:FontWeight.bold)),
              ]),
              Column(crossAxisAlignment:CrossAxisAlignment.end,children:[
                const Text("Total",style:TextStyle(color:Colors.white70,fontSize:13)),
                Text("₹${filteredTotal.toStringAsFixed(2)}",
                    style:const TextStyle(color:Colors.white,fontSize:18,fontWeight:FontWeight.bold)),
              ]),
            ],
          ),
        ),

        // List
        Expanded(
          child: filteredExpenses.isEmpty
              ? Center(child:Column(
                  mainAxisAlignment:MainAxisAlignment.center,children:[
                    Icon(Icons.receipt_long,size:60,color:isDark?Colors.grey.shade600:Colors.grey.shade300),
                    const SizedBox(height:12),
                    Text("No expenses for $selectedFilter",
                        style:TextStyle(fontSize:16,color:subColor)),
                  ]))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal:12),
                  itemCount: filteredExpenses.length,
                  itemBuilder: (context,index) {
                    final expense = filteredExpenses[index];
                    final double amount = double.tryParse(expense['amount']?.toString()??"0")??0;
                    DateTime? date = DateTime.tryParse(expense['date']?.toString()??"");
                    String dateStr = date!=null
                        ?"${date.day}/${date.month}/${date.year}  ${date.hour}:${date.minute.toString().padLeft(2,'0')}"
                        :"";

                    return Dismissible(
                      key: Key(expense['id'].toString()),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right:20),
                        margin: const EdgeInsets.symmetric(vertical:5),
                        decoration: BoxDecoration(
                            color:Colors.red,borderRadius:BorderRadius.circular(12)),
                        child: const Icon(Icons.delete,color:Colors.white),
                      ),
                      confirmDismiss: (_) async {
                        return await showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            backgroundColor: isDark?Colors.grey.shade800:Colors.white,
                            title: Text("Delete Expense",
                                style:TextStyle(color:textColor)),
                            content: Text("Are you sure?",
                                style:TextStyle(color:textColor)),
                            actions:[
                              TextButton(onPressed:()=>Navigator.pop(context,false),
                                  child:const Text("Cancel")),
                              TextButton(onPressed:()=>Navigator.pop(context,true),
                                  child:const Text("Delete",style:TextStyle(color:Colors.red))),
                            ],
                          ),
                        );
                      },
                      onDismissed: (_) async {
                        await DatabaseHelper.instance.deleteExpense(expense['id']);
                        loadExpenses();
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical:5),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow:[BoxShadow(
                              color:Colors.black.withOpacity(isDark?0.3:0.05),
                              blurRadius:6,offset:const Offset(0,2))],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal:16,vertical:8),
                          leading: CircleAvatar(
                            backgroundColor: const Color(0xFF1A6BFF).withOpacity(0.1),
                            child: const Icon(Icons.account_balance_wallet,
                                color:Color(0xFF1A6BFF),size:20),
                          ),
                          title: Text(expense['title']?.toString()??"No Title",
                              style:TextStyle(fontWeight:FontWeight.bold,
                                  fontSize:15,color:textColor)),
                          subtitle: Text(dateStr,
                              style:TextStyle(color:subColor,fontSize:12)),
                          trailing: Text("₹${amount.toStringAsFixed(2)}",
                              style:const TextStyle(fontSize:16,
                                  fontWeight:FontWeight.bold,color:Color(0xFF00C896))),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ]),
    );
  }
}