import 'package:hive/hive.dart';

part 'model.g.dart';

@HiveType(typeId: 0)
class Workout {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String type;

  @HiveField(2)
  final String details;

  @HiveField(3)
  final DateTime date;

  Workout({
    required this.id,
    required this.type,
    required this.details,
    required this.date,
  });
}

@HiveType(typeId: 1)
class Gym {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final double lat;

  @HiveField(2)
  final double lng;

  Gym({required this.name, required this.lat, required this.lng});
}
