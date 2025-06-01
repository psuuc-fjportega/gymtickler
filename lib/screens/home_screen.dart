import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gymtickler_mad_etr/model/model.dart';
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
    if (permission == LocationPermission.deniedForever) {
      setState(() => _weather = 'Location permissions permanently denied');
      return;
    }

    _currentPosition = await Geolocator.getCurrentPosition();
    setState(() {});

    await _fetchGyms();
    await _fetchWeather();
  }

  Future<void> _fetchGyms() async {
    if (_currentPosition == null) return;

    final box = Hive.box<Gym>('gyms');
    if (box.isNotEmpty) {
      setState(() {
        _gyms = box.values.cast<Gym>().toList();
      });
      return;
    }

    final url =
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
        '?location=${_currentPosition!.latitude},${_currentPosition!.longitude}'
        '&radius=5000&type=establishment&key=AIzaSyAuIZ2Wzf153fefXb81qx5ry-MlT7Lq-mA';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final results = data['results'] as List;

        _gyms =
            results
                .where((place) {
                  final name = (place['name'] as String).toLowerCase();
                  return name.contains('gym') || name.contains('fitness');
                })
                .map(
                  (place) => Gym(
                    name: place['name'],
                    lat: place['geometry']['location']['lat'],
                    lng: place['geometry']['location']['lng'],
                  ),
                )
                .toList();

        await box.clear();
        await box.addAll(_gyms);

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
        '&appid=32aa21ce39e4e3be112de0c1d4b4242a&units=metric';

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

  void _showInfoModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Colors.transparent,
      builder:
          (context) => SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.2),
              end: Offset.zero,
            ).animate(
              CurvedAnimation(
                parent: ModalRoute.of(context)!.animation!,
                curve: Curves.easeOutCubic,
              ),
            ),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: ModalRoute.of(context)!.animation!,
                  curve: Curves.easeIn,
                ),
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFAB47BC), // Lighter purple
                      Color(0xFFE1BEE7), // Softer purple
                      Colors.white,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 50,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Color(0xFF6A1B9A),
                            size: 28,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Workout Info',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF6A1B9A),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Weather: $_weather',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[900],
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Suggested Workout: $_workoutSuggestion',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                          height: 1.5,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/log'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6A1B9A),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 4,
                          shadowColor: Colors.black.withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Log Workout'),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed:
                            () => Navigator.pushNamed(context, '/history'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF6A1B9A),
                          minimumSize: const Size(double.infinity, 56),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          side: const BorderSide(
                            color: Color(0xFF6A1B9A),
                            width: 2,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('View History'),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(
          Icons.fitness_center,
          size: 28,
          color: Colors.white,
        ),
        title: const Text(
          'GymTickler',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6A1B9A), // Deep purple
                Color(0xFFAB47BC), // Lighter purple
              ],
            ),
          ),
        ),
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white, size: 28),
            onPressed: _showInfoModal,
          ),
        ],
      ),
      body:
          _currentPosition == null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFAB47BC),
                      ),
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Finding your location...',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              : GoogleMap(
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                compassEnabled: true,
                zoomControlsEnabled: true,
                mapType: MapType.normal,
                onTap: (LatLng latLng) {
                  mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
                },
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: LatLng(
                    _currentPosition!.latitude,
                    _currentPosition!.longitude,
                  ),
                  zoom: 16,
                ),
                markers:
                    _gyms
                        .map(
                          (gym) => Marker(
                            markerId: MarkerId(gym.name),
                            position: LatLng(gym.lat, gym.lng),
                            infoWindow: InfoWindow(
                              title: gym.name,
                              snippet: 'Tap to visit',
                            ),
                            icon: BitmapDescriptor.defaultMarkerWithHue(
                              BitmapDescriptor.hueViolet,
                            ),
                          ),
                        )
                        .toSet(),
              ),
    );
  }

  Future<void> _loadCachedData() async {
    final box = Hive.box<Gym>('gyms');
    if (box.isNotEmpty) {
      setState(() {
        _gyms = box.values.cast<Gym>().toList();
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
