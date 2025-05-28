import 'package:flutter/material.dart';
import 'package:gymtickler_mad_etr/model/model.dart';
import 'package:hive_flutter/hive_flutter.dart';

class HistoryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var box = Hive.box<Workout>('workouts');
    final workouts = box.values.cast<Workout>().toList();

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
