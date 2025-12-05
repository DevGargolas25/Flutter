import 'package:studentbrigade/Models/mapMod.dart';

class DonationCenter {
  final String id; // Clave: "1", "2", "3"
  final String name;
  final String openTime; // Ej: "08:00"
  final String closeTime; // Ej: "18:00"
  final int donations; // Cantidad total de donaciones
  final double latitude;
  final double longitude;
  final String? description;

  const DonationCenter({
    required this.id,
    required this.name,
    required this.openTime,
    required this.closeTime,
    required this.donations,
    required this.latitude,
    required this.longitude,
    this.description,
  });

  // Convertir a JSON (para caché si es necesario)
  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'openTime': openTime,
    'closeTime': closeTime,
    'donations': donations,
    'latitude': latitude,
    'longitude': longitude,
    'description': description,
  };

  // Crear desde JSON (Firebase)
  factory DonationCenter.fromJson(String id, Map<String, dynamic> json) {
    return DonationCenter(
      id: id,
      name: json['Name'] as String? ?? 'Unknown Center',
      openTime: json['Open'] as String? ?? '08:00',
      closeTime: json['Close'] as String? ?? '18:00',
      donations: json['Donations'] as int? ?? 0,
      latitude: json['Latitude'] as double? ?? 4.6014,
      longitude: json['Longitude'] as double? ?? -74.0660,
      description: json['Description'] as String?,
    );
  }

  // Convertir a MapLocation para el mapa
  MapLocation toMapLocation() => MapLocation(
    latitude: latitude,
    longitude: longitude,
    name: name,
    description: description,
    locationType: LocationType.bloodDonation,
  );

  @override
  String toString() => 'DonationCenter($id: $name)';
}

/// Modelo para registrar donaciones del usuario
class UserDonation {
  final String userId;
  final String centerId;
  final DateTime donatedAt;
  final String semesterYear; // Ej: "2025-1" (año-semestre)

  const UserDonation({
    required this.userId,
    required this.centerId,
    required this.donatedAt,
    required this.semesterYear,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'centerId': centerId,
    'donatedAt': donatedAt.toIso8601String(),
    'semesterYear': semesterYear,
  };

  factory UserDonation.fromJson(Map<String, dynamic> json) => UserDonation(
    userId: json['userId'] as String,
    centerId: json['centerId'] as String,
    donatedAt: DateTime.parse(json['donatedAt'] as String),
    semesterYear: json['semesterYear'] as String,
  );
}
