import 'package:flutter/material.dart';

import 'overlay_tooltip.dart';
import 'showcase_integration.dart';
import 'tutorial_models.dart';
import 'tutorial_preferences.dart';
import 'tutorial_service.dart';

/// Centralized registry for tutorial anchors and step metadata.
class TutorialAnchors {
  TutorialAnchors._();

  static final GlobalKey dashboardNotifications = GlobalKey(debugLabel: 'tutorial_dashboard_notifications');
  static final GlobalKey dashboardProgressCta = GlobalKey(debugLabel: 'tutorial_dashboard_progress_cta');
  static final GlobalKey assessmentPrelimStart = GlobalKey(debugLabel: 'tutorial_assessment_start');
  static final GlobalKey recordCameraToggle = GlobalKey(debugLabel: 'tutorial_record_camera_toggle');
  static final GlobalKey recordPauseButton = GlobalKey(debugLabel: 'tutorial_record_pause');
  static final GlobalKey recordFinishButton = GlobalKey(debugLabel: 'tutorial_record_finish');
  static final GlobalKey reportsExportPdf = GlobalKey(debugLabel: 'tutorial_reports_export_pdf');
  static final GlobalKey welcomeSignIn = GlobalKey(debugLabel: 'tutorial_welcome_sign_in');
  static final GlobalKey welcomeGuest = GlobalKey(debugLabel: 'tutorial_welcome_guest');
  static final GlobalKey welcomeRegister = GlobalKey(debugLabel: 'tutorial_welcome_register');
  static final GlobalKey profileLogout = GlobalKey(debugLabel: 'tutorial_profile_logout');
}

/// Tutorial registry definition used by [TutorialService].
class TutorialRegistry {
  static const String defaultFeatureFlag = 'tutorials_enabled';

  static final List<TutorialStep> steps = <TutorialStep>[
    TutorialStep(
      id: 'dashboard_notifications_badge',
      pageId: 'dashboard',
      anchorKey: TutorialAnchors.dashboardNotifications,
      title: 'Check Alerts',
      description: 'Open the bell to review reminders, pain alerts, and plan updates.',
      longText: 'You will receive assessment prompts, new plan suggestions, and adherence reminders here.',
      placement: TutorialPlacement.bottom,
      highlightShape: TutorialHighlightShape.circle,
      priority: TutorialPriority.critical,
      flowId: 'onboarding_dashboard',
      order: 1,
      featureFlagId: defaultFeatureFlag,
      fallback: const TutorialFallback(
        message: 'Find notifications from the bell icon at the top right.',
        alignment: Alignment.topRight,
      ),
      metadata: <String, Object?>{
        'file': 'lib/dashboard/dashboard_page.dart',
        'line_start': 743,
        'widget_type': 'IconButton',
        'skip_if_seen': true,
      },
    ),
    TutorialStep(
      id: 'dashboard_progress_cta',
      pageId: 'dashboard',
      anchorKey: TutorialAnchors.dashboardProgressCta,
      title: 'Resume Session',
      description: 'Tap to jump back into your guided exercise recording or start today’s routine.',
      longText: 'This button opens the recording flow with your next prescribed exercise.',
      placement: TutorialPlacement.top,
      highlightShape: TutorialHighlightShape.roundedRect,
      priority: TutorialPriority.critical,
      flowId: 'onboarding_dashboard',
      order: 2,
      featureFlagId: defaultFeatureFlag,
      fallback: const TutorialFallback(
        message: 'Use the green Start / Resume button on the dashboard cards to record exercises.',
      ),
      metadata: <String, Object?>{
        'file': 'lib/dashboard/dashboard_page.dart',
        'line_start': 912,
        'widget_type': 'InkWell',
        'skip_if_seen': true,
      },
    ),
    TutorialStep(
      id: 'assessment_preliminary_start',
      pageId: 'assessment_preliminary',
      anchorKey: TutorialAnchors.assessmentPrelimStart,
      title: 'Begin Assessment',
      description: 'Start your clinical assessment to tailor plans to your goals and symptoms.',
      longText: 'We guide you through goals, pain checks, history, and camera assessments.',
      placement: TutorialPlacement.top,
      highlightShape: TutorialHighlightShape.roundedRect,
      priority: TutorialPriority.critical,
      flowId: 'onboarding_assessment',
      order: 1,
      featureFlagId: defaultFeatureFlag,
      fallback: const TutorialFallback(
        message: 'Use the large gradient button at the bottom to progress through the assessment.',
      ),
      metadata: <String, Object?>{
        'file': 'lib/assessment/preliminary.dart',
        'line_start': 192,
        'widget_type': 'ElevatedButton',
        'skip_if_seen': true,
      },
    ),
    TutorialStep(
      id: 'record_camera_toggle',
      pageId: 'record_exercise',
      anchorKey: TutorialAnchors.recordCameraToggle,
      title: 'Switch Camera',
      description: 'Swap between front and rear cameras without leaving the recording session.',
      placement: TutorialPlacement.right,
      highlightShape: TutorialHighlightShape.circle,
      priority: TutorialPriority.important,
      flowId: 'onboarding_camera',
      order: 1,
      cameraSafe: true,
      featureFlagId: defaultFeatureFlag,
      fallback: const TutorialFallback(
        message: 'Use the camera switch icon near the preview to toggle viewpoints.',
        alignment: Alignment.topLeft,
      ),
      metadata: <String, Object?>{
        'file': 'lib/record/record_exercise.dart',
        'line_start': 505,
        'widget_type': 'InkWell',
        'skip_if_seen': true,
      },
    ),
    TutorialStep(
      id: 'record_pause_button',
      pageId: 'record_exercise',
      anchorKey: TutorialAnchors.recordPauseButton,
      title: 'Pause & Rest',
      description: 'Pause recording to log partial progress and review instructions.',
      placement: TutorialPlacement.top,
      highlightShape: TutorialHighlightShape.roundedRect,
      priority: TutorialPriority.critical,
      flowId: 'onboarding_camera',
      order: 2,
      featureFlagId: defaultFeatureFlag,
      fallback: const TutorialFallback(
        message: 'Pause via the red Pause button in the bottom control bar.',
      ),
      metadata: <String, Object?>{
        'file': 'lib/record/record_exercise.dart',
        'line_start': 1048,
        'widget_type': 'InkWell',
        'skip_if_seen': true,
      },
    ),
    TutorialStep(
      id: 'record_finish_button',
      pageId: 'record_exercise',
      anchorKey: TutorialAnchors.recordFinishButton,
      title: 'Finish & Save',
      description: 'Complete the set to review cooldown guidance and save metrics.',
      placement: TutorialPlacement.top,
      highlightShape: TutorialHighlightShape.roundedRect,
      priority: TutorialPriority.critical,
      flowId: 'onboarding_camera',
      order: 3,
      featureFlagId: defaultFeatureFlag,
      fallback: const TutorialFallback(
        message: 'Tap the green Proceed or Finish button at the bottom to move on.',
      ),
      metadata: <String, Object?>{
        'file': 'lib/record/record_exercise.dart',
        'line_start': 1097,
        'widget_type': 'InkWell',
        'skip_if_seen': true,
      },
    ),
    TutorialStep(
      id: 'reports_export_pdf',
      pageId: 'reports',
      anchorKey: TutorialAnchors.reportsExportPdf,
      title: 'Export Reports',
      description: 'Generate a PDF summary with pain charts and adherence stats for your clinician.',
      placement: TutorialPlacement.top,
      highlightShape: TutorialHighlightShape.roundedRect,
      priority: TutorialPriority.important,
      flowId: 'onboarding_reports',
      order: 1,
      featureFlagId: defaultFeatureFlag,
      fallback: const TutorialFallback(
        message: 'Scroll to the Export Reports card and tap Export PDF Report.',
      ),
      metadata: <String, Object?>{
        'file': 'lib/reports/widgets/export_pdf_button.dart',
        'line_start': 248,
        'widget_type': 'ElevatedButton',
        'skip_if_seen': true,
      },
    ),
    TutorialStep(
      id: 'welcome_sign_in',
      pageId: 'login',
      anchorKey: TutorialAnchors.welcomeSignIn,
      title: 'Sign In Securely',
      description: 'Authenticate with your email to sync rehab plans and progress.',
      placement: TutorialPlacement.top,
      highlightShape: TutorialHighlightShape.roundedRect,
      priority: TutorialPriority.critical,
      flowId: 'onboarding_welcome',
      order: 1,
      featureFlagId: defaultFeatureFlag,
      fallback: const TutorialFallback(
        message: 'Sign in via the primary gradient button.',
      ),
      metadata: <String, Object?>{
        'file': 'lib/welcome/login_page.dart',
        'line_start': 755,
        'widget_type': 'ElevatedButton',
        'skip_if_seen': true,
      },
    ),
    TutorialStep(
      id: 'welcome_guest_mode',
      pageId: 'login',
      anchorKey: TutorialAnchors.welcomeGuest,
      title: 'Preview as Guest',
      description: 'Explore core flows without creating an account. Data stays on-device.',
      placement: TutorialPlacement.top,
      highlightShape: TutorialHighlightShape.roundedRect,
      priority: TutorialPriority.important,
      flowId: 'onboarding_welcome',
      order: 2,
      featureFlagId: defaultFeatureFlag,
      fallback: const TutorialFallback(
        message: 'Use Continue as Guest below the sign-in form.',
      ),
      metadata: <String, Object?>{
        'file': 'lib/welcome/login_page.dart',
        'line_start': 884,
        'widget_type': 'OutlinedButton',
        'skip_if_seen': true,
      },
    ),
    TutorialStep(
      id: 'welcome_register_link',
      pageId: 'login',
      anchorKey: TutorialAnchors.welcomeRegister,
      title: 'Create Account',
      description: 'Need full tracking? Open registration to set up your secure profile.',
      placement: TutorialPlacement.top,
      highlightShape: TutorialHighlightShape.rect,
      priority: TutorialPriority.important,
      flowId: 'onboarding_welcome',
      order: 3,
      featureFlagId: defaultFeatureFlag,
      fallback: const TutorialFallback(
        message: 'Tap Create Account under the guest button to register.',
      ),
      metadata: <String, Object?>{
        'file': 'lib/welcome/login_page.dart',
        'line_start': 949,
        'widget_type': 'RichTextGesture',
        'skip_if_seen': true,
      },
    ),
    TutorialStep(
      id: 'profile_logout_action',
      pageId: 'profile',
      anchorKey: TutorialAnchors.profileLogout,
      title: 'Sign Out Safely',
      description: 'Use Logout to end your session and protect medical data.',
      longText: 'We automatically sync progress before signing out so you can resume later.',
      placement: TutorialPlacement.left,
      highlightShape: TutorialHighlightShape.roundedRect,
      priority: TutorialPriority.important,
      flowId: 'onboarding_profile',
      order: 2,
      featureFlagId: defaultFeatureFlag,
      fallback: const TutorialFallback(
        message: 'Use the Logout tile in Profile > Account & Security.',
        alignment: Alignment.centerRight,
      ),
      metadata: <String, Object?>{
        'file': 'lib/profile/profile_page.dart',
        'line_start': 692,
        'widget_type': 'InkWell',
        'skip_if_seen': true,
      },
    ),
  ];

  /// Registers steps and default implementations with the [TutorialService].
  static void registerAll() {
    final service = TutorialService.instance;
    final prefs = TutorialPreferences.instance;

    service.defaultFeatureFlagResolver = () async {
      await prefs.ensureInitialized();
      return prefs.tutorialsEnabled;
    };

    service.globalStepFilter = (BuildContext context, TutorialStep step) async {
      await prefs.ensureInitialized();
      final bool skipIfSeen = (step.metadata?['skip_if_seen'] as bool?) ?? true;
      if (!prefs.tutorialsEnabled) {
        return false;
      }
      if (skipIfSeen && prefs.isStepCompleted(step.id)) {
        return false;
      }
      if (skipIfSeen && prefs.isFlowCompleted(step.flowId)) {
        return false;
      }
      return true;
    };

    service.registerImplementation(
      TutorialImplementation.overlay,
      sequenceRunner: (
        BuildContext context,
        List<TutorialStep> steps, {
        String? flowId,
        required TutorialEventEmitter emit,
      }) =>
          TutorialOverlay.instance.showSequence(
        context: context,
        steps: steps,
        flowId: flowId,
        emit: emit,
      ),
      singleStepRunner: (
        BuildContext context,
        TutorialStep step, {
        String? flowId,
        required TutorialEventEmitter emit,
      }) =>
          TutorialOverlay.instance.showStep(
        context: context,
        step: step,
        flowId: flowId,
        emit: emit,
      ),
    );

    service.registerImplementation(
      TutorialImplementation.coachMark,
      sequenceRunner: (
        BuildContext context,
        List<TutorialStep> steps, {
        String? flowId,
        required TutorialEventEmitter emit,
      }) =>
          TutorialPackageIntegration.startCoachMark(context, steps, emit, flowId: flowId),
      singleStepRunner: (
        BuildContext context,
        TutorialStep step, {
        String? flowId,
        required TutorialEventEmitter emit,
      }) =>
          TutorialPackageIntegration.startCoachMark(context, <TutorialStep>[step], emit, flowId: flowId),
    );

    service.registerImplementation(
      TutorialImplementation.showcaseView,
      sequenceRunner: (
        BuildContext context,
        List<TutorialStep> steps, {
        String? flowId,
        required TutorialEventEmitter emit,
      }) =>
          TutorialPackageIntegration.startShowcase(context, steps, emit, flowId: flowId),
      singleStepRunner: (
        BuildContext context,
        TutorialStep step, {
        String? flowId,
        required TutorialEventEmitter emit,
      }) =>
          TutorialPackageIntegration.startShowcase(context, <TutorialStep>[step], emit, flowId: flowId),
    );

    service.registerSteps(steps);
  }

  /// Exports step metadata as a manifest for documentation and tooling.
  static List<Map<String, Object?>> toManifest() {
    return steps
        .map((step) => <String, Object?>{
              'id': step.id,
              'page': step.pageId,
              'file': step.metadata?['file'],
              'line_start': step.metadata?['line_start'],
              'widget_type': step.metadata?['widget_type'],
              'title': step.title,
              'description': step.description,
              'long_text': step.longText,
              'placement': step.placement.name,
              'shape': step.highlightShape.name,
              'priority': step.priority.name,
              'flow': step.flowId,
              'order': step.order,
              'feature_flag': step.featureFlagId,
              'camera_safe': step.cameraSafe,
              'fallback': <String, Object?>{
                'alignment': _alignmentName(step.fallback.alignment),
                'message': step.fallback.message,
              },
            })
        .toList();
  }

  static String _alignmentName(Alignment alignment) {
    if (alignment == Alignment.topLeft) return 'topLeft';
    if (alignment == Alignment.topRight) return 'topRight';
    if (alignment == Alignment.bottomLeft) return 'bottomLeft';
    if (alignment == Alignment.bottomRight) return 'bottomRight';
    if (alignment == Alignment.centerLeft) return 'centerLeft';
    if (alignment == Alignment.centerRight) return 'centerRight';
    if (alignment == Alignment.topCenter) return 'topCenter';
    if (alignment == Alignment.bottomCenter) return 'bottomCenter';
    return 'center';
  }
}

