import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../providers/report_providers.dart';

class ExportPDFButton extends ConsumerWidget {
  const ExportPDFButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
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
                    onPressed: () => _generateAndExportPDF(context, ref),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
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

  Future<void> _generateAndExportPDF(BuildContext context, WidgetRef ref) async {
    final rehabPlans = ref.read(rehabPlansProvider);
    final exerciseRecords = ref.read(exerciseRecordsProvider);
    final pdf = pw.Document();

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
          _buildRehabPlansSection(rehabPlans),
          pw.SizedBox(height: 24),
          _buildExerciseRecordsSection(exerciseRecords),
          pw.SizedBox(height: 24),
          _buildFooter(),
        ],
      ),
    );

    try {
      await Printing.sharePdf(
        bytes: await pdf.save(),
        filename: 'pocketpt_report_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
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
            pw.Text(
              'PocketPT Progress Report',
              style: pw.TextStyle(
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF6A5D7B), // Updated to new purple
              ),
            ),
            pw.Text(
              DateFormat('MMMM d, yyyy').format(DateTime.now()),
              style: pw.TextStyle(
                fontSize: 12,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
        pw.Divider(
          thickness: 1.5,
          color: PdfColor.fromInt(0xFF6A5D7B), // Updated to new purple
        ),
        pw.SizedBox(height: 8),
      ],
    );
  }

  pw.Widget _buildRehabPlansSection(List<RehabPlan> plans) {
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
                  plan.title,
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 6),
                _buildDetailRow('ICD-10 Code:', plan.icdCode),
                _buildDetailRow('Status:', plan.status),
                _buildDetailRow(
                  'Start Date:', 
                  DateFormat('MMMM d, yyyy').format(plan.startDate),
                ),
                _buildDetailRow('Focus Area:', plan.focusArea),
                _buildDetailRow('Target Muscle:', plan.targetMuscle),
              ],
            ),
          ),
        )),
      ],
    );
  }

  pw.Widget _buildExerciseRecordsSection(List<ExerciseRecord> records) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Exercise Records',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF6A5D7B), // Updated to new purple
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(
            color: PdfColors.grey300,
            width: 0.5,
          ),
          columnWidths: {
            0: const pw.FlexColumnWidth(1.5),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: PdfColor.fromInt(0x1A6A5D7B), // Updated to new purple with 10% opacity
              ),
              children: [
                _tableCell('Date', bold: true, center: true),
                _tableCell('Exercise', bold: true),
                _tableCell('Sets', bold: true, center: true),
                _tableCell('Reps', bold: true, center: true),
                _tableCell('Status', bold: true, center: true),
              ],
            ),
            ...records.map((record) => pw.TableRow(
              decoration: pw.BoxDecoration(
                color: records.indexOf(record).isEven
                    ? PdfColors.grey50
                    : PdfColors.white,
              ),
              children: [
                _tableCell(
                  DateFormat('MMM d, yyyy').format(record.date),
                  center: true,
                ),
                _tableCell(record.exerciseName),
                _tableCell(record.sets.toString(), center: true),
                _tableCell(record.reps.toString(), center: true),
                _tableCell(
                  record.status,
                  center: true,
                  color: record.status.toLowerCase() == 'completed'
                      ? PdfColor.fromInt(0xFF4CAF50) // Green for completed
                      : PdfColor.fromInt(0xFFF44336), // Red for others
                ),
              ],
            )),
          ],
        ),
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

  pw.Widget _buildFooter() {
    return pw.Column(
      children: [
        pw.Divider(
          thickness: 1,
          color: PdfColors.grey300,
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          'Generated by PocketPT - ${DateFormat('MMMM d, yyyy').format(DateTime.now())}',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
      ],
    );
  }
}