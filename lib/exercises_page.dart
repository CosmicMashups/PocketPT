import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'exercise_detail.dart';

class Exercise {
  final String id;
  final String name;
  final String description;
  final String muscle;
  final String painLevel;
  final String goal;
  final int rep;
  final int set;
  final String imageUrl;
  final String videoUrl;

  Exercise({
    required this.id,
    required this.name,
    required this.description,
    required this.muscle,
    required this.painLevel,
    required this.goal,
    required this.rep,
    required this.set,
    required this.imageUrl,
    required this.videoUrl,
  });

  factory Exercise.fromCsv(List<dynamic> row) {
    return Exercise(
      id: row[0].toString(),
      name: row[1].toString(),
      description: row[2].toString(),
      muscle: row[3].toString(),
      painLevel: row[4].toString(),
      goal: row[5].toString(),
      rep: int.tryParse(row[6].toString()) ?? 0,
      set: int.tryParse(row[7].toString()) ?? 0,
      imageUrl: row[8].toString(),
      videoUrl: row[9].toString(),
    );
  }
}

class ExercisesPage extends StatefulWidget {
  const ExercisesPage({super.key});

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  late Future<List<Exercise>> exercisesFuture;

  @override
  void initState() {
    super.initState();
    exercisesFuture = loadCSVData();
  }

  Future<List<Exercise>> loadCSVData() async {
    try {
      final data = await rootBundle.loadString('assets/data/exercises.csv'); // Make sure this path is correct in pubspec.yaml
      List<List<dynamic>> csvData = const CsvToListConverter().convert(data);

      return csvData.skip(1).map((row) => Exercise.fromCsv(row)).toList();
    } catch (e) {
      throw Exception("Failed to load exercise data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F4),
      appBar: AppBar(
        title: const Text(
          'Exercises',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Color(0xFFF8F6F4),
          ),
        ),
        backgroundColor: const Color(0xFF8B2E2E),
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<Exercise>>(
        future: exercisesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading data'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No exercises found.'));
          }

          List<Exercise> exercises = snapshot.data!;

          return ListView.builder(
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              return ExerciseCard(exercise: exercises[index]);
            },
          );
        },
      ),
    );
  }
}

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;

  const ExerciseCard({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    String imagePath = 'assets/images/exercise/${exercise.imageUrl}';

    return Card(
      margin: const EdgeInsets.all(15),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Color(0xFF557A95), width: 1),
      ),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            imagePath,
            width: 70,
            height: 70,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return const Icon(Icons.error, color: Colors.red);
            },
          ),
        ),
        title: Text(
          exercise.name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E2E2E),
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Muscles: ${exercise.muscle}', style: const TextStyle(color: Color(0xFF5B5B5B))),
              Text('Pain Level: ${exercise.painLevel}', style: const TextStyle(color: Color(0xFF5B5B5B))),
            ],
          ),
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ExerciseDetailPage(exercise: exercise),
            ),
          );
        },
      ),
    );
  }
}