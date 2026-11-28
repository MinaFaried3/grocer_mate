import 'dart:async';

abstract interface class Injector {
  T get<T extends Object>();

  bool isRegistered<T extends Object>();

  T singleton<T extends Object>(
    T Function() create, {
    FutureOr<void> Function(T)? dispose,
  });

  T factory<T extends Object>(T Function() create);

  T factoryWithParameter<T extends Object, P>(
    T Function(P) create,
    P parameter,
  );

  Future<void> reset();
}
