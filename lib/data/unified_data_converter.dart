import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'unified_data_models.dart';

/// Utility class for converting between Hive and Firebase data formats
class UnifiedDataConverter {
  
  /// Convert DateTime to milliseconds for Hive storage
  static int? dateTimeToMilliseconds(DateTime? dateTime) {
    return dateTime?.millisecondsSinceEpoch;
  }
  
  /// Convert milliseconds to DateTime for Hive loading
  static DateTime? millisecondsToDateTime(int? milliseconds) {
    return milliseconds != null ? DateTime.fromMillisecondsSinceEpoch(milliseconds) : null;
  }
  
  /// Convert DateTime to Timestamp for Firebase storage
  static Timestamp? dateTimeToTimestamp(DateTime? dateTime) {
    return dateTime != null ? Timestamp.fromDate(dateTime) : null;
  }
  
  /// Convert Timestamp to DateTime for Firebase loading
  static DateTime? timestampToDateTime(Timestamp? timestamp) {
    return timestamp?.toDate();
  }
  
  /// Convert dynamic value to int with null safety
  static int toInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? defaultValue;
    return defaultValue;
  }
  
  /// Convert dynamic value to String with null safety
  static String toStringValue(dynamic value, {String defaultValue = ''}) {
    if (value == null) return defaultValue;
    return value.toString();
  }
  
  /// Convert dynamic value to bool with null safety
  static bool toBool(dynamic value, {bool defaultValue = false}) {
    if (value == null) return defaultValue;
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    if (value is int) return value != 0;
    return defaultValue;
  }
  
  /// Convert dynamic value to List<String> with null safety
  static List<String> toStringList(dynamic value, {List<String> defaultValue = const []}) {
    if (value == null) return defaultValue;
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }
    return defaultValue;
  }
  
  /// Convert dynamic value to List<int> with null safety
  static List<int> toIntList(dynamic value, {List<int> defaultValue = const []}) {
    if (value == null) return defaultValue;
    if (value is List) {
      return value.map((item) => toInt(item)).toList();
    }
    return defaultValue;
  }
  
  /// Validate required fields in a map
  static bool validateRequiredFields(Map<String, dynamic> map, List<String> requiredFields) {
    for (final field in requiredFields) {
      if (!map.containsKey(field) || map[field] == null) {
        debugPrint('UnifiedDataConverter: Missing required field: $field');
        return false;
      }
    }
    return true;
  }
  
  /// Validate field types in a map
  static bool validateFieldTypes(Map<String, dynamic> map, Map<String, Type> expectedTypes) {
    for (final entry in expectedTypes.entries) {
      final field = entry.key;
      final expectedType = entry.value;
      
      if (map.containsKey(field) && map[field] != null) {
        final actualType = map[field].runtimeType;
        if (actualType != expectedType) {
          debugPrint('UnifiedDataConverter: Type mismatch for field $field. Expected: $expectedType, Actual: $actualType');
          return false;
        }
      }
    }
    return true;
  }
  
  /// Safe map access with default value
  static T safeGet<T>(Map<String, dynamic> map, String key, T defaultValue) {
    final value = map[key];
    if (value is T) return value;
    return defaultValue;
  }
  
  /// Safe map access with type conversion
  static T safeGetAs<T>(Map<String, dynamic> map, String key, T Function(dynamic) converter, T defaultValue) {
    final value = map[key];
    if (value == null) return defaultValue;
    try {
      return converter(value);
    } catch (e) {
      debugPrint('UnifiedDataConverter: Error converting field $key: $e');
      return defaultValue;
    }
  }
  
  /// Convert Hive map to Firebase map with proper type conversions
  static Map<String, dynamic> hiveToFirebaseMap(Map<String, dynamic> hiveMap) {
    final firebaseMap = <String, dynamic>{};
    
    for (final entry in hiveMap.entries) {
      final key = entry.key;
      final value = entry.value;
      
      // Convert DateTime fields from milliseconds to Timestamp
      if (key == 'lastModified' && value is int) {
        firebaseMap['lastUpdated'] = Timestamp.fromDate(DateTime.fromMillisecondsSinceEpoch(value));
      } else if (key == 'date' && value is int) {
        firebaseMap[key] = Timestamp.fromDate(DateTime.fromMillisecondsSinceEpoch(value));
      } else if (key == 'lastExerciseDate' && value is int) {
        firebaseMap[key] = DateTime.fromMillisecondsSinceEpoch(value);
      } else {
        firebaseMap[key] = value;
      }
    }
    
    return firebaseMap;
  }
  
  /// Convert Firebase map to Hive map with proper type conversions
  static Map<String, dynamic> firebaseToHiveMap(Map<String, dynamic> firebaseMap) {
    final hiveMap = <String, dynamic>{};
    
    for (final entry in firebaseMap.entries) {
      final key = entry.key;
      final value = entry.value;
      
      // Convert Timestamp fields to milliseconds
      if (key == 'lastUpdated' && value is Timestamp) {
        hiveMap['lastModified'] = value.toDate().millisecondsSinceEpoch;
      } else if (key == 'date' && value is Timestamp) {
        hiveMap[key] = value.toDate().millisecondsSinceEpoch;
      } else if (key == 'lastExerciseDate' && value is DateTime) {
        hiveMap[key] = value.millisecondsSinceEpoch;
      } else {
        hiveMap[key] = value;
      }
    }
    
    return hiveMap;
  }
  
  /// Merge two maps with conflict resolution (last-write-wins)
  static Map<String, dynamic> mergeMaps(Map<String, dynamic> map1, Map<String, dynamic> map2) {
    final merged = Map<String, dynamic>.from(map1);
    
    for (final entry in map2.entries) {
      final key = entry.key;
      final value = entry.value;
      
      // For timestamp fields, use the more recent one
      if (key == 'lastModified' || key == 'lastUpdated') {
        final existingValue = merged[key];
        if (existingValue != null) {
          final existingTime = _extractDateTime(existingValue);
          final newTime = _extractDateTime(value);
          
          if (newTime != null && existingTime != null) {
            if (newTime.isAfter(existingTime)) {
              merged[key] = value;
            }
          } else if (newTime != null) {
            merged[key] = value;
          }
        } else {
          merged[key] = value;
        }
      } else {
        // For other fields, use the new value (last-write-wins)
        merged[key] = value;
      }
    }
    
    return merged;
  }
  
  /// Extract DateTime from various formats
  static DateTime? _extractDateTime(dynamic value) {
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return null;
  }
  
  /// Validate data integrity for a unified model
  static bool validateDataIntegrity(UnifiedDataModel model) {
    try {
      // Convert to both formats and back to ensure consistency
      final hiveMap = model.toHiveMap();
      final firebaseMap = model.toFirebaseMap();
      
      // Validate the model itself
      if (!model.validate()) {
        debugPrint('UnifiedDataConverter: Model validation failed');
        return false;
      }
      
      // Check that required fields are present
      if (!hiveMap.containsKey('userId') || hiveMap['userId'] == null) {
        debugPrint('UnifiedDataConverter: Missing userId in Hive map');
        return false;
      }
      
      if (!firebaseMap.containsKey('userId') || firebaseMap['userId'] == null) {
        debugPrint('UnifiedDataConverter: Missing userId in Firebase map');
        return false;
      }
      
      return true;
    } catch (e) {
      debugPrint('UnifiedDataConverter: Data integrity validation failed: $e');
      return false;
    }
  }
  
  /// Create a unified model from mixed data sources
  static T createFromMixedData<T extends UnifiedDataModel>(
    Map<String, dynamic>? hiveData,
    Map<String, dynamic>? firebaseData,
    T Function(Map<String, dynamic>) fromHiveMap,
    T Function(Map<String, dynamic>) fromFirebaseMap,
  ) {
    if (hiveData != null && firebaseData != null) {
      // Both sources available - merge and use Firebase as primary
      final mergedData = mergeMaps(hiveData, firebaseData);
      return fromFirebaseMap(mergedData);
    } else if (firebaseData != null) {
      // Only Firebase data available
      return fromFirebaseMap(firebaseData);
    } else if (hiveData != null) {
      // Only Hive data available
      return fromHiveMap(hiveData);
    } else {
      throw Exception('No data available from either source');
    }
  }
  
  /// Convert list of unified models to Hive format
  static List<Map<String, dynamic>> modelsToHiveList<T extends UnifiedDataModel>(List<T> models) {
    return models.map((model) => model.toHiveMap()).toList();
  }
  
  /// Convert list of unified models to Firebase format
  static List<Map<String, dynamic>> modelsToFirebaseList<T extends UnifiedDataModel>(List<T> models) {
    return models.map((model) => model.toFirebaseMap()).toList();
  }
  
  /// Convert Hive list to unified models
  static List<T> hiveListToModels<T extends UnifiedDataModel>(
    List<dynamic> hiveList,
    T Function(Map<String, dynamic>) fromHiveMap,
  ) {
    return hiveList
        .where((item) => item is Map<String, dynamic>)
        .map((item) => fromHiveMap(item as Map<String, dynamic>))
        .toList();
  }
  
  /// Convert Firebase list to unified models
  static List<T> firebaseListToModels<T extends UnifiedDataModel>(
    List<dynamic> firebaseList,
    T Function(Map<String, dynamic>) fromFirebaseMap,
  ) {
    return firebaseList
        .where((item) => item is Map<String, dynamic>)
        .map((item) => fromFirebaseMap(item as Map<String, dynamic>))
        .toList();
  }
}
