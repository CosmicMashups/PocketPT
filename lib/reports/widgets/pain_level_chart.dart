import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../services/reports_data_service.dart';
import '../../data/globals.dart';

class PainLevelChart extends ConsumerWidget {
  const PainLevelChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final painHistoryAsync = ref.watch(painHistoryProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: painHistoryAsync.when(
        loading: () => _buildLoadingState(context, isDark),
        error: (error, stackTrace) => _buildErrorState(context, isDark, error.toString()),
        data: (painHistory) => _buildChartContent(context, isDark, painHistory),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, isDark),
        const SizedBox(height: 16),
        const Center(
          child: CircularProgressIndicator(),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, bool isDark, String error) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, isDark),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 32),
              const SizedBox(height: 8),
              Text(
                'Failed to load pain data',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                error,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChartContent(BuildContext context, bool isDark, List<PainRecordEntry> painHistory) {
    if (painHistory.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isDark),
          const SizedBox(height: 16),
          _buildEmptyState(context, isDark),
        ],
      );
    }

    // Filter out invalid entries (entries with empty pain level or invalid dates)
    final validEntries = painHistory.where((entry) {
      return entry.painLevel.isNotEmpty && 
             entry.painScale >= 0 && 
             entry.painScale <= 10;
    }).toList();

    if (validEntries.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isDark),
          const SizedBox(height: 16),
          _buildEmptyState(context, isDark),
        ],
      );
    }

    // Group pain records by date and get the latest entry per day
    final Map<String, PainRecordEntry> dailyPain = {};
    for (final entry in validEntries) {
      try {
        final dateKey = DateFormat('yyyy-MM-dd').format(entry.date);
        if (!dailyPain.containsKey(dateKey) || 
            entry.date.isAfter(dailyPain[dateKey]!.date)) {
          dailyPain[dateKey] = entry;
        }
      } catch (e) {
        debugPrint('PainLevelChart: Error processing entry date: $e');
        // Skip invalid entries
        continue;
      }
    }

    if (dailyPain.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isDark),
          const SizedBox(height: 16),
          _buildEmptyState(context, isDark),
        ],
      );
    }

    // Sort by date
    final sortedDates = dailyPain.keys.toList()..sort();
    final sortedEntries = sortedDates.map((dateKey) => dailyPain[dateKey]!).toList();

    // Limit to last 30 days for better visualization
    final recentEntries = sortedEntries.length > 30 
        ? sortedEntries.sublist(sortedEntries.length - 30)
        : sortedEntries;

    // Prepare chart data
    final spots = recentEntries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.painScale.toDouble());
    }).toList();

    // Calculate min and max for better scaling
    final painValues = recentEntries.map((e) => e.painScale).toList();
    final minPain = painValues.isEmpty ? 0 : painValues.reduce((a, b) => a < b ? a : b);
    final maxPain = painValues.isEmpty ? 10 : painValues.reduce((a, b) => a > b ? a : b);
    final chartMin = (minPain > 0 ? minPain - 1 : 0).toDouble();
    final chartMax = (maxPain < 10 ? maxPain + 1 : 10).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, isDark),
        const SizedBox(height: 16),
        SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 2,
                getDrawingHorizontalLine: (value) {
                  return FlLine(
                    color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                    strokeWidth: 1,
                  );
                },
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    interval: recentEntries.length > 7 ? (recentEntries.length / 7).ceil().toDouble() : 1,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < recentEntries.length) {
                        final entry = recentEntries[value.toInt()];
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            DateFormat('MMM d').format(entry.date),
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.grey.shade600,
                              fontSize: 10,
                            ),
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
                    interval: 2,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.grey.shade600,
                          fontSize: 10,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
                ),
              ),
              minX: 0,
              maxX: (recentEntries.length - 1).toDouble(),
              minY: chartMin,
              maxY: chartMax,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: const Color(0xFF8B2E2E),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    color: const Color(0xFF8B2E2E).withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _buildChartLegend(context, isDark, recentEntries),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF8B2E2E).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.show_chart,
            color: Color(0xFF8B2E2E),
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'Daily Pain Level',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF8B2E2E),
          ),
        ),
      ],
    );
  }

  Widget _buildChartLegend(BuildContext context, bool isDark, List<PainRecordEntry> recentEntries) {
    if (recentEntries.isEmpty) return const SizedBox.shrink();

    try {
      final painValues = recentEntries.map((e) => e.painScale).where((v) => v >= 0 && v <= 10).toList();
      if (painValues.isEmpty) return const SizedBox.shrink();
      
      final avgPain = painValues.reduce((a, b) => a + b) / painValues.length;
      final minPain = painValues.reduce((a, b) => a < b ? a : b);
      final maxPain = painValues.reduce((a, b) => a > b ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildLegendItem(
          context,
          isDark,
          'Average',
          avgPain.toStringAsFixed(1),
          Icons.trending_flat,
        ),
        _buildLegendItem(
          context,
          isDark,
          'Min',
          minPain.toString(),
          Icons.arrow_downward,
        ),
        _buildLegendItem(
          context,
          isDark,
          'Max',
          maxPain.toString(),
          Icons.arrow_upward,
        ),
      ],
    );
    } catch (e) {
      debugPrint('PainLevelChart: Error building legend: $e');
      return const SizedBox.shrink();
    }
  }

  Widget _buildLegendItem(
    BuildContext context,
    bool isDark,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 16,
          color: isDark ? Colors.white70 : Colors.grey.shade600,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white70 : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF8B2E2E),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.show_chart_outlined,
            size: 48,
            color: isDark ? Colors.white38 : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No pain data available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pain level data will appear here once you start recording',
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

