import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Mixin to provide consistent structure and layout for assessment pages
/// No Firebase/Hive dependencies - uses local data storage
mixin AssessmentPageMixin<T extends StatefulWidget> on State<T> {
  bool _isDataLoaded = true; // Always loaded since we use local data
  bool _isLoading = false;

  // Professional healthcare color scheme
  static const mainColor = Color(0xFF8B2E2E);
  static const subColor = Color(0xFFC24A4A);
  static const detailColor = Color(0xFF6B7280);
  static const backgroundColor = Color(0xFFF8FAFC);
  static const successColor = Color(0xFF10B981);

  /// Initialize assessment data (no loading needed for local data)
  void initializeAssessmentData() {
    print('${T.toString()}: Initializing assessment data (local storage)');
    // Data is always available since it's stored locally
    _isDataLoaded = true;
    _isLoading = false;
  }

  /// Refresh assessment data (no-op for local data)
  Future<void> refreshAssessmentData() async {
    print('${T.toString()}: Refreshing assessment data (local storage)');
    // No refresh needed for local data
  }

  /// Check if data is loaded
  bool get isDataLoaded => _isDataLoaded;
  bool get isLoading => _isLoading;

  /// Build standard loading state
  Widget buildLoadingState(String title, String subtitle) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: mainColor,
        title: Text(
          title,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(mainColor),
                        strokeWidth: 3,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        "Loading Assessment",
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: mainColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: GoogleFonts.ptSans(
                          fontSize: 14,
                          color: detailColor,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Save assessment data (no-op for local data)
  Future<void> saveAssessmentData() async {
    print('${T.toString()}: Assessment data is automatically saved locally');
    // Data is automatically saved in local variables, no additional action needed
  }

  /// Check if should show loading state (always false for local data)
  bool get shouldShowLoading => false;

  /// Build a safe non-scrolling body with SafeArea
  Widget buildSafeBody({
    required List<Widget> children,
    EdgeInsetsGeometry? padding,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    return SafeArea(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: crossAxisAlignment,
          children: children,
        ),
      ),
    );
  }

  /// Build a safe scrollable body
  Widget buildSafeScrollView({
    required List<Widget> children,
    EdgeInsetsGeometry? padding,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    return SingleChildScrollView(
      padding: padding ?? const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      ),
    );
  }

  /// Build a standard app bar for assessment pages
  PreferredSizeWidget buildAssessmentAppBar(String title, {VoidCallback? onRefresh}) {
    return AppBar(
      backgroundColor: AssessmentPageMixin.mainColor,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.w700,
          fontSize: 20,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
      actions: onRefresh != null ? [
        IconButton(
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, color: Colors.white),
        ),
      ] : [
        const SizedBox(width: 48), // Balance the back button
      ],
    );
  }

  /// Build a progress section widget
  Widget buildProgressSection(int currentStep, int totalSteps, String stepName) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AssessmentPageMixin.mainColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.track_changes,
              color: AssessmentPageMixin.mainColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Assessment Progress",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AssessmentPageMixin.mainColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Step $currentStep of $totalSteps - $stepName",
                  style: GoogleFonts.ptSans(
                    fontSize: 14,
                    color: AssessmentPageMixin.detailColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build a question section widget
  Widget buildQuestionSection(String title, String description, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE5E7EB),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AssessmentPageMixin.mainColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: AssessmentPageMixin.mainColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AssessmentPageMixin.mainColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: GoogleFonts.ptSans(
              fontSize: 16,
              color: AssessmentPageMixin.detailColor,
            ),
          ),
        ],
      ),
    );
  }
}
