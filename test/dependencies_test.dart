import 'package:flutter_test/flutter_test.dart';
import 'package:grocer_mate/core/injection/dependencies.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shares dependency initialization during and after startup', () async {
    final startup = initializeDependencies();
    final concurrentStartup = initializeDependencies();
    final dependencies = await startup;
    addTearDown(dependencies.reset);

    expect(concurrentStartup, same(startup));
    expect(await initializeDependencies(), same(dependencies));
  });
}
