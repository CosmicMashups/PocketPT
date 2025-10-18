import 'package:flutter/material.dart';
import 'test_firebase_integration.dart';
import 'data/data_sync_service.dart';

/// Test page for Firebase integration
class TestFirebasePage extends StatefulWidget {
  const TestFirebasePage({Key? key}) : super(key: key);

  @override
  State<TestFirebasePage> createState() => _TestFirebasePageState();
}

class _TestFirebasePageState extends State<TestFirebasePage> {
  bool _isLoading = false;
  Map<String, dynamic>? _testResults;
  String _status = 'Ready to test Firebase integration';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Integration Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _isLoading ? Colors.orange : Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _status,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Test buttons
            ElevatedButton(
              onPressed: _isLoading ? null : _runCompleteTest,
              child: const Text('Run Complete Integration Test'),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testIndividualCollections,
              child: const Text('Test Individual Collections'),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _testDataSync,
              child: const Text('Test Data Sync Service'),
            ),
            
            const SizedBox(height: 10),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _clearTestData,
              child: const Text('Clear Test Data'),
            ),
            
            const SizedBox(height: 20),
            
            // Results display
            if (_testResults != null) ...[
              const Text(
                'Test Results:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      _formatTestResults(_testResults!),
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _runCompleteTest() async {
    setState(() {
      _isLoading = true;
      _status = 'Running complete integration test...';
    });

    try {
      final results = await FirebaseIntegrationTest.testCompleteIntegration();
      
      setState(() {
        _testResults = results;
        _status = results['success'] 
            ? 'Integration test completed successfully!' 
            : 'Integration test completed with errors';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Integration test failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testIndividualCollections() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing individual collections...';
    });

    try {
      final results = await FirebaseIntegrationTest.testIndividualCollections();
      
      setState(() {
        _testResults = results;
        _status = results['success'] 
            ? 'Individual collections test completed successfully!' 
            : 'Individual collections test completed with errors';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Individual collections test failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testDataSync() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing data sync service...';
    });

    try {
      final results = await DataSyncService.instance.syncAllData();
      
      setState(() {
        _testResults = results;
        _status = results['success'] 
            ? 'Data sync test completed successfully!' 
            : 'Data sync test completed with errors';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Data sync test failed: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _clearTestData() async {
    setState(() {
      _isLoading = true;
      _status = 'Clearing test data...';
    });

    try {
      await FirebaseIntegrationTest.clearTestData();
      
      setState(() {
        _status = 'Test data cleared successfully!';
        _testResults = null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Failed to clear test data: $e';
        _isLoading = false;
      });
    }
  }

  String _formatTestResults(Map<String, dynamic> results) {
    final buffer = StringBuffer();
    
    buffer.writeln('Overall Success: ${results['success']}');
    buffer.writeln();
    
    if (results.containsKey('tests')) {
      buffer.writeln('Individual Tests:');
      final tests = results['tests'] as Map<String, dynamic>;
      tests.forEach((testName, testResult) {
        buffer.writeln('  $testName: ${testResult['success']}');
        if (testResult.containsKey('error')) {
          buffer.writeln('    Error: ${testResult['error']}');
        }
        if (testResult.containsKey('userId')) {
          buffer.writeln('    User ID: ${testResult['userId']}');
        }
        if (testResult.containsKey('createdCollections')) {
          buffer.writeln('    Created: ${testResult['createdCollections']}');
        }
        if (testResult.containsKey('existingCollections')) {
          buffer.writeln('    Existing: ${testResult['existingCollections']}');
        }
        if (testResult.containsKey('syncCount')) {
          buffer.writeln('    Sync Count: ${testResult['syncCount']}');
        }
        if (testResult.containsKey('successCount')) {
          buffer.writeln('    Success Count: ${testResult['successCount']}/${testResult['totalOperations']}');
        }
        buffer.writeln();
      });
    }
    
    if (results.containsKey('collections')) {
      buffer.writeln('Collections Status:');
      final collections = results['collections'] as Map<String, dynamic>;
      collections.forEach((collectionName, collectionData) {
        buffer.writeln('  $collectionName:');
        buffer.writeln('    Exists: ${collectionData['exists']}');
        if (collectionData.containsKey('hasData')) {
          buffer.writeln('    Has Data: ${collectionData['hasData']}');
        }
        if (collectionData.containsKey('fields')) {
          buffer.writeln('    Fields: ${collectionData['fields']}');
        }
        if (collectionData.containsKey('error')) {
          buffer.writeln('    Error: ${collectionData['error']}');
        }
        buffer.writeln();
      });
    }
    
    if (results.containsKey('errors') && (results['errors'] as List).isNotEmpty) {
      buffer.writeln('Errors:');
      for (final error in results['errors']) {
        buffer.writeln('  - $error');
      }
      buffer.writeln();
    }
    
    return buffer.toString();
  }
}
