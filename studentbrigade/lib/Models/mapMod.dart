/// =============================
/// CLASES PRINCIPALES
/// =============================

// Enum para tipos de ubicación en mapa
enum LocationType {
  meetingPoint, // Punto de encuentro (emergencias)
  bloodDonation, // Centro de donación de sangre
}

class MapLocation {
  final double latitude;
  final double longitude;
  final String name;
  final String? description;
  final LocationType locationType;

  const MapLocation({
    required this.latitude,
    required this.longitude,
    required this.name,
    this.description,
    this.locationType = LocationType.meetingPoint,
  });

  // Convertir a JSON
  Map<String, dynamic> toJson() => {
    'latitude': latitude,
    'longitude': longitude,
    'name': name,
    'description': description,
    'locationType': locationType.toString(),
  };

  // Crear desde JSON
  factory MapLocation.fromJson(Map<String, dynamic> json) => MapLocation(
    latitude: json['latitude'],
    longitude: json['longitude'],
    name: json['name'],
    description: json['description'],
    locationType: json['locationType'] == LocationType.bloodDonation.toString()
        ? LocationType.bloodDonation
        : LocationType.meetingPoint,
  );
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

// CLASE PARA PUNTOS DE RUTA
class RoutePoint {
  final double latitude;
  final double longitude;

  const RoutePoint({required this.latitude, required this.longitude});
}

// Enum para los tipos de ruta
enum RouteType {
  meetingPoint, // Ruta a punto de encuentro (mapa normal)
  brigadist, // Ruta al brigadista (emergencia)
}

// Clase para manejar múltiples rutas
class RouteData {
  final List<RoutePoint> points;
  final RouteType type;
  final DateTime calculatedAt;
  final double? estimatedDurationMinutes;

  const RouteData({
    required this.points,
    required this.type,
    required this.calculatedAt,
    this.estimatedDurationMinutes,
  });
}

/// =============================
/// DATOS ESTÁTICOS
/// =============================

class MapData {
  // ===== PUNTOS DE ENCUENTRO =====
  static const MapLocation Boho = MapLocation(
    latitude: 4.6014,
    longitude: -74.0660,
    name: 'Boho',
    description: 'Punto de encuentro',
    locationType: LocationType.meetingPoint,
  );

  static const MapLocation ML_banderas = MapLocation(
    latitude: 4.603164,
    longitude: -74.065204,
    name: 'ML Banderas',
    description: 'Punto de encuentro',
    locationType: LocationType.meetingPoint,
  );

  static const MapLocation sd_cerca = MapLocation(
    latitude: 4.603966,
    longitude: -74.065778,
    name: 'SD Cerca',
    description: 'Punto de encuentro',
    locationType: LocationType.meetingPoint,
  );

  static const MapLocation mockUp = MapLocation(
    latitude: 4.795467,
    longitude: -74.067037,
    name: 'Mockup',
    description: 'Punto de encuentro de prueba',
    locationType: LocationType.meetingPoint,
  );

  static const List<MapLocation> meetingPoints = [Boho, ML_banderas, sd_cerca];

  // ===== CENTROS DE DONACIÓN DE SANGRE =====
  static const MapLocation bloodDonationMain = MapLocation(
    latitude: 4.6015,
    longitude: -74.0665,
    name: 'Centro de Donación Principal',
    description: 'Centro principal de donación de sangre',
    locationType: LocationType.bloodDonation,
  );

  static const MapLocation bloodDonationNorth = MapLocation(
    latitude: 4.6040,
    longitude: -74.0645,
    name: 'Centro de Donación Norte',
    description: 'Centro de donación zona norte',
    locationType: LocationType.bloodDonation,
  );

  static const MapLocation bloodDonationSouth = MapLocation(
    latitude: 4.5990,
    longitude: -74.0680,
    name: 'Centro de Donación Sur',
    description: 'Centro de donación zona sur',
    locationType: LocationType.bloodDonation,
  );

  static const List<MapLocation> bloodDonationCenters = [
    bloodDonationMain,
    bloodDonationNorth,
    bloodDonationSouth,
  ];
}
