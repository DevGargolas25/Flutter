
class MapLocation {
  final double latitude;
  final double longitude;
  final String name;

  const MapLocation({
    required this.latitude,
    required this.longitude,
    required this.name,
  });
}

// Datos estáticos de ubicaciones
class MapData {
  static const MapLocation uniandes = MapLocation(
    latitude: 4.6014,
    longitude: -74.0660,
    name: 'Universidad de los Andes',
  );
}