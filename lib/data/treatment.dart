/// Treatment data model containing all treatment information including instructions.
/// 
/// The treatmentInstruction field contains step-by-step instructions on how to 
/// perform or apply the treatment. This field is populated from the 
/// "Treatment_Instruction" column in treatment.csv (7th column, index 6).
class Treatment {
  final String treatmentId;
  final String treatmentName;
  final String description;
  final String musclesInvolved;
  final String painLevel;
  final String painDuration;
  final String treatmentInstruction;

  Treatment({
    required this.treatmentId,
    required this.treatmentName,
    required this.description,
    required this.musclesInvolved,
    required this.painLevel,
    required this.painDuration,
    this.treatmentInstruction = '', // Optional for backward compatibility with older CSV files
  });

  @override
  String toString() {
    return 'Treatment{treatmentId: $treatmentId, treatmentName: $treatmentName, description: $description, musclesInvolved: $musclesInvolved, painLevel: $painLevel, painDuration: $painDuration, treatmentInstruction: $treatmentInstruction}';
  }
}

// Lightweight treatment reference for storage
class TreatmentReference {
  final String treatmentId;

  TreatmentReference({
    required this.treatmentId,
  });

  Map<String, dynamic> toMap() {
    return {
      'treatmentId': treatmentId,
    };
  }

  factory TreatmentReference.fromMap(Map<String, dynamic> map) {
    return TreatmentReference(
      treatmentId: map['treatmentId'] ?? '',
    );
  }
}