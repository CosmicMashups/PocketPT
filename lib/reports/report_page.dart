import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'widgets/rehab_plan_expansion_panel.dart';
import 'widgets/exercise_calendar_grid.dart';
import 'widgets/export_pdf_button.dart';
import 'widgets/pain_level_chart.dart';
import '../data/user_data_notifier.dart';
import '../core/animations.dart';
import 'services/reports_data_service.dart';
import '../tutorials/tutorial_preferences.dart';
import '../tutorials/tutorial_service.dart';
import '../data/globals.dart';
// removed data wrapper: using direct globals like a_goal1.dart
class ReportPage extends ConsumerStatefulWidget {
  const ReportPage({super.key});

  @override
  ConsumerState<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends ConsumerState<ReportPage> with TickerProviderStateMixin {
  late AnimationController _animationController;
  bool _tutorialScheduled = false;

  @override
  void initState() {
    super.initState();
    _animationController = PocketPTAnimations.createController(
      this,
      duration: PocketPTAnimations.medium,
    );
    // Listen for rehabilitation plan changes
    UserDataNotifier.instance.addListener(_onRehabilitationPlanChanged);
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    UserDataNotifier.instance.removeListener(_onRehabilitationPlanChanged);
    super.dispose();
  }
  
  void _onRehabilitationPlanChanged() {
    if (mounted) {
      // Refresh the reports data when rehabilitation plans change
      ref.invalidate(reportsDataProvider);
    }
  }

  // Professional healthcare color scheme
  static const mainColor = Color(0xFF8B2E2E); // Muscular maroon
  static const subColor = Color(0xFFC24A4A); // Lighter maroon
  static const detailColor = Color(0xFF6B7280); // Gray
  static const backgroundColor = Color(0xFFF8FAFC); // Light background

  @override
  Widget build(BuildContext context) {
    final reportsDataAsync = ref.watch(reportsDataProvider);
    final reportsService = ref.watch(reportsDataServiceProvider);

    if (!_tutorialScheduled && reportsDataAsync.hasValue) {
      _scheduleReportTutorial();
    }

      return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? Theme.of(context).scaffoldBackgroundColor 
          : backgroundColor,
      appBar: _buildAppBar(context),
      body: reportsDataAsync.when(
        loading: () => _buildLoadingState(context),
        error: (error, stackTrace) => _buildErrorState(context, error.toString()),
        data: (reportsData) => _buildReportsContent(context, reportsData, reportsService),
      ),
    );
  }

  void _scheduleReportTutorial() {
    if (_tutorialScheduled) {
      return;
    }
    _tutorialScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) {
        _tutorialScheduled = false;
        return;
      }

      await TutorialPreferences.instance.ensureInitialized();
      if (!mounted) {
        _tutorialScheduled = false;
        return;
      }
      
      if (!TutorialPreferences.instance.tutorialsEnabled) {
        _tutorialScheduled = false;
        return;
      }

      if (TutorialPreferences.instance.isFlowCompleted('onboarding_reports')) {
        return;
      }

      if (!mounted) {
        _tutorialScheduled = false;
        return;
      }
      
      await TutorialService.instance.startFlow(context, 'onboarding_reports');
    });
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
          title: const Text(
            'Clinical Reports',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
          ),
          automaticallyImplyLeading: false,
          centerTitle: true,
          backgroundColor: mainColor,
          elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              mainColor,
              subColor,
            ],
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(24),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () {
            ref.invalidate(reportsDataProvider);
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            'Loading reports data...',
            style: TextStyle(
              fontSize: 16,
              color: detailColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              'Failed to load reports',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
              const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: detailColor,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(reportsDataProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: mainColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              ),
            ],
          ),
        ),
      );
    }
    
  Widget _buildReportsContent(BuildContext context, ReportsData reportsData, ReportsDataService service) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Handle empty data state
    final hasNoData = reportsData.rehabPlans.isEmpty && 
                      reportsData.exerciseHistory.isEmpty && 
                      reportsData.painHistory.isEmpty;
    
    if (hasNoData) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 64,
                color: detailColor.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No Reports Data Available',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : mainColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete some exercises or record pain levels to see your progress reports here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: detailColor,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.invalidate(reportsDataProvider);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: mainColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: AnimationLimiter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Header Section with improved design
          AnimationConfiguration.staggeredList(
            position: 0,
            duration: PocketPTAnimations.pageTransition,
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildHeaderSection(context, reportsData, isDark),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick Stats Section
          AnimationConfiguration.staggeredList(
            position: 1,
            duration: PocketPTAnimations.pageTransition,
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildQuickStatsSection(context, reportsData, isDark),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Pain Level Chart
          AnimationConfiguration.staggeredList(
            position: 2,
            duration: PocketPTAnimations.pageTransition,
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: const PainLevelChart(),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Reports Content
          AnimationConfiguration.staggeredList(
            position: 3,
            duration: PocketPTAnimations.pageTransition,
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: const RehabPlanExpansionPanel(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          AnimationConfiguration.staggeredList(
            position: 4,
            duration: PocketPTAnimations.pageTransition,
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: const ExerciseCalendarGrid(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          AnimationConfiguration.staggeredList(
            position: 5,
            duration: PocketPTAnimations.pageTransition,
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: const ExportPDFButton(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          AnimationConfiguration.staggeredList(
            position: 6,
            duration: PocketPTAnimations.pageTransition,
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: _buildSampleDataButton(context, isDark),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
        ),
      ),
    );
  }

  Widget _buildSampleDataButton(BuildContext context, bool isDark) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sample Data',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : mainColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add sample pain history data for testing',
            style: TextStyle(
              fontSize: 14,
              color: detailColor,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _saveSamplePainData(context),
            icon: const Icon(Icons.add_chart),
            label: const Text('Add Sample Pain Data'),
            style: ElevatedButton.styleFrom(
              backgroundColor: mainColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveSamplePainData(BuildContext context) async {
    try {
      // Show loading indicator
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Parse dates: 11-21-2025 00:00:00 and 11-22-2025 00:00:00
      // Normalize to date only (remove time component)
      final date1 = DateTime(2025, 11, 21);
      final date2 = DateTime(2025, 11, 22);

      // Create sample pain entries
      final entry1 = PainRecordEntry(
        date: date1,
        painScale: 8,
        painLevel: 'Severe',
      );
      final entry2 = PainRecordEntry(
        date: date2,
        painScale: 5,
        painLevel: 'Moderate',
      );

      // Helper function to check if two dates are the same (ignoring time)
      bool isSameDate(DateTime a, DateTime b) {
        return a.year == b.year && a.month == b.month && a.day == b.day;
      }

      // Check if entries already exist for these dates and replace them
      final existingIndex1 = PainHistory.entries.indexWhere(
        (e) => isSameDate(e.date, date1),
      );
      final existingIndex2 = PainHistory.entries.indexWhere(
        (e) => isSameDate(e.date, date2),
      );

      if (existingIndex1 >= 0) {
        PainHistory.entries[existingIndex1] = entry1;
      } else {
        PainHistory.entries.add(entry1);
      }

      if (existingIndex2 >= 0) {
        PainHistory.entries[existingIndex2] = entry2;
      } else {
        PainHistory.entries.add(entry2);
      }

      // Sort entries by date
      PainHistory.entries.sort((a, b) => a.date.compareTo(b.date));

      // Save to Hive
      await PainHistory.saveToHive();
      
      // Save to Firebase
      await PainHistory.saveToFirebase();

      // Close loading dialog
      if (!mounted) return;
      Navigator.of(context).pop();

      // Show success message
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sample pain data saved successfully to Hive and Firebase'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Clear cache and refresh reports data
      final service = ref.read(reportsDataServiceProvider);
      service.clearCacheEntry('pain_history');
      ref.invalidate(reportsDataProvider);
      ref.invalidate(painHistoryProvider);
    } catch (e, stackTrace) {
      // Close loading dialog if still open
      if (mounted) {
        try {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        } catch (_) {
          // Ignore navigation errors
        }
      }

      // Show error message
      if (!mounted) return;
      debugPrint('Error saving sample pain data: $e');
      debugPrint('Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving sample data: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildHeaderSection(BuildContext context, ReportsData reportsData, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            isDark ? Theme.of(context).colorScheme.surface : Colors.white,
            isDark ? Theme.of(context).colorScheme.surface : const Color(0xFFF0F9FF),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.analytics,
                  color: mainColor,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clinical Progress Reports',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : mainColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Comprehensive analysis of patient rehabilitation progress',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white70 : detailColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Last updated indicator
          Row(
            children: [
              Icon(
                Icons.update,
                size: 16,
                color: detailColor.withOpacity(0.7),
              ),
              const SizedBox(width: 8),
              Text(
                'Last updated: ${_formatLastUpdated(reportsData.lastUpdated)}',
                style: TextStyle(
                  fontSize: 12,
                  color: detailColor.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection(BuildContext context, ReportsData reportsData, bool isDark) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : mainColor,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Completed Exercises',
                  reportsData.totalCompletedExercises.toString(),
                  Icons.fitness_center,
                  const Color(0xFF10B981),
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Avg Pain Level',
                  reportsData.averagePainLevel.toStringAsFixed(1),
                  Icons.analytics,
                  reportsData.averagePainLevel > 5 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  context,
                  'Completion Rate',
                  '${(reportsData.exerciseCompletionRate * 100).toStringAsFixed(1)}%',
                  Icons.trending_up,
                  const Color(0xFF3B82F6),
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  context,
                  'Pain Trend',
                  reportsData.painTrend > 0 ? 'Increasing' : reportsData.painTrend < 0 ? 'Decreasing' : 'Stable',
                  Icons.trending_up,
                  reportsData.painTrend > 0 ? const Color(0xFFEF4444) : reportsData.painTrend < 0 ? const Color(0xFF10B981) : const Color(0xFF6B7280),
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : detailColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
          style: TextStyle(
              fontSize: 20,
            fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : mainColor,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastUpdated(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}