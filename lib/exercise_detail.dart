import 'package:flutter/material.dart';
import 'exercises_page.dart';

class ExerciseDetailPage extends StatelessWidget {
  final Exercise exercise;

  const ExerciseDetailPage({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    String imagePath = '../assets/images/exercise/${exercise.imageUrl}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          exercise.name,
          style: const TextStyle(
            color: Color(0xFFF8F6F4),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF8B2E2E),
      ),
      backgroundColor: const Color(0xFFF8F6F4),
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
                  return const Icon(Icons.error, color: Colors.red, size: 100);
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              exercise.description,
              style: const TextStyle(fontSize: 16, color: Color(0xFF5B5B5B)),
            ),
            const SizedBox(height: 15),
            Text(
              'Muscle Group: ${exercise.muscle}',
              style: const TextStyle(fontSize: 16, color: Color(0xFF5B5B5B)),
            ),
            const SizedBox(height: 10),
            Text(
              'Pain Level: ${exercise.painLevel}',
              style: const TextStyle(fontSize: 16, color: Color(0xFF5B5B5B)),
            ),
            const SizedBox(height: 10),
            Text(
              'Goal: ${exercise.goal}',
              style: const TextStyle(fontSize: 16, color: Color(0xFF5B5B5B)),
            ),
            const SizedBox(height: 10),
            Text(
              'Repetitions: ${exercise.rep}',
              style: const TextStyle(fontSize: 16, color: Color(0xFF5B5B5B)),
            ),
            const SizedBox(height: 10),
            Text(
              'Sets: ${exercise.set}',
              style: const TextStyle(fontSize: 16, color: Color(0xFF5B5B5B)),
            ),
            const SizedBox(height: 20),
            if (exercise.videoUrl.isNotEmpty)
              TextButton.icon(
                onPressed: () {
                  // TODO: Implement logic to open video URL (e.g. using url_launcher)
                },
                icon: const Icon(Icons.play_circle_fill, color: Color(0xFF8B2E2E)),
                label: const Text(
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