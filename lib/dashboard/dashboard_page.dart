import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../record/pre_record_page.dart';
import '../data/globals.dart';
import '../data/rehabilitation_plan.dart';
import '../assessment/preliminary.dart';

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

  @override
  Widget build(BuildContext context) {
    final rehabPlans = UserRehabilitation.instance.rehabPlans;
    final rehabPlan = rehabPlans.isNotEmpty ? rehabPlans.first : null;
    final currentExercise = rehabPlan?.exercises.isNotEmpty == true ? rehabPlan!.exercises.first : null;
    double progress = currentExercise != null ? 0.3 : 0.0;

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
                        backgroundImage: const AssetImage('assets/images/profile/profile.jpg'),
                        backgroundColor: Colors.grey[200],
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
                            '${UserDetails.firstName} ${UserDetails.lastName}',
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
                height: 220,
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
                                Text(
                                  currentExercise?.exerciseName ?? 'No Exercise',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 22,
                                    color: Colors.white,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
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
                                  currentExercise != null
                                      ? '${currentExercise.sets} sets: ${currentExercise.repetitions} reps'
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
                                  onTap: () {
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
                    title: 'Total Exercises',
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
                children: UserAssess.isAssessed == false
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
                                    ...plan.exercises.map(
                                      (exercise) => Row(
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
                                              exercise.exerciseName,
                                              style: GoogleFonts.ptSans(
                                                color: const Color(0xFF7A7A7A),
                                                fontSize: 14,
                                              ),
                                              softWrap: true,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
    );
  }
}