class Treatment {
  final String treatmentId;
  final String treatmentName;
  final String description;
  final String musclesInvolved;
  final String painLevel;
  final String painDuration;

  Treatment({
    required this.treatmentId,
    required this.treatmentName,
    required this.description,
    required this.musclesInvolved,
    required this.painLevel,
    required this.painDuration,
  });

  @override
  String toString() {
    return 'Treatment{treatmentId: $treatmentId, treatmentName: $treatmentName, description: $description, musclesInvolved: $musclesInvolved, painLevel: $painLevel, painDuration: $painDuration}';
  }
}