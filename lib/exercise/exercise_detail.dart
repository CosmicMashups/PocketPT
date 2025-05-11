import 'package:flutter/material.dart';
// import 'exercises_page.dart';
import 'exercise_list.dart';

class ExerciseDetailPage extends StatelessWidget {
  final Exercise exercise;

  const ExerciseDetailPage({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    String imagePath = 'assets/images/exercise/${exercise.imageUrl}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          exercise.name,
          style: const TextStyle(
            color: Color(0xFFF8F6F4),
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: const Color(0xFF8B2E2E),
        elevation: 10,
      ),
      backgroundColor: const Color(0xFFF8F6F4),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: ListView(
          children: [
            // Image with rounded corners and shadow
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Image.asset(
                  imagePath,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error, color: Colors.red, size: 100);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Description Section
            Text(
              exercise.description,
              style: const TextStyle(
                fontSize: 18,
                color: Color(0xFF5B5B5B),
                height: 1.6,
                // fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 20),

            // Muscle Group Section
            Row(
              children: [
                const Icon(
                  Icons.fitness_center,
                  color: Color(0xFF8B2E2E),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Muscle Group: ${exercise.muscle}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF5B5B5B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Pain Level Section
            Row(
              children: [
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Color(0xFF8B2E2E),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Pain Level: ${exercise.painLevel}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF5B5B5B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Goal Section
            Row(
              children: [
                Icon(
                  Icons.flag,
                  color: Color(0xFF8B2E2E),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Goal: ${exercise.goal}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF5B5B5B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Repetitions Section
            Row(
              children: [
                const Icon(
                  Icons.loop,
                  color: Color(0xFF8B2E2E),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Repetitions: ${exercise.rep}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF5B5B5B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Sets Section
            Row(
              children: [
                const Icon(
                  Icons.exposure,
                  color: Color(0xFF8B2E2E),
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Sets: ${exercise.set}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF5B5B5B),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Video Section (Only if available)
            if (exercise.videoUrl.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement logic to open video URL (e.g., using url_launcher)
                },
                icon: const Icon(Icons.play_circle_fill, color: Colors.white),
                label: const Text(
                  'Watch Video',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B2E2E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }
}