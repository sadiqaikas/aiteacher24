import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smathmathai/firebase_options.dart';

import 'package:smathmathai/screen/mathsolver.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Math Tutor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => MathSolverScreen(),
      },
    );
  }
}
