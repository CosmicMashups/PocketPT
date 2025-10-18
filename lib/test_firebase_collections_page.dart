import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'test_firebase_collections_access.dart';

/// Page to test and display Firebase collections access
class TestFirebaseCollectionsPage extends StatefulWidget {
  const TestFirebaseCollectionsPage({super.key});

  @override
  State<TestFirebaseCollectionsPage> createState() => _TestFirebaseCollectionsPageState();
}

class _TestFirebaseCollectionsPageState extends State<TestFirebaseCollectionsPage> {
  Map<String, dynamic>? _testResults;
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firebase Collections Test'),
        backgroundColor: const Color(0xFF8B2E2E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Test Button
            ElevatedButton(
              onPressed: _isLoading ? null : _runTest,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B2E2E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('Testing Collections...'),
                      ],
                    )
                  : const Text('Test All Firebase Collections'),
            ),
            
            const SizedBox(height: 20),
            
            // Results
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border.all(color: Colors.red.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Error: $_error',
                  style: GoogleFonts.poppins(
                    color: Colors.red.shade700,
                    fontSize: 14,
                  ),
                ),
              ),
            
            if (_testResults != null) ...[
              // Summary
              _buildSummaryCard(),
              const SizedBox(height: 16),
              
              // Detailed Results
              Expanded(
                child: _buildDetailedResults(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final summary = _testResults!['summary'] as Map<String, dynamic>?;
    final success = _testResults!['success'] as bool? ?? false;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: success ? Colors.green.shade50 : Colors.red.shade50,
        border: Border.all(
          color: success ? Colors.green.shade200 : Colors.red.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                success ? Icons.check_circle : Icons.error,
                color: success ? Colors.green : Colors.red,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                success ? 'All Collections Accessible' : 'Some Collections Failed',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: success ? Colors.green.shade700 : Colors.red.shade700,
                ),
              ),
            ],
          ),
          if (summary != null) ...[
            const SizedBox(height: 12),
            _buildSummaryRow('Total Collections', summary['totalCollections']?.toString() ?? '0'),
            _buildSummaryRow('Successful', summary['successfulCollections']?.toString() ?? '0'),
            _buildSummaryRow('Failed', summary['failedCollections']?.toString() ?? '0'),
            _buildSummaryRow('With Data', summary['collectionsWithData']?.toString() ?? '0'),
            _buildSummaryRow('Without Data', summary['collectionsWithoutData']?.toString() ?? '0'),
          ],
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
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedResults() {
    final collections = _testResults!['collections'] as Map<String, dynamic>?;
    if (collections == null) return const SizedBox();

    return ListView(
      children: [
        Text(
          'Collection Details',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        ...collections.entries.map((entry) => _buildCollectionCard(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildCollectionCard(String collectionName, dynamic data) {
    if (data is! Map<String, dynamic>) return const SizedBox();

    final success = data['success'] as bool? ?? false;
    final canRead = data['canRead'] as bool? ?? false;
    final canWrite = data['canWrite'] as bool? ?? false;
    final documentExists = data['documentExists'] as bool? ?? false;
    final error = data['error'] as String?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                Text(
                  collectionName,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildStatusRow('Read Access', canRead),
            _buildStatusRow('Write Access', canWrite),
            _buildStatusRow('Document Exists', documentExists),
            if (error != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Error: $error',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            status ? Icons.check : Icons.close,
            color: status ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Future<void> _runTest() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _testResults = null;
    });

    try {
      final results = await FirebaseCollectionsAccessTest.testAllCollectionsAccess();
      setState(() {
        _testResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }
}
