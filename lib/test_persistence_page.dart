import 'package:flutter/material.dart';
import 'data/persistence_test.dart';
import 'data/persistence_validation.dart';

class TestPersistencePage extends StatefulWidget {
  const TestPersistencePage({super.key});

  @override
  State<TestPersistencePage> createState() => _TestPersistencePageState();
}

class _TestPersistencePageState extends State<TestPersistencePage> {
  bool _isRunning = false;
  Map<String, dynamic>? _testResults;
  String _status = 'Ready to run tests';
  Map<String, dynamic>? _validationResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Persistence Test Suite'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Persistence Test Suite',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: const Color(0xFF2E5A88),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _status,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: _isRunning ? Colors.blue : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : _runTests,
                icon: _isRunning 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
                label: Text(_isRunning ? 'Running Tests...' : 'Run All Tests'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: ElevatedButton.icon(
                onPressed: _isRunning ? null : _runValidation,
                icon: const Icon(Icons.verified),
                label: const Text('Run Hive ↔ Firebase Validation'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            if (_testResults != null) ...[
              Text(
                'Test Results',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildResultCard('Overall Result', _testResults!['success']),
                      const SizedBox(height: 12),
                      if (_testResults!['summary'] != null)
                        _buildSummaryCard(_testResults!['summary']),
                      const SizedBox(height: 12),
                      if (_testResults!['tests'] != null)
                        ..._buildTestResultCards(_testResults!['tests']),
                    ],
                  ),
                ),
              ),
            ],
            if (_validationResult != null) ...[
              const SizedBox(height: 16),
              Text(
                'Validation Summary',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildKeyValue('Success', (_validationResult!['success'] == true).toString()),
                      if (_validationResult!['steps'] != null)
                        _buildKeyValue('Steps', (_validationResult!['steps'] as List).join(' \u2192 ')),
                      if (_validationResult!['errors'] != null && (_validationResult!['errors'] as List).isNotEmpty)
                        _buildKeyValue('Errors', (_validationResult!['errors'] as List).join(' | ')),
                      if (_validationResult!['collections'] != null)
                        _buildKeyValue('Collections Ensured', _validationResult!['collections'].toString()),
                      if (_validationResult!['models'] != null)
                        _buildKeyValue('Models Snapshot', _validationResult!['models'].toString()),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _runTests() async {
    setState(() {
      _isRunning = true;
      _status = 'Running persistence tests...';
    });

    try {
      final results = await PersistenceTest.runAllTests();
      
      setState(() {
        _testResults = results;
        _isRunning = false;
        _status = results['success'] 
          ? 'All tests completed successfully!'
          : 'Some tests failed. Check results below.';
      });
    } catch (e) {
      setState(() {
        _isRunning = false;
        _status = 'Error running tests: $e';
        _testResults = {
          'success': false,
          'error': e.toString(),
        };
      });
    }
  }

  Future<void> _runValidation() async {
    setState(() {
      _isRunning = true;
      _status = 'Running Hive ↔ Firebase validation...';
      _validationResult = null;
    });

    try {
      final result = await PersistenceValidation.runFull();
      setState(() {
        _validationResult = result;
        _isRunning = false;
        _status = result['success'] == true
            ? 'Validation succeeded.'
            : 'Validation failed. See summary below.';
      });
    } catch (e) {
      setState(() {
        _isRunning = false;
        _status = 'Error running validation: $e';
        _validationResult = {
          'success': false,
          'errors': ['Exception: $e'],
        };
      });
    }
  }

  Widget _buildResultCard(String title, bool success) {
    return Card(
      color: success ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(
              success ? Icons.check_circle : Icons.error,
              color: success ? Colors.green : Colors.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              success ? 'PASSED' : 'FAILED',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: success ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(Map<String, dynamic> summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Total Tests: ${summary['totalTests']}'),
            Text('Passed: ${summary['passedTests']}'),
            Text('Failed: ${summary['failedTests']}'),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTestResultCards(Map<String, dynamic> tests) {
    return tests.entries.map((entry) {
      final testName = entry.key;
      final testResult = entry.value as Map<String, dynamic>;
      final success = testResult['success'] == true;
      
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    success ? Icons.check_circle : Icons.error,
                    color: success ? Colors.green : Colors.red,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _formatTestName(testName),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    success ? 'PASSED' : 'FAILED',
                    style: TextStyle(
                      color: success ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (testResult.containsKey('message'))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    testResult['message'],
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ),
              if (testResult.containsKey('error'))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Error: ${testResult['error']}',
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }).toList();
  }

  String _formatTestName(String testName) {
    switch (testName) {
      case 'hiveAdapters':
        return 'Hive Adapter Registration';
      case 'hiveSaving':
        return 'Hive Data Saving';
      case 'hiveLoading':
        return 'Hive Data Loading';
      case 'dataIntegrity':
        return 'Data Integrity Check';
      case 'firebaseCollections':
        return 'Firebase Collections';
      case 'firebaseSync':
        return 'Firebase Synchronization';
      case 'errorHandling':
        return 'Error Handling';
      default:
        return testName;
    }
  }

  Widget _buildKeyValue(String key, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              key,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}



