import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/user_data_notifier.dart';
import '../../core/animations.dart';
import '../services/reports_data_service.dart';
import '../services/pdf_export_service.dart';
import '../../tutorials/tutorial_config.dart';

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
                key: TutorialAnchors.reportsExportPdf,
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
      // Use the PDF export service
      final success = await PDFExportService.instance.exportPDFReport(context);
      
      if (!success) {
        setState(() {
          _exportError = 'Failed to export PDF report';
        });
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