import 'package:flutter/material.dart';
import 'a_goal1.dart';
import 'b_focus1.dart';
import 'assessment_data.dart';

/// Test widget to verify assessment pages work correctly
class TestAssessmentPages extends StatelessWidget {
  const TestAssessmentPages({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Assessment Pages'),
        backgroundColor: const Color(0xFF8B2E2E),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Reset Data Button
            ElevatedButton(
              onPressed: () {
                AssessmentData.reset();
                print('Assessment data reset');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Reset Assessment Data'),
            ),
            const SizedBox(height: 16),
            
            // View Current Data Button
            ElevatedButton(
              onPressed: () {
                print('Current Assessment Data:');
                AssessmentData.printData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Check console for assessment data'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('View Current Data'),
            ),
            const SizedBox(height: 16),
            
            // Navigate to Goal Page
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AssessGoal1()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B2E2E),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Test Goal Selection Page'),
            ),
            const SizedBox(height: 16),
            
            // Navigate to Focus Page
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AssessFocus1()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC24A4A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
              child: const Text('Test Focus Area Page'),
            ),
            const SizedBox(height: 24),
            
            // Current Data Display
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Assessment Data:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Rehab Goal: ${AssessmentData.rehabGoal.isEmpty ? "Not selected" : AssessmentData.rehabGoal}'),
                  Text('General Muscle: ${AssessmentData.generalMuscle.isEmpty ? "Not selected" : AssessmentData.generalMuscle}'),
                  Text('Progress: ${(AssessmentData.progressPercentage * 100).toStringAsFixed(1)}%'),
                  Text('Complete: ${AssessmentData.isComplete ? "Yes" : "No"}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
