import 'package:flutter/material.dart';
import 'package:gymtickler_mad_etr/model/model.dart';
import 'package:gymtickler_mad_etr/screens/history_screen.dart';
import 'package:gymtickler_mad_etr/screens/log_workout_screen.dart';
import 'package:gymtickler_mad_etr/screens/splash_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(WorkoutAdapter());
  Hive.registerAdapter(GymAdapter());
  await Hive.openBox<Workout>('workouts');
  await Hive.openBox<Gym>('gyms');
  await Hive.openBox('weather');
  runApp(GymTicklerApp());
}

class GymTicklerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymTickler',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
      routes: {
        '/log': (context) => LogWorkoutScreen(),
        '/history': (context) => HistoryScreen(),
      },
    );
  }
}
