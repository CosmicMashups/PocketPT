import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:pocketpt/record/pre_record_page.dart';
import '../data/globals.dart';
// import 'package:percent_indicator/percent_indicator.dart';
import '../data/rehabilitation_plan.dart';


class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  List<String> notifications = UserDetails.notifications;

  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color(0xFFF1F1F1),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.notifications, color: Color(0xFF557A95)),
              const SizedBox(width: 8),
              Text('Notifications', style: GoogleFonts.poppins(fontWeight: FontWeight.w800)),
            ],
          ),
          content: notifications.isEmpty
              ? Text('No new notifications', style: GoogleFonts.poppins())
              : SingleChildScrollView(
                  child: Column(
                    children: notifications
                        .map((notification) => Container(
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
                            ))
                        .toList(),
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

  // Widget: Info Card
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: iconColor),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: const Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.ptSans(
                  fontSize: 14,
                  color: const Color(0xFF7A7A7A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rehabPlans = UserRehabilitation.instance.rehabPlans;
    final rehabPlan = rehabPlans.isNotEmpty ? rehabPlans.first : null;
    final currentExercise = rehabPlan?.exercises.isNotEmpty == true ? rehabPlan!.exercises.first : null;
    double progress = currentExercise != null ? 0.0 : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: const AssetImage('assets/images/profile/profile.jpg'),
                    backgroundColor: Colors.grey[200],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${UserDetails.firstName.toUpperCase()} ${UserDetails.lastName.toUpperCase()}',
                          style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                        Row(
                          children: [
                            const Icon(Icons.local_fire_department, color: Colors.orange, size: 18),
                            const SizedBox(width: 4),
                            Text(UserProgress.title, style: GoogleFonts.poppins(fontSize: 14)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _showNotificationsDialog(context),
                    icon: const Icon(Icons.notifications_active),
                    color: Color(0xFF557A95),
                  )
                ],
              ),
              const SizedBox(height: 30),

              // 2. Progress Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF9F8F7), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: Color(0xFFDEDAD6)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Top Header Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Static 'PROGRESS' Text
                        Text(
                          'PROGRESS',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                            letterSpacing: 1.2,
                            color: const Color(0xFF5B5B5B),
                          ),
                        ),
                        const SizedBox(width: 8), // Small space between 'PROGRESS' and exercise name
                        
                        /// Expanded space for exercise details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end, // Align text to the right
                            children: [
                              // Exercise Name Text with maxLines and overflow handling
                              Align(
                                alignment: Alignment.centerRight, // Align the text to the right
                                child: Text(
                                  currentExercise?.exerciseName ?? 'No Exercise',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 26,
                                    color: const Color(0xFF2E2E2E),
                                  ),
                                  maxLines: 2, // Allows the text to span across two lines if needed
                                  overflow: TextOverflow.ellipsis, // Ensures text is truncated with '...' if it overflows
                                  textAlign: TextAlign.right, // Aligns text to the right
                                ),
                              ),
                              const SizedBox(height: 4),
                              // Specific Muscle Text
                              Text(
                                UserAssess.specificMuscle.isNotEmpty ? UserAssess.specificMuscle : 'No target muscle',
                                style: GoogleFonts.ptSans(
                                  fontSize: 16,
                                  color: const Color(0xFF557A95),
                                ),
                              ),
                              // Set and Repetition Information
                              Text(
                                currentExercise != null
                                    ? '${currentExercise.sets} sets: ${currentExercise.repetitions} reps'
                                    : 'No set info',
                                style: GoogleFonts.ptSans(
                                  fontSize: 14,
                                  color: const Color(0xFF5B5B5B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

                    /// Progress & Resume Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        /// Progress Circle
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              height: 66,
                              width: 66,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFFF8F6F4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.15),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(6.0), // Prevents the indicator from clipping
                                child: CircularProgressIndicator(
                                  value: progress, // must be between 0.0 and 1.0
                                  strokeWidth: 6,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: const AlwaysStoppedAnimation(Color(0xFFC1574F)),
                                ),
                              ),
                            ),
                            Text(
                              '${(progress * 100).toInt()}%',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: const Color(0xFF2E2E2E),
                              ),
                            ),
                          ],
                        ),

                        /// Resume Button
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (context, animation, secondaryAnimation) => PreRecordPage(),
                                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                  // SlideTransition
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
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
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
                              'Resume >',
                              style: GoogleFonts.ptSans(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
              const SizedBox(height: 20),

              // 3. Streak and Stats
              Row(
                children: [
                  // Left Column – Streak
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFE6E6), Color(0xFFFFF5F5)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.1),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // const Icon(Icons.local_fire_department, color: Colors.deepOrange, size: 24),
                              // const SizedBox(width: 6),
                              Text(
                                'Streak',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: const Color(0xFF2E2E2E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            '${UserProgress.streak}',
                            style: GoogleFonts.poppins(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFFB12E2E),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Day(s) of Workout',
                            style: GoogleFonts.ptSans(
                              fontSize: 14,
                              color: const Color(0xFF6B6B6B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  // Right Column – Stats
                  Expanded(
                    flex: 7,
                    child: Column(
                      children: [
                        // Exercises Card
                        _buildInfoCard(
                          icon: Icons.fitness_center,
                          title: 'Exercises Done',
                          value: '${UserProgress.totalExercises} Completed',
                          iconColor: const Color(0xFF8B2E2E),
                        ),

                        const SizedBox(height: 12),

                        // Time Spent Card
                        _buildInfoCard(
                          icon: Icons.schedule,
                          title: 'Time Spent',
                          value: '${UserProgress.totalMinutes} Minute(s)',
                          iconColor: const Color(0xFFC1574F),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4. Your Plan
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
                children: UserRehabilitation.instance.rehabPlans.map((plan) {
                  // // Calculate total sets
                  // final totalSets = plan.exercises.fold<int>(0, (sum, ex) => sum + ex.sets);

                  // // Calculate completed sets from DailyProgress
                  // int completedSets = 0;
                  // for (final progress in plan.daily) {
                  //   for (final entry in progress.completedExercises.entries) {
                  //     if (entry.value) {
                  //       final matchingExercise = plan.exercises.firstWhere(
                  //         (ex) => ex.exerciseId == entry.key,
                  //         orElse: () => Exercise(
                  //           exerciseId: '',
                  //           exerciseName: '',
                  //           description: '',
                  //           muscle: '',
                  //           painLevel: '',
                  //           goal: '',
                  //           repetitions: 0,
                  //           sets: 0,
                  //           imageUrl: '',
                  //           videoUrl: '',
                  //         ),
                  //       );
                  //       completedSets += matchingExercise.sets;
                  //     }
                  //   }
                  // }

                  // final percent = totalSets == 0 ? 0.0 : completedSets / totalSets;

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
                        // Plan Image
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
                              // List Exercises for this Plan
                              ...plan.exercises.map((exercise) => Row(
                                    children: [
                                      Icon(
                                        Icons.fitness_center,
                                        size: 18,
                                        color: const Color(0xFF8B2E2E),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        exercise.exerciseName,
                                        style: GoogleFonts.ptSans(
                                          color: const Color(0xFF7A7A7A),
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  )),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Progress Indicator
                        // SizedBox(
                        //   height: 65,
                        //   width: 65,
                        //   child: CircularPercentIndicator(
                        //     radius: 30.0,
                        //     lineWidth: 6.0,
                        //     percent: percent.clamp(0.0, 1.0),
                        //     center: Text(
                        //       "${(percent * 100).toInt()}%",
                        //       style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                        //     ),
                        //     progressColor: const Color(0xFF8B2E2E),
                        //     backgroundColor: Colors.grey.shade200,
                        //     circularStrokeCap: CircularStrokeCap.round,
                        //   ),
                        // ),
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
  }
}