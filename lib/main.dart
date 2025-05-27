import 'package:flutter/material.dart';
import 'package:gymtickler_mad_etr/screens/history_screen.dart';
import 'package:gymtickler_mad_etr/screens/home_screen.dart';
import 'package:gymtickler_mad_etr/screens/log_workout_screen.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Data models
class Workout {
  final String id;
  final String type;
  final String details;
  final DateTime date;

  Workout({
    required this.id,
    required this.type,
    required this.details,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'details': details,
    'date': date.toIso8601String(),
  };

  static Workout fromJson(Map<String, dynamic> json) => Workout(
    id: json['id'],
    type: json['type'],
    details: json['details'],
    date: DateTime.parse(json['date']),
  );
}

class Gym {
  final String name;
  final double lat;
  final double lng;

  Gym({required this.name, required this.lat, required this.lng});

  Map<String, dynamic> toJson() => {'name': name, 'lat': lat, 'lng': lng};

  static Gym fromJson(Map<String, dynamic> json) =>
      Gym(name: json['name'], lat: json['lat'], lng: json['lng']);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  Hive.registerAdapter(WorkoutAdapter());
  Hive.registerAdapter(GymAdapter());
  await Hive.openBox('workouts');
  await Hive.openBox('gyms');
  await Hive.openBox('weather');
  runApp(GymTicklerApp());
}

class WorkoutAdapter extends TypeAdapter<Workout> {
  @override
  final typeId = 0;

  @override
  Workout read(BinaryReader reader) {
    return Workout(
      id: reader.read(),
      type: reader.read(),
      details: reader.read(),
      date: DateTime.parse(reader.read()),
    );
  }

  @override
  void write(BinaryWriter writer, Workout obj) {
    writer.write(obj.id);
    writer.write(obj.type);
    writer.write(obj.details);
    writer.write(obj.date.toIso8601String());
  }
}

class GymAdapter extends TypeAdapter<Gym> {
  @override
  final typeId = 1;

  @override
  Gym read(BinaryReader reader) {
    return Gym(name: reader.read(), lat: reader.read(), lng: reader.read());
  }

  @override
  void write(BinaryWriter writer, Gym obj) {
    writer.write(obj.name);
    writer.write(obj.lat);
    writer.write(obj.lng);
  }
}

class GymTicklerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GymTickler',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
      routes: {
        '/log': (context) => LogWorkoutScreen(),
        '/history': (context) => HistoryScreen(),
      },
    );
  }
}
