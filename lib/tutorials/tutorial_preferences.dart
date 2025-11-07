import 'package:shared_preferences/shared_preferences.dart';

/// Persists tutorial feature toggles and completion state per user/device.
class TutorialPreferences {
  TutorialPreferences._();

  static final TutorialPreferences instance = TutorialPreferences._();

  static const String _enabledKey = 'tutorials_enabled_v1';
  static const String _completedPrefix = 'tutorial_step_completed_';
  static const String _flowCompletedPrefix = 'tutorial_flow_completed_';

  SharedPreferences? _prefs;

  Future<void> ensureInitialized() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  bool get tutorialsEnabled => _prefs?.getBool(_enabledKey) ?? true;

  Future<void> setTutorialsEnabled(bool value) async {
    await ensureInitialized();
    await _prefs?.setBool(_enabledKey, value);
  }

  bool isStepCompleted(String stepId) {
    return _prefs?.getBool('$_completedPrefix$stepId') ?? false;
  }

  Future<void> markStepCompleted(String stepId) async {
    await ensureInitialized();
    await _prefs?.setBool('$_completedPrefix$stepId', true);
  }

  Future<void> resetStep(String stepId) async {
    await ensureInitialized();
    await _prefs?.remove('$_completedPrefix$stepId');
  }

  bool isFlowCompleted(String? flowId) {
    if (flowId == null) return false;
    return _prefs?.getBool('$_flowCompletedPrefix$flowId') ?? false;
  }

  Future<void> markFlowCompleted(String? flowId) async {
    if (flowId == null) return;
    await ensureInitialized();
    await _prefs?.setBool('$_flowCompletedPrefix$flowId', true);
  }

  Future<void> resetFlow(String flowId) async {
    await ensureInitialized();
    await _prefs?.remove('$_flowCompletedPrefix$flowId');
  }
}

