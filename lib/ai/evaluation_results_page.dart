import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/exercise_ranking_service.dart';
import '../data/rehabilitation_plan.dart';
import '../data/globals.dart';

/// Page displaying AI exercise ranking evaluation metrics
/// 
/// Shows NDCG@3, Precision@3, Recall@3, and comparison with baselines
class EvaluationResultsPage extends StatefulWidget {
  const EvaluationResultsPage({super.key});

  @override
  State<EvaluationResultsPage> createState() => _EvaluationResultsPageState();
}

class _EvaluationResultsPageState extends State<EvaluationResultsPage> {
  Map<String, dynamic>? _metrics;
  bool _isLoading = true;
  String? _error;

  // Medical color scheme
  static const Color primaryBrand = Color(0xFF8B2E2E);
  static const Color brandAccent = Color(0xFFC24A4A);
  static const Color successGreen = Color(0xFF10B981);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color textSecondary = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();
    _loadEvaluationMetrics();
  }

  Future<void> _loadEvaluationMetrics() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load exercises for testing
      final allExercises = await ExerciseDataService.loadAllExercises();
      
      if (allExercises.isEmpty) {
        setState(() {
          _error = 'No exercises available. Please ensure exercises.csv is loaded.';
          _isLoading = false;
        });
        return;
      }

      // Filter exercises matching user condition or use first 10
      final filteredExercises = allExercises.where((e) {
        return e.muscle.toLowerCase() == UserAssess.specificMuscle.toLowerCase() ||
               e.painLevel.toLowerCase() == UserAssess.painLevel.toLowerCase();
      }).toList();

      final testExercises = filteredExercises.isNotEmpty
          ? filteredExercises.take(10).toList()
          : allExercises.take(10).toList();

      // Compute evaluation metrics
      final metrics = await ExerciseRankingService.getEvaluationMetrics(
        testExercises: testExercises,
        specificMuscle: UserAssess.specificMuscle,
        painLevel: UserAssess.painLevel,
        rehabGoal: UserAssess.rehabGoal,
      );

      setState(() {
        _metrics = metrics;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      debugPrint('Error loading evaluation metrics: $e');
      debugPrint('Stack trace: $stackTrace');
      setState(() {
        _error = 'Failed to load evaluation metrics: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: primaryBrand),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: Text(
          'AI Ranking Evaluation',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: primaryBrand),
            onPressed: _loadEvaluationMetrics,
            tooltip: 'Refresh metrics',
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingState()
            : _error != null
                ? _buildErrorState()
                : _buildMetricsContent(isDark),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryBrand),
          ),
          const SizedBox(height: 16),
          Text(
            'Computing evaluation metrics...',
            style: GoogleFonts.ptSans(
              fontSize: 16,
              color: textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Color(0xFFDC2626),
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Failed to Load Metrics',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1F2937),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _error ?? 'Unknown error',
              style: GoogleFonts.ptSans(
                fontSize: 14,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadEvaluationMetrics,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBrand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsContent(bool isDark) {
    if (_metrics == null) {
      return _buildErrorState();
    }

    final evaluationStatus = _metrics!['evaluationStatus'] as String?;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          _buildHeaderCard(isDark),
          const SizedBox(height: 16),

          // Service Status
          _buildServiceStatusCard(isDark),
          const SizedBox(height: 16),

          // Evaluation Results
          if (evaluationStatus == 'Complete') ...[
            _buildAIMetricsCard(isDark),
            const SizedBox(height: 16),
            _buildBaselineComparisonCard(isDark),
            const SizedBox(height: 16),
            _buildImprovementsCard(isDark),
            const SizedBox(height: 16),
            _buildComponentStatsCard(isDark),
          ] else ...[
            _buildStatusMessageCard(isDark, evaluationStatus ?? 'Unknown'),
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primaryBrand, brandAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBrand.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.analytics,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Exercise Ranking Evaluation',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'AI Ranking Performance Metrics',
            style: GoogleFonts.ptSans(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildServiceStatusCard(bool isDark) {
    final serviceStatus = _metrics!['serviceStatus'] as String? ?? 'Unknown';
    final hasEnoughData = _metrics!['hasEnoughData'] as bool? ?? false;
    final exerciseHistoryCount = _metrics!['exerciseHistoryRecords'] as int? ?? 0;
    final painHistoryDays = _metrics!['painHistoryDays'] as int? ?? 0;

    return _buildCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                hasEnoughData ? Icons.check_circle : Icons.info_outline,
                color: hasEnoughData ? successGreen : accentTeal,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'Service Status',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatRow('Status', serviceStatus, isDark),
          _buildStatRow('Exercise History', '$exerciseHistoryCount records', isDark),
          _buildStatRow('Pain History', '$painHistoryDays days', isDark),
          _buildStatRow(
            'Data Sufficient',
            hasEnoughData ? 'Yes' : 'No',
            isDark,
            valueColor: hasEnoughData ? successGreen : Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildAIMetricsCard(bool isDark) {
    final aiRanking = _metrics!['aiRanking'] as Map<String, dynamic>?;
    if (aiRanking == null) return const SizedBox.shrink();

    final ndcg = aiRanking['ndcg@3'] as double? ?? 0.0;
    final precision = aiRanking['precision@3'] as double? ?? 0.0;
    final recall = aiRanking['recall@3'] as double? ?? 0.0;

    return _buildCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryBrand.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: primaryBrand,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Ranking Metrics',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'NDCG@3',
                  ndcg.toStringAsFixed(3),
                  _getMetricColor(ndcg),
                  Icons.star,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Precision@3',
                  precision.toStringAsFixed(3),
                  _getMetricColor(precision),
                  Icons.precision_manufacturing,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  'Recall@3',
                  recall.toStringAsFixed(3),
                  _getMetricColor(recall),
                  Icons.search,
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildMetricExplanation(isDark),
        ],
      ),
    );
  }

  Widget _buildBaselineComparisonCard(bool isDark) {
    final randomBaseline = _metrics!['randomBaseline'] as Map<String, dynamic>?;
    final ruleBasedBaseline = _metrics!['ruleBasedBaseline'] as Map<String, dynamic>?;
    final aiRanking = _metrics!['aiRanking'] as Map<String, dynamic>?;

    if (randomBaseline == null || ruleBasedBaseline == null || aiRanking == null) {
      return const SizedBox.shrink();
    }

    final aiNDCG = aiRanking['ndcg@3'] as double? ?? 0.0;
    final randomNDCG = randomBaseline['ndcg@3'] as double? ?? 0.0;
    final ruleBasedNDCG = ruleBasedBaseline['ndcg@3'] as double? ?? 0.0;

    return _buildCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.compare_arrows,
                  color: accentTeal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Baseline Comparison',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildComparisonRow('AI Ranking', aiNDCG, _getMetricColor(aiNDCG), isDark),
          const SizedBox(height: 12),
          _buildComparisonRow('Rule-Based', ruleBasedNDCG, textSecondary, isDark),
          const SizedBox(height: 12),
          _buildComparisonRow('Random', randomNDCG, textSecondary, isDark),
        ],
      ),
    );
  }

  Widget _buildImprovementsCard(bool isDark) {
    final improvements = _metrics!['improvements'] as Map<String, dynamic>?;
    if (improvements == null) return const SizedBox.shrink();

    final overRandom = improvements['overRandom'] as double? ?? 0.0;
    final overRuleBased = improvements['overRuleBased'] as double? ?? 0.0;

    return _buildCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: successGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.trending_up,
                  color: successGreen,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Improvements',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildImprovementRow(
            'Over Random Baseline',
            overRandom,
            isDark,
          ),
          const SizedBox(height: 12),
          _buildImprovementRow(
            'Over Rule-Based Baseline',
            overRuleBased,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildComponentStatsCard(bool isDark) {
    final aiRanking = _metrics!['aiRanking'] as Map<String, dynamic>?;
    final componentStats = aiRanking?['componentStats'] as Map<String, dynamic>?;
    
    if (componentStats == null) return const SizedBox.shrink();

    return _buildCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.bar_chart,
                  color: accentTeal,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Component Statistics',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStatRow(
            'Average Score',
            (componentStats['avgScore'] as double? ?? 0.0).toStringAsFixed(3),
            isDark,
          ),
          _buildStatRow(
            'Min Score',
            (componentStats['minScore'] as double? ?? 0.0).toStringAsFixed(3),
            isDark,
          ),
          _buildStatRow(
            'Max Score',
            (componentStats['maxScore'] as double? ?? 0.0).toStringAsFixed(3),
            isDark,
          ),
          _buildStatRow(
            'Std Deviation',
            (componentStats['stdDev'] as double? ?? 0.0).toStringAsFixed(3),
            isDark,
          ),
          _buildStatRow(
            'Score Range',
            (componentStats['scoreRange'] as double? ?? 0.0).toStringAsFixed(3),
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMessageCard(bool isDark, String status) {
    return _buildCard(
      isDark: isDark,
      child: Column(
        children: [
          Icon(
            Icons.info_outline,
            color: accentTeal,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            status,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
            textAlign: TextAlign.center,
          ),
          if (_metrics!['note'] != null) ...[
            const SizedBox(height: 12),
            Text(
              _metrics!['note'] as String,
              style: GoogleFonts.ptSans(
                fontSize: 14,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF374151) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    Color color,
    IconData icon,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.ptSans(
              fontSize: 12,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, double value, Color color, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.ptSans(
            fontSize: 14,
            color: isDark ? Colors.white70 : const Color(0xFF1F2937),
            fontWeight: FontWeight.w500,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            value.toStringAsFixed(3),
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImprovementRow(String label, double percent, bool isDark) {
    final isPositive = percent > 0;
    final color = isPositive ? successGreen : Colors.orange;
    final icon = isPositive ? Icons.arrow_upward : Icons.arrow_downward;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.ptSans(
            fontSize: 14,
            color: isDark ? Colors.white70 : const Color(0xFF1F2937),
            fontWeight: FontWeight.w500,
          ),
        ),
        Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 4),
            Text(
              '${percent.toStringAsFixed(1)}%',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, bool isDark, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.ptSans(
              fontSize: 14,
              color: isDark ? Colors.white70 : textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? (isDark ? Colors.white : const Color(0xFF1F2937)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricExplanation(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentTeal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accentTeal.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline, color: accentTeal, size: 16),
              const SizedBox(width: 8),
              Text(
                'Metric Definitions',
                style: GoogleFonts.ptSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: accentTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildExplanationItem('NDCG@3', 'Ranking quality at top 3 positions (0.0-1.0)', isDark),
          _buildExplanationItem('Precision@3', 'Fraction of top 3 that are relevant', isDark),
          _buildExplanationItem('Recall@3', 'Fraction of relevant exercises found', isDark),
        ],
      ),
    );
  }

  Widget _buildExplanationItem(String term, String definition, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: GoogleFonts.ptSans(
            fontSize: 11,
            color: isDark ? Colors.white70 : textSecondary,
          ),
          children: [
            TextSpan(
              text: '$term: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(text: definition),
          ],
        ),
      ),
    );
  }

  Color _getMetricColor(double value) {
    if (value >= 0.7) return successGreen;
    if (value >= 0.5) return accentTeal;
    return Colors.orange;
  }
}
