import '../result.dart';
import 'base_repository.dart';

/// User data model
class User {
  final String id;
  final String email;
  final String? name;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? preferences;
  
  const User({
    required this.id,
    required this.email,
    this.name,
    required this.createdAt,
    required this.updatedAt,
    this.preferences,
  });
  
  User copyWith({
    String? id,
    String? email,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? preferences,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      preferences: preferences ?? this.preferences,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'preferences': preferences,
    };
  }
  
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      name: json['name'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      preferences: json['preferences'] as Map<String, dynamic>?,
    );
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          name == other.name &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;
  
  @override
  int get hashCode =>
      id.hashCode ^
      email.hashCode ^
      name.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;
  
  @override
  String toString() {
    return 'User{id: $id, email: $email, name: $name, createdAt: $createdAt, updatedAt: $updatedAt}';
  }
}

/// User repository interface
abstract class UserRepository extends BaseRepository<User, String> {
  /// Get user by email
  Future<Result<User?>> getByEmail(String email);
  
  /// Update user preferences
  Future<Result<User>> updatePreferences(String userId, Map<String, dynamic> preferences);
  
  /// Get user preferences
  Future<Result<Map<String, dynamic>?>> getPreferences(String userId);
  
  /// Check if email exists
  Future<Result<bool>> emailExists(String email);
  
  /// Update user profile
  Future<Result<User>> updateProfile(String userId, {String? name, String? email});
}

