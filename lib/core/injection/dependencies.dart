import 'package:grocer_mate/core/storage/hive_local_storage.dart';
import 'package:grocer_mate/core/storage/local_storage.dart';
import 'package:grocer_mate/features/app/injection/app_dependencies.dart';

import 'get_it_injector.dart';
import 'injector.dart';

final Injector injector = GetItInjector();

/// Shares app startup across calls. Feature instances resolve on demand.
Future<void> initializeDependencies() async {
  // A cold deep link needs the initial status before reading the catalog.
  await injector.appConnection.stream.first;
}

extension SharedDependencies on Injector {
  LocalStorage get localStorage => singleton<LocalStorage>(
    () => singleton<HiveLocalStorage>(
      HiveLocalStorage.new,
      dispose: (storage) => storage.close(),
    ),
  );
}
