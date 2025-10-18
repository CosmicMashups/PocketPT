import '../result.dart';

/// Base repository interface that all repositories should implement
/// This provides a consistent pattern for data access throughout the application
abstract class BaseRepository<T, ID> {
  /// Get an entity by its ID
  Future<Result<T?>> getById(ID id);
  
  /// Get all entities
  Future<Result<List<T>>> getAll();
  
  /// Create a new entity
  Future<Result<T>> create(T entity);
  
  /// Update an existing entity
  Future<Result<T>> update(T entity);
  
  /// Delete an entity by its ID
  Future<Result<void>> deleteById(ID id);
  
  /// Check if an entity exists by its ID
  Future<Result<bool>> existsById(ID id);
  
  /// Get count of entities
  Future<Result<int>> count();
}

/// Repository interface for entities that can be searched
abstract class SearchableRepository<T, ID> extends BaseRepository<T, ID> {
  /// Search entities by query
  Future<Result<List<T>>> search(String query);
  
  /// Search entities with pagination
  Future<Result<List<T>>> searchPaginated(String query, int page, int pageSize);
}

/// Repository interface for entities that support batch operations
abstract class BatchRepository<T, ID> extends BaseRepository<T, ID> {
  /// Create multiple entities
  Future<Result<List<T>>> createBatch(List<T> entities);
  
  /// Update multiple entities
  Future<Result<List<T>>> updateBatch(List<T> entities);
  
  /// Delete multiple entities by their IDs
  Future<Result<void>> deleteBatch(List<ID> ids);
}

/// Repository interface for entities that support caching
abstract class CachedRepository<T, ID> extends BaseRepository<T, ID> {
  /// Get entity from cache
  Future<Result<T?>> getFromCache(ID id);
  
  /// Cache an entity
  Future<Result<void>> cache(T entity);
  
  /// Clear cache
  Future<Result<void>> clearCache();
  
  /// Clear cache for specific entity
  Future<Result<void>> clearCacheForId(ID id);
}

/// Repository interface for entities that support offline operations
abstract class OfflineRepository<T, ID> extends BaseRepository<T, ID> {
  /// Get entities that are pending sync
  Future<Result<List<T>>> getPendingSync();
  
  /// Mark entity as synced
  Future<Result<void>> markAsSynced(ID id);
  
  /// Mark entity as pending sync
  Future<Result<void>> markAsPendingSync(ID id);
  
  /// Get sync status for entity
  Future<Result<bool>> isSynced(ID id);
}

