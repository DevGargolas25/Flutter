

class Emergency {
  final String id;
  final String userId;
  final String? assignedBrigadistId;
  final DateTime requestTime;
  final DateTime? responseTime;
  final DateTime? resolvedTime;
  final double requestLatitude;
  final double requestLongitude;
  final String building;
  final EmergencyStatus status;
  final EmergencyType type;
  final String? description;
  final int? rating;
  final String? feedback;

  const Emergency({
    required this.id,
    required this.userId,
    this.assignedBrigadistId,
    required this.requestTime,
    this.responseTime,
    this.resolvedTime,
    required this.requestLatitude,
    required this.requestLongitude,
    required this.building,
    required this.status,
    required this.type,
    this.description,
    this.rating,
    this.feedback,
  });

  // Getters calculados para analíticas
  Duration? get responseTimeRsolution => responseTime != null 
      ? responseTime!.difference(requestTime) : null;
      
  Duration? get totalResolutionTime => resolvedTime != null 
      ? resolvedTime!.difference(requestTime) : null;

  bool get isResolved => status == EmergencyStatus.resolved;
  bool get isActive => status == EmergencyStatus.in_progress;
  
  // Determinar edificio automáticamente
  factory Emergency.create({
    required String userId,
    required double latitude,
    required double longitude,
    required EmergencyType type,
    String? description,
  }) {
    final building = Building.getBuildingFromCoordinates(latitude, longitude) ?? 'Unknown';
    
    return Emergency(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      requestTime: DateTime.now(),
      requestLatitude: latitude,
      requestLongitude: longitude,
      building: building,
      status: EmergencyStatus.pending,
      type: type,
      description: description,
    );
  }
}

enum EmergencyStatus { pending, in_progress, resolved, cancelled }
enum EmergencyType { medical, fire, security, evacuation, other }