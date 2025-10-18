import 'package:flutter/material.dart';
import 'data_persistence_service.dart';
import 'globals.dart';
import 'rehabilitation_plan.dart';
import 'firebase_helper.dart';
import 'firebase_integration_test.dart';
import 'login_test_service.dart';
import 'data_sync_service.dart';
import '../test_firebase_collections_access.dart';
import '../test_firebase_write_operations.dart';

/// Widget to display data management information and controls
class DataManagementWidget extends StatefulWidget {
  const DataManagementWidget({super.key});

  @override
  State<DataManagementWidget> createState() => _DataManagementWidgetState();
}

class _DataManagementWidgetState extends State<DataManagementWidget> {
  Map<String, dynamic> _saveStats = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _updateSaveStats();
  }

  void _updateSaveStats() {
    setState(() {
      _saveStats = DataPersistenceService.instance.getSaveStatistics();
    });
  }

  Future<void> _forceSave() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await DataPersistenceService.instance.forceSave(reason: 'Manual save triggered by user');
      _updateSaveStats();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Data saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _validateData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final isValid = await DataPersistenceService.validateDataIntegrity();
      _updateSaveStats();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isValid ? 'Data integrity check passed!' : 'Data integrity issues found'),
            backgroundColor: isValid ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error validating data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _syncWithFirebase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (UserDetails.isAuthenticated) {
        // Initialize Firebase collections first
        await FirebaseHelper.initializeUserCollections();
        
        // Then sync the data
        await UserRehabilitation.instance.syncWithFirebase();
        _updateSaveStats();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Successfully synced with Firebase!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please log in to sync with Firebase'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error syncing with Firebase: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testFirebaseIntegration() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await FirebaseIntegrationTest.runAllTests();
      
      if (mounted) {
        _showTestResultsDialog(results);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firebase test error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testLoginFunctionality() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await LoginTestService.runAllTests();
      
      if (mounted) {
        _showLoginTestResultsDialog(results);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Login test error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testDataSync() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Test comprehensive data sync
      final syncResults = await DataSyncService.instance.syncAllData();
      
      // Test data integrity
      final integrityResults = await DataSyncService.instance.verifyDataIntegrity();
      
      // Get sync statistics
      final syncStats = DataSyncService.instance.getSyncStatistics();
      
      if (mounted) {
        _showDataSyncTestResultsDialog(syncResults, integrityResults, syncStats);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Data sync test error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testFirebaseCollections() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await FirebaseCollectionsAccessTest.testAllCollectionsAccess();
      
      if (mounted) {
        _showFirebaseCollectionsResultsDialog(results);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firebase collections test error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _testFirebaseWriteOperations() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final results = await FirebaseWriteOperationsTest.testAllWriteOperations();
      
      if (mounted) {
        _showFirebaseWriteResultsDialog(results);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Firebase write operations test error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showTestResultsDialog(Map<String, dynamic> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Firebase Integration Test Results'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTestResult('Configuration', results['configuration']),
              _buildTestResult('Authentication', results['authentication']),
              _buildTestResult('User Document', results['userDocument']),
              _buildTestResult('Collections', results['collections']),
              _buildTestResult('User Data Persistence', results['userDataPersistence']),
              _buildTestResult('Rehab Data Persistence', results['rehabDataPersistence']),
              _buildTestResult('Data Sync', results['dataSync']),
              _buildTestResult('Error Handling', results['errorHandling']),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showLoginTestResultsDialog(Map<String, dynamic> results) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Login Functionality Test Results'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTestResult('Auth Service Init', results['authServiceInit']),
              _buildTestResult('Firebase Auth Config', results['firebaseAuthConfig']),
              _buildTestResult('User Auth Flow', results['userAuthFlow']),
              _buildTestResult('Data Persistence', results['dataPersistence']),
              _buildTestResult('Auth State Monitoring', results['authStateMonitoring']),
              _buildTestResult('Error Handling', results['errorHandling']),
              _buildTestResult('Login Page Integration', results['loginPageIntegration']),
              const Divider(),
              Text(
                'Overall Success Rate: ${((results['overallSuccess'] ?? 0) * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDataSyncTestResultsDialog(
    Map<String, dynamic> syncResults,
    Map<String, dynamic> integrityResults,
    Map<String, dynamic> syncStats,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Data Synchronization Test Results'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sync Results
              Text(
                'Data Sync Results:',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildTestResult('Overall Sync', {
                'success': syncResults['success'],
                'message': syncResults['message'] ?? 'No message',
              }),
              _buildTestResult('User Data', syncResults['userData']),
              _buildTestResult('Rehabilitation Data', syncResults['rehabilitationData']),
              _buildTestResult('Progress Data', syncResults['progressData']),
              _buildTestResult('Settings Data', syncResults['settingsData']),
              
              const Divider(),
              
              // Integrity Results
              Text(
                'Data Integrity:',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildTestResult('User Data Integrity', integrityResults['userData']),
              _buildTestResult('Rehabilitation Data Integrity', integrityResults['rehabilitationData']),
              _buildTestResult('Progress Data Integrity', integrityResults['progressData']),
              _buildTestResult('Settings Data Integrity', integrityResults['settingsData']),
              
              const Divider(),
              
              // Sync Statistics
              Text(
                'Sync Statistics:',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text('Initialized: ${syncStats['isInitialized']}'),
              Text('Last Sync: ${syncStats['lastSyncTime'] ?? 'Never'}'),
              Text('Sync Count: ${syncStats['syncCount']}'),
              Text('Authenticated: ${syncStats['isAuthenticated']}'),
              Text('User ID: ${syncStats['currentUserId'] ?? 'None'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildTestResult(String testName, dynamic result) {
    if (result == null) return const SizedBox.shrink();
    
    final passed = result['passed'] == true;
    final message = result['message'] ?? 'No message';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            passed ? Icons.check_circle : Icons.error,
            color: passed ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$testName: $message',
              style: TextStyle(
                color: passed ? Colors.green : Colors.red,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'Data Management',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: _updateSaveStats,
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Refresh statistics',
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Save Statistics
            _buildStatCard(
              'Save Statistics',
              [
                'Total Saves: ${_saveStats['saveCount'] ?? 0}',
                'Last Save: ${_formatTimestamp(_saveStats['lastSaveTime'])}',
                'Auto-save: ${_saveStats['autoSaveEnabled'] == true ? 'Active' : 'Inactive'}',
                'Currently Saving: ${_saveStats['isSaving'] == true ? 'Yes' : 'No'}',
              ],
              Icons.analytics,
              Colors.blue,
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _forceSave,
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save),
                    label: const Text('Save Now'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _validateData,
                    icon: _isLoading 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.verified_user),
                    label: const Text('Validate'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Firebase Sync Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _syncWithFirebase,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.cloud_sync),
                label: Text(UserDetails.isAuthenticated ? 'Sync with Firebase' : 'Login to Sync'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: UserDetails.isAuthenticated ? Colors.blue : Colors.grey,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Firebase Test Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testFirebaseIntegration,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bug_report),
                label: const Text('Test Firebase Integration'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Login Test Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testLoginFunctionality,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login),
                label: const Text('Test Login Functionality'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Firebase Collections Test Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testFirebaseCollections,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.storage),
                label: const Text('Test Firebase Collections'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Firebase Write Operations Test Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testFirebaseWriteOperations,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.edit),
                label: const Text('Test Firebase Write Operations'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Data Sync Test Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testDataSync,
                icon: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                label: const Text('Test Data Synchronization'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Information
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue.shade700, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Auto-save Information',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Data is automatically saved every 2 seconds after changes\n'
                    '• Maximum save interval: 5 minutes\n'
                    '• Data is saved when app goes to background\n'
                    '• All user interactions trigger auto-save\n'
                    '• ${UserDetails.isAuthenticated ? "Firebase sync enabled - data backed up to cloud" : "Login to enable Firebase cloud backup"}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, List<String> stats, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...stats.map((stat) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              stat,
              style: const TextStyle(fontSize: 12),
            ),
          )),
        ],
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Never';
    try {
      final dateTime = DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Invalid timestamp';
    }
  }

  void _showFirebaseCollectionsResultsDialog(Map<String, dynamic> results) {
    final success = results['success'] as bool? ?? false;
    final summary = results['summary'] as Map<String, dynamic>?;
    final collections = results['collections'] as Map<String, dynamic>?;
    final errors = results['errors'] as List<String>? ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Firebase Collections Test Results'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (summary != null) ...[
                Text(
                  'Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: success ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSummaryRow('Total Collections', summary['totalCollections']?.toString() ?? '0'),
                _buildSummaryRow('Successful', summary['successfulCollections']?.toString() ?? '0'),
                _buildSummaryRow('Failed', summary['failedCollections']?.toString() ?? '0'),
                _buildSummaryRow('With Data', summary['collectionsWithData']?.toString() ?? '0'),
                _buildSummaryRow('Without Data', summary['collectionsWithoutData']?.toString() ?? '0'),
                const SizedBox(height: 16),
              ],
              
              if (collections != null) ...[
                Text(
                  'Collection Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...collections.entries.map((entry) => _buildCollectionResult(entry.key, entry.value)),
              ],
              
              if (errors.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Errors',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                ...errors.map((error) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $error',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionResult(String collectionName, dynamic data) {
    if (data is! Map<String, dynamic>) return const SizedBox();

    final success = data['success'] as bool? ?? false;
    final canRead = data['canRead'] as bool? ?? false;
    final canWrite = data['canWrite'] as bool? ?? false;
    final documentExists = data['documentExists'] as bool? ?? false;
    final error = data['error'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: success ? Colors.green.shade50 : Colors.red.shade50,
        border: Border.all(
          color: success ? Colors.green.shade200 : Colors.red.shade200,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                collectionName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: success ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildStatusRow('Read', canRead),
          _buildStatusRow('Write', canWrite),
          _buildStatusRow('Document Exists', documentExists),
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(
              'Error: $error',
              style: TextStyle(
                fontSize: 10,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Icon(
            status ? Icons.check : Icons.close,
            color: status ? Colors.green : Colors.red,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  void _showFirebaseWriteResultsDialog(Map<String, dynamic> results) {
    final success = results['success'] as bool? ?? false;
    final summary = results['summary'] as Map<String, dynamic>?;
    final collections = results['collections'] as Map<String, dynamic>?;
    final errors = results['errors'] as List<String>? ?? [];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text('Firebase Write Operations Test Results'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (summary != null) ...[
                Text(
                  'Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: success ? Colors.green : Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                _buildSummaryRow('Total Collections', summary['totalCollections']?.toString() ?? '0'),
                _buildSummaryRow('Successful', summary['successfulCollections']?.toString() ?? '0'),
                _buildSummaryRow('Failed', summary['failedCollections']?.toString() ?? '0'),
                _buildSummaryRow('Write Access', summary['collectionsWithWriteAccess']?.toString() ?? '0'),
                _buildSummaryRow('Read Access', summary['collectionsWithReadAccess']?.toString() ?? '0'),
                _buildSummaryRow('Data Integrity', summary['collectionsWithDataIntegrity']?.toString() ?? '0'),
                const SizedBox(height: 16),
              ],
              
              if (collections != null) ...[
                Text(
                  'Collection Write/Read Details',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                ...collections.entries.map((entry) => _buildWriteResult(entry.key, entry.value)),
              ],
              
              if (errors.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'Errors',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 8),
                ...errors.map((error) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '• $error',
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildWriteResult(String collectionName, dynamic data) {
    if (data is! Map<String, dynamic>) return const SizedBox();

    final success = data['success'] as bool? ?? false;
    final canWrite = data['canWrite'] as bool? ?? false;
    final canRead = data['canRead'] as bool? ?? false;
    final dataMatches = data['dataMatches'] as bool? ?? false;
    final error = data['error'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: success ? Colors.green.shade50 : Colors.red.shade50,
        border: Border.all(
          color: success ? Colors.green.shade200 : Colors.red.shade200,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                collectionName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: success ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _buildStatusRow('Write', canWrite),
          _buildStatusRow('Read', canRead),
          _buildStatusRow('Data Integrity', dataMatches),
          if (error != null) ...[
            const SizedBox(height: 4),
            Text(
              'Error: $error',
              style: TextStyle(
                fontSize: 10,
                color: Colors.red.shade700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
