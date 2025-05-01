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
          icon: const Icon(Icons.picture_as_pdf),
          label: const Text('Export PDF Report'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
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
                fontSize: 24,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              DateFormat('MMMM d, yyyy').format(DateTime.now()),
              style: const pw.TextStyle(fontSize: 14),
            ),
          ],
        ),
        pw.Divider(thickness: 2),
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
          text: 'Rehabilitation Plans',
        ),
        pw.SizedBox(height: 10),
        ...plans.map((plan) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    plan.title,
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
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
        pw.Header(
          level: 1,
          text: 'Exercise Records',
        ),
        pw.SizedBox(height: 10),
        pw.Table.fromTextArray(
          headers: ['Date', 'Exercise', 'Sets', 'Reps', 'Status'],
          data: records.map((record) => [
            DateFormat('MM/dd/yyyy').format(record.date),
            record.exerciseName,
            record.sets.toString(),
            record.reps.toString(),
            record.status,
          ]).toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          cellAlignment: pw.Alignment.center,
          cellStyle: const pw.TextStyle(fontSize: 12),
          headerDecoration: pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          border: pw.TableBorder.all(),
          cellHeight: 25,
        ),
      ],
    );
  }
} 