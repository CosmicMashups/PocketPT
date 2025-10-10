import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../data/globals.dart';
import '../../data/rehabilitation_plan.dart';
import '../../data/user_data_notifier.dart';

class ExportPDFButton extends StatefulWidget {
  const ExportPDFButton({super.key});

  @override
  State<ExportPDFButton> createState() => _ExportPDFButtonState();
}

class _ExportPDFButtonState extends State<ExportPDFButton> {
  @override
  void initState() {
    super.initState();
    // Listen for rehabilitation plan changes
    UserDataNotifier.instance.addListener(_onRehabilitationPlanChanged);
  }
  
  @override
  void dispose() {
    UserDataNotifier.instance.removeListener(_onRehabilitationPlanChanged);
    super.dispose();
  }
  
  void _onRehabilitationPlanChanged() {
    if (mounted) {
      setState(() {
        // Trigger rebuild when rehabilitation plans change
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generate Report',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF6A5D7B), // Updated to new purple
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Export your rehabilitation progress and exercise records as a PDF document.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf, size: 24),
                    label: const Text(
                      'Export PDF Report',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: const Color(0xFF6A5D7B), // Updated to new purple
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    onPressed: () => _generateAndExportPDF(context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What\'s included in the report:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6A5D7B), // Updated to new purple
                      ),
                ),
                const SizedBox(height: 12),
                _buildFeatureItem(context, Icons.assignment, 'Rehabilitation Plans Overview'),
                _buildFeatureItem(context, Icons.fitness_center, 'Exercise Records'),
                _buildFeatureItem(context, Icons.calendar_today, 'Date Range Summary'),
                _buildFeatureItem(context, Icons.assessment, 'Progress Statistics'),
                _buildFeatureItem(context, Icons.analytics, 'Pain Level Tracking'),
                _buildFeatureItem(context, Icons.edit_note, 'User Notes & Observations'),
                _buildFeatureItem(context, Icons.timeline, 'Plan Changes & Modifications'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF6A5D7B), size: 20), // Updated to new purple
          const SizedBox(width: 12),
          Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndExportPDF(BuildContext context) async {
    // Use the most up-to-date rehabilitation plans from UserDataNotifier
    final rehabPlans = UserDataNotifier.instance.rehabPlans.isNotEmpty 
        ? UserDataNotifier.instance.rehabPlans 
        : UserRehabilitation.instance.rehabPlans;
    final pdf = pw.Document();

    // Load data from globals
    await PainHistory.loadFromHive();
    await ExerciseHistory.loadFromHive();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(
          base: await PdfGoogleFonts.openSansRegular(),
          bold: await PdfGoogleFonts.openSansBold(),
        ),
        build: (context) => [
          _buildHeader(),
          pw.SizedBox(height: 24),
          _buildPatientInfoSection(),
          pw.SizedBox(height: 24),
          _buildPainTrackingSection(),
          pw.SizedBox(height: 24),
          _buildDailyExerciseLogSection(),
          pw.SizedBox(height: 24),
          _buildRehabPlansSection(rehabPlans),
          pw.SizedBox(height: 24),
          _buildPlanChangesSection(),
          pw.SizedBox(height: 24),
          _buildUserNotesSection(),
          pw.SizedBox(height: 24),
          _buildProgressStatisticsSection(),
          pw.SizedBox(height: 24),
          _buildFooter(),
        ],
      ),
    );

    try {
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'pocketpt_therapy_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  pw.Widget _buildHeader() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'PocketPT Physical Therapy Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF6A5D7B),
                  ),
                ),
                pw.Text(
                  'Patient Progress Monitoring Report',
                  style: pw.TextStyle(
                    fontSize: 14,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  DateFormat('MMMM d, yyyy').format(DateTime.now()),
                  style: pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.Text(
                  'Report Period: ${_getReportPeriod()}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey500,
                  ),
                ),
              ],
            ),
          ],
        ),
        pw.Divider(
          thickness: 1.5,
          color: PdfColor.fromInt(0xFF6A5D7B),
        ),
        pw.SizedBox(height: 8),
      ],
    );
  }

  pw.Widget _buildRehabPlansSection(List<RehabilitationPlan> plans) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Rehabilitation Plans',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF6A5D7B), // Updated to new purple
          ),
        ),
        pw.SizedBox(height: 12),
        ...plans.map((plan) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            borderRadius: pw.BorderRadius.circular(8),
            color: PdfColors.grey50,
          ),
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(12),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Week ${plan.weekNumber} Plan',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                _buildDetailRow('Week Number:', plan.weekNumber.toString()),
                _buildDetailRow('Status:', plan.isActive ? 'Active' : 'Inactive'),
                _buildDetailRow(
                  'Created Date:', 
                  DateFormat('MMMM d, yyyy').format(plan.createdAt),
                ),
                _buildDetailRow('Exercise Count:', plan.exerciseReferences.length.toString()),
                _buildDetailRow('Daily Entries:', plan.daily.length.toString()),
              ],
            ),
          ),
        )),
      ],
    );
  }


  pw.Widget _buildDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _tableCell(
    String text, {
    bool bold = false,
    bool center = false,
    PdfColor? color,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        textAlign: center ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: color ?? PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget _buildPatientInfoSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Patient Information',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF6A5D7B),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            borderRadius: pw.BorderRadius.circular(8),
            color: PdfColors.grey50,
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Patient Name:', '${UserDetails.firstName} ${UserDetails.lastName}'),
              _buildDetailRow('Email:', UserDetails.email),
              _buildDetailRow('Assessment Date:', DateFormat('MMMM d, yyyy').format(DateTime.now())),
              _buildDetailRow('Target Muscle:', UserAssess.specificMuscle.isNotEmpty ? UserAssess.specificMuscle : 'Not specified'),
              _buildDetailRow('Pain Duration:', UserAssess.painDuration.isNotEmpty ? UserAssess.painDuration : 'Not specified'),
              _buildDetailRow('Rehabilitation Goal:', UserAssess.rehabGoal.isNotEmpty ? UserAssess.rehabGoal : 'Not specified'),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildPainTrackingSection() {
    final painEntries = PainHistory.entries;
    if (painEntries.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Pain Level Tracking',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF6A5D7B),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: pw.BorderRadius.circular(8),
              color: PdfColors.grey50,
            ),
            child: pw.Text(
              'No pain level data available',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            ),
          ),
        ],
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Pain Level Tracking',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF6A5D7B),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey300,
            width: 0.5,
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0x1A6A5D7B),
              ),
              children: [
                _tableCell('Date', bold: true, center: true),
                _tableCell('Pain Scale', bold: true, center: true),
                _tableCell('Pain Level', bold: true, center: true),
              ],
            ),
            ...painEntries.map((entry) => pw.TableRow(
              decoration: pw.BoxDecoration(
                color: painEntries.indexOf(entry).isEven
                    ? PdfColors.grey50
                    : PdfColors.white,
              ),
              children: [
                _tableCell(
                  DateFormat('MMM d, yyyy').format(entry.date),
                  center: true,
                ),
                _tableCell(
                  entry.painScale.toString(),
                  center: true,
                  color: _getPainColor(entry.painScale),
                ),
                _tableCell(
                  entry.painLevel,
                  center: true,
                  color: _getPainColor(entry.painScale),
                ),
              ],
            )),
          ],
        ),
      ],
    );
  }

  pw.Widget _buildDailyExerciseLogSection() {
    final exerciseEntries = ExerciseHistory.entries;
    if (exerciseEntries.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Daily Exercise Log',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromInt(0xFF6A5D7B),
            ),
          ),
          pw.SizedBox(height: 12),
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: pw.BorderRadius.circular(8),
              color: PdfColors.grey50,
            ),
            child: pw.Text(
              'No exercise data available',
              style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600),
            ),
          ),
        ],
      );
    }

    // Group exercises by date
    final Map<DateTime, List<ExerciseRecordEntry>> exercisesByDate = {};
    for (final entry in exerciseEntries) {
      final date = DateTime(entry.date.year, entry.date.month, entry.date.day);
      exercisesByDate.putIfAbsent(date, () => []).add(entry);
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Daily Exercise Log',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF6A5D7B),
          ),
        ),
        pw.SizedBox(height: 12),
        ...exercisesByDate.entries.map((dateEntry) {
          final date = dateEntry.key;
          final exercises = dateEntry.value;
          
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
              borderRadius: pw.BorderRadius.circular(8),
              color: PdfColors.grey50,
            ),
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(12),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    DateFormat('EEEE, MMMM d, yyyy').format(date),
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Table(
                    border: pw.TableBorder.all(
                      color: PdfColors.grey300,
                      width: 0.5,
                    ),
                    columnWidths: {
                      0: const pw.FlexColumnWidth(3),
                      1: const pw.FlexColumnWidth(1),
                      2: const pw.FlexColumnWidth(1),
                      3: const pw.FlexColumnWidth(1.5),
                      4: const pw.FlexColumnWidth(1.5),
                    },
                    children: [
                      pw.TableRow(
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromInt(0x1A6A5D7B),
                        ),
                        children: [
                          _tableCell('Exercise', bold: true),
                          _tableCell('Sets', bold: true, center: true),
                          _tableCell('Reps', bold: true, center: true),
                          _tableCell('Duration', bold: true, center: true),
                          _tableCell('Status', bold: true, center: true),
                        ],
                      ),
                      ...exercises.map((exercise) => pw.TableRow(
                        children: [
                          _tableCell(exercise.exerciseName),
                          _tableCell(exercise.sets.toString(), center: true),
                          _tableCell(exercise.reps.toString(), center: true),
                          _tableCell('${(exercise.durationSeconds / 60).toStringAsFixed(1)}m', center: true),
                          _tableCell(
                            exercise.status,
                            center: true,
                            color: exercise.status.toLowerCase() == 'completed'
                                ? PdfColor.fromInt(0xFF4CAF50)
                                : exercise.status.toLowerCase() == 'partial'
                                    ? PdfColor.fromInt(0xFFFF9800)
                                    : PdfColor.fromInt(0xFFF44336),
                          ),
                        ],
                      )),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  pw.Widget _buildPlanChangesSection() {
    // This would track plan modifications - for now showing current plan structure
    final userRehab = UserRehabilitation.instance;
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Rehabilitation Plan Changes',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF6A5D7B),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            borderRadius: pw.BorderRadius.circular(8),
            color: PdfColors.grey50,
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Current Plan:', 'Week ${userRehab.rehabPlans.isNotEmpty ? userRehab.rehabPlans.first.weekNumber : 'N/A'} - ${userRehab.selectedMuscle} Rehabilitation'),
              _buildDetailRow('Total Plans:', userRehab.rehabPlans.length.toString()),
              _buildDetailRow('Target Muscle:', userRehab.selectedMuscle),
              _buildDetailRow('Pain Level:', userRehab.selectedPainLevel),
              _buildDetailRow('Pain Duration:', userRehab.selectedPainDuration),
              if (userRehab.treatmentReferences != null && userRehab.treatmentReferences!.isNotEmpty)
                _buildDetailRow('Active Treatments:', userRehab.treatmentReferences!.length.toString()),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildUserNotesSection() {
    final notes = UserProgress.notes;
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'User Notes & Observations',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF6A5D7B),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            borderRadius: pw.BorderRadius.circular(8),
            color: PdfColors.grey50,
          ),
          child: pw.Text(
            notes?.isNotEmpty == true ? notes! : 'No notes recorded',
            style: pw.TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildProgressStatisticsSection() {
    final painEntries = PainHistory.entries;
    final exerciseEntries = ExerciseHistory.entries;
    
    // Calculate statistics
    final totalDays = painEntries.isNotEmpty ? 
        DateTime.now().difference(painEntries.first.date).inDays + 1 : 0;
    final avgPainLevel = painEntries.isNotEmpty ? 
        painEntries.map((e) => e.painScale).reduce((a, b) => a + b) / painEntries.length : 0;
    final totalExercises = exerciseEntries.where((e) => e.status == 'completed').length;
    final totalExerciseTime = exerciseEntries.fold(0, (sum, e) => sum + e.durationSeconds);
    
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Progress Statistics',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF6A5D7B),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          children: [
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(8),
                  color: PdfColors.grey50,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Pain Management',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    _buildDetailRow('Average Pain Level:', avgPainLevel.toStringAsFixed(1)),
                    _buildDetailRow('Total Assessments:', painEntries.length.toString()),
                    _buildDetailRow('Days Tracked:', totalDays.toString()),
                  ],
                ),
              ),
            ),
            pw.SizedBox(width: 12),
            pw.Expanded(
              child: pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
                  borderRadius: pw.BorderRadius.circular(8),
                  color: PdfColors.grey50,
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Exercise Progress',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    _buildDetailRow('Completed Exercises:', totalExercises.toString()),
                    _buildDetailRow('Total Exercise Time:', '${(totalExerciseTime / 60).toStringAsFixed(1)} minutes'),
                    _buildDetailRow('Current Streak:', UserProgress.streak.toString()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _getReportPeriod() {
    final painEntries = PainHistory.entries;
    if (painEntries.isEmpty) return 'No data available';
    
    final startDate = painEntries.first.date;
    final endDate = painEntries.last.date;
    
    if (startDate.year == endDate.year && startDate.month == endDate.month) {
      return '${DateFormat('MMM d').format(startDate)} - ${DateFormat('d, yyyy').format(endDate)}';
    } else {
      return '${DateFormat('MMM d, yyyy').format(startDate)} - ${DateFormat('MMM d, yyyy').format(endDate)}';
    }
  }

  PdfColor _getPainColor(int painScale) {
    if (painScale <= 3) return PdfColor.fromInt(0xFF4CAF50); // Green
    if (painScale <= 7) return PdfColor.fromInt(0xFFFF9800); // Orange
    return PdfColor.fromInt(0xFFF44336); // Red
  }

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(
          thickness: 1,
          color: PdfColors.grey300,
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Generated by PocketPT Physical Therapy App - ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          'This report is intended for healthcare professionals and contains confidential patient information.',
          style: pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey500,
          ),
        ),
      ],
    );
  }
}