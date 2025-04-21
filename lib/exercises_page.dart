import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'exercise_detail.dart';

class Exercise {
  final String name;
  final String description;
  final String muscles;
  final String painLevel;
  final String functionalGoal;
  final String imagePath;
  final String videoLink;

  Exercise({
    required this.name,
    required this.description,
    required this.muscles,
    required this.painLevel,
    required this.functionalGoal,
    required this.imagePath,
    required this.videoLink,
  });
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

  // Load CSV data asynchronously
  Future<List<Exercise>> loadCSVData() async {
    try {
      final data = await rootBundle.loadString('../assets/data/exercises.csv');
      List<List<dynamic>> csvData = CsvToListConverter().convert(data);

      return csvData.skip(1).map((e) {
        return Exercise(
          name: e[0],
          description: e[1],
          muscles: e[2],
          painLevel: e[3],
          functionalGoal: e[4],
          imagePath: e[5], 
          videoLink: e[6],
        );
      }).toList();
    } catch (e) {
      // Handle error if CSV load fails
      throw Exception("Failed to load exercise data");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F6F4), // Background color
      appBar: AppBar(
        title: Text(
          'Exercises',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Color(0xFFF8F6F4)), // Heading color
        ),
        backgroundColor: Color(0xFF8B2E2E), // Main color
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<Exercise>>(
        future: exercisesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading data'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No exercises found.'));
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

// Custom ExerciseCard widget with palette applied
class ExerciseCard extends StatelessWidget {
  final Exercise exercise;

  const ExerciseCard({super.key, required this.exercise});

  @override
  Widget build(BuildContext context) {
    String imagePath = '../assets/images/exercise/${exercise.imagePath}';

    return Card(
      margin: EdgeInsets.all(15),
      elevation: 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Color(0xFF557A95), width: 1),
      ),
      color: Colors.white,
      child: ListTile(
        contentPadding: EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            imagePath,
            width: 70,
            height: 70,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Icon(Icons.error, color: Colors.red);
            },
          ),
        ),
        title: Text(
          exercise.name,
          style: TextStyle(
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
              Text('Muscles: ${exercise.muscles}', style: TextStyle(color: Color(0xFF5B5B5B))),
              Text('Pain Level: ${exercise.painLevel}', style: TextStyle(color: Color(0xFF5B5B5B))),
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