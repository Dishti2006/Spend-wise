import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'database_helper.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});
  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  List<Map<String, dynamic>> expenses = [];
  double monthlyBudget = 0;
  final budgetController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadData();
  }

  Future<void> loadData() async {
    final data = await DatabaseHelper.instance.getExpenses();
    setState(() => expenses = data);
  }

  double get totalSpent => expenses.fold(0,(s,e)=>s+(double.tryParse(e['amount'].toString())??0));
  double get avgSpent => expenses.isEmpty?0:totalSpent/expenses.length;
  int get impulsiveCount => expenses.where((e)=>e['impulsive']==1||e['impulsive']==true).length;
  int get regretCount => expenses.where((e)=>e['regret']==1||e['regret']==true).length;
  int get smartCount => expenses.where((e)=>
    (e['necessary']==1||e['necessary']==true)&&
    (e['planned']  ==1||e['planned']  ==true)&&
     e['impulsive']!=1&&e['impulsive']!=true&&
     e['regret']   !=1&&e['regret']   !=true).length;

  Map<String,dynamic>? get biggestExpense {
    if (expenses.isEmpty) return null;
    return expenses.reduce((a,b)=>
        (double.tryParse(a['amount'].toString())??0)>
        (double.tryParse(b['amount'].toString())??0)?a:b);
  }

  String get busiestDay {
    Map<int,double> dayTotals={};
    for (var e in expenses) {
      DateTime? d = DateTime.tryParse(e['date']?.toString()??"");
      if (d==null) continue;
      dayTotals[d.weekday]=(dayTotals[d.weekday]??0)+(double.tryParse(e['amount'].toString())??0);
    }
    if (dayTotals.isEmpty) return "N/A";
    final top = dayTotals.entries.reduce((a,b)=>a.value>b.value?a:b);
    const days=["","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"];
    return days[top.key];
  }

  double _monthTotal(int monthsAgo) {
    final now = DateTime.now();
    final target = DateTime(now.year,now.month-monthsAgo);
    return expenses.where((e) {
      DateTime? d = DateTime.tryParse(e['date']?.toString()??"");
      return d!=null&&d.month==target.month&&d.year==target.year;
    }).fold(0,(s,e)=>s+(double.tryParse(e['amount'].toString())??0));
  }

  double get thisMonthSpent => _monthTotal(0);
  double get lastMonthSpent => _monthTotal(1);

  List<PieChartSectionData> buildPie(bool isDark) {
    int necessary = expenses.where((e)=>e['necessary']==1||e['necessary']==true).length;
    int unnecessary = expenses.length-necessary;
    if (expenses.isEmpty) return [];
    return [
      PieChartSectionData(
        value:necessary.toDouble(),
        title:'Needs\n$necessary',
        color:Colors.green,
        radius:70,
        titleStyle:const TextStyle(fontSize:12,color:Colors.white,fontWeight:FontWeight.bold),
      ),
      PieChartSectionData(
        value:unnecessary.toDouble(),
        title:'Wants\n$unnecessary',
        color:Colors.orange,
        radius:70,
        titleStyle:const TextStyle(fontSize:12,color:Colors.white,fontWeight:FontWeight.bold),
      ),
    ];
  }

  List<BarChartGroupData> buildMonthBars() {
    return [
      BarChartGroupData(x:0,barRods:[BarChartRodData(
          toY:lastMonthSpent,color:Colors.blue.shade300,
          width:30,borderRadius:BorderRadius.circular(6))]),
      BarChartGroupData(x:1,barRods:[BarChartRodData(
          toY:thisMonthSpent,color:Colors.purple,
          width:30,borderRadius:BorderRadius.circular(6))]),
    ];
  }

  void showBudgetDialog(bool isDark) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: isDark?Colors.grey.shade800:Colors.white,
        title: Text("Set Monthly Budget",
            style:TextStyle(color:isDark?Colors.white:Colors.black)),
        content: TextField(
          controller: budgetController,
          keyboardType: TextInputType.number,
          style: TextStyle(color:isDark?Colors.white:Colors.black),
          decoration: InputDecoration(
            labelText: "Budget Amount (₹)",
            labelStyle: TextStyle(color:isDark?Colors.grey.shade400:Colors.grey),
            border: const OutlineInputBorder(),
            // ✅ FIXED: was enabledBorderColor (invalid)
            enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(
                color: isDark?Colors.grey.shade600:Colors.grey,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: ()=>Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(()=>monthlyBudget=double.tryParse(budgetController.text)??0);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor   = isDark ? Colors.grey.shade900 : const Color(0xFFF0F4F8);
    final cardColor = isDark ? Colors.grey.shade800 : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subColor  = isDark ? Colors.grey.shade400 : Colors.grey;

    final double budgetUsed = monthlyBudget>0?(thisMonthSpent/monthlyBudget).clamp(0.0,1.0):0;
    final bool overBudget   = monthlyBudget>0&&thisMonthSpent>monthlyBudget;
    final double momChange  = lastMonthSpent>0?((thisMonthSpent-lastMonthSpent)/lastMonthSpent)*100:0;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Insights"),
        backgroundColor: isDark?Colors.grey.shade900:Colors.white,
        foregroundColor: isDark?Colors.white:Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: ()=>showBudgetDialog(isDark),
            tooltip: "Set Budget",
          ),
        ],
      ),
      body: expenses.isEmpty
          ? Center(child:Text("No data yet. Add expenses first.",
              style:TextStyle(fontSize:18,color:isDark?Colors.white70:Colors.black54)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Summary Cards ─────────────────────────
                  Row(children:[
                    _statCard("Total Spent","₹${totalSpent.toStringAsFixed(0)}",Colors.purple,isDark),
                    const SizedBox(width:10),
                    _statCard("Avg / Expense","₹${avgSpent.toStringAsFixed(0)}",Colors.blue,isDark),
                  ]),
                  const SizedBox(height:10),
                  Row(children:[
                    _statCard("Impulse","$impulsiveCount",Colors.red,isDark),
                    const SizedBox(width:10),
                    _statCard("Regretted","$regretCount",Colors.orange,isDark),
                    const SizedBox(width:10),
                    _statCard("Smart","$smartCount",Colors.green,isDark),
                  ]),

                  const SizedBox(height:20),

                  // ── Monthly Budget ────────────────────────
                  _sectionTitle("🎯 Monthly Budget",textColor),
                  monthlyBudget==0
                      ? _infoTile("Tap ⚙️ icon to set your monthly budget.",
                          isDark?Colors.blue.shade900:Colors.blue.shade50,textColor)
                      : Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                          Row(mainAxisAlignment:MainAxisAlignment.spaceBetween,children:[
                            Text("₹${thisMonthSpent.toStringAsFixed(0)} / ₹${monthlyBudget.toStringAsFixed(0)}",
                                style:TextStyle(fontWeight:FontWeight.bold,
                                    color:overBudget?Colors.red:Colors.green)),
                            Text("${(budgetUsed*100).toStringAsFixed(0)}% used",
                                style:TextStyle(color:overBudget?Colors.red:subColor)),
                          ]),
                          const SizedBox(height:8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: budgetUsed,
                              minHeight: 16,
                              backgroundColor: isDark?Colors.grey.shade700:Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation(overBudget?Colors.red:Colors.green),
                            ),
                          ),
                          if (overBudget)
                            Padding(
                              padding: const EdgeInsets.only(top:8),
                              child: Text(
                                "⚠️ Over budget by ₹${(thisMonthSpent-monthlyBudget).toStringAsFixed(0)}!",
                                style: const TextStyle(color:Colors.red,fontWeight:FontWeight.bold),
                              ),
                            ),
                        ]),

                  const SizedBox(height:20),

                  // ── Biggest Expense ───────────────────────
                  _sectionTitle("💸 Biggest Single Expense",textColor),
                  biggestExpense==null
                      ? _infoTile("No expenses yet.",
                          isDark?Colors.grey.shade800:Colors.grey.shade100,textColor)
                      : _infoTile(
                          "${biggestExpense!['title']} — ₹${biggestExpense!['amount']}",
                          isDark?Colors.red.shade900:Colors.red.shade50,textColor),

                  const SizedBox(height:20),

                  // ── Busiest Day ───────────────────────────
                  _sectionTitle("📅 Day You Spend Most",textColor),
                  _infoTile(busiestDay,
                      isDark?Colors.indigo.shade900:Colors.indigo.shade50,textColor),

                  const SizedBox(height:20),

                  // ── Month Comparison ──────────────────────
                  _sectionTitle("📊 Month-over-Month",textColor),
                  Row(children:[
                    _statCard("Last Month","₹${lastMonthSpent.toStringAsFixed(0)}",Colors.blue,isDark),
                    const SizedBox(width:10),
                    _statCard("This Month","₹${thisMonthSpent.toStringAsFixed(0)}",
                        thisMonthSpent>lastMonthSpent?Colors.red:Colors.green,isDark),
                  ]),
                  const SizedBox(height:12),
                  if (lastMonthSpent>0)
                    _infoTile(
                      momChange>0
                          ?"📈 Spent ${momChange.toStringAsFixed(1)}% MORE than last month."
                          :"📉 Spent ${momChange.abs().toStringAsFixed(1)}% LESS. Great job!",
                      momChange>0
                          ?(isDark?Colors.red.shade900:Colors.red.shade50)
                          :(isDark?Colors.green.shade900:Colors.green.shade50),
                      textColor,
                    ),
                  const SizedBox(height:12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow:[BoxShadow(
                          color:Colors.black.withOpacity(isDark?0.3:0.08),blurRadius:8)],
                    ),
                    child: SizedBox(
                      height: 200,
                      child: BarChart(BarChartData(
                        barGroups: buildMonthBars(),
                        borderData: FlBorderData(show:false),
                        gridData: FlGridData(
                          show: true,
                          getDrawingHorizontalLine: (_)=>FlLine(
                              color:isDark?Colors.white12:Colors.grey.shade200),
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(sideTitles:SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v,_)=>Text(
                              v==0?"Last\nMonth":"This\nMonth",
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize:11,
                                  color:isDark?Colors.white70:Colors.black54),
                            ),
                          )),
                          leftTitles:  AxisTitles(sideTitles:SideTitles(showTitles:false)),
                          topTitles:   AxisTitles(sideTitles:SideTitles(showTitles:false)),
                          rightTitles: AxisTitles(sideTitles:SideTitles(showTitles:false)),
                        ),
                      )),
                    ),
                  ),

                  const SizedBox(height:20),

                  // ── Needs vs Wants Pie ────────────────────
                  _sectionTitle("🥧 Needs vs Wants",textColor),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow:[BoxShadow(
                          color:Colors.black.withOpacity(isDark?0.3:0.08),blurRadius:8)],
                    ),
                    child: SizedBox(
                      height: 220,
                      child: PieChart(PieChartData(
                          sections:buildPie(isDark),centerSpaceRadius:40)),
                    ),
                  ),

                  const SizedBox(height:20),

                  // ── Suggestions ───────────────────────────
                  _sectionTitle("💡 Suggestions",textColor),
                  if (impulsiveCount>expenses.length*0.4)
                    _suggestionCard("⚠️ Over 40% impulse buys. Try the 24-hour rule.",
                        isDark?Colors.red.shade900:Colors.red.shade50,textColor),
                  if (regretCount>2)
                    _suggestionCard("😔 You regret $regretCount purchases. Ask yourself before buying.",
                        isDark?Colors.orange.shade900:Colors.orange.shade50,textColor),
                  if (smartCount==expenses.length&&expenses.isNotEmpty)
                    _suggestionCard("🎉 All Smart Spends! You're nailing it.",
                        isDark?Colors.green.shade900:Colors.green.shade50,textColor),
                  if (avgSpent>1000)
                    _suggestionCard("💸 Avg spend ₹${avgSpent.toStringAsFixed(0)}. Consider a per-purchase cap.",
                        isDark?Colors.blue.shade900:Colors.blue.shade50,textColor),
                  if (busiestDay!="N/A")
                    _suggestionCard("📅 You spend most on ${busiestDay}s. Plan ahead.",
                        isDark?Colors.purple.shade900:Colors.purple.shade50,textColor),
                  if (momChange>20)
                    _suggestionCard("📈 Spending up ${momChange.toStringAsFixed(0)}% vs last month.",
                        isDark?Colors.red.shade900:Colors.red.shade50,textColor),

                  const SizedBox(height:30),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title, Color color) => Padding(
    padding: const EdgeInsets.only(bottom:10),
    child: Text(title,
        style:TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:color)),
  );

  Widget _infoTile(String text, Color bg, Color textColor) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color:bg,borderRadius:BorderRadius.circular(12)),
    child: Text(text,style:TextStyle(fontSize:15,color:textColor)),
  );

  Widget _statCard(String label, String value, Color color, bool isDark) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark?color.withOpacity(0.2):color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color:color.withOpacity(0.3)),
      ),
      child: Column(children:[
        Text(value,
            style:TextStyle(fontSize:18,fontWeight:FontWeight.bold,color:color)),
        const SizedBox(height:4),
        Text(label,
            textAlign:TextAlign.center,
            style:TextStyle(fontSize:11,
                color:isDark?Colors.grey.shade400:Colors.grey)),
      ]),
    ),
  );

  Widget _suggestionCard(String text, Color bg, Color textColor) => Container(
    margin: const EdgeInsets.only(bottom:10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color:bg,borderRadius:BorderRadius.circular(12)),
    child: Text(text,style:TextStyle(fontSize:14,color:textColor)),
  );
}