import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:gymtickler_mad_etr/model/model.dart';

class AddMarkersScreen extends StatefulWidget {
  const AddMarkersScreen({super.key});

  @override
  _AddMarkersScreenState createState() => _AddMarkersScreenState();
}

class _AddMarkersScreenState extends State<AddMarkersScreen> {
  late GoogleMapController mapController;
  Set<Marker> markers = {};
  final Box<Gym> gymBox = Hive.box<Gym>('gyms');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Markers')),
      body: GoogleMap(
        onMapCreated: (GoogleMapController controller) {
          mapController = controller;
        },
        initialCameraPosition: CameraPosition(
          target: LatLng(15.971336, 120.571518), // SM URDANETA PARE
          zoom: 15,
        ),
        markers: markers,
        onTap: _addMarker,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveMarkers,
        child: Icon(Icons.save),
      ),
    );
  }

  void _addMarker(LatLng position) async {
    String? name = await showDialog<String>(
      context: context,
      builder: (context) {
        String tempName = '';
        return AlertDialog(
          title: Text('Enter Gym Name'),
          content: TextField(
            autofocus: true,
            onChanged: (value) => tempName = value,
            decoration: InputDecoration(hintText: 'Gym Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (tempName.trim().isNotEmpty) {
                  Navigator.of(context).pop(tempName.trim());
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );

    if (name != null && name.isNotEmpty) {
      final markerId = MarkerId('${position.toString()}_$name');
      final marker = Marker(
        markerId: markerId,
        position: position,
        infoWindow: InfoWindow(title: name),
      );

      setState(() {
        markers.add(marker);
      });
    }
  }

  void _saveMarkers() {
    for (var marker in markers) {
      final gym = Gym(
        name: marker.markerId.value,
        lat: marker.position.latitude,
        lng: marker.position.longitude,
      );
      gymBox.add(gym);
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Markers saved!')));
  }
}

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Home')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/log'),
              child: Text('Log Workout'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/history'),
              child: Text('View History'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/addMarkers'),
              child: Text('Add Markers'),
            ),
          ],
        ),
      ),
    );
  }
}
