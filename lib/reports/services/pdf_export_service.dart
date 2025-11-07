import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reports_data_service.dart';

/// Service for exporting PDF reports that can be called from anywhere
class PDFExportService {
  static final PDFExportService _instance = PDFExportService._internal();
  static PDFExportService get instance => _instance;
  PDFExportService._internal();

  /// Export PDF report with comprehensive data
  /// Returns true if successful, false otherwise
  /// Shows error message via ScaffoldMessenger if context is provided
  Future<bool> exportPDFReport(BuildContext? context) async {
    try {
      // Force refresh data from Firebase before exporting to ensure all historical data is included
      final service = ReportsDataService.instance;
      final refreshedData = await service.loadAllReportsData(forceRefresh: true);
      
      // Load assessment data from Firebase
      Map<String, dynamic>? assessmentData;
      try {
        assessmentData = await service.loadAssessmentData(forceRefresh: true);
      } catch (e) {
        debugPrint('PDFExportService: Error loading assessment data: $e');
        // Continue without assessment data if it fails
      }
      
      // Use refreshed data for PDF export
      final reportsDataToExport = refreshedData;
      final pdf = pw.Document();
      final now = DateTime.now();
      final formattedDate = DateFormat('MMMM d, yyyy').format(now);

      // Add content to PDF
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'PocketPT Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.red800,
                      ),
                    ),
                    pw.Text(
                      formattedDate,
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Data freshness section
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Data Freshness',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Report generated: ${DateFormat('MMMM d, yyyy at h:mm a').format(now)}',
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                    ),
                    pw.Text(
                      'Data last updated: ${DateFormat('MMMM d, yyyy at h:mm a').format(reportsDataToExport.lastUpdated)}',
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                    ),
                    pw.Text(
                      'Total records: ${reportsDataToExport.painHistory.length} pain entries, ${reportsDataToExport.exerciseHistory.length} exercise entries',
                      style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Assessment Data section (first page)
              if (assessmentData != null) ...[
                pw.Text(
                  'Assessment Information',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey300),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Table(
                    columnWidths: {
                      0: const pw.FlexColumnWidth(1),
                      1: const pw.FlexColumnWidth(2),
                    },
                    children: [
                      // Display fields in the order specified by user
                      _buildAssessmentRow('Rehabilitation Goal', assessmentData['rehabGoal']?.toString() ?? 'N/A'),
                      _buildAssessmentRow('General Muscle', assessmentData['generalMuscle']?.toString() ?? 'N/A'),
                      _buildAssessmentRow('Specific Muscle', assessmentData['specificMuscle']?.toString() ?? 'N/A'),
                      _buildAssessmentRow('Pain Scale', _formatPainScale(assessmentData['painScale'])),
                      _buildAssessmentRow('Pain Type', assessmentData['painType']?.toString() ?? 'N/A'),
                      _buildAssessmentRow('Pain Duration', assessmentData['painDuration']?.toString() ?? 'N/A'),
                      _buildAssessmentRow('Last Updated', _formatLastUpdated(assessmentData['lastUpdated'])),
                      // Additional fields (if available)
                      if (assessmentData['painLevel'] != null && assessmentData['painLevel'].toString().isNotEmpty)
                        _buildAssessmentRow('Pain Level', assessmentData['painLevel']?.toString() ?? 'N/A'),
                      if (assessmentData['injuredMuscles'] != null)
                        pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                'Injured Muscles',
                                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.all(8),
                              child: pw.Text(
                                (assessmentData['injuredMuscles'] as List<dynamic>?)
                                    ?.join(', ') ?? 'N/A',
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 20),
              ],
              
              // Summary section
              pw.Text(
                'Summary',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Completed Exercises',
                            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                          ),
                          pw.Text(
                            reportsDataToExport.totalCompletedExercises.toString(),
                            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Average Pain Level',
                            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                          ),
                          pw.Text(
                            reportsDataToExport.averagePainLevel.toStringAsFixed(1),
                            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 10),
              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Completion Rate',
                            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                          ),
                          pw.Text(
                            '${(reportsDataToExport.exerciseCompletionRate * 100).toStringAsFixed(1)}%',
                            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Pain Trend',
                            style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
                          ),
                          pw.Text(
                            reportsDataToExport.painTrend > 0 ? 'Increasing' : reportsDataToExport.painTrend < 0 ? 'Decreasing' : 'Stable',
                            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Pain History Trends section
              pw.Text(
                'Pain Level Trends',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              if (reportsDataToExport.painHistory.isEmpty)
                pw.Text(
                  'No pain records found.',
                  style: pw.TextStyle(color: PdfColors.grey600),
                )
              else
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(100),
                    1: const pw.FixedColumnWidth(60),
                    2: const pw.FlexColumnWidth(2),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Scale', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Level', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...reportsDataToExport.painHistory.take(30).map((record) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(DateFormat('MMM d, yyyy').format(record.date)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(record.painScale.toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(record.painLevel),
                        ),
                      ],
                    )).toList(),
                  ],
                ),
              pw.SizedBox(height: 20),
              
              // Exercise History section
              pw.Text(
                'Exercise History',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),
              if (reportsDataToExport.exerciseHistory.isEmpty)
                pw.Text(
                  'No exercise records found.',
                  style: pw.TextStyle(color: PdfColors.grey600),
                )
              else
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  columnWidths: {
                    0: const pw.FixedColumnWidth(80),
                    1: const pw.FlexColumnWidth(2),
                    2: const pw.FixedColumnWidth(60),
                    3: const pw.FixedColumnWidth(60),
                    4: const pw.FixedColumnWidth(80),
                    5: const pw.FixedColumnWidth(80),
                  },
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Exercise', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Sets', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Reps', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Duration', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('Status', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ),
                      ],
                    ),
                    ...reportsDataToExport.exerciseHistory.take(30).map((record) => pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(DateFormat('MMM d').format(record.date)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(record.exerciseName),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(record.sets.toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(record.reps.toString()),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text('${(record.durationSeconds / 60).toStringAsFixed(1)}m'),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(record.status),
                        ),
                      ],
                    )).toList(),
                  ],
                ),
            ];
          },
        ),
      );

      // Save and share the PDF
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
        name: 'PocketPT_Report_${DateFormat('yyyy-MM-dd').format(now)}.pdf',
      );

      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PDF report exported successfully!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
      
      return true;
    } catch (e) {
      debugPrint('PDFExportService: Failed to export PDF: $e');
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
      return false;
    }
  }

  pw.TableRow _buildAssessmentRow(String label, String value) {
    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(
            label,
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(value),
        ),
      ],
    );
  }

  /// Format pain scale as a number
  String _formatPainScale(dynamic painScale) {
    if (painScale == null) return 'N/A';
    if (painScale is num) {
      return painScale.toString();
    }
    if (painScale is String) {
      final parsed = int.tryParse(painScale);
      if (parsed != null) return parsed.toString();
      return painScale;
    }
    return painScale.toString();
  }

  /// Format lastUpdated date/time, handling Firebase Timestamp
  String _formatLastUpdated(dynamic lastUpdated) {
    if (lastUpdated == null) return 'N/A';
    
    DateTime? dateTime;
    
    // Handle Firebase Timestamp
    if (lastUpdated is Timestamp) {
      dateTime = lastUpdated.toDate();
    }
    // Handle DateTime directly
    else if (lastUpdated is DateTime) {
      dateTime = lastUpdated;
    }
    // Handle int timestamp (milliseconds)
    else if (lastUpdated is int) {
      dateTime = DateTime.fromMillisecondsSinceEpoch(lastUpdated);
    }
    // Handle string timestamp
    else if (lastUpdated is String) {
      final parsed = DateTime.tryParse(lastUpdated);
      if (parsed != null) {
        dateTime = parsed;
      } else {
        final intParsed = int.tryParse(lastUpdated);
        if (intParsed != null) {
          dateTime = DateTime.fromMillisecondsSinceEpoch(intParsed);
        }
      }
    }
    // Handle Map (Firebase Timestamp serialized)
    else if (lastUpdated is Map) {
      try {
        final seconds = lastUpdated['_seconds'] as int?;
        if (seconds != null) {
          dateTime = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      } catch (e) {
        debugPrint('PDFExportService: Error parsing timestamp from Map: $e');
      }
    }
    
    if (dateTime != null) {
      return DateFormat('MMMM d, yyyy at h:mm a').format(dateTime);
    }
    
    return lastUpdated.toString();
  }
}

