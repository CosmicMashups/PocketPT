class Exercise {
  final String name;
  final String description;
  final String muscle;
  final String painLevel;
  final String goal;
  final String imageUrl;
  final String videoUrl;

  Exercise({
    required this.name,
    required this.description,
    required this.muscle,
    required this.painLevel,
    required this.goal,
    required this.imageUrl,
    required this.videoUrl,
  });

  factory Exercise.fromCsv(List<dynamic> row) {
    return Exercise(
      name: row[0],
      description: row[1],
      muscle: row[2],
      painLevel: row[3],
      goal: row[4],
      imageUrl: row[5],
      videoUrl: row[6],
    );
  }
}
