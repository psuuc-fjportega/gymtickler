import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gymtickler_mad_etr/main.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  GoogleMapController? mapController;
  Position? _currentPosition;
  List<Gym> _gyms = [];
  String _weather = 'Loading...';
  String _workoutSuggestion = '';

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _loadCachedData();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() => _weather = 'Location services disabled');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() => _weather = 'Location permission denied');
        return;
      }
    }

    _currentPosition = await Geolocator.getCurrentPosition();
    setState(() {});
    _fetchGyms();
    _fetchWeather();
  }

  Future<void> _fetchGyms() async {
    if (_currentPosition == null) return;

    final box = Hive.box('gyms');
    if (box.isNotEmpty) {
      setState(() {
        _gyms =
            box.values
                .cast<Map>()
                .map((e) => Gym.fromJson(Map<String, dynamic>.from(e)))
                .toList();
      });
      return;
    }

    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${_currentPosition!.latitude},${_currentPosition!.longitude}'
        '&radius=5000&type=gym&key=YOUR_GOOGLE_API_KEY';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;
        _gyms =
            results
                .map(
                  (place) => Gym(
                    name: place['name'],
                    lat: place['geometry']['location']['lat'],
                    lng: place['geometry']['location']['lng'],
                  ),
                )
                .toList();
        await box.clear();
        await box.addAll(_gyms.map((g) => g.toJson()));
        setState(() {});
      }
    } catch (e) {
      setState(() => _weather = 'Error fetching gyms');
    }
  }

  Future<void> _fetchWeather() async {
    if (_currentPosition == null) return;

    final box = Hive.box('weather');
    if (box.isNotEmpty) {
      setState(() {
        _weather = box.get('condition', defaultValue: 'Unknown');
        _workoutSuggestion = _getWorkoutSuggestion(_weather);
      });
      return;
    }

    final url =
        'https://api.openweathermap.org/data/2.5/weather'
        '?lat=${_currentPosition!.latitude}&lon=${_currentPosition!.longitude}'
        '&appid=YOUR_OPENWEATHERMAP_API_KEY&units=metric';
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final condition = data['weather'][0]['main'];
        await box.put('condition', condition);
        setState(() {
          _weather = condition;
          _workoutSuggestion = _getWorkoutSuggestion(condition);
        });
      }
    } catch (e) {
      setState(() => _weather = 'Error fetching weather');
    }
  }

  String _getWorkoutSuggestion(String weather) {
    if (weather.contains('Rain') || weather.contains('Snow')) {
      return 'Try indoor strength training: Leg Day (Squats, Lunges, RDLs)';
    }
    return 'Great day for running!';
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('GymTickler')),
      body: Column(
        children: [
          Container(
            height: 300,
            child:
                _currentPosition == null
                    ? Center(child: CircularProgressIndicator())
                    : GoogleMap(
                      onMapCreated: _onMapCreated,
                      initialCameraPosition: CameraPosition(
                        target: LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                        zoom: 12,
                      ),
                      markers:
                          _gyms
                              .map(
                                (gym) => Marker(
                                  markerId: MarkerId(gym.name),
                                  position: LatLng(gym.lat, gym.lng),
                                  infoWindow: InfoWindow(title: gym.name),
                                ),
                              )
                              .toSet(),
                    ),
          ),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text('Weather: $_weather'),
                SizedBox(height: 8),
                Text('Suggested Workout: $_workoutSuggestion'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/log'),
                  child: Text('Log Workout'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/history'),
                  child: Text('View History'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadCachedData() async {
    final box = Hive.box('gyms');
    if (box.isNotEmpty) {
      setState(() {
        _gyms =
            box.values
                .cast<Map>()
                .map((e) => Gym.fromJson(Map<String, dynamic>.from(e)))
                .toList();
      });
    }
    final weatherBox = Hive.box('weather');
    if (weatherBox.isNotEmpty) {
      setState(() {
        _weather = weatherBox.get('condition', defaultValue: 'Unknown');
        _workoutSuggestion = _getWorkoutSuggestion(_weather);
      });
    }
  }
}
