import 'package:flutter/material.dart';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'exercise_detail.dart';
import '../core/medical_design_system.dart';

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
      print('First exercise: ${defaultExercises.isNotEmpty ? defaultExercises.first.name : "No exercises"}');
      print('CSV data sample: ${csvData.length > 1 ? csvData[1] : "No data"}');

      print('Total exercises loaded: ${defaultExercises.length}');
      return defaultExercises;
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
                  colors: [MedicalDesignSystem.backgroundClean, MedicalDesignSystem.cardBackground],
                ),
        ),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 140.0,
              floating: false,
              pinned: true,
              backgroundColor: MedicalDesignSystem.primaryBrand,
              elevation: 8,
              shadowColor: MedicalDesignSystem.primaryBrand.withOpacity(0.3),
              flexibleSpace: FlexibleSpaceBar(
                title: const Text(
                  'Medical Exercise Library',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                centerTitle: true,
                background: Container(
                  decoration: MedicalDesignSystem.medicalGradientBackground,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          MedicalDesignSystem.primaryBrand,
                          MedicalDesignSystem.primaryLight,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(height: 20),
                          Icon(
                            MedicalIcons.fitnessCenter,
                            color: Colors.white,
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Professional Rehabilitation Exercises',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            _buildExerciseList(context, isDark),
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
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF8B2E2E)),
                ),
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return SliverToBoxAdapter(
            child: Center(
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
            ),
          );
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
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
            ),
          );
        }

        List<Exercise> exercises = snapshot.data!;

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final item = exercises[index];
                return AnimatedOpacity(
                  opacity: 1.0,
                  duration: Duration(milliseconds: 300 + (index * 100)),
                  child: KeyedSubtree(
                    key: ValueKey('exercise_${item.id}_$index'),
                child: ExerciseCard(
                  exercise: item,
                  isSelecting: widget.selectingForAddition || widget.selectingForReplacement,
                  selectingForAddition: widget.selectingForAddition,
                  selectingForReplacement: widget.selectingForReplacement,
                ),
                  ),
                );
              },
              childCount: exercises.length,
            ),
          ),
        );
      },
    );
  }
}

class ExerciseCard extends StatelessWidget {
  final Exercise exercise;
  final bool isSelecting;
  final bool selectingForAddition;
  final bool selectingForReplacement;

  const ExerciseCard({
    super.key,
    required this.exercise,
    this.isSelecting = false,
    this.selectingForAddition = false,
    this.selectingForReplacement = false,
  });

  @override
  Widget build(BuildContext context) {
    return _ExerciseCardContent(
      exercise: exercise,
      isSelecting: isSelecting,
      selectingForAddition: selectingForAddition,
      selectingForReplacement: selectingForReplacement,
    );
  }
}

class _ExerciseCardContent extends StatelessWidget {
  final Exercise exercise;
  final bool isSelecting;
  final bool selectingForAddition;
  final bool selectingForReplacement;

  const _ExerciseCardContent({
    required this.exercise,
    required this.isSelecting,
    required this.selectingForAddition,
    required this.selectingForReplacement,
  });

  @override
  Widget build(BuildContext context) {
    String imagePath = 'assets/images/exercise/${exercise.imageUrl}';
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: isSelecting 
          ? MedicalDesignSystem.medicalCardAccentDecoration
          : MedicalDesignSystem.medicalCardDecoration,
      child: InkWell(
        onTap: () {
          if (!isSelecting) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ExerciseDetailPage(
                  exercise: exercise,
                  isSelecting: selectingForAddition || selectingForReplacement,
                ),
              ),
            );
          }
        },
        splashColor: MedicalDesignSystem.primaryBrand.withOpacity(0.1),
        highlightColor: MedicalDesignSystem.primaryBrand.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: isSelecting 
                ? Border.all(color: MedicalDesignSystem.primaryBrand, width: 2)
                : null,
          ),
          child: Row(
            children: [
              // Medical Exercise Image
              Hero(
                tag: 'exercise_${exercise.id}',
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          MedicalDesignSystem.primaryBrand.withOpacity(0.1),
                          MedicalDesignSystem.primaryLight.withOpacity(0.05),
                        ],
                      ),
                    ),
                    child: (exercise.imageUrl.trim().isNotEmpty)
                        ? Image.asset(
                            imagePath,
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: MedicalDesignSystem.primaryBrand.withOpacity(0.1),
                                child: Icon(
                                  MedicalIcons.fitnessCenter,
                                  color: MedicalDesignSystem.primaryBrand,
                                  size: 32,
                                ),
                              );
                            },
                          )
                        : Container(
                            width: 100,
                            height: 100,
                            color: MedicalDesignSystem.primaryBrand.withOpacity(0.08),
                            child: Icon(
                              MedicalIcons.fitnessCenter,
                              color: MedicalDesignSystem.primaryBrand,
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
                      // Medical Exercise Name
                      Text(
                        exercise.name,
                        style: MedicalDesignSystem.subheaderStyle.copyWith(
                          color: MedicalDesignSystem.primaryBrand,
                          fontSize: 16,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      
                      // Medical Exercise Information
                      Row(
                        children: [
                          MedicalDesignSystem.medicalStatusBadge(
                            text: exercise.muscle,
                            status: MedicalStatus.info,
                          ),
                          const SizedBox(width: 6),
                          MedicalDesignSystem.medicalStatusBadge(
                            text: exercise.painLevel,
                            status: MedicalStatus.warning,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      
                      // Exercise Details
                      Row(
                        children: [
                          Icon(
                            MedicalIcons.timer,
                            color: MedicalDesignSystem.textSecondary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${exercise.rep} reps',
                            style: MedicalDesignSystem.labelStyle,
                          ),
                          const SizedBox(width: 12),
                          Icon(
                            MedicalIcons.schedule,
                            color: MedicalDesignSystem.textSecondary,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${exercise.set} sets',
                            style: MedicalDesignSystem.labelStyle,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              // Medical Selection Button
              if (isSelecting)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context, exercise);
                    },
                    icon: const Icon(MedicalIcons.checkCircle, size: 18),
                    label: const Text('Select'),
                    style: MedicalDesignSystem.primaryMedicalButton.copyWith(
                      padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
