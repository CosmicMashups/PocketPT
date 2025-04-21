import 'package:flutter/material.dart';
import 'exercises_page.dart';

class ExerciseDetailPage extends StatelessWidget {
  final Exercise exercise;

  const ExerciseDetailPage({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    String imagePath = '../assets/images/exercise/${exercise.imagePath}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          exercise.name,
          style: TextStyle(
            color: Color(0xFFF8F6F4),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF8B2E2E),
      ),
      backgroundColor: Color(0xFFF8F6F4),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: ListView(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                imagePath,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.error, color: Colors.red, size: 100);
                },
              ),
            ),
            SizedBox(height: 20),
            Text(
              exercise.description,
              style: TextStyle(fontSize: 16, color: Color(0xFF5B5B5B)),
            ),
            SizedBox(height: 15),
            Text(
              'Muscles Involved: ${exercise.muscles}',
              style: TextStyle(fontSize: 16, color: Color(0xFF5B5B5B)),
            ),
            SizedBox(height: 10),
            Text(
              'Pain Level: ${exercise.painLevel}',
              style: TextStyle(fontSize: 16, color: Color(0xFF5B5B5B)),
            ),
            SizedBox(height: 10),
            Text(
              'Functional Goal: ${exercise.functionalGoal}',
              style: TextStyle(fontSize: 16, color: Color(0xFF5B5B5B)),
            ),
            SizedBox(height: 20),
            if (exercise.videoLink.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  // Handle navigation to video page / browser
                },
                icon: Icon(Icons.play_circle_fill, color: Color(0xFF8B2E2E)),
                label: Text(
                  'Watch Video',
                  style: TextStyle(color: Color(0xFF8B2E2E)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}