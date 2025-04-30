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
      id: row[0],
      name: row[1],
      description: row[2],
      muscle: row[3],
      painLevel: row[4],
      goal: row[5],
      rep: row[6],
      set: row[7],
      imageUrl: row[8],
      videoUrl: row[9],
    );
  }
}
