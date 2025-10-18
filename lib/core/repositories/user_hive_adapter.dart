import 'package:hive/hive.dart';
import 'user_repository.dart';

/// Hive adapter for User class
/// This enables Hive to serialize/deserialize User objects
class UserAdapter extends TypeAdapter<User> {
  @override
  final int typeId = 0; // Unique type ID for User
  
  @override
  User read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    
    return User(
      id: fields[0] as String,
      email: fields[1] as String,
      name: fields[2] as String?,
      createdAt: DateTime.parse(fields[3] as String),
      updatedAt: DateTime.parse(fields[4] as String),
      preferences: fields[5] as Map<String, dynamic>?,
    );
  }
  
  @override
  void write(BinaryWriter writer, User obj) {
    writer
      ..writeByte(6) // Number of fields
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.email)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.createdAt.toIso8601String())
      ..writeByte(4)
      ..write(obj.updatedAt.toIso8601String())
      ..writeByte(5)
      ..write(obj.preferences);
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
  
  @override
  int get hashCode => typeId.hashCode;
}

