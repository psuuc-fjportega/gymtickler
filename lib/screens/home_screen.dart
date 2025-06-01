import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:gymtickler_mad_etr/model/model.dart';
import 'package:gymtickler_mad_etr/screens/add_markers.dart';
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
  bool _gymZoneShown = false;

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

    // Check for gyms nearby after fetching data
    _checkForNearbyGymZone();
  }

  Future<void> _fetchGyms() async {
    if (_currentPosition == null) return;

    final box = Hive.box<Gym>('gyms');
    if (box.isNotEmpty) {
      final allGyms = box.values.toList();
      _gyms =
          allGyms.where((gym) {
            final distance = Geolocator.distanceBetween(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
              gym.lat,
              gym.lng,
            );
            return distance <= 5000; // Filter for 5km radius
          }).toList();

      setState(() {});
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

        final fetchedGyms =
            results
                .where((place) {
                  final name = (place['name'] as String).toLowerCase();
                  return name.contains('gym') || name.contains('fitness');
                })
                .map((place) {
                  return Gym(
                    name: place['name'],
                    lat: place['geometry']['location']['lat'],
                    lng: place['geometry']['location']['lng'],
                  );
                })
                .toList();

        await box.clear();
        await box.addAll(fetchedGyms);

        // Apply the 5km filter
        _gyms =
            fetchedGyms.where((gym) {
              final distance = Geolocator.distanceBetween(
                _currentPosition!.latitude,
                _currentPosition!.longitude,
                gym.lat,
                gym.lng,
              );
              return distance <= 5000;
            }).toList();

        print('Filtered markers count: ${_gyms.length}');
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

  void _showGymZoneModal(String gymName, int gymCount) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Gym Alert"),
          content: Text(
            "There are $gymCount gym(s) nearby. \nYou are near $gymName. ",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _checkForNearbyGymZone() {
    if (_currentPosition == null || _gyms.isEmpty || _gymZoneShown) return;

    const double radius = 5000; // 5 km radius

    for (var gym in _gyms) {
      final distance = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        gym.lat,
        gym.lng,
      );

      if (distance <= radius) {
        _showGymZoneModal(gym.name, _gyms.length);
        _gymZoneShown = true; // Show only once per session
        break;
      }
    }
  }

  Set<Marker> _buildGymMarkers() {
    return _gyms.map((gym) {
      return Marker(
        markerId: MarkerId(gym.name),
        position: LatLng(gym.lat, gym.lng),
        infoWindow: InfoWindow(title: gym.name),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      );
    }).toSet();
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
                      Color(0xFFAB47BC),
                      Color(0xFFE1BEE7),
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
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Suggested Workout: $_workoutSuggestion',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[800],
                          height: 1.5,
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
                        ),
                        child: const Text('Log Workout'),
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

  Future<void> _loadCachedData() async {
    final gymBox = Hive.box<Gym>('gyms');
    final weatherBox = Hive.box('weather');

    if (_gyms.isEmpty && gymBox.isNotEmpty) {
      setState(() {
        _gyms = gymBox.values.toList();
      });
      _checkForNearbyGymZone();
    }

    if (weatherBox.containsKey('condition')) {
      setState(() {
        _weather = weatherBox.get('condition');
        _workoutSuggestion = _getWorkoutSuggestion(_weather);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const Icon(Icons.fitness_center, color: Colors.white),
        title: const Text(
          'GymTickler',
          style: TextStyle(color: Colors.white, fontSize: 22),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Reload',
            onPressed: () async {
              setState(() {
                _weather = 'Loading...';
                _workoutSuggestion = '';
                _gyms.clear();
                _gymZoneShown = false;
              });

              await _getCurrentLocation();
            },
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.white),
            onPressed: () => Navigator.pushNamed(context, '/history'),
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
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Finding your location...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              : GoogleMap(
                myLocationEnabled: true,
                myLocationButtonEnabled: true,
                compassEnabled: true,
                mapType: MapType.normal,
                zoomControlsEnabled: false,
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
                markers: _buildGymMarkers(),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showInfoModal,
        // onPressed: () {
        //   Navigator.of(
        //     context,
        //   ).push(MaterialPageRoute(builder: (context) => AddMarkersScreen()));
        // },
        backgroundColor: const Color(0xFF6A1B9A),
        child: const Icon(Icons.info_outline, color: Colors.white),
      ),
    );
  }
}
