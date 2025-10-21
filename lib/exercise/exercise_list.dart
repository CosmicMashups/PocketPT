import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'exercise_detail.dart';
import '../data/widget_cache_service.dart';
import '../data/performance_optimization_service.dart';
import '../data/custom_exercise_service.dart';

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
  final String otherMuscles;

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
    required this.otherMuscles,
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
      otherMuscles: row[10].toString(),
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
      print('Successfully loaded ${exercises.length} exercises into cache');
    } catch (e) {
      print('Error in _loadExercises: $e');
      // Handle error - ensure we have an empty list to prevent crashes
      _cachedExercises = [];
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<Exercise>> loadCSVData() async {
    try {
      // Load default exercises from assets
      final data = await rootBundle.loadString('assets/data/exercises.csv');
      List<List<dynamic>> csvData = const CsvToListConverter().convert(data);
      List<Exercise> defaultExercises = csvData.skip(1).map((row) => Exercise.fromCsv(row)).toList();
      
      print('Loaded ${defaultExercises.length} default exercises from CSV');

      // Load custom exercises from local storage (optional)
      List<Exercise> customExercises = [];
      try {
        customExercises = await CustomExerciseService.loadCustomExercisesFromLocal();
        print('Loaded ${customExercises.length} custom exercises');
      } catch (e) {
        // Custom exercises are optional, don't fail if they can't be loaded
        print('Warning: Could not load custom exercises: $e');
      }

      // Combine both lists (custom exercises first to show them prominently)
      final allExercises = [...customExercises, ...defaultExercises];
      
      print('Total exercises loaded: ${allExercises.length} (${customExercises.length} custom + ${defaultExercises.length} default)');
      return allExercises;
    } catch (e) {
      print('Error loading exercise data: $e');
      throw Exception("Failed to load exercise data: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF121212), Color(0xFF1C1C1C)],
                )
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.white, Color(0xFFF5F5F5)],
                ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              backgroundColor: const Color(0xFF8B2E2E),
              elevation: 4,
              shadowColor: Colors.black.withOpacity(0.3),
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Exercises',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 26,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                centerTitle: true,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF8B2E2E), Color(0xFFA03A3A)],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _buildExerciseList(context, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseList(BuildContext context, bool isDark) {
    return FutureBuilder<List<Exercise>>(
      future: exercisesFuture,
      builder: (context, snapshot) {
        print('FutureBuilder state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}');
        if (snapshot.hasData) {
          print('Snapshot data length: ${snapshot.data!.length}');
        }
        if (snapshot.hasError) {
          print('Snapshot error: ${snapshot.error}');
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B2E2E)),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading data',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.fitness_center_outlined,
                    size: 64,
                    color: isDark ? Colors.white54 : Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No exercises found',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        List<Exercise> exercises = snapshot.data!;

        return CachedListView(
          cacheKey: 'exercise_list',
          itemCount: exercises.length,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          itemBuilder: (context, index) {
            final item = exercises[index];
            return AnimatedOpacity(
              opacity: 1.0,
              duration: Duration(milliseconds: 300 + (index * 100)),
              child: KeyedSubtree(
                key: ValueKey('exercise_${item.id}_$index'),
                child: ExerciseCard(
                  exercise: item,
                  isSelecting: widget.selectingForAddition || widget.selectingForReplacement,
                ),
              ),
            );
          },
        );
      },
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
      elevation: isDark ? 6 : 8,
      shadowColor: Colors.black.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      clipBehavior: Clip.antiAlias,
      color: isDark 
          ? Theme.of(context).colorScheme.surface.withOpacity(0.9)
          : Colors.white.withOpacity(0.95),
      child: InkWell(
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
        splashColor: const Color(0xFF8B2E2E).withOpacity(0.1),
        highlightColor: const Color(0xFF8B2E2E).withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: isSelecting 
                ? Border.all(color: const Color(0xFF8B2E2E), width: 2)
                : null,
          ),
          child: Row(
            children: [
              // Exercise Image with Hero animation
              Hero(
                tag: 'exercise_${exercise.id}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF8B2E2E).withOpacity(0.1),
                          const Color(0xFF8B2E2E).withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: PerformanceOptimizationService().buildOptimizedImage(
                      imagePath: imagePath,
                      imageKey: 'exercise_thumb_${exercise.id}',
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                      placeholder: Container(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                        child: Icon(
                          Icons.fitness_center,
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                          size: 32,
                        ),
                      ),
                      errorWidget: Icon(
                        Icons.error_outline,
                        color: Colors.red.shade300,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
              // Exercise Details
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Exercise Name with Custom Indicator
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exercise.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF8B2E2E),
                                letterSpacing: 0.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (exercise.id.startsWith('CE'))
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.orange.shade300, width: 1),
                              ),
                              child: Text(
                                'Custom',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.orange.shade800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Muscle Group
                      Row(
                        children: [
                          Icon(
                            Icons.fitness_center_rounded,
                            color: const Color(0xFF8B2E2E).withOpacity(0.8),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              exercise.muscle,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.grey.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      // Other Muscles (only if not empty)
                      if (exercise.otherMuscles.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.fitness_center_outlined,
                              color: const Color(0xFF8B2E2E).withOpacity(0.6),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Also: ${exercise.otherMuscles}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : Colors.grey.shade600,
                                  fontWeight: FontWeight.w400,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      
                      // Pain Level
                      Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.orange.shade400,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Pain: ${exercise.painLevel}',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Selection Button
              if (isSelecting)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context, exercise);
                    },
                    icon: const Icon(Icons.check_circle_outline, size: 18),
                    label: const Text('Select'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B2E2E),
                      foregroundColor: Colors.white,
                      elevation: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
