import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../record/pre_record_page.dart';
import '../data/globals.dart';
import '../data/rehabilitation_plan.dart';
import '../data/treatment.dart';
import '../data/optimized_data_service.dart';
import '../assessment/preliminary.dart';
import '../dailyAssessment/instructionVideo.dart';
import '../dailyAssessment/cameraPose.dart';
import '../assessment/generate_plan.dart';
import '../data/user_data_notifier.dart';
import '../data/local_notifications_service.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

// Notification data structure
class NotificationItem {
  final String text;
  final String actionType;
  final bool isClickable;

  NotificationItem({
    required this.text,
    required this.actionType,
    this.isClickable = true,
  });
}

class _DashboardPageState extends State<DashboardPage> with AutomaticKeepAliveClientMixin {
  List<String> notifications = UserDetails.notifications;

  // Derived notifications store (computed fresh on each open)
  List<NotificationItem> _computedNotifications = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Initialize the notifier with current data
    UserDataNotifier.instance.initialize();
    // Load critical data immediately
    _refreshNotifications();
    
    // Defer heavy operations to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureTreatmentsLoaded();
      final hasPlan = UserRehabilitation.instance.rehabPlans.isNotEmpty;
      if (hasPlan) {
        // Delay dialog showing to improve perceived performance
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _maybeShowDailyAssessmentDialog(context);
            _maybeShowDailyPainChangeDialog(context);
            _maybeShowRegeneratePlanDialog(context);
          }
        });
      }
    });
  }

  Future<void> _ensureTreatmentsLoaded() async {
    // Ensure treatment references are loaded from Hive if they exist
    if (UserRehabilitation.instance.treatmentReferences == null && 
        UserRehabilitation.instance.rehabPlans.isNotEmpty) {
      try {
        await UserRehabilitation.instance.loadPlansFromHive();
        if (mounted) {
          setState(() {}); // Refresh UI to show treatment references
        }
      } catch (e) {
        debugPrint('Error loading treatment references in dashboard: $e');
      }
    }
  }

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          scrollable: true,
          backgroundColor: const Color(0xFFF1F1F1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.notifications, color: Color(0xFF557A95)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Notifications',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
            ],
          ),
          content: (_computedNotifications.isEmpty && notifications.isEmpty)
              ? Text('No new notifications', style: GoogleFonts.poppins())
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // Dynamic notifications (clickable)
                      ..._computedNotifications.map((notification) => _buildNotificationCard(
                        notification: notification,
                        context: context,
                      )),
                      // Static notifications (non-clickable)
                      ...notifications.map((notification) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.campaign, color: Color(0xFF557A95)),
                                const SizedBox(width: 10),
                                Expanded(child: Text(notification, style: GoogleFonts.poppins(fontSize: 15))),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Close', style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );
  }

  void _refreshNotifications() {
    final List<NotificationItem> dynamicNotes = [];

    // Streak notifications: first day, weekly, monthly
    if (UserSettings.isStreakAlert) {
      if (UserProgress.streak == 1) {
        dynamicNotes.add(NotificationItem(
          text: '🔥 Day 1 streak! Great start—keep going!',
          actionType: 'none',
          isClickable: false,
        ));
      }
      if (UserProgress.streak != 0 && UserProgress.streak % 7 == 0) {
        dynamicNotes.add(NotificationItem(
          text: '🏁 ${UserProgress.streak} days streak! Completed another week!',
          actionType: 'none',
          isClickable: false,
        ));
      }
      if (UserProgress.streak != 0 && UserProgress.streak % 30 == 0) {
        dynamicNotes.add(NotificationItem(
          text: '🏆 ${UserProgress.streak} days streak! One month milestone!',
          actionType: 'none',
          isClickable: false,
        ));
      }
    }

    // Exercise reminders
    if (UserSettings.isExerciseReminder) {
      final now = TimeOfDay.now();
      final reminder = UserSettings.exerciseReminderTime;
      // If current time has passed reminder time and user hasn't worked out yet
      final didWorkoutToday = UserProgress.lastExerciseDate != null &&
          DateTime(UserProgress.lastExerciseDate!.year, UserProgress.lastExerciseDate!.month, UserProgress.lastExerciseDate!.day) ==
              DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
      if (!didWorkoutToday && _isTimePassed(reminder, now)) {
        dynamicNotes.add(NotificationItem(
          text: '⏰ Exercise reminder: It\'s time for today\'s plan.',
          actionType: 'start_exercise',
        ));
      }
    }

    // Daily Assessment reminder if no pain record today
    if (UserSettings.isDailyReminder && PainHistory.todaysEntry() == null) {
      dynamicNotes.add(NotificationItem(
        text: '🩺 Daily assessment: Please assess your pain level today.',
        actionType: 'daily_assessment',
      ));
    }

    // Incomplete exercise reminders
    final hasActivePlan = UserRehabilitation.instance.rehabPlans.isNotEmpty;
    if (hasActivePlan) {
      // Suppose we infer started-but-not-finished if there is a DailyProgress today with any false
      final plan = UserRehabilitation.instance.rehabPlans.first;
      final today = DateTime.now();
      final todayProgress = plan.daily.where((d) => d.date.year == today.year && d.date.month == today.month && d.date.day == today.day).toList();
      if (todayProgress.isEmpty) {
        dynamicNotes.add(NotificationItem(
          text: '📋 Reminder: Complete today\'s exercises.',
          actionType: 'start_exercise',
        ));
      } else {
        final anyIncomplete = todayProgress.any((d) => d.completedExercises.values.any((done) => done == false));
        if (anyIncomplete) {
          dynamicNotes.add(NotificationItem(
            text: '⏳ Reminder: You started today\'s plan. Finish your exercises.',
            actionType: 'resume_exercise',
          ));
        }
      }
    }

    // Regenerate plan notification (non-blocking prompt)
    if (UserRehabilitation.instance.rehabPlans.isNotEmpty && PainHistory.hasSamePainForConsecutiveDays(7)) {
      dynamicNotes.add(NotificationItem(
        text: '🔁 Pain unchanged for 7 days: Consider regenerating your plan.',
        actionType: 'regenerate_plan',
      ));
    }

    setState(() {
      _computedNotifications = dynamicNotes;
    });

    // Also show device notifications for actionable reminders (deduped per day)
    for (final note in dynamicNotes) {
      if (!note.isClickable) continue;
      // Map a stable small id per action type
      final int id;
      switch (note.actionType) {
        case 'daily_assessment':
          id = 1001;
          break;
        case 'start_exercise':
          id = 1002;
          break;
        case 'resume_exercise':
          id = 1003;
          break;
        case 'regenerate_plan':
          id = 1004;
          break;
        default:
          id = 1999;
      }
      LocalNotificationsService.instance.showUniqueDailyNotification(
        id: id,
        title: 'PocketPT',
        body: note.text,
        actionType: note.actionType,
      );
    }
  }

  bool _isTimePassed(TimeOfDay target, TimeOfDay now) {
    final int targetMinutes = target.hour * 60 + target.minute;
    final int nowMinutes = now.hour * 60 + now.minute;
    return nowMinutes >= targetMinutes;
  }

  Widget _buildNotificationCard({
    required NotificationItem notification,
    required BuildContext context,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: notification.isClickable ? () => _handleNotificationAction(notification.actionType, context) : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: notification.isClickable 
                ? Border.all(color: const Color(0xFF557A95).withOpacity(0.3), width: 1)
                : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Row(
            children: [
              Icon(
                notification.isClickable ? Icons.touch_app : Icons.campaign,
                color: notification.isClickable ? const Color(0xFF557A95) : const Color(0xFF557A95),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  notification.text,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    color: notification.isClickable ? const Color(0xFF557A95) : Colors.black87,
                    fontWeight: notification.isClickable ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (notification.isClickable)
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Color(0xFF557A95),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleNotificationAction(String actionType, BuildContext context) {
    // Close the notification dialog first
    Navigator.of(context).pop();
    
    switch (actionType) {
      case 'daily_assessment':
        _showDailyAssessmentDialog(context);
        break;
      case 'start_exercise':
        _navigateToExercise(context);
        break;
      case 'resume_exercise':
        _navigateToExercise(context);
        break;
      case 'regenerate_plan':
        _showRegeneratePlanDialog(context);
        break;
      default:
        // No action for 'none' or unknown types
        break;
    }
  }

  void _showDailyAssessmentDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          scrollable: true,
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.assignment, color: Color(0xFF800020)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Daily Re-Assessment Required',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              'Please complete today\'s quick pain re-assessment.',
              style: GoogleFonts.ptSans(fontSize: 16, color: const Color(0xFF3A3A3A)),
              softWrap: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Later', style: GoogleFonts.poppins(color: Colors.grey[700])),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF800020)),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InstructionVideoPage()),
                );
              },
              child: Text('Start', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _navigateToExercise(BuildContext context) {
    final rehabPlans = UserRehabilitation.instance.rehabPlans;
    if (rehabPlans.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No rehabilitation plan available. Please complete assessment first.')),
      );
      return;
    }

    final currentExercise = ExerciseHistory.getCurrentExercise();
    if (currentExercise != null) {
      OptimizedNavigation.navigateWithDataPreload(
        context,
        const PreRecordPage(),
        dataKey: 'current_exercise_data',
        dataPreloader: () async {
          await UserRehabilitation.instance.loadPlansFromHive();
        },
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All exercises completed for today!')),
      );
    }
  }

  void _showRegeneratePlanDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          scrollable: true,
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.autorenew, color: Color(0xFF800020)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Regenerate Plan?',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                  overflow: TextOverflow.ellipsis,
                  softWrap: true,
                ),
              ),
            ],
          ),
          content: Text(
            'Your pain level has been unchanged for 7 days. Would you like to regenerate a new rehabilitation plan and treatments?',
            style: GoogleFonts.ptSans(fontSize: 16, color: const Color(0xFF3A3A3A)),
            softWrap: true,
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[600]),
              onPressed: () {
                PainHistory.markPromptedToday();
                Navigator.of(ctx).pop();
              },
              child: Text('Not Now', style: GoogleFonts.poppins(color: Colors.white)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF800020)),
              onPressed: () async {
                Navigator.of(ctx).pop();
                _archiveCurrentProgram();
                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const GeneratePlanPage()),
                  );
                }
              },
              child: Text('Regenerate', style: GoogleFonts.poppins(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _maybeShowDailyAssessmentDialog(BuildContext context) {
    if (!UserSettings.isDailyReminder) return;

    // Check if user has taken daily re-assessment today
    if (PainHistory.todaysEntry() == null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            scrollable: true,
            backgroundColor: Theme.of(ctx).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.assignment, color: Color(0xFF800020)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Daily Re-Assessment Required',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                'Please complete today\'s quick pain re-assessment.',
                style: GoogleFonts.ptSans(fontSize: 16, color: const Color(0xFF3A3A3A)),
                softWrap: true,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Later', style: GoogleFonts.poppins(color: Colors.grey[700])),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF800020)),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const InstructionVideoPage()),
                  );
                },
                child: Text('Start', style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          );
        },
      );
    }
  }

  void _maybeShowDailyPainChangeDialog(BuildContext context) {
    if (!UserSettings.isDailyReminder) return;

    // Ensure there is a baseline entry for today using current UserAssess state
    if (PainHistory.todaysEntry() == null) {
      PainHistory.recordToday(
        painScale: UserAssess.painScale,
        painLevel: UserAssess.painLevel.isEmpty ? UserAssess.painScale.toString() : UserAssess.painLevel,
      );
    }

    if (PainHistory.shouldPromptForRetake()) {
      PainHistory.markPromptedToday();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            scrollable: true,
            backgroundColor: Theme.of(ctx).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.health_and_safety, color: Color(0xFF800020)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Daily Pain Check',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ),
              ],
            ),
            content: Text(
              'Your pain level seems different today. Would you like to retake the quick pain assessment now?',
              style: GoogleFonts.ptSans(fontSize: 16, color: const Color(0xFF3A3A3A)),
              softWrap: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text('Later', style: GoogleFonts.poppins(color: Colors.grey[700])),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF800020)),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => const InstructionVideoPage(),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) {
                        const begin = Offset(1.0, 0.0);
                        const end = Offset.zero;
                        final tween = Tween(begin: begin, end: end).chain(CurveTween(curve: Curves.easeInOut));
                        return SlideTransition(position: animation.drive(tween), child: child);
                      },
                    ),
                  );
                },
                child: Text('Retake Now', style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          );
        },
      );
    }
  }

  void _maybeShowRegeneratePlanDialog(BuildContext context) {
    // Need an active plan to consider regeneration
    if (UserRehabilitation.instance.rehabPlans.isEmpty) return;

    // Ensure program start date
    ActiveProgram.startDate ??= DateTime.now();

    // If pain is unchanged for 7 consecutive days, prompt regeneration
    if (PainHistory.hasSamePainForConsecutiveDays(7)) {
      showDialog(
        context: context,
        barrierDismissible: false, // Make it persistent
        builder: (ctx) {
          return AlertDialog(
            scrollable: true,
            backgroundColor: Theme.of(ctx).colorScheme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.autorenew, color: Color(0xFF800020)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Regenerate Plan?',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                  ),
                ),
              ],
            ),
            content: Text(
              'Your pain level has been unchanged for 7 days. Would you like to regenerate a new rehabilitation plan and treatments?',
              style: GoogleFonts.ptSans(fontSize: 16, color: const Color(0xFF3A3A3A)),
              softWrap: true,
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[600]),
                onPressed: () {
                  // Mark as dismissed for today
                  PainHistory.markPromptedToday();
                  Navigator.of(ctx).pop();
                },
                child: Text('Not Now', style: GoogleFonts.poppins(color: Colors.white)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF800020)),
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  _archiveCurrentProgram();
                  // Navigate to generation to create a new plan
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GeneratePlanPage()),
                    );
                  }
                },
                child: Text('Regenerate', style: GoogleFonts.poppins(color: Colors.white)),
              ),
            ],
          );
        },
      );
    }
  }

  void _archiveCurrentProgram() async {
    final plans = UserRehabilitation.instance.rehabPlans;
    if (plans.isEmpty) return;
    final plan = plans.first;

    // Estimate days completed as unique dates recorded in DailyProgress
    final Set<DateTime> uniqueDays = {};
    for (final dp in plan.daily) {
      uniqueDays.add(DateTime(dp.date.year, dp.date.month, dp.date.day));
    }
    final int daysCompleted = uniqueDays.length;

    // Get full exercise data for archiving
    final exercises = <ExerciseSnapshot>[];
    for (final exerciseRef in plan.exerciseReferences) {
      final exercise = await ExerciseDataService.getExerciseById(exerciseRef.exerciseId);
      if (exercise != null) {
        exercises.add(ExerciseSnapshot(
          exerciseId: exercise.exerciseId,
          exerciseName: exercise.exerciseName,
          description: exercise.description,
          muscle: exercise.muscle,
          painLevel: exercise.painLevel,
          goal: exercise.goal,
          repetitions: exerciseRef.repetitions,
          sets: exerciseRef.sets,
          imageUrl: exercise.imageUrl,
          videoUrl: exercise.videoUrl,
        ));
      }
    }

    // Get full treatment data for archiving
    final treatments = <TreatmentSnapshot>[];
    if (UserRehabilitation.instance.treatmentReferences != null) {
      for (final treatmentRef in UserRehabilitation.instance.treatmentReferences!) {
        final treatment = await ExerciseDataService.getTreatmentById(treatmentRef.treatmentId);
        if (treatment != null) {
          treatments.add(TreatmentSnapshot(
            treatmentId: treatment.treatmentId,
            treatmentName: treatment.treatmentName,
            description: treatment.description,
            musclesInvolved: treatment.musclesInvolved,
            painLevel: treatment.painLevel,
            painDuration: treatment.painDuration,
          ));
        }
      }
    }

    final DateTime start = ActiveProgram.startDate ?? DateTime.now();
    final DateTime end = DateTime.now();
    ProgramArchive.addArchive(ArchivedProgram(
      startDate: DateTime(start.year, start.month, start.day),
      endDate: DateTime(end.year, end.month, end.day),
      daysCompleted: daysCompleted,
      exercises: exercises,
      treatments: treatments,
    ));

    // Reset active program start date for new plan
    ActiveProgram.startDate = DateTime.now();
  }

  Widget _buildClinicalMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 4),
            Text(
              title,
              style: GoogleFonts.poppins(
              fontSize: 14,
                fontWeight: FontWeight.w600,
              color: const Color(0xFF1F2937),
              ),
            ),
            Text(
            subtitle,
              style: GoogleFonts.poppins(
              fontSize: 12,
              color: const Color(0xFF6B7280),
              ),
            ),
          ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentExercise = ExerciseHistory.getCurrentExercise();
    double progress = ExerciseHistory.calculateTodaysProgressPercentage();

    return ListenableBuilder(
      listenable: UserDataNotifier.instance,
      builder: (context, child) {
        return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Professional Header with Patient Info
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF8B2E2E), // Professional blue
                      const Color(0xFFC24A4A),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B2E2E).withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                      ),
                      child: CircleAvatar(
                            radius: 36,
                        backgroundImage: const AssetImage('assets/images/profile/profile.jpg'),
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                        const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                                'Patient Dashboard',
                            style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: Colors.white.withOpacity(0.9),
                                  fontWeight: FontWeight.w500,
                            ),
                          ),
                              const SizedBox(height: 4),
                        Flexible(
                          child: UserDataNotifier.instance.isLoading
                              ? Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Loading...',
                                      style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  '${UserDataNotifier.instance.firstName} ${UserDataNotifier.instance.lastName}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                        ),
                              const SizedBox(height: 8),
                                  Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                    ),
                                    child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(Icons.local_fire_department, 
                                      color: Colors.orange, size: 20),
                                    const SizedBox(width: 6),
                                        Text(
                                      '${UserProgress.streak} Day Streak',
                                          style: GoogleFonts.poppins(
                                        fontSize: 14,
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            onPressed: () => _showNotificationsDialog(context),
                            icon: Stack(
                              children: [
                                const Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                                if (_computedNotifications.isNotEmpty || notifications.isNotEmpty)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFEF4444),
                                        shape: BoxShape.circle,
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 16,
                                        minHeight: 16,
                                      ),
                                      child: Text(
                                        '${_computedNotifications.length + notifications.length}',
                                        style: GoogleFonts.poppins(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                          ),
                        ],
                      ),
                    ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Clinical Progress Overview
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
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
                            color: const Color(0xFF8B2E2E).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.trending_up,
                            color: Color(0xFF8B2E2E),
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                'Today\'s Progress',
                                  style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                                Flexible(
                                  child: Text(
                                    currentExercise?.exerciseName ?? 'No active exercise',
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: const Color(0xFF6B7280),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: progress > 0.5 
                                ? const Color(0xFF10B981).withOpacity(0.1)
                                : const Color(0xFFF59E0B).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: progress > 0.5 
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${(progress * 100).toInt()}%',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: progress > 0.5 
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFFF59E0B),
                            ),
                                  ),
                                ),
                              ],
                            ),
                    const SizedBox(height: 20),
                            Row(
                              children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                              Text(
                                'Target Muscle',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: const Color(0xFF6B7280),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Flexible(
                                child: Text(
                                  UserAssess.specificMuscle.isNotEmpty
                                      ? UserAssess.specificMuscle
                                      : 'Not specified',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: const Color(0xFF1F2937),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (currentExercise != null) ...[
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                    Text(
                                  'Exercise Details',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                    color: const Color(0xFF6B7280),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${currentExercise.sets} sets × ${currentExercise.repetitions} reps',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    color: const Color(0xFF1F2937),
                                    fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) =>
                                            const PreRecordPage(),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          const begin = Offset(1.0, 0.0);
                                          const end = Offset.zero;
                                          const curve = Curves.easeInOut;
                                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                          var offsetAnimation = animation.drive(tween);
                                          return SlideTransition(position: offsetAnimation, child: child);
                                        },
                                      ),
                                    );
                                  },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B2E2E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              progress == 0 ? Icons.play_arrow : Icons.refresh,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              progress == 0 ? 'Start Exercise Session' : 'Resume Exercise',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                        ),
                      ),
                            ),
                          ],
                        ),
              ),

              // Clinical Metrics
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
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
                    Text(
                      'Clinical Metrics',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                children: [
                        Expanded(
                          child: _buildClinicalMetricCard(
                            title: 'Compliance',
                            value: '${UserProgress.streak}',
                            subtitle: 'Consecutive Days',
                    icon: Icons.local_fire_department,
                            color: const Color(0xFFF59E0B),
                  ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildClinicalMetricCard(
                    title: 'Exercises',
                    value: '${UserProgress.totalExercises}',
                            subtitle: 'Total Completed',
                    icon: Icons.fitness_center,
                            color: const Color(0xFFC24A4A),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildClinicalMetricCard(
                            title: 'Duration',
                            value: '${UserProgress.totalMinutes}',
                            subtitle: 'Minutes',
                    icon: Icons.timer,
                            color: const Color(0xFF10B981),
                          ),
                  ),
                ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // AI Assessment Tools
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF6366F1),
                      const Color(0xFF8B5CF6),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
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
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.psychology,
                            size: 28,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI-Powered Assessment',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Advanced CNN-based pose estimation for clinical pain assessment',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                                width: 1,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Clinical Benefits',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '• Objective pain measurement\n• Real-time posture analysis\n• Clinical-grade accuracy',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                    height: 1.4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                    SizedBox(
                          width: 120,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const CameraPosePage(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF6366F1),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                              elevation: 0,
                        ),
                        child: Text(
                              'Launch AI Assessment',
                          style: GoogleFonts.poppins(
                                fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                              textAlign: TextAlign.center,
                        ),
                      ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Treatment Plan Section
              const SizedBox(height: 24),
              Text(
                'Treatment Plan',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 16),
              Column(
                children: UserRehabilitation.instance.rehabPlans.isEmpty
                    ? [
                        // Assessment Required Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFFDC2626),
                                const Color(0xFFEF4444),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFDC2626).withOpacity(0.2),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.assignment_outlined,
                                      size: 28,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Initial Assessment Required',
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Complete the comprehensive assessment to generate your personalized treatment plan.',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: Colors.white.withOpacity(0.9),
                                            height: 1.4,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const AssessPrelim(),
                                      ),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFFDC2626),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.assignment, size: 20),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Begin Assessment',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
                    : UserRehabilitation.instance.rehabPlans.map((plan) {
                        return Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
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
                                      color: const Color(0xFF8B2E2E).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.medical_information,
                                      color: Color(0xFF8B2E2E),
                                      size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                          'Week ${plan.weekNumber.toString().padLeft(2, '0')} Treatment Plan',
                                      style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.w700,
                                        fontSize: 18,
                                            color: const Color(0xFF1F2937),
                                          ),
                                        ),
                                        Text(
                                          'Active rehabilitation program',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: const Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              // Exercises Section
                              Text(
                                'Prescribed Exercises',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 12),
                                    FutureBuilder<List<Exercise>>(
                                      future: plan.getExercises(),
                                      builder: (context, snapshot) {
                                        if (snapshot.connectionState == ConnectionState.waiting) {
                                          return const Center(child: CircularProgressIndicator());
                                        }
                                        if (snapshot.hasError) {
                                          return Text('Error loading exercises: ${snapshot.error}');
                                        }
                                        final exercises = snapshot.data ?? [];
                                        return Column(
                                          children: exercises.map(
                                      (exercise) => Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF9FAFB),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: const Color(0xFFE5E7EB),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                              children: [
                                            Container(
                                              padding: const EdgeInsets.all(6),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF8B2E2E).withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: const Icon(
                                                  Icons.fitness_center,
                                                size: 16,
                                                color: Color(0xFF8B2E2E),
                                                ),
                                            ),
                                            const SizedBox(width: 12),
                                                Expanded(
                                                  child: Text(
                                                    exercise.exerciseName,
                                                style: GoogleFonts.poppins(
                                                  color: const Color(0xFF1F2937),
                                                      fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                        ),
                                            ),
                                          ).toList(),
                                        );
                                      },
                                    ),
                              // Treatments Section
                                    if (UserRehabilitation.instance.treatmentReferences != null && 
                                        UserRehabilitation.instance.treatmentReferences!.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                Text(
                                  'Recommended Treatments',
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1F2937),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                      FutureBuilder<List<dynamic>?>(
                                        future: UserRehabilitation.instance.getTreatments(),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const Center(child: CircularProgressIndicator());
                                          }
                                          if (snapshot.hasError) {
                                            return Text('Error loading treatments: ${snapshot.error}');
                                          }
                                          final treatments = snapshot.data ?? [];
                                          return Column(
                                            children: treatments.map(
                                              (treatment) {
                                                final treatmentObj = treatment as Treatment?;
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF0FDF4),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: const Color(0xFF10B981).withOpacity(0.2),
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                                  children: [
                                                Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: const Color(0xFF10B981).withOpacity(0.1),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Icon(
                                                      Icons.medical_services,
                                                    size: 16,
                                                    color: Color(0xFF10B981),
                                                    ),
                                                ),
                                                const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        treatmentObj?.treatmentName ?? 'Unknown Treatment',
                                                    style: GoogleFonts.poppins(
                                                      color: const Color(0xFF1F2937),
                                                          fontSize: 14,
                                                      fontWeight: FontWeight.w500,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                            ),
                                                );
                                              },
                                            ).toList(),
                                          );
                                        },
                                      ),
                                    ],
                            ],
                          ),
                        );
                      }).toList(),
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}