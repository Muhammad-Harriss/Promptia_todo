import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:supabase_todo/model/prompt_model.dart';

class AnalyticsDashboard extends StatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  State<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends State<AnalyticsDashboard> {
  final supabase = Supabase.instance.client;

  List<Prompt> prompts = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPrompts();
    _listenForPromptChanges();
  }

  Future<void> _fetchPrompts() async {
    final response = await supabase.from("prompts").select();
    setState(() {
      prompts = (response as List).map((e) => Prompt.fromJson(e)).toList();
      isLoading = false;
    });
  }

  void _listenForPromptChanges() {
    supabase
        .channel("prompts-changes")
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: "public",
          table: "prompts",
          callback: (payload) {
            _fetchPrompts(); // 🔄 Refresh data whenever a row is inserted/updated/deleted
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final int completed = prompts.where((p) => p.status == "completed").length;
    final int pending = prompts.where((p) => p.status == "pending").length;
    final int total = completed + pending;

    final double completionRate = total > 0 ? (completed / total) * 100 : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Analytics Dashboard"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text(
              "Prompt Status Overview",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            // ✅ Summary Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard("Completed", completed, Colors.green),
                _buildStatCard("Pending", pending, Colors.orange),
                _buildStatCard("Total", total, Colors.blue),
              ],
            ),
            const SizedBox(height: 20),

            // ✅ Circular Progress
            SizedBox(
              height: 120,
              width: 120,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CircularProgressIndicator(
                    value: total > 0 ? completed / total : 0,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation(Colors.green),
                  ),
                  Center(
                    child: Text(
                      "${completionRate.toStringAsFixed(1)}%",
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // ✅ Pie Chart
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: [
                    PieChartSectionData(
                      color: Colors.green,
                      value: completed.toDouble(),
                      title: "$completed\nDone",
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    PieChartSectionData(
                      color: Colors.orange,
                      value: pending.toDouble(),
                      title: "$pending\nPending",
                      radius: 60,
                      titleStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                  sectionsSpace: 4,
                  centerSpaceRadius: 40,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ✅ Bar Chart
            Expanded(
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (completed > pending ? completed : pending).toDouble() + 2,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return const Text("Completed");
                            case 1:
                              return const Text("Pending");
                          }
                          return const Text("");
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: completed.toDouble(),
                          color: Colors.green,
                          width: 40,
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: pending.toDouble(),
                          color: Colors.orange,
                          width: 40,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          children: [
            Text(
              "$count",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
