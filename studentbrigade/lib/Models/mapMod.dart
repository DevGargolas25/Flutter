class MapLocation {
  final double latitude;
  final double longitude;
  final String name;
  final String? description;

  const MapLocation({
    required this.latitude,
    required this.longitude,
    required this.name,
    this.description,
  });
}

// CLASE PARA UBICACIÓN DEL USUARIO
class UserLocation {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double accuracy;

  const UserLocation({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.accuracy,
  });
  
}

class RoutePoint {
    final double latitude;
    final double longitude;

    const RoutePoint({
      required this.latitude,
      required this.longitude,
    });
  }

// Datos estáticos de ubicaciones
class MapData {
  static const MapLocation Boho = MapLocation(
    latitude: 4.6014,
    longitude: -74.0660,
    name: 'Boho',
    description: 'Punto de encuentro',
  );

  // AGREGAR MÁS PUNTOS DE ENCUENTRO
  static const MapLocation ML_banderas = MapLocation(
    latitude: 4.603164, 
    longitude: -74.065204,
    name: 'ML Banderas',
    description: 'Punto de encuentro',
  );

  // AGREGAR MÁS PUNTOS DE ENCUENTRO
  static const MapLocation sd_cerca = MapLocation(
    latitude: 4.603966, 
    longitude:-74.065778,
    name: 'SD Cerca',
    description: 'Punto de encuentro',
  );

  static const MapLocation mockUp = MapLocation( // cerca a mi casa para probar
    latitude: 4.795467, 
    longitude: -74.067037,
    name: 'mockup',
    description: 'Punto de encuentro',
  );

  

  // LISTA DE TODOS LOS PUNTOS DE ENCUENTRO
  static const List<MapLocation> meetingPoints = [
    Boho,
    ML_banderas,
    sd_cerca,
  ];
}