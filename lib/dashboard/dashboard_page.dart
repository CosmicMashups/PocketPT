import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../data/globals.dart';
import '../data/rehabilitation_plan.dart';
import '../assessment/preliminary.dart';
import '../dailyAssessment/instructionVideo.dart';
import '../assessment/generate_plan.dart';
import '../data/user_data_notifier.dart';
import '../data/local_notifications_service.dart';
// removed loader: using direct global data like a_goal1.dart

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
  List<String> notifications = [];
  List<NotificationItem> _computedNotifications = [];

  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    // Listen for rehabilitation plan changes
    UserDataNotifier.instance.addListener(_onRehabilitationPlanChanged);
  }
  
  @override
  void dispose() {
    UserDataNotifier.instance.removeListener(_onRehabilitationPlanChanged);
    super.dispose();
  }
  
  void _onRehabilitationPlanChanged() {
    if (mounted) {
      setState(() {
        // Trigger rebuild when rehabilitation plans change
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final data = _gatherDashboardData();

    // Refresh notifications based on current globals
    _refreshNotifications();

    final hasCompletedAssessment = data['hasCompletedAssessment'] ?? false;
    if (!hasCompletedAssessment) {
      return _buildAssessmentRequiredState(context);
    }

    return _buildDashboardContent(context, data);
  }

  Map<String, dynamic> _gatherDashboardData() {
    // Build a data map similar to what the previous loader provided
    final userDetails = {
      'firstName': UserDataNotifier.instance.firstName,
      'lastName': UserDataNotifier.instance.lastName,
      'email': UserDataNotifier.instance.email,
      'profilePicture': UserDataNotifier.instance.profilePicture,
    };

    final userProgress = {
      'streak': UserProgress.streak,
      'totalExercises': UserProgress.totalExercises,
    };

    // Use the most up-to-date rehabilitation plans from UserDataNotifier
    final rehabilitationPlans = UserDataNotifier.instance.rehabPlans.isNotEmpty 
        ? UserDataNotifier.instance.rehabPlans 
        : UserRehabilitation.instance.rehabPlans;

    return {
      'hasCompletedAssessment': UserDetails.hasCompletedAssessment,
      'userDetails': userDetails,
      'userProgress': userProgress,
      'rehabilitationPlans': rehabilitationPlans,
      // notifications are computed via _refreshNotifications
    };
  }

  // Removed: legacy loading/error states since we now build directly from globals
  // _buildLoadingState and _buildErrorState were used by the old loader.

  // Removed legacy loading/error UI from previous loader-based approach

  Widget _buildAssessmentRequiredState(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF8B2E2E),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.assessment, size: 80, color: Color(0xFF8B2E2E)),
            const SizedBox(height: 24),
            const Text(
              'Assessment Required',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B2E2E),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Please complete your assessment to access the dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AssessPrelim()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B2E2E),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'Start Assessment',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, Map<String, dynamic> data) {
    // Initialize the notifier with current data
    UserDataNotifier.instance.initialize();
    
    // Defer heavy operations to after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (mounted) {
            _maybeShowDailyAssessmentDialog(context);
            _maybeShowDailyPainChangeDialog(context);
            _maybeShowRegeneratePlanDialog(context);
          }
        });
    
    return _buildMainDashboard(context, data);
  }

  Widget _buildMainDashboard(BuildContext context, Map<String, dynamic> data) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: const Color(0xFF8B2E2E),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Section
            _buildWelcomeSection(data),
            const SizedBox(height: 24),
            
            // Progress Section
            _buildProgressSection(data),
            const SizedBox(height: 24),
            
            // Notifications Section
            _buildNotificationsSection(),
            const SizedBox(height: 24),
            
            // Treatment Plans Section
            _buildTreatmentPlansSection(data),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection(Map<String, dynamic> data) {
    final userDetails = data['userDetails'] ?? {};
    final firstName = userDetails['firstName'] ?? '';
    final profilePicture = userDetails['profilePicture'] ?? '01.jpg';
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF8B2E2E), Color(0xFFC24A4A)],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage: AssetImage('assets/images/pfp/$profilePicture'),
            backgroundColor: Colors.white,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back, ${firstName.isNotEmpty ? firstName : 'User'}!',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ready for your rehabilitation journey?',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(Map<String, dynamic> data) {
    final userProgress = data['userProgress'] ?? {};
    final streak = userProgress['streak'] ?? 0;
    final totalExercises = userProgress['totalExercises'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Progress',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF8B2E2E),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildProgressCard(
                  'Streak',
                  '$streak days',
                  Icons.local_fire_department,
                  const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildProgressCard(
                  'Exercises',
                  '$totalExercises completed',
                  Icons.fitness_center,
                  const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(
            children: [
              const Icon(Icons.notifications, color: Color(0xFF8B2E2E)),
              const SizedBox(width: 8),
              Text(
                  'Notifications',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8B2E2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_computedNotifications.isEmpty)
            const Text('No notifications at this time.')
          else
            ..._computedNotifications.take(3).map((notification) => 
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  notification.text,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTreatmentPlansSection(Map<String, dynamic> data) {
    final rehabilitationPlans = data['rehabilitationPlans'] ?? [];
    
    return Container(
      padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
        borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
          Row(
            children: [
              const Icon(Icons.medical_services, color: Color(0xFF8B2E2E)),
              const SizedBox(width: 8),
              Text(
                'Treatment Plans',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF8B2E2E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (rehabilitationPlans.isEmpty)
            const Text('No treatment plans available. Complete your assessment to generate a plan.')
          else
            ...rehabilitationPlans.map((plan) => 
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B2E2E).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF8B2E2E).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Week ${plan.weekNumber ?? 1} Plan',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF8B2E2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${plan.exerciseReferences?.length ?? 0} exercises',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    ],
                  ),
                ),
            ),
          ],
      ),
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

}