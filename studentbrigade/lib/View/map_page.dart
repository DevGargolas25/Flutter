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
  late LatLng _initialLocation;

  @override
  void initState() {
    super.initState();
    final meetingPoints = widget.orchestrator.getMeetingPoints();
    if (meetingPoints.isNotEmpty) {
      final firstPoint = meetingPoints.first;
      _initialLocation = LatLng(firstPoint.latitude, firstPoint.longitude);
    } else {
      _initialLocation = const LatLng(4.6014, -74.0660);
    }

    _requestLocation();
    widget.orchestrator.mapVM.addListener(_onLocationUpdate);
  }

  @override
  void dispose() {
    widget.orchestrator.stopLocationTracking();
    widget.orchestrator.mapVM.removeListener(_onLocationUpdate);
    super.dispose();
  }

  void _onLocationUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _requestLocation() async {
    await widget.orchestrator.getCurrentLocation();
    widget.orchestrator.startLocationTracking();
  }

  List<Marker> _buildMarkers(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final closestPoint = widget.orchestrator.getClosestMeetingPoint();
    final markers = <Marker>[];

    // Meeting points (closest = error color, others = secondary)
    final meetingPoints = widget.orchestrator.getMeetingPoints();
    for (var point in meetingPoints) {
      final isClosest = closestPoint != null &&
          point.latitude == closestPoint.latitude &&
          point.longitude == closestPoint.longitude;

      final baseColor = isClosest ? cs.error : cs.secondary;
      final onBase = isClosest ? cs.onError : cs.onSecondary;

      markers.add(
        Marker(
          point: LatLng(point.latitude, point.longitude),
          width: 80,
          height: 60,
          child: Column(
            children: [
              Icon(Icons.location_on, color: baseColor, size: 35),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: baseColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  point.name,
                  style: TextStyle(
                    color: onBase,
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

    // User location (primary)
    final userLocation = widget.orchestrator.currentUserLocation;
    if (userLocation != null) {
      markers.add(
        Marker(
          point: LatLng(userLocation.latitude, userLocation.longitude),
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
              border: Border.all(color: cs.surface, width: 3),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withOpacity(0.28),
                  blurRadius: 10,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Icon(Icons.person_pin_circle, color: cs.onPrimary, size: 25),
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

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
              MarkerLayer(markers: _buildMarkers(context)),
            ],
          ),

          // Loading banner
          if (isLoading)
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.inverseSurface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Getting your location...',
                      style: tt.bodyMedium?.copyWith(color: cs.onInverseSurface),
                    ),
                  ],
                ),
              ),
            ),

          // Error banner
          if (locationError != null)
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.error,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error, color: cs.onError, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        locationError,
                        style: tt.bodyMedium?.copyWith(color: cs.onError),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Accuracy chip
          if (userLocation != null)
            Positioned(
              bottom: 100,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: cs.primary.withOpacity(.85),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Accuracy: ${userLocation.accuracy.toStringAsFixed(0)}m',
                  style: tt.labelMedium?.copyWith(color: cs.onPrimary),
                ),
              ),
            ),

          // Legend card
          Positioned(
            top: 50,
            right: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withOpacity(theme.brightness == Brightness.light ? .12 : .32),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Legend', style: tt.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _LegendItem(icon: Icons.location_on, color: cs.secondary, label: 'Meeting Points'),
                  const SizedBox(height: 4),
                  _LegendItem(icon: Icons.location_on, color: cs.error, label: 'Closest Point'),
                  const SizedBox(height: 4),
                  _LegendItem(icon: Icons.person_pin_circle, color: cs.primary, label: 'Your Location'),
                ],
              ),
            ),
          ),
        ],
      ),

      // FABs con colores de tema
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
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
            backgroundColor: userLocation != null ? cs.primary : cs.surfaceVariant,
            foregroundColor: userLocation != null ? cs.onPrimary : cs.onSurfaceVariant,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "route",
            onPressed: userLocation != null
                ? () async {
              if (widget.orchestrator.meetingPointRoute != null) {
                widget.orchestrator.clearRoute();
              } else {
                await widget.orchestrator.calculateRouteToClosestPoint();
              }
            }
                : null,
            backgroundColor: widget.orchestrator.meetingPointRoute != null ? cs.tertiary : cs.secondary,
            foregroundColor: widget.orchestrator.meetingPointRoute != null ? cs.onTertiary : cs.onSecondary,
            child: Icon(widget.orchestrator.meetingPointRoute != null ? Icons.clear : Icons.directions),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "refresh",
            onPressed: _requestLocation,
            backgroundColor: cs.primaryContainer,
            foregroundColor: cs.onPrimaryContainer,
            child: const Icon(Icons.refresh),
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
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Text(label, style: tt.bodySmall?.copyWith(color: cs.onSurface)),
      ],
    );
  }
}
