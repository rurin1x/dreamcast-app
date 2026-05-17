import 'package:dream_cast/app/bootstrap/app_bootstrap.dart';
import 'package:dream_cast/app/bootstrap/dream_cast_app.dart';
import 'package:flutter/widgets.dart';

Future<void> main() async {
  final bootstrap = await AppBootstrap.start();

  runApp(DreamCastApp(bootstrap: bootstrap));
}
