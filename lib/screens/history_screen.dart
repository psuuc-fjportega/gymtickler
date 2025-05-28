import 'package:flutter/material.dart';
import 'package:gymtickler_mad_etr/model/model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final box = Hive.box('workouts');
    final workouts =
        box.values
            .cast<Map>()
            .map((e) => Workout.fromJson(Map<String, dynamic>.from(e)))
            .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Workout History')),
      body: ListView.builder(
        itemCount: workouts.length,
        itemBuilder: (context, index) {
          final workout = workouts[index];
          return ListTile(
            title: Text(
              '${workout.type} - ${workout.date.toString().split(' ')[0]}',
            ),
            subtitle: Text(workout.details),
          );
        },
      ),
    );
  }
}
