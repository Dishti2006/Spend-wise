import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'database_helper.dart';

class SmartAnalysisScreen extends StatefulWidget {
  const SmartAnalysisScreen({super.key});
  @override
  State<SmartAnalysisScreen> createState() => _SmartAnalysisScreenState();
}

class _SmartAnalysisScreenState extends State<SmartAnalysisScreen> {
  List<Map<String, dynamic>> allExpenses = [];
  int necessaryYes = 0, necessaryNo = 0;
  int plannedYes = 0, plannedNo = 0;
  int impulsiveYes = 0, impulsiveNo = 0;
  int regretYes = 0, regretNo = 0;
  Map<String, int> expenseData = {};

  final List<Color> pieColors = [
    Colors.green, Colors.red, Colors.blue, Colors.orange, Colors.purple,
    Colors.teal, Colors.pink, Colors.amber, Colors.cyan, Colors.indigo,
    Colors.lime, Colors.brown, Colors.deepOrange, Colors.lightBlue,
    Colors.deepPurple, Colors.grey,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    loadData();
  }

  Future<void> loadData() async {
    final expenses = await DatabaseHelper.instance.getExpenses();
    int nY=0,nN=0,pY=0,pN=0,iY=0,iN=0,rY=0,rN=0;
    Map<String,int> counts = {};
    for (var e in expenses) {
      bool necessary = e['necessary']==1||e['necessary']==true;
      bool planned   = e['planned']  ==1||e['planned']  ==true;
      bool impulsive = e['impulsive']==1||e['impulsive']==true;
      bool regret    = e['regret']   ==1||e['regret']   ==true;
      necessary?nY++:nN++; planned?pY++:pN++;
      impulsive?iY++:iN++; regret?rY++:rN++;
      String type = getExpenseType(e);
      counts[type] = (counts[type]??0)+1;
    }
    setState(() {
      necessaryYes=nY; necessaryNo=nN;
      plannedYes=pY;   plannedNo=pN;
      impulsiveYes=iY; impulsiveNo=iN;
      regretYes=rY;    regretNo=rN;
      expenseData=counts;
      allExpenses=expenses;
    });
  }

  String getExpenseType(Map<String,dynamic> expense) {
    bool necessary = expense['necessary']==1||expense['necessary']==true;
    bool planned   = expense['planned']  ==1||expense['planned']  ==true;
    bool impulsive = expense['impulsive']==1||expense['impulsive']==true;
    bool regret    = expense['regret']   ==1||expense['regret']   ==true;
    if ( necessary&& planned&&!impulsive&&!regret) return "Smart Spending";
    if ( necessary&& planned&& impulsive&&!regret) return "Urgent Planned";
    if ( necessary&& planned&&!impulsive&& regret) return "Overplanned Regret";
    if ( necessary&& planned&& impulsive&& regret) return "Conflicted Spending";
    if ( necessary&&!planned&&!impulsive&&!regret) return "Basic Need";
    if ( necessary&&!planned&& impulsive&&!regret) return "Urgent Need";
    if ( necessary&&!planned&&!impulsive&& regret) return "Necessary Regret";
    if ( necessary&&!planned&& impulsive&& regret) return "Unplanned Necessary";
    if (!necessary&& planned&&!impulsive&&!regret) return "Planned Luxury";
    if (!necessary&& planned&& impulsive&&!regret) return "Excited Purchase";
    if (!necessary&& planned&&!impulsive&& regret) return "Planned Regret";
    if (!necessary&& planned&& impulsive&& regret) return "Luxury Regret";
    if (!necessary&&!planned&&!impulsive&&!regret) return "Random Spending";
    if (!necessary&&!planned&& impulsive&&!regret) return "Impulse Fun";
    if (!necessary&&!planned&&!impulsive&& regret) return "Pointless Spending";
    if (!necessary&&!planned&& impulsive&& regret) return "Impulse Regret";
    return "Other";
  }

  List<PieChartSectionData> buildYesNoPie(int yes, int no, Color yesColor) {
    int total = yes+no;
    if (total==0) return [];
    return [
      PieChartSectionData(
        value: yes.toDouble(),
        title: '${((yes/total)*100).toStringAsFixed(0)}%',
        color: yesColor,
        radius: 42, // ✅ reduced from 55
        titleStyle: const TextStyle(fontSize:14, color:Colors.white, fontWeight:FontWeight.bold), // ✅ font increased
      ),
      PieChartSectionData(
        value: no.toDouble(),
        title: '${((no/total)*100).toStringAsFixed(0)}%',
        color: Colors.grey,
        radius: 42, // ✅ reduced from 55
        titleStyle: const TextStyle(fontSize:14, color:Colors.white, fontWeight:FontWeight.bold), // ✅ font increased
      ),
    ];
  }

  List<BarChartGroupData> buildBars() {
    int index = 0;
    return expenseData.entries.map((entry) {
      Color color = pieColors[index%pieColors.length];
      return BarChartGroupData(x: index++, barRods: [
        BarChartRodData(
          toY: entry.value.toDouble(),
          color: color,
          width: 18,
          borderRadius: BorderRadius.circular(6),
        ),
      ]);
    }).toList();
  }

  List<PieChartSectionData> buildFullPie() {
    int i = 0;
    return expenseData.entries.map((entry) {
      Color color = pieColors[i%pieColors.length]; i++;
      return PieChartSectionData(
        value: entry.value.toDouble(),
        title: entry.value.toString(),
        color: color,
        radius: 48, // ✅ reduced from 60
        titleStyle: const TextStyle(fontSize:14, color:Colors.white, fontWeight:FontWeight.bold), // ✅ font increased
      );
    }).toList();
  }

  List<Widget> buildSuggestions(bool isDark) {
    List<Widget> suggestions = [];
    int total = allExpenses.length;
    if (total==0) return [];
    double impulsiveRate = impulsiveYes/total;
    double regretRate    = regretYes/total;
    double necessaryRate = necessaryYes/total;
    double plannedRate   = plannedYes/total;
    int smartCount       = expenseData['Smart Spending']??0;
    int impulseRegret    = expenseData['Impulse Regret']??0;
    int randomCount      = expenseData['Random Spending']??0;
    int pointlessCount   = expenseData['Pointless Spending']??0;

    if (smartCount>0&&smartCount==total)
      suggestions.add(_suggCard("🏆 Perfect! All expenses are Smart Spending!", Colors.green, isDark));
    else if (smartCount>total*0.6)
      suggestions.add(_suggCard("🌟 Over 60% Smart Spending! Great decisions.", Colors.green, isDark));
    if (plannedRate>0.7)
      suggestions.add(_suggCard("📋 ${(plannedRate*100).toStringAsFixed(0)}% planned purchases. Excellent budgeting!", Colors.teal, isDark));
    if (necessaryRate>0.8)
      suggestions.add(_suggCard("✅ ${(necessaryRate*100).toStringAsFixed(0)}% on necessities. Spending responsibly.", Colors.blue, isDark));
    if (impulsiveRate>0.5)
      suggestions.add(_suggCard("⚠️ ${(impulsiveRate*100).toStringAsFixed(0)}% impulse buys! Try the 48-hour rule.", Colors.orange, isDark));
    else if (impulsiveRate>0.3)
      suggestions.add(_suggCard("💡 ${(impulsiveRate*100).toStringAsFixed(0)}% impulse buys. Make a list before shopping.", Colors.amber, isDark));
    if (regretRate>0.4)
      suggestions.add(_suggCard("😔 You regret ${(regretRate*100).toStringAsFixed(0)}% of purchases. Ask: will I want this next week?", Colors.red, isDark));
    if (impulseRegret>2)
      suggestions.add(_suggCard("🚨 $impulseRegret purchases were impulsive AND regretted. Pure money drain!", Colors.red, isDark));
    if (randomCount>total*0.2)
      suggestions.add(_suggCard("🎲 $randomCount random purchases. Track spending daily.", Colors.purple, isDark));
    if (pointlessCount>1)
      suggestions.add(_suggCard("🗑️ $pointlessCount pointless purchases. How many work hours is that?", Colors.deepOrange, isDark));
    if (necessaryRate<0.3)
      suggestions.add(_suggCard("💸 Under 30% on necessities. Are wants overtaking needs?", Colors.orange, isDark));
    if (plannedRate<0.3)
      suggestions.add(_suggCard("📝 Only ${(plannedRate*100).toStringAsFixed(0)}% planned. Start a monthly budget list.", Colors.blue, isDark));
    if (total>=10&&regretYes==0&&impulsiveYes==0)
      suggestions.add(_suggCard("🎉 Zero impulse buys and zero regrets across $total expenses!", Colors.green, isDark));
    if (suggestions.isEmpty)
      suggestions.add(_suggCard("📊 Keep adding expenses to get personalised suggestions!", Colors.grey, isDark));
    return suggestions;
  }

  Widget _suggCard(String text, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom:10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? color.withOpacity(0.2) : color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(text,
          style: TextStyle(
            fontSize: 15, // ✅ increased from 14
            color: isDark ? color.withOpacity(0.9) : color.withOpacity(0.85),
          )),
    );
  }

  Widget _questionCard({
    required String question, required int yes, required int no,
    required Color color, required String insight, required bool isDark,
  }) {
    int total = yes+no;
    return Container(
      margin: const EdgeInsets.only(bottom:20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(isDark?0.3:0.08),
            blurRadius:8, offset: const Offset(0,3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: TextStyle(
            fontSize: 17, // ✅ increased from 16
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          )),
          const SizedBox(height:4),
          Text(insight, style: TextStyle(
            fontSize: 13, // ✅ increased from 12
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          )),
          const SizedBox(height:16),
          Row(
            children: [
              SizedBox(
                height: 100, // ✅ reduced from 120
                width: 100,  // ✅ reduced from 120
                child: total==0
                    ? Center(child: Text("No data",
                        style: TextStyle(color: isDark?Colors.grey.shade400:Colors.grey)))
                    : PieChart(PieChartData(
                        sections: buildYesNoPie(yes,no,color),
                        centerSpaceRadius: 20, // ✅ reduced from 25
                        sectionsSpace: 2,
                      )),
              ),
              const SizedBox(width:20),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _legendItem("Yes", yes, total, color, isDark),
                  const SizedBox(height:8),
                  _legendItem("No", no, total, Colors.grey, isDark),
                ],
              )),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(String label, int count, int total, Color color, bool isDark) {
    double pct = total>0?(count/total*100):0;
    return Row(children: [
      Container(width:12, height:12,
          decoration:BoxDecoration(color:color, shape:BoxShape.circle)),
      const SizedBox(width:8),
      Text("$label: $count (${pct.toStringAsFixed(0)}%)",
          style: TextStyle(
            fontSize: 14, // ✅ increased from 13
            color: isDark?Colors.white70:Colors.black87,
          )),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey.shade900 : const Color(0xFFF0F4F8);
    final cardColor = isDark ? Colors.grey.shade800 : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text("Smart Analysis"),
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 1,
      ),
      body: allExpenses.isEmpty
          ? Center(child: Text("No data yet. Add expenses first.",
              style: TextStyle(fontSize:18, color: isDark?Colors.white70:Colors.black54)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Total banner
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom:20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                          colors:[Color(0xFF1A6BFF),Color(0xFF00C896)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(children: [
                      const Text("Total Expenses Analysed",
                          style: TextStyle(color:Colors.white70, fontSize:15)), // ✅ increased
                      Text("${allExpenses.length}",
                          style: const TextStyle(
                              color:Colors.white, fontSize:36, fontWeight:FontWeight.bold)),
                    ]),
                  ),

                  Text("📊 Analysis by Question",
                      style: TextStyle(
                        fontSize: 20, // ✅ increased from 18
                        fontWeight: FontWeight.bold,
                        color: isDark?Colors.white:Colors.black87,
                      )),
                  const SizedBox(height:12),

                  _questionCard(question:"Was it Necessary?", yes:necessaryYes, no:necessaryNo,
                      color:Colors.green, insight:"Needs like food, bills, health", isDark:isDark),
                  _questionCard(question:"Was it Planned?", yes:plannedYes, no:plannedNo,
                      color:Colors.blue, insight:"You budgeted for this in advance", isDark:isDark),
                  _questionCard(question:"Was it Impulsive?", yes:impulsiveYes, no:impulsiveNo,
                      color:Colors.orange, insight:"Decided on the spot without thinking", isDark:isDark),
                  _questionCard(question:"Do you Regret it?", yes:regretYes, no:regretNo,
                      color:Colors.red, insight:"Felt it was a mistake after buying", isDark:isDark),

                  const SizedBox(height:10),

                  Text("🥧 Spending Type Distribution",
                      style: TextStyle(
                        fontSize: 20, // ✅ increased from 18
                        fontWeight: FontWeight.bold,
                        color: isDark?Colors.white:Colors.black87,
                      )),
                  const SizedBox(height:12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(
                          color:Colors.black.withOpacity(isDark?0.3:0.08), blurRadius:8)],
                    ),
                    child: Column(children: [
                      SizedBox(
                        height: 200, // ✅ reduced from 250
                        child: PieChart(PieChartData(
                            sections:buildFullPie(),
                            centerSpaceRadius:25, // ✅ reduced from 30
                            sectionsSpace:2)),
                      ),
                      const SizedBox(height:16),
                      Wrap(
                        spacing:10, runSpacing:6,
                        children: expenseData.entries.toList().asMap().entries.map((e) {
                          Color color = pieColors[e.key%pieColors.length];
                          return Row(mainAxisSize:MainAxisSize.min, children:[
                            Container(width:10, height:10,
                                decoration:BoxDecoration(color:color, shape:BoxShape.circle)),
                            const SizedBox(width:4),
                            Text(e.value.key,
                                style: TextStyle(
                                  fontSize: 12, // ✅ increased from 11
                                  color: isDark?Colors.white70:Colors.black87,
                                )),
                          ]);
                        }).toList(),
                      ),
                    ]),
                  ),

                  const SizedBox(height:20),

                  Text("📈 Expense Count by Type",
                      style: TextStyle(
                        fontSize: 20, // ✅ increased from 18
                        fontWeight: FontWeight.bold,
                        color: isDark?Colors.white:Colors.black87,
                      )),
                  const SizedBox(height:12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(
                          color:Colors.black.withOpacity(isDark?0.3:0.08), blurRadius:8)],
                    ),
                    child: SizedBox(
                      height: 250,
                      child: BarChart(BarChartData(
                        borderData: FlBorderData(show:false),
                        gridData: FlGridData(
                          show: true,
                          getDrawingHorizontalLine: (_) => FlLine(
                              color: isDark?Colors.white12:Colors.grey.shade200),
                        ),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (val,_) {
                              List<String> keys = expenseData.keys.toList();
                              int i = val.toInt();
                              if (i>=keys.length) return const SizedBox();
                              return Padding(
                                padding: const EdgeInsets.only(top:4),
                                child: Text(keys[i].split(" ").first,
                                    style: TextStyle(
                                      fontSize: 10, // ✅ increased from 9
                                      color: isDark?Colors.white70:Colors.black54,
                                    )),
                              );
                            },
                          )),
                          leftTitles:  AxisTitles(sideTitles:SideTitles(showTitles:false)),
                          topTitles:   AxisTitles(sideTitles:SideTitles(showTitles:false)),
                          rightTitles: AxisTitles(sideTitles:SideTitles(showTitles:false)),
                        ),
                        barGroups: buildBars(),
                      )),
                    ),
                  ),

                  const SizedBox(height:20),

                  Text("💡 Smart Suggestions",
                      style: TextStyle(
                        fontSize: 20, // ✅ increased from 18
                        fontWeight: FontWeight.bold,
                        color: isDark?Colors.white:Colors.black87,
                      )),
                  const SizedBox(height:12),
                  ...buildSuggestions(isDark),
                  const SizedBox(height:30),
                ],
              ),
            ),
    );
  }
}