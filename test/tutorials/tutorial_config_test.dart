import 'package:flutter_test/flutter_test.dart';
import 'package:PocketPT/tutorials/tutorial_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('tutorial registry exposes manifest metadata', () {
    final manifest = TutorialRegistry.toManifest();

    expect(manifest, isNotEmpty);
    final ids = manifest.map((entry) => entry['id']).toSet();
    expect(ids.length, TutorialRegistry.steps.length);
    expect(ids, contains('dashboard_notifications_badge'));

    final dashboardEntry = manifest.firstWhere(
      (entry) => entry['id'] == 'dashboard_progress_cta',
    );
    expect(dashboardEntry['placement'], equals('top'));
    expect(dashboardEntry['priority'], equals('critical'));
    expect(dashboardEntry['flow'], equals('onboarding_dashboard'));
  });
}

