import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;

  // Punto inicial: Universidad de los Andes
  final LatLng _uniandes = const LatLng(4.6014, -74.0660);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _uniandes,
          zoom: 16,
        ),
        onMapCreated: (controller) {
          _controller = controller;
        },
        zoomControlsEnabled: true, // botones de + y -
        myLocationEnabled: false,  // sin mostrar ubicación
        myLocationButtonEnabled: false, // sin botón de centrado
      ),
    );
  }
}
