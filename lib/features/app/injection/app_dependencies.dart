import 'package:grocer_mate/core/injection/injector.dart';
import 'package:grocer_mate/core/network/connectivity/platform_connection_checker.dart';

import '../presentation/controllers/app_connection_cubit.dart';

extension AppDependencies on Injector {
  AppConnectionCubit get appConnection => singleton(
    () => AppConnectionCubit(const PlatformConnectionChecker()),
    dispose: (connection) => connection.close(),
  );

  bool isOnline() => get<AppConnectionCubit>().online;
}
