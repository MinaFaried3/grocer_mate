import 'dart:async';

import 'package:get_it/get_it.dart';

import 'injector.dart';

class GetItInjector implements Injector {
  factory GetItInjector() => _instance;

  GetItInjector._();

  static final _instance = GetItInjector._();

  final _getIt = GetIt.asNewInstance();

  @override
  T get<T extends Object>() => _getIt.get<T>();

  @override
  bool isRegistered<T extends Object>() => _getIt.isRegistered<T>();

  @override
  T singleton<T extends Object>(
    T Function() create, {
    FutureOr<void> Function(T)? dispose,
  }) => _registerIfNot<T>(
    () => _getIt.registerLazySingleton<T>(create, dispose: dispose),
  );

  @override
  T factory<T extends Object>(T Function() create) =>
      _registerIfNot<T>(() => _getIt.registerFactory<T>(create));

  @override
  T factoryWithParameter<T extends Object, P>(
    T Function(P) create,
    P parameter,
  ) => _registerIfNot<T>(
    () => _getIt.registerFactoryParam<T, P, void>((value, _) => create(value)),
    parameter: parameter,
  );

  T _registerIfNot<T extends Object>(
    void Function() register, {
    Object? parameter,
  }) {
    if (!isRegistered<T>()) register();
    return _getIt.get<T>(param1: parameter);
  }

  @override
  Future<void> reset() => _getIt.reset();
}
