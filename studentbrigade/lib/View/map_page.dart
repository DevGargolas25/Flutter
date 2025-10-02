import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../VM/Orchestrator.dart';
// ✅ NO IMPORTS DE MODELS

class MapPage extends StatefulWidget {
  final Orchestrator orchestrator;
  
  const MapPage({super.key, required this.orchestrator});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  late LatLng _initialLocation;

  @override
  void initState() {
    super.initState();
    // Buscar ubicación inicial
    final meetingPoints = widget.orchestrator.getMeetingPoints();
    if (meetingPoints.isNotEmpty) {
      final firstPoint = meetingPoints.first;
      _initialLocation = LatLng(firstPoint.latitude, firstPoint.longitude);
    } else {
      // Fallback si no hay puntos
      _initialLocation = const LatLng(4.6014, -74.0660);
    }
    
    // INICIAR SEGUIMIENTO DE UBICACIÓN
    _requestLocation();
    
    // ESCUCHAR CAMBIOS DEL ORCHESTRATOR
    widget.orchestrator.mapVM.addListener(_onLocationUpdate);
  }

  @override
  void dispose() {
    widget.orchestrator.stopLocationTracking();
    widget.orchestrator.mapVM.removeListener(_onLocationUpdate);
    super.dispose();
  }

  // CALLBACK PARA ACTUALIZACIONES DE UBICACIÓN
  void _onLocationUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  // SOLICITAR UBICACIÓN ACTUAL - DELEGAR AL ORCHESTRATOR
  Future<void> _requestLocation() async {
    await widget.orchestrator.getCurrentLocation();
    widget.orchestrator.startLocationTracking();
  }

  // CONSTRUIR MARCADORES - SOLO USANDO ORCHESTRATOR
  List<Marker> _buildMarkers() {
    final closestPoint = widget.orchestrator.getClosestMeetingPoint();

    List<Marker> markers = [];

    final meetingPoints = widget.orchestrator.getMeetingPoints();
  for (var point in meetingPoints) {
    // ROJO SI ES EL MÁS CERCANO, VERDE SI NO
    final isClosest = closestPoint != null && 
                     point.latitude == closestPoint.latitude && 
                     point.longitude == closestPoint.longitude;
    
    markers.add(
      Marker(
        point: LatLng(point.latitude, point.longitude),
        width: 80,
        height: 60,
        child: Column(
          children: [
            Icon(
              Icons.location_on,
              color: isClosest ? Colors.red : Colors.green, // CAMBIAR COLOR
              size: 35,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: BoxDecoration(
                color: isClosest ? Colors.red : Colors.green, // CAMBIAR COLOR
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                point.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

    // UBICACIÓN DEL USUARIO (AZUL) - PEDIR AL ORCHESTRATOR
    final userLocation = widget.orchestrator.currentUserLocation;
    if (userLocation != null) { // Verificar si no es null
      markers.add(
        Marker(
          point: LatLng(userLocation.latitude, userLocation.longitude),
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: const Icon(
              Icons.person_pin_circle,
              color: Colors.white,
              size: 25,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    // OBTENER ESTADO DEL ORCHESTRATOR (SIN USAR MODELS)
    final userLocation = widget.orchestrator.currentUserLocation;
    final isLoading = widget.orchestrator.isLocationLoading;
    final locationError = widget.orchestrator.locationError;

    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _initialLocation,
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
              if (widget.orchestrator.meetingPointRoute != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: widget.orchestrator.meetingPointRoute!
                        .map((point) => LatLng(point.latitude, point.longitude))
                        .toList(), // pasar de RoutePoint a LatLong
                      color: Colors.blue,
                      strokeWidth: 4.0,
                    ),
                  ],
                ),
              MarkerLayer(markers: _buildMarkers()), // MARCADORES DINÁMICOS
            ],
          ),
          
          // INDICADOR DE CARGA
          if (isLoading)
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Getting your location...',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

          // MENSAJE DE ERROR
          if (locationError != null)
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        locationError,
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // INFO DE PRECISIÓN
          if (userLocation != null)
            Positioned(
              bottom: 100,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Accuracy: ${userLocation.accuracy.toStringAsFixed(0)}m',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
            Positioned(
              top: 50,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Legend',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    _LegendItem(icon: Icons.location_on, color: Colors.green, label: 'Meeting Points'),
                    const SizedBox(height: 4),
                    _LegendItem(icon: Icons.location_on, color: Colors.red, label: 'Closest Point'),
                    const SizedBox(height: 4),
                    _LegendItem(icon: Icons.person_pin_circle, color: Colors.blue, label: 'Your Location'),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // BOTÓN PARA CENTRAR EN UBICACIÓN ACTUAL
          FloatingActionButton(
            heroTag: "location",
            onPressed: userLocation != null
                ? () {
                    _mapController.move(
                      LatLng(userLocation.latitude, userLocation.longitude),
                      17.0,
                    );
                  }
                : null,
            backgroundColor: userLocation != null ? Colors.blue : Colors.grey,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
          const SizedBox(height: 10),
          // botón calcular ruta
          FloatingActionButton(
            heroTag: "route",
            onPressed: userLocation != null
                ? () async {
                    if (widget.orchestrator.currentRoute != null) {
                      widget.orchestrator.clearRoute();
                    } else {
                      await widget.orchestrator.calculateRouteToClosestPoint();
                    }
                  }
                : null,
            backgroundColor: widget.orchestrator.currentRoute != null 
                ? Colors.orange 
                : Colors.purple,
            child: Icon(
              widget.orchestrator.currentRoute != null 
                  ? Icons.clear 
                  : Icons.directions,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          // botón refrescar ubicación
          FloatingActionButton(
            heroTag: "refresh",
            onPressed: _requestLocation,
            backgroundColor: Colors.green,
            child: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _LegendItem({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}