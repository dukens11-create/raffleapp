import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:raffle_app/models/statistics.dart';

class DepartmentBarChart extends StatelessWidget {
  final List<DepartmentStat> departmentStats;
  final double height;

  const DepartmentBarChart({
    Key? key,
    required this.departmentStats,
    this.height = 300,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (departmentStats.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxValue() * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final dept = departmentStats[groupIndex];
                return BarTooltipItem(
                  '${dept.department}\n',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: '${dept.ticketsSold} tickets\n',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    TextSpan(
                      text: '${dept.revenue.toStringAsFixed(2)} HTG',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < departmentStats.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        departmentStats[value.toInt()].department,
                        style: const TextStyle(fontSize: 10),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _getMaxValue() / 5,
          ),
          borderData: FlBorderData(show: false),
          barGroups: _createBarGroups(),
        ),
      ),
    );
  }

  List<BarChartGroupData> _createBarGroups() {
    return List.generate(departmentStats.length, (index) {
      final stat = departmentStats[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: stat.ticketsSold.toDouble(),
            color: _getDepartmentColor(index),
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
          ),
        ],
      );
    });
  }

  double _getMaxValue() {
    return departmentStats
        .map((e) => e.ticketsSold.toDouble())
        .reduce((a, b) => a > b ? a : b);
  }

  Color _getDepartmentColor(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }
}
