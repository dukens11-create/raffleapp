import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:raffle_app/models/statistics.dart';

class CategoryPieChart extends StatelessWidget {
  final List<CategoryStat> categoryStats;
  final double size;

  const CategoryPieChart({
    Key? key,
    required this.categoryStats,
    this.size = 200,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (categoryStats.isEmpty) {
      return Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.grey[600]),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: size,
          child: PieChart(
            PieChartData(
              sections: _createSections(),
              centerSpaceRadius: 40,
              sectionsSpace: 2,
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {},
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: categoryStats.map((stat) {
            final color = _getCategoryColor(stat.category);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${stat.category}: ${stat.sold}',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }

  List<PieChartSectionData> _createSections() {
    final total = categoryStats.fold<int>(0, (sum, stat) => sum + stat.sold);
    
    return categoryStats.map((stat) {
      final percentage = total > 0 ? (stat.sold / total * 100) : 0;
      return PieChartSectionData(
        value: stat.sold.toDouble(),
        title: '${percentage.toStringAsFixed(1)}%',
        color: _getCategoryColor(stat.category),
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getCategoryColor(String category) {
    switch (category.toUpperCase()) {
      case 'BAS':
        return Colors.blue;
      case 'PRM':
        return Colors.green;
      case 'BRZ':
        return Colors.orange;
      case 'SLV':
        return Colors.grey;
      case 'GLD':
        return Colors.amber;
      case 'DIA':
        return Colors.purple;
      default:
        return Colors.blueGrey;
    }
  }
}
