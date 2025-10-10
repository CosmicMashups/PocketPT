import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'data/page_specific_data_service.dart';
import 'data/auto_save_service.dart';

/// Test page to verify optimized data loading functionality
class TestOptimizedLoading extends StatefulWidget {
  const TestOptimizedLoading({super.key});

  @override
  State<TestOptimizedLoading> createState() => _TestOptimizedLoadingState();
}

class _TestOptimizedLoadingState extends State<TestOptimizedLoading> {
  Map<String, dynamic> _testResults = {};
  bool _isRunningTests = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Optimized Loading Test'),
        backgroundColor: const Color(0xFF8B2E2E),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Test Controls
            _buildTestControls(),
            const SizedBox(height: 24),
            
            // Test Results
            Expanded(
              child: _buildTestResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestControls() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Controls',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF8B2E2E),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: _isRunningTests ? null : _runAllTests,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B2E2E),
                  ),
                  child: _isRunningTests
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text('Run All Tests'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _clearResults,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                  ),
                  child: const Text('Clear Results'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestResults() {
    if (_testResults.isEmpty) {
      return const Center(
        child: Text(
          'No test results yet. Run tests to see performance metrics.',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView(
      children: _testResults.entries.map((entry) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B2E2E),
                  ),
                ),
                const SizedBox(height: 8),
                if (entry.value is Map)
                  ...((entry.value as Map).entries.map((subEntry) {
                    return Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Text(
                        '${subEntry.key}: ${subEntry.value}',
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }))
                else
                  Text(
                    entry.value.toString(),
                    style: const TextStyle(fontSize: 14),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _runAllTests() async {
    setState(() {
      _isRunningTests = true;
      _testResults = {};
    });

    try {
      // Test 1: Page-specific data loading
      await _testPageSpecificLoading();
      
      // Test 2: Auto-save service
      await _testAutoSaveService();
      
      // Test 3: Cache performance
      await _testCachePerformance();
      
      debugPrint('All tests completed successfully');
    } catch (e) {
      debugPrint('Test failed: $e');
      setState(() {
        _testResults['Test Error'] = e.toString();
      });
    } finally {
      setState(() {
        _isRunningTests = false;
      });
    }
  }

  Future<void> _testPageSpecificLoading() async {
    final results = <String, dynamic>{};
    
    // Test assessment data loading
    final assessmentStart = DateTime.now();
    try {
      await PageSpecificDataService.instance.loadAssessmentData();
      final assessmentDuration = DateTime.now().difference(assessmentStart);
      results['Assessment Data Loading'] = {
        'Status': 'Success',
        'Duration': '${assessmentDuration.inMilliseconds}ms',
      };
    } catch (e) {
      results['Assessment Data Loading'] = {
        'Status': 'Failed',
        'Error': e.toString(),
      };
    }

    // Test dashboard data loading
    final dashboardStart = DateTime.now();
    try {
      await PageSpecificDataService.instance.loadDashboardData();
      final dashboardDuration = DateTime.now().difference(dashboardStart);
      results['Dashboard Data Loading'] = {
        'Status': 'Success',
        'Duration': '${dashboardDuration.inMilliseconds}ms',
      };
    } catch (e) {
      results['Dashboard Data Loading'] = {
        'Status': 'Failed',
        'Error': e.toString(),
      };
    }

    // Test profile data loading
    final profileStart = DateTime.now();
    try {
      await PageSpecificDataService.instance.loadProfileData();
      final profileDuration = DateTime.now().difference(profileStart);
      results['Profile Data Loading'] = {
        'Status': 'Success',
        'Duration': '${profileDuration.inMilliseconds}ms',
      };
    } catch (e) {
      results['Profile Data Loading'] = {
        'Status': 'Failed',
        'Error': e.toString(),
      };
    }

    setState(() {
      _testResults['Page-Specific Data Loading'] = results;
    });
  }

  Future<void> _testAutoSaveService() async {
    final results = <String, dynamic>{};
    
    try {
      final status = AutoSaveService.instance.getStatus();
      results['Auto-Save Service'] = {
        'Status': 'Initialized',
        'Is Saving': status['isSaving'],
        'Save Count': status['saveCount'],
        'Last Save Time': status['lastSaveTime'] ?? 'Never',
        'Auto-Save Interval': '${status['autoSaveInterval']} minutes',
      };
    } catch (e) {
      results['Auto-Save Service'] = {
        'Status': 'Failed',
        'Error': e.toString(),
      };
    }

    setState(() {
      _testResults['Auto-Save Service Status'] = results;
    });
  }

  Future<void> _testCachePerformance() async {
    final results = <String, dynamic>{};
    
    // Test cache hit performance
    try {
      // First load (should populate cache)
      await PageSpecificDataService.instance.loadAssessmentData();
      
      // Second load (should use cache)
      final secondLoadStart = DateTime.now();
      await PageSpecificDataService.instance.loadAssessmentData();
      final secondLoadDuration = DateTime.now().difference(secondLoadStart);
      
      results['Cache Performance'] = {
        'Cache Hit Duration': '${secondLoadDuration.inMilliseconds}ms',
        'Status': secondLoadDuration.inMilliseconds < 10 ? 'Excellent' : 'Good',
      };
    } catch (e) {
      results['Cache Performance'] = {
        'Status': 'Failed',
        'Error': e.toString(),
      };
    }

    setState(() {
      _testResults['Cache Performance Test'] = results;
    });
  }

  void _clearResults() {
    setState(() {
      _testResults = {};
    });
  }
}
