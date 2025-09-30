import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../VM/Orchestrator.dart';

class MapPage extends StatefulWidget {
  final Orchestrator orchestrator;
  
  const MapPage({super.key, required this.orchestrator});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  late LatLng _currentLocation;

  @override
  void initState() {
    super.initState();
    // Pedir ubicación al orchestrator
    final location = widget.orchestrator.getUniandesLocation();
    _currentLocation = LatLng(location.latitude, location.longitude);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          initialCenter: _currentLocation,
          initialZoom: 16.0,
          minZoom: 5.0,
          maxZoom: 18.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.studentbrigade',
            maxZoom: 18,
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: _currentLocation,
                width: 40,
                height: 40,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _mapController.move(_currentLocation, 16.0);
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }
}