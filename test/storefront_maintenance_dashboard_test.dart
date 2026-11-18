import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// J-08: the dashboard is the screen a customer lands on, and it shows the maintenance screen instead of its content while the server has put the customer's storefront in maintenance. No test builds the
/// dashboard (it needs the providers of the whole app and loads data when it opens), so what makes the app honour the stop is pinned here as the lines that do it: deleting them, moving them below the content or
/// reading the controller without watching it fails a test, which the tests of the controller and of the screen could not notice.
void main() {
  final String source = File('lib/features/dashboard/screens/dashboard_screen.dart').readAsStringSync();
  final int build = source.indexOf('Widget build(BuildContext context) {');

  test('the build of the dashboard answers with the maintenance screen before it builds any of its content', () {
    final int gate = source.indexOf('StorefrontConfig.enabled &&', build);
    final int maintenance = source.indexOf('context.watch<StorefrontController>().inMaintenance', gate);
    final int answer = source.indexOf('return const StorefrontMaintenanceScreen();', maintenance);
    final int content = source.indexOf('ThemeSwitchingArea(', build);

    expect(build, greaterThan(0), reason: 'the dashboard has a build method');
    expect(gate, greaterThan(build), reason: 'only while storefronts are on');
    expect(maintenance, greaterThan(gate), reason: 'only while the storefront of the customer is in maintenance');
    expect(answer, greaterThan(maintenance));
    expect(content, greaterThan(answer), reason: 'before the content of the dashboard is built');
  });

  test('the controller is watched, not read once, so the screen goes as soon as a newer answer says the stop is over', () {
    expect(source, contains('context.watch<StorefrontController>().inMaintenance'));
    expect(source, isNot(contains('Provider.of<StorefrontController>(context, listen: false).inMaintenance')));
  });

  test('the branch is the whole of the answer: the maintenance screen, with no other condition and nothing else in it', () {
    final RegExp branch = RegExp(r'if \(StorefrontConfig\.enabled &&\s*context\.watch<StorefrontController>\(\)\.inMaintenance\) \{\s*return const StorefrontMaintenanceScreen\(\);\s*\}');

    expect(branch.hasMatch(source), isTrue);
  });
}
