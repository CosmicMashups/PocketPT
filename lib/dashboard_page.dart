import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Profile Header
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Image.asset('assets/profile_banner.jpg'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text(
                        'YURI BROWN',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                      const Spacer(),
                      Column(
                        children: [
                          Icon(Icons.bolt, color: Colors.green),
                          Text(
                            'Initiator',
                            style: GoogleFonts.ptSans(),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey,
                        ),
                        child: const Icon(Icons.notifications, color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 2. Progress Container
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('PROGRESS', style: GoogleFonts.poppins()),
                        const Spacer(),
                        Text('Lateral Raise', style: GoogleFonts.poppins(fontWeight: FontWeight.w900)),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Biceps', style: GoogleFonts.ptSans()),
                            Text('3 sets: 5-10 reps', style: GoogleFonts.ptSans()),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              height: 60,
                              width: 60,
                              child: CircularProgressIndicator(
                                value: 0.6,
                                backgroundColor: Colors.grey[300],
                                color: Colors.green,
                                strokeWidth: 6,
                              ),
                            ),
                            Text('60%', style: GoogleFonts.poppins(fontWeight: FontWeight.w900)),
                          ],
                        ),
                        Text('Resume >', style: GoogleFonts.ptSans(fontWeight: FontWeight.bold)),
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
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.local_fire_department, color: Colors.orange),
                              const SizedBox(width: 6),
                              Text('Streak', style: GoogleFonts.poppins(fontWeight: FontWeight.w900)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('8', style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.w900)),
                          Text('Days of Workout', style: GoogleFonts.ptSans(color: const Color(0xFF5B5B5B))),
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
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.fitness_center),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Exercises', style: GoogleFonts.poppins(fontWeight: FontWeight.w900)),
                                        Text('24 Completed Exercises', style: GoogleFonts.ptSans(color: const Color(0xFF5B5B5B))),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('Time Spent', style: GoogleFonts.poppins(fontWeight: FontWeight.w900)),
                                        Text('72 Minutes', style: GoogleFonts.ptSans(color: const Color(0xFF5B5B5B))),
                                      ],
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
                ],
              ),
              const SizedBox(height: 20),

              // 4. Your Plan
              Text('Your Plan', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset('assets/plan_week01.jpg'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Week 01', style: GoogleFonts.poppins(fontWeight: FontWeight.w900)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Push-Ups: 3 sets, 10 reps', style: GoogleFonts.ptSans(color: const Color(0xFF5B5B5B))),
                            Text('Push-Ups: 3 sets, 10 reps', style: GoogleFonts.ptSans(color: const Color(0xFF5B5B5B))),
                          ],
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
    );
  }
}