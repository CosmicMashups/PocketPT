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
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
          label: const Text(
            'Export PDF Report',
            style: TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            backgroundColor: Colors.blueAccent,  // Custom blue background color
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),  // Rounded corners
            ),
          ),
          onPressed: () => _generateAndExportPDF(context, ref),
        ),
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
        build: (context) => [
          _buildHeader(),
          _buildRehabPlansSection(rehabPlans),
          _buildExerciseRecordsSection(exerciseRecords),
        ],
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'progress_report_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.pdf',
    );
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
                fontSize: 26,  // Larger font for title
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromInt(0xFF8B2E2E),  // Custom title color
              ),
            ),
            pw.Text(
              DateFormat('MMMM d, yyyy').format(DateTime.now()),
              style: const pw.TextStyle(
                fontSize: 14,
                color: PdfColors.grey,
              ),
            ),
          ],
        ),
        pw.Divider(thickness: 2, color: PdfColor.fromInt(0xFF8B2E2E)),  // Custom divider color
        pw.SizedBox(height: 20),
      ],
    );
  }

  pw.Widget _buildRehabPlansSection(List<RehabPlan> plans) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Header(
          level: 1,
          text: 'Rehabilitation Plans',  // Pass the text as a string
        ),
        pw.SizedBox(height: 10),
        pw.Text(  // Apply styling with pw.Text here
          'Rehabilitation Plans',
          style: pw.TextStyle(
            fontSize: 18,  // Increased header size
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromInt(0xFF8B2E2E),  // Custom header color
          ),
        ),
        pw.SizedBox(height: 10),
        ...plans.map((plan) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                color: PdfColors.grey100,  // Light background color for the rehab plan section
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    plan.title,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text('ICD-10: ${plan.icdCode}'),
                  pw.Text('Status: ${plan.status}'),
                  pw.Text('Start Date: ${DateFormat('MM/dd/yyyy').format(plan.startDate)}'),
                  pw.Text('Focus Area: ${plan.focusArea}'),
                  pw.Text('Target Muscle: ${plan.targetMuscle}'),
                ],
              ),
            ),
            pw.SizedBox(height: 10),
          ],
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
            color: PdfColor.fromInt(0xFF8B2E2E),
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Table(
          border: pw.TableBorder.all(),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(3),
            2: const pw.FlexColumnWidth(1),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(2),
          },
          children: [
            // Header row
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColors.grey300),
              children: [
                _tableCell('Date', bold: true),
                _tableCell('Exercise', bold: true),
                _tableCell('Sets', bold: true),
                _tableCell('Reps', bold: true),
                _tableCell('Status', bold: true),
              ],
            ),
            // Data rows
            for (int i = 0; i < records.length; i++)
              pw.TableRow(
                decoration: i.isEven
                    ? pw.BoxDecoration(color: PdfColors.grey50)
                    : null,
                children: [
                  _tableCell(DateFormat('MM/dd/yyyy').format(records[i].date)),
                  _tableCell(records[i].exerciseName),
                  _tableCell(records[i].sets.toString()),
                  _tableCell(records[i].reps.toString()),
                  _tableCell(records[i].status),
                ],
              ),
          ],
        ),
      ],
    );
  }

  // Helper method for table cells
  pw.Widget _tableCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8.0),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 12,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }
}