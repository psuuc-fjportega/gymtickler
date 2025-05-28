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
