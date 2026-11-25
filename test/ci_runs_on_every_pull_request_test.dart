import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// J-18: every pull request of this app gets a CI run.
///
/// The workflow used to answer pull requests `branches: [main]` only, and the work of this
/// repository is stacked — a pull request based on another pull request's branch matched nothing,
/// so it got a run only if its head happened to be pushed to a `gcc/**` branch, and one (#4) got
/// no run at all. A change that was never run is a change nobody has checked, however green the
/// branch underneath it looked.
///
/// Read off the workflow file, because that is where the answer is, and the only other way to know
/// is to open a pull request and watch. The cases below fail if the base filter comes back.
void main() {
  /// The `on:` block of the workflow, down to the first job.
  String triggers() => File('.github/workflows/ci.yml')
      .readAsStringSync()
      .split('\njobs:')
      .first;

  /// The lines belonging to one trigger: the ones indented under its key.
  String? bodyOf(String trigger) {
    final RegExpMatch? found =
        RegExp('\\n  $trigger:\\n((?:    .*\\n|\\n)*)').firstMatch(triggers());

    return found?.group(1);
  }

  test('a pull request is answered whatever branch it is based on', () {
    expect(triggers(), contains('\n  pull_request:\n'),
        reason: 'the workflow has to answer pull requests at all');
    expect(bodyOf('pull_request'), isNot(contains('branches')),
        reason:
            'a base-branch filter is what left the stacked pull requests of this repository without a run; '
            'every pull request has to be run on the base it will be merged into');
  });

  test('and a run can be asked for without pushing an empty commit', () {
    expect(triggers(), contains('workflow_dispatch:'));
  });

  test('and a push to a working branch is still answered', () {
    expect(bodyOf('push'), contains('branches:'),
        reason:
            'pushes stay filtered on purpose: every branch of every working tree would otherwise run the whole suite twice');
    expect(bodyOf('push'), contains('gcc/'));
  });
}
