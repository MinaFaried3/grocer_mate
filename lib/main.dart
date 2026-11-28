import 'package:flutter/widgets.dart';

import 'package:grocer_mate/features/app/presentation/ui/screen/grocer_mate_app.dart';
import 'package:grocer_mate/core/injection/dependencies.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDependencies();

  runApp(const GrocerMateApp());
}
