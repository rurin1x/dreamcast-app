import 'package:dream_cast/app/bootstrap/app_bootstrap.dart';
import 'package:dream_cast/app/bootstrap/dream_cast_app.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

Future<void> main() async {
  FlutterForegroundTask.initCommunicationPort();
  final bootstrap = await AppBootstrap.start();

  runApp(DreamCastApp(bootstrap: bootstrap));
}
