import 'package:flutter/widgets.dart';

import 'package:grocer_mate/app/grocer_mate_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(await createApp());
}
