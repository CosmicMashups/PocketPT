import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../data/user_data_notifier.dart';
import '../../core/animations.dart';
import '../services/reports_data_service.dart';

class ExportPDFButton extends ConsumerStatefulWidget {
  const ExportPDFButton({super.key});

  @override
  ConsumerState<ExportPDFButton> createState() => _ExportPDFButtonState();
}

class _ExportPDFButtonState extends ConsumerState<ExportPDFButton> with TickerProviderStateMixin {
  bool _isExporting = false;
  String? _exportError;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = PocketPTAnimations.createController(
      this,
      duration: PocketPTAnimations.medium,
    );
    // Listen for rehabilitation plan changes
    UserDataNotifier.instance.addListener(_onRehabilitationPlanChanged);
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    UserDataNotifier.instance.removeListener(_onRehabilitationPlanChanged);
    super.dispose();
  }
  
  void _onRehabilitationPlanChanged() {
    // Defer setState to avoid calling during build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          // Trigger rebuild when rehabilitation plans change
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reportsDataAsync = ref.watch(reportsDataProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Theme.of(context).colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: reportsDataAsync.when(
        loading: () => _buildLoadingState(context, isDark),
        error: (error, stackTrace) => _buildErrorState(context, isDark, error.toString()),
        data: (reportsData) => _buildExportContent(context, isDark, reportsData),
      ),
    );
  }

  Widget _buildLoadingState(BuildContext context, bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B2E2E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.picture_as_pdf,
                color: Color(0xFF8B2E2E),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Export Reports',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF8B2E2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Center(
          child: CircularProgressIndicator(),
        ),
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, bool isDark, String error) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Export Reports',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF8B2E2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.red.withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 32),
              const SizedBox(height: 8),
              Text(
                'Failed to load data for export',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                error,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExportContent(BuildContext context, bool isDark, ReportsData reportsData) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF8B2E2E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.picture_as_pdf,
                color: Color(0xFF8B2E2E),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Export Reports',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF8B2E2E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (_exportError != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _exportError!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red, size: 16),
                  onPressed: () {
                    setState(() {
                      _exportError = null;
                    });
                  },
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : () => _exportPDF(context, reportsData),
                icon: _isExporting 
                    ? AnimatedBuilder(
                        animation: _animationController,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _animationController.value * 2 * 3.14159,
                            child: const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        },
                      )
                    : const Icon(Icons.picture_as_pdf, size: 18),
                label: Text(_isExporting ? 'Exporting...' : 'Export PDF Report'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B2E2E),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _exportPDF(BuildContext context, ReportsData reportsData) async {
    setState(() {
      _isExporting = true;
      _exportError = null;
    });
    _animationController.repeat();

    try {
      // Force refresh data from Firebase before exporting to ensure all historical data is included
      final service = ReportsDataService.instance;
      final refreshedData = await service.loadAllReportsData(forceRefresh: true);
      
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PDF report exported successfully!'),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _exportError = 'Failed to export PDF: ${e.toString()}';
      });
    } finally {
      if (mounted) {
        _animationController.stop();
        setState(() {
          _isExporting = false;
        });
      }
    }
  }
}