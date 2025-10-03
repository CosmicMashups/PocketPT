import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'exercise_detail.dart';
import '../data/widget_cache_service.dart';
import '../data/performance_optimization_service.dart';

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
  final bool selectingForReplacement;
  final bool selectingForAddition;

  const ExercisesPage({
    super.key,
    this.selectingForAddition = false,
    this.selectingForReplacement = false,
  });

  @override
  State<ExercisesPage> createState() => _ExercisesPageState();
}

class _ExercisesPageState extends State<ExercisesPage> {
  late Future<List<Exercise>> exercisesFuture;
  List<Exercise>? _cachedExercises;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExercises();
  }

  Future<void> _loadExercises() async {
    if (_cachedExercises != null) {
      setState(() {
        exercisesFuture = Future.value(_cachedExercises!);
      });
      return;
    }

    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      exercisesFuture = loadCSVData();
      final exercises = await exercisesFuture;
      _cachedExercises = exercises;
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Exercise>> loadCSVData() async {
    try {
      final data = await rootBundle.loadString('assets/data/exercises.csv');
      List<List<dynamic>> csvData = const CsvToListConverter().convert(data);
      return csvData.skip(1).map((row) => Exercise.fromCsv(row)).toList();
    } catch (e) {
      throw Exception("Failed to load exercise data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? Theme.of(context).scaffoldBackgroundColor : Colors.grey.shade200,
      appBar: AppBar(
        title: const Text(
          'Exercises',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF8B2E2E),
        automaticallyImplyLeading: true,
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

          return CachedListView(
            cacheKey: 'exercise_list',
            itemCount: exercises.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final item = exercises[index];
              return KeyedSubtree(
                key: ValueKey('exercise_${item.id}_$index'),
                child: ExerciseCard(
                  exercise: item,
                  isSelecting: widget.selectingForAddition || widget.selectingForReplacement,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final bool isSelecting;

  const ExerciseCard({
    super.key,
    required this.exercise,
    this.isSelecting = false,
  });

  @override
  Widget build(BuildContext context) {
    return _ExerciseCardContent(
      exercise: exercise,
      isSelecting: isSelecting,
    );
  }
}

class _ExerciseCardContent extends StatelessWidget {
  final Exercise exercise;
  final bool isSelecting;

  const _ExerciseCardContent({
    required this.exercise,
    required this.isSelecting,
  });

  @override
  Widget build(BuildContext context) {
    String imagePath = 'assets/images/exercise/${exercise.imageUrl}';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.all(15),
      elevation: isDark ? 2 : 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: const BorderSide(color: Color(0xFF8B2E2E), width: 1),
      ),
      color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: PerformanceOptimizationService().buildOptimizedImage(
                    imagePath: imagePath,
                    imageKey: 'exercise_thumb_${exercise.id}',
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                    placeholder: Container(color: Colors.grey[300]),
                    errorWidget: const Icon(Icons.error, color: Colors.red),
                  ),
                ),
              ),
              title: Text(
                exercise.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B2E2E),
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 5.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.fitness_center, color: Color(0xFF8B2E2E), size: 18),
                        const SizedBox(width: 5),
                        Text('Muscles: ${exercise.muscle}', style: const TextStyle(color: Color(0xFF5B5B5B))),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Color(0xFF8B2E2E), size: 18),
                        const SizedBox(width: 5),
                        Text('Pain Level: ${exercise.painLevel}', style: const TextStyle(color: Color(0xFF5B5B5B))),
                      ],
                    ),
                  ],
                ),
              ),
              onTap: () {
                if (!isSelecting) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExerciseDetailPage(exercise: exercise),
                    ),
                  );
                }
              },
            ),
            if (isSelecting)
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, exercise); // Return selected exercise
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B2E2E),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Select', style: TextStyle(color: Colors.white)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
