import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import '../record/pre_record_page.dart';
import '../data/globals.dart';
import '../data/rehabilitation_plan.dart';
import '../data/treatment.dart';
import '../assessment/preliminary.dart';
import '../dailyAssessment/instructionVideo.dart';
import '../assessment/generate_plan.dart';
import '../data/user_data_notifier.dart';
import '../data/data_persistence_service.dart';
import '../data/local_notifications_service.dart';
import '../widgets/responsive_dialog.dart';
import '../core/animations.dart';
import '../main.dart';
import '../tutorials/tutorial_config.dart';
import '../tutorials/tutorial_preferences.dart';
import '../tutorials/tutorial_service.dart';
// import '../demo/cnn_poseDemo.dart'; // Commented out until file exists

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

class _DashboardPageState extends State<DashboardPage> 
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  List<String> notifications = [];
  List<NotificationItem> _computedNotifications = [];
  bool _isLoading = true;
  String? _loadError;
  late AnimationController _animationController;
  bool _tutorialScheduled = false;
  
  // Cache for exercise and treatment futures to prevent recreation on every build
  final Map<String, Future<Exercise?>> _exerciseFutureCache = {};
  final Map<String, Future<Treatment?>> _treatmentFutureCache = {};
  
  Future<Exercise?> _getCachedExerciseFuture(String exerciseId) {
    if (!_exerciseFutureCache.containsKey(exerciseId)) {
      _exerciseFutureCache[exerciseId] = ExerciseDataService.getExerciseById(exerciseId)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('Dashboard: Timeout loading exercise $exerciseId');
              return null;
            },
          )
          .catchError((error) {
            debugPrint('Dashboard: Error loading exercise $exerciseId: $error');
            return null;
          });
    }
    return _exerciseFutureCache[exerciseId]!;
  }
  
  Future<Treatment?> _getCachedTreatmentFuture(String treatmentId) {
    if (!_treatmentFutureCache.containsKey(treatmentId)) {
      _treatmentFutureCache[treatmentId] = ExerciseDataService.getTreatmentById(treatmentId)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('Dashboard: Timeout loading treatment $treatmentId');
              return null;
            },
          )
          .catchError((error) {
            debugPrint('Dashboard: Error loading treatment $treatmentId: $error');
            return null;
          });
    }
    return _treatmentFutureCache[treatmentId]!;
  }

  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    _animationController = PocketPTAnimations.createController(
      this,
      duration: PocketPTAnimations.medium,
    );
    // Trigger lazy load of full dataset for Dashboard only
    _loadData();
    // Listen for rehabilitation plan changes
    UserDataNotifier.instance.addListener(_onRehabilitationPlanChanged);
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    UserDataNotifier.instance.removeListener(_onRehabilitationPlanChanged);
    // Unload full dataset when leaving Dashboard to reduce memory usage
    DataPersistenceService.instance.unloadUserData();
    super.dispose();
  }
  
  void _onRehabilitationPlanChanged() {
    // Clear caches when plans change to ensure fresh data
    _exerciseFutureCache.clear();
    _treatmentFutureCache.clear();
    
    // Defer setState to avoid calling during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // Trigger rebuild when rehabilitation plans change
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 40),
            const SizedBox(height: 12),
            Text(_loadError!, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    final data = _gatherDashboardData();

    // Refresh notifications based on current globals (deferred to post-frame to avoid setState during build)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _refreshNotifications();
      }
    });

    final hasCompletedAssessment = data['hasCompletedAssessment'] ?? false;
    if (!hasCompletedAssessment) {
      return _buildAssessmentRequiredState(context);
    }

    return _buildNewDashboardContent(context, data);
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      await DataPersistenceService.instance.loadUserDataIfNeeded();
      // Initialize notifier once data is available
      UserDataNotifier.instance.initialize();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
      _scheduleDashboardTutorial();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = 'Failed to load dashboard data. Please try again.';
      });
    }
  }

  void _scheduleDashboardTutorial() {
    if (_tutorialScheduled) {
      return;
    }
    _tutorialScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _isLoading) {
        _tutorialScheduled = false;
        return;
      }

      await TutorialPreferences.instance.ensureInitialized();
      if (!mounted) {
        _tutorialScheduled = false;
        return;
      }
      
      if (!TutorialPreferences.instance.tutorialsEnabled) {
        return;
      }

      if (TutorialPreferences.instance.isFlowCompleted('onboarding_dashboard')) {
        return;
      }

      if (!mounted) {
        _tutorialScheduled = false;
        return;
      }
      
      await TutorialService.instance.startFlow(context, 'onboarding_dashboard');
    });
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

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ResponsiveDialog(
          title: 'Notifications',
          icon: Icons.notifications,
          content: (_computedNotifications.isEmpty && notifications.isEmpty)
              ? Text(
                  'No new notifications',
                  style: GoogleFonts.ptSans(
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? Colors.white70 
                        : kTextNormal,
                  ),
                  textAlign: TextAlign.center,
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
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
                            color: Theme.of(context).brightness == Brightness.dark 
                                ? Theme.of(context).colorScheme.surface.withOpacity(0.5)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.white.withOpacity(0.1)
                                  : Colors.grey.withOpacity(0.3),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.campaign, 
                                color: Theme.of(context).brightness == Brightness.dark 
                                    ? Colors.white70 
                                    : const Color(0xFF557A95),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  notification, 
                                  style: GoogleFonts.ptSans(
                                    fontSize: 15,
                                    color: Theme.of(context).brightness == Brightness.dark 
                                        ? Colors.white70 
                                        : kTextNormal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: kTextNormal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(
                'Close',
                style: GoogleFonts.ptSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        );
      },
    );
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
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => PreRecordPage(),
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All exercises completed for today!')),
      );
    }
  }

  Widget _buildAssessmentRequiredState(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(16),
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
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF557A95).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundImage: AssetImage('assets/images/pfp/${UserDataNotifier.instance.profilePicture}'),
                        backgroundColor: Colors.grey[200],
                        onBackgroundImageError: (exception, stackTrace) {
                          debugPrint('Dashboard: Error loading profile picture: $exception');
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF7A7A7A),
                            ),
                          ),
                          Text(
                            '${UserDataNotifier.instance.firstName} ${UserDataNotifier.instance.lastName}',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2E2E2E),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: TutorialAnchors.dashboardNotifications,
                      onPressed: () => _showNotificationsDialog(context),
                      icon: const Badge(
                        smallSize: 8,
                        backgroundColor: Color(0xFFC1574F),
                        child: Icon(Icons.notifications_active, 
                          color: Color(0xFF557A95)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Assessment Required Card
              Container(
                margin: const EdgeInsets.only(bottom: 18),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF800020).withOpacity(0.9),
                      const Color(0xFFB22222),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.assignment,
                            size: 30,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Assessment Required',
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please complete the assessment to generate your personalized rehabilitation plan.',
                                style: GoogleFonts.ptSans(
                                  fontSize: 15,
                                  color: Colors.white.withOpacity(0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
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
                          foregroundColor: const Color(0xFF800020),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 3,
                        ),
                        child: Text(
                          'Take Assessment Now',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNewDashboardContent(BuildContext context, Map<String, dynamic> data) {
    try {
      // Note: UserDataNotifier is already initialized in _loadData(), so we don't need to initialize here
      // Defer heavy operations to after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          if (mounted) {
            _maybeShowDailyAssessmentDialog(context);
            await _maybeShowDailyPainChangeDialog(context);
            _maybeShowRegeneratePlanDialog(context);
          }
        } catch (e) {
          debugPrint('Dashboard: Error in post-frame callbacks: $e');
        }
      });
      
      // Get current exercise directly from rehabilitation plans
      final rehabilitationPlans = UserDataNotifier.instance.rehabPlans.isNotEmpty 
          ? UserDataNotifier.instance.rehabPlans 
          : UserRehabilitation.instance.rehabPlans;
      
      ExerciseReference? currentExerciseRef;
      if (rehabilitationPlans.isNotEmpty && rehabilitationPlans.first.exerciseReferences.isNotEmpty) {
        currentExerciseRef = rehabilitationPlans.first.exerciseReferences.first;
      }
      
      double progress = 0.0;
      try {
        progress = ExerciseHistory.calculateTodaysProgressPercentage();
      } catch (e) {
        debugPrint('Dashboard: Error calculating progress: $e');
        progress = 0.0;
      }

      return Scaffold(
      backgroundColor: const Color(0xFFF8F6F4),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: AnimationLimiter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Profile Header
              Container(
                padding: const EdgeInsets.all(16),
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
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF557A95).withOpacity(0.3),
                          width: 2,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 32,
                        backgroundImage: AssetImage('assets/images/pfp/${UserDataNotifier.instance.profilePicture}'),
                        backgroundColor: Colors.grey[200],
                        onBackgroundImageError: (exception, stackTrace) {
                          debugPrint('Dashboard: Error loading profile picture: $exception');
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back,',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: const Color(0xFF7A7A7A),
                            ),
                          ),
                          Text(
                            '${UserDataNotifier.instance.firstName} ${UserDataNotifier.instance.lastName}',
                            style: GoogleFonts.poppins(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF2E2E2E),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF557A95).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.local_fire_department, 
                                          color: Colors.orange, size: 18),
                                        const SizedBox(width: 4),
                                        Text(
                                          UserProgress.title,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: const Color(0xFF557A95),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: TutorialAnchors.dashboardNotifications,
                      onPressed: () => _showNotificationsDialog(context),
                      icon: const Badge(
                        smallSize: 8,
                        backgroundColor: Color(0xFFC1574F),
                        child: Icon(Icons.notifications_active, 
                          color: Color(0xFF557A95)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              
              // Progress Card
              Container(
                constraints: const BoxConstraints(minHeight: 220),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  image: const DecorationImage(
                    image: AssetImage('assets/images/exercise/exercise.jpg'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.black.withOpacity(0.6),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: SizedBox(
                    height: 220,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'PROGRESS',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Use FutureBuilder to load actual exercise data
                                FutureBuilder<Exercise?>(
                                  key: currentExerciseRef != null 
                                      ? ValueKey('exercise_${currentExerciseRef.exerciseId}')
                                      : const ValueKey('exercise_null'),
                                  future: currentExerciseRef != null 
                                      ? _getCachedExerciseFuture(currentExerciseRef.exerciseId)
                                      : Future.value(null),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return Text(
                                        'Loading...',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 22,
                                          color: Colors.white,
                                        ),
                                      );
                                    }
                                    
                                    if (snapshot.hasError) {
                                      return Text(
                                        'Error loading exercise',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 22,
                                          color: Colors.white,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    }
                                    
                                    final exercise = snapshot.data;
                                    return Text(
                                      exercise?.exerciseName ?? 'No Exercise',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 22,
                                        color: Colors.white,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    );
                                  },
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  UserAssess.specificMuscle.isNotEmpty
                                      ? UserAssess.specificMuscle
                                      : 'No target muscle',
                                  style: GoogleFonts.ptSans(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                                Text(
                                  currentExerciseRef != null
                                      ? '${currentExerciseRef.sets} sets: ${currentExerciseRef.repetitions} reps'
                                      : 'No set info',
                                  style: GoogleFonts.ptSans(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      height: 60,
                                      width: 60,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.2),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(6.0),
                                        child: CircularProgressIndicator(
                                          value: progress,
                                          strokeWidth: 6,
                                          backgroundColor: Colors.white.withOpacity(0.3),
                                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${(progress * 100).toInt()}%',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                                InkWell(
                                  key: TutorialAnchors.dashboardProgressCta,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) =>
                                            PreRecordPage(),
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
                                  borderRadius: BorderRadius.circular(30),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF709255),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF709255).withOpacity(0.3),
                                          offset: const Offset(0, 4),
                                          blurRadius: 10,
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      progress == 0 ? 'Start >' : 'Resume >',
                                      style: GoogleFonts.ptSans(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    ),
                  ),
                ),
              ),

              // Stats Cards
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoCard(
                    title: 'Streak',
                    value: '${UserProgress.streak} day(s)',
                    icon: Icons.local_fire_department,
                    backgroundColor: const Color(0xFFFFF3E0),
                    iconColor: Colors.deepOrange,
                  ),
                  _buildInfoCard(
                    title: 'Exercises',
                    value: '${UserProgress.totalExercises}',
                    icon: Icons.fitness_center,
                    backgroundColor: const Color(0xFFE3F2FD),
                    iconColor: Colors.blueAccent,
                  ),
                  _buildInfoCard(
                    title: 'Time Spent',
                    value: '${UserProgress.totalMinutes} min(s)',
                    icon: Icons.timer,
                    backgroundColor: const Color(0xFFE8F5E9),
                    iconColor: Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // // CNN Demo Section
              // Container(
              //   margin: const EdgeInsets.only(bottom: 20),
              //   padding: const EdgeInsets.all(20),
              //   decoration: BoxDecoration(
              //     gradient: LinearGradient(
              //       begin: Alignment.topLeft,
              //       end: Alignment.bottomRight,
              //       colors: [
              //         Colors.blue.withOpacity(0.9),
              //         Colors.blueAccent,
              //       ],
              //     ),
              //     borderRadius: BorderRadius.circular(20),
              //     boxShadow: [
              //       BoxShadow(
              //         color: Colors.blue.withOpacity(0.2),
              //         blurRadius: 10,
              //         offset: const Offset(0, 6),
              //       ),
              //     ],
              //   ),
              //   child: Column(
              //     children: [
              //       Row(
              //         crossAxisAlignment: CrossAxisAlignment.start,
              //         children: [
              //           Container(
              //             padding: const EdgeInsets.all(10),
              //             decoration: BoxDecoration(
              //               color: Colors.white.withOpacity(0.2),
              //               shape: BoxShape.circle,
              //             ),
              //             child: const Icon(
              //               Icons.psychology,
              //               size: 30,
              //               color: Colors.white,
              //             ),
              //           ),
              //           const SizedBox(width: 16),
              //           Expanded(
              //             child: Column(
              //               crossAxisAlignment: CrossAxisAlignment.start,
              //               children: [
              //                 Text(
              //                   'CNN Pose Demo',
              //                   style: GoogleFonts.poppins(
              //                     fontSize: 20,
              //                     fontWeight: FontWeight.w700,
              //                     color: Colors.white,
              //                   ),
              //                 ),
              //                 const SizedBox(height: 8),
              //                 Text(
              //                   'Try the new CNN-based pose estimation for pain assessment.',
              //                   style: GoogleFonts.ptSans(
              //                     fontSize: 15,
              //                     color: Colors.white.withOpacity(0.9),
              //                   ),
              //                 ),
              //               ],
              //             ),
              //           ),
              //         ],
              //       ),
              //       const SizedBox(height: 20),
              //       SizedBox(
              //         width: double.infinity,
              //         child: ElevatedButton(
              //           onPressed: () {
              //             // TODO: Uncomment when CNNCameraPosePage is available
              //             // Navigator.push(
              //             //   context,
              //             //   MaterialPageRoute(
              //             //     builder: (context) => const CNNCameraPosePage(),
              //             //   ),
              //             // );
              //             ScaffoldMessenger.of(context).showSnackBar(
              //               const SnackBar(content: Text('CNN Demo coming soon!')),
              //             );
              //           },
              //           style: ElevatedButton.styleFrom(
              //             backgroundColor: Colors.white,
              //             foregroundColor: Colors.blue,
              //             padding: const EdgeInsets.symmetric(vertical: 14),
              //             shape: RoundedRectangleBorder(
              //               borderRadius: BorderRadius.circular(12),
              //             ),
              //           ),
              //           child: Text(
              //             'Try CNN Demo',
              //             style: GoogleFonts.poppins(
              //               fontSize: 16,
              //               fontWeight: FontWeight.w600,
              //             ),
              //           ),
              //         ),
              //       ),
              //     ],
              //   ),
              // ),

              // Your Plan Section
              Text(
                'Your Plan',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF2E2E2E),
                ),
              ),
              const SizedBox(height: 14),
              Column(
                children: UserRehabilitation.instance.rehabPlans.isEmpty
                    ? [
                        // Assessment Required Card
                        Container(
                          margin: const EdgeInsets.only(bottom: 18),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                const Color(0xFF800020).withOpacity(0.9),
                                const Color(0xFFB22222),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.assignment,
                                      size: 30,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Assessment Required',
                                          style: GoogleFonts.poppins(
                                            fontSize: 20,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Please complete the assessment to generate your personalized rehabilitation plan.',
                                          style: GoogleFonts.ptSans(
                                            fontSize: 15,
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
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
                                    foregroundColor: const Color(0xFF800020),
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 3,
                                  ),
                                  child: Text(
                                    'Take Assessment Now',
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ]
                    : UserRehabilitation.instance.rehabPlans.map((plan) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 18),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey.shade300),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox(
                                  height: 80,
                                  width: 80,
                                  child: Image.asset(
                                    'assets/images/exercise/exercise.jpg',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Week ${plan.weekNumber.toString().padLeft(2, '0')}',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 18,
                                        color: const Color(0xFF333333),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ...plan.exerciseReferences.map(
                                      (exerciseRef) => FutureBuilder<Exercise?>(
                                        key: ValueKey('exercise_${exerciseRef.exerciseId}'),
                                        future: _getCachedExerciseFuture(exerciseRef.exerciseId),
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState == ConnectionState.waiting) {
                                            return const Row(
                                              children: [
                                                SizedBox(
                                                  width: 16,
                                                  height: 16,
                                                  child: CircularProgressIndicator(strokeWidth: 2),
                                                ),
                                                SizedBox(width: 8),
                                                Text('Loading...', style: TextStyle(fontSize: 12)),
                                              ],
                                            );
                                          }
                                          if (snapshot.hasError) {
                                            return Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.error_outline,
                                                  size: 18,
                                                  color: Colors.red.shade300,
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    'Error loading exercise ${exerciseRef.exerciseId}',
                                                    style: GoogleFonts.ptSans(
                                                      color: Colors.red.shade300,
                                                      fontSize: 12,
                                                    ),
                                                    softWrap: true,
                                                  ),
                                                ),
                                              ],
                                            );
                                          }
                                          final exerciseName = snapshot.hasData && snapshot.data != null
                                              ? snapshot.data!.exerciseName
                                              : 'Exercise ${exerciseRef.exerciseId}';
                                          
                                          return Row(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                Icons.fitness_center,
                                                size: 18,
                                                color: const Color(0xFF8B2E2E),
                                              ),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  exerciseName,
                                                  style: GoogleFonts.ptSans(
                                                    color: const Color(0xFF7A7A7A),
                                                    fontSize: 14,
                                                  ),
                                                  softWrap: true,
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    ),
                                    // Add treatments if available
                                    if (UserRehabilitation.instance.treatmentReferences != null && 
                                        UserRehabilitation.instance.treatmentReferences!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      ...UserRehabilitation.instance.treatmentReferences!.map(
                                        (treatmentRef) => FutureBuilder<Treatment?>(
                                          key: ValueKey('treatment_${treatmentRef.treatmentId}'),
                                          future: _getCachedTreatmentFuture(treatmentRef.treatmentId),
                                          builder: (context, snapshot) {
                                            if (snapshot.connectionState == ConnectionState.waiting) {
                                              return const Row(
                                                children: [
                                                  SizedBox(
                                                    width: 16,
                                                    height: 16,
                                                    child: CircularProgressIndicator(strokeWidth: 2),
                                                  ),
                                                  SizedBox(width: 8),
                                                  Text('Loading...', style: TextStyle(fontSize: 12)),
                                                ],
                                              );
                                            }
                                            if (snapshot.hasError) {
                                              return Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Icon(
                                                    Icons.error_outline,
                                                    size: 18,
                                                    color: Colors.red.shade300,
                                                  ),
                                                  const SizedBox(width: 6),
                                                  Expanded(
                                                    child: Text(
                                                      'Error loading treatment ${treatmentRef.treatmentId}',
                                                      style: GoogleFonts.ptSans(
                                                        color: Colors.red.shade300,
                                                        fontSize: 12,
                                                      ),
                                                      softWrap: true,
                                                    ),
                                                  ),
                                                ],
                                              );
                                            }
                                            final treatmentName = snapshot.hasData && snapshot.data != null
                                                ? snapshot.data!.treatmentName
                                                : 'Treatment ${treatmentRef.treatmentId}';
                                            
                                            return Row(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Icon(
                                                  Icons.medical_services,
                                                  size: 18,
                                                  color: const Color(0xFF8B2E2E),
                                                ),
                                                const SizedBox(width: 6),
                                                Expanded(
                                                  child: Text(
                                                    treatmentName,
                                                    style: GoogleFonts.ptSans(
                                                      color: const Color(0xFF7A7A7A),
                                                      fontSize: 14,
                                                    ),
                                                    softWrap: true,
                                                  ),
                                                ),
                                              ],
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
              ),
            ],
            ),
          ),
        ),
      ),
    );
    } catch (e, stackTrace) {
      debugPrint('Dashboard: Error building new dashboard content: $e');
      debugPrint('Dashboard: Stack trace: $stackTrace');
      // Return a safe fallback UI
      return Scaffold(
        backgroundColor: const Color(0xFFF8F6F4),
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Error loading dashboard',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'Please try refreshing or contact support if the issue persists.',
                    style: GoogleFonts.ptSans(
                      fontSize: 14,
                      color: const Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isLoading = true;
                    });
                    _loadData();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B2E2E),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    'Retry',
                    style: GoogleFonts.ptSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 28),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
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
      // Calculate today's progress percentage
      double progress = 0.0;
      try {
        progress = ExerciseHistory.calculateTodaysProgressPercentage();
      } catch (e) {
        debugPrint('Dashboard: Error calculating progress in notifications: $e');
        progress = 0.0;
      }
      
      // Suppose we infer started-but-not-finished if there is a DailyProgress today with any false
      final plan = UserRehabilitation.instance.rehabPlans.first;
      final today = DateTime.now();
      final todayProgress = plan.daily.where((d) => d.date.year == today.year && d.date.month == today.month && d.date.day == today.day).toList();
      if (todayProgress.isEmpty) {
        // Only show reminder if progress is less than 100%
        if (progress < 1.0) {
          dynamicNotes.add(NotificationItem(
            text: '📋 Reminder: Complete today\'s exercises.',
            actionType: 'start_exercise',
          ));
        }
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




  void _showDailyAssessmentDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return ResponsiveDialog(
          title: 'Daily Re-Assessment Required',
          icon: Icons.assignment,
          content: Text(
            'Please complete today\'s quick pain re-assessment.',
            style: GoogleFonts.ptSans(
              fontSize: 16,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white70 
                  : kTextNormal,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              style: TextButton.styleFrom(
                foregroundColor: kTextNormal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: Text(
                'Later',
                style: GoogleFonts.ptSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const InstructionVideoPage()),
                );
              },
              child: Text(
                'Start',
                style: GoogleFonts.ptSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
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
      _showDailyAssessmentDialog(context);
    }
  }

  Future<void> _maybeShowDailyPainChangeDialog(BuildContext context) async {
    if (!UserSettings.isDailyReminder) return;

    // Ensure there is a baseline entry for today using current UserAssess state
    if (PainHistory.todaysEntry() == null) {
      try {
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text('Saving pain data...'),
                ],
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
        
        await PainHistory.recordTodayAndSave(
          painScale: UserAssess.painScale,
          painLevel: UserAssess.painLevel.isEmpty ? UserAssess.painScale.toString() : UserAssess.painLevel,
        );
        
        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Pain data saved successfully'),
                ],
              ),
              backgroundColor: Color(0xFF10B981),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        // Show error feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Failed to save pain data: ${e.toString()}')),
                ],
              ),
              backgroundColor: const Color(0xFFEF4444),
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => _maybeShowDailyPainChangeDialog(context),
              ),
            ),
          );
        }
      }
    }

    if (PainHistory.shouldPromptForRetake()) {
      PainHistory.markPromptedToday();
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return ResponsiveDialog(
            title: 'Daily Pain Check',
            icon: Icons.health_and_safety,
            content: Text(
              'Your pain level seems different today. Would you like to retake the quick pain assessment now?',
              style: GoogleFonts.ptSans(
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white70 
                    : kTextNormal,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: kTextNormal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: Text(
                  'Later',
                  style: GoogleFonts.ptSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMainColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
                child: Text(
                  'Retake Now',
                  style: GoogleFonts.ptSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  void _showRegeneratePlanDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return ResponsiveDialog(
          title: 'Regenerate Plan?',
          icon: Icons.autorenew,
          content: Text(
            'Your pain level has been unchanged for 7 days. Would you like to regenerate a new rehabilitation plan and treatments?',
            style: GoogleFonts.ptSans(
              fontSize: 16,
              color: Theme.of(context).brightness == Brightness.dark 
                  ? Colors.white70 
                  : kTextNormal,
              height: 1.5,
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                PainHistory.markPromptedToday();
                Navigator.of(ctx).pop();
              },
              child: Text(
                'Not Now',
                style: GoogleFonts.ptSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: kMainColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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
              child: Text(
                'Regenerate',
                style: GoogleFonts.ptSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
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
          return ResponsiveDialog(
            title: 'Regenerate Plan?',
            icon: Icons.autorenew,
            content: Text(
              'Your pain level has been unchanged for 7 days. Would you like to regenerate a new rehabilitation plan and treatments?',
              style: GoogleFonts.ptSans(
                fontSize: 16,
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white70 
                    : kTextNormal,
                height: 1.5,
              ),
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[600],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  // Mark as dismissed for today
                  PainHistory.markPromptedToday();
                  Navigator.of(ctx).pop();
                },
                child: Text(
                  'Not Now',
                  style: GoogleFonts.ptSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kMainColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
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
                child: Text(
                  'Regenerate',
                  style: GoogleFonts.ptSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
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
          otherMuscles: exercise.otherMuscles,
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