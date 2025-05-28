import 'package:flutter/material.dart';
import 'package:gymtickler_mad_etr/model/model.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

class LogWorkoutScreen extends StatefulWidget {
  @override
  _LogWorkoutScreenState createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends State<LogWorkoutScreen> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'Running';
  String _details = '';
  final List<String> _workoutTypes = ['Running', 'Strength Training'];

  void _saveWorkout() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final workout = Workout(
        id: Uuid().v4(),
        type: _type,
        details: _details,
        date: DateTime.now(),
      );
      final box = Hive.box('workouts');
      await box.add(workout.toJson());
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Log Workout')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                value: _type,
                items:
                    _workoutTypes
                        .map(
                          (type) =>
                              DropdownMenuItem(value: type, child: Text(type)),
                        )
                        .toList(),
                onChanged: (value) => setState(() => _type = value!),
                decoration: InputDecoration(labelText: 'Workout Type'),
              ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: 'Details (e.g., 5km run, Squats 3x10)',
                ),
                validator: (value) => value!.isEmpty ? 'Enter details' : null,
                onSaved: (value) => _details = value!,
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveWorkout,
                child: Text('Save Workout'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
