import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'assessment/globals.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'data/rehabilitation_plan.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  // Sample notifications data
  List<String> notifications = UserDetails.notifications;

  // Function to show notifications dialog
  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Notifications',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w900),
          ),
          content: notifications.isEmpty
              ? Text('No new notifications', style: GoogleFonts.poppins())
              : SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: notifications
                        .map((notification) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: Colors.grey.shade200,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.notifications, color: Colors.blue, size: 28),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        notification,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ))
                        .toList(),
                  ),
              ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Close', style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {    
    final rehabPlans = UserRehabilitation.instance.rehabPlans;
    final rehabPlan = rehabPlans.isNotEmpty ? rehabPlans.first : null;
    final currentExercise = rehabPlan?.exercises.isNotEmpty == true ? rehabPlan!.exercises.first : null;    
    // double progress = currentExercise != null ? currentExercise.progress : 0.0;
    double progress = currentExercise != null ? 0.0 : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Profile Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image
                  Container(
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: const Color(0xFF5E5E5E),
                        width: 2,
                      ),
                      image: const DecorationImage(
                        image: AssetImage('../../assets/images/profile/profile.jpg'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Right side: Texts and Icons
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // First row: Name and bell icon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start, // Align all children to the left
                              children: [
                                Text(
                                  'YURI BROWN',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 20,
                                  ),
                                ),
                                const SizedBox(height: 0),
                                Row(
                                  mainAxisSize: MainAxisSize.min, // Prevent Row from expanding full width
                                  children: [
                                    const Icon(Icons.bolt, color: Colors.green, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      UserProgress.title,
                                      style: GoogleFonts.ptSans(fontSize: 14),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            GestureDetector(
                              onTap: () {
                                _showNotificationsDialog(context); // Show notifications when tapped
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey,
                                ),
                                child: const Icon(Icons.notifications, color: Colors.white),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Other UI elements (e.g., Progress Container, Stats, etc.)
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
                        Expanded(
                          child: Text(
                            'PROGRESS',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                              letterSpacing: 1.2,
                              color: const Color(0xFF5B5B5B),
                            ),
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currentExercise?.exerciseName ?? 'No Exercise',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w800,
                                fontSize: 26,
                                color: const Color(0xFF2E2E2E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              UserAssess.specificMuscle.isNotEmpty ? UserAssess.specificMuscle : 'No target muscle',
                              style: GoogleFonts.ptSans(
                                fontSize: 16,
                                color: const Color(0xFF557A95),
                              ),
                            ),
                            Text(
                              currentExercise != null ? '${currentExercise.sets} sets: ${currentExercise.repetitions} reps' : 'No set info',
                              style: GoogleFonts.ptSans(
                                fontSize: 14,
                                color: const Color(0xFF5B5B5B),
                              ),
                            ),
                          ],
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
                            Navigator.pushNamed(context, '/exercisePage', arguments: currentExercise);
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
                  // Left Column (30%)
                  Expanded(
                    flex: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.15),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.local_fire_department, color: Colors.orange, size: 20),
                              const SizedBox(width: 6),
                              Text(
                                'Streak',
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                  color: const Color(0xFF2E2E2E),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${UserProgress.streak}',
                            style: GoogleFonts.poppins(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF8B2E2E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.center,
                            child: Text(
                              'Days of Workout',
                              style: GoogleFonts.ptSans(
                                fontSize: 14,
                                color: const Color(0xFF5B5B5B),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Right Column (70%)
                  Expanded(
                    flex: 7,
                    child: Column(
                      children: [
                        // Exercises Card
                        Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.fitness_center, size: 28, color: Color(0xFF8B2E2E)), // main color
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Exercises',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: const Color(0xFF2E2E2E),
                                    ),
                                  ),
                                  Text(
                                    '${UserProgress.totalExercises} Completed Exercises',
                                    style: GoogleFonts.ptSans(
                                      fontSize: 14,
                                      color: const Color(0xFF5B5B5B),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Time Spent Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, size: 28, color: Color(0xFFC1574F)), // sub-color
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Time Spent',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: const Color(0xFF2E2E2E),
                                    ),
                                  ),
                                  Text(
                                    '${UserProgress.totalMinutes} Minutes',
                                    style: GoogleFonts.ptSans(
                                      fontSize: 14,
                                      color: const Color(0xFF5B5B5B),
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
                ],
              ),
              const SizedBox(height: 20),

              // 4. Your Plan
              Text('Your Plan', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 75,
                        width: 100,
                        child: Image.asset(
                          '../../assets/images/welcome_1.jpg',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Week 01',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Push-Ups: 3 sets, 10 reps',
                            style: GoogleFonts.ptSans(
                              color: const Color(0xFF5B5B5B),
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            'Sit-Ups: 3 sets, 15 reps',
                            style: GoogleFonts.ptSans(
                              color: const Color(0xFF5B5B5B),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      height: 60,
                      width: 60,
                      child: CircularPercentIndicator(
                        radius: 28.0,
                        lineWidth: 5.0,
                        percent: 0.7,
                        center: Text(
                          "70%",
                          style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                        progressColor: const Color(0xFF8B2E2E),
                        backgroundColor: Colors.grey.shade300,
                        circularStrokeCap: CircularStrokeCap.round,
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
}