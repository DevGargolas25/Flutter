// models/emergency.dart
import 'dart:convert';

/// <<emerType>> según el diagrama: Medical, Psycological, Hazard
enum EmergencyType { Medical, Psycological, Hazard, Fire, Earthquake }

/// <<location>> según el diagrama: SD, ML, RGD
enum LocationEnum { SD, ML, RGD }

/// Status de la emergencia: Unattended / In progress / Resolved
enum EmergencyStatus { Unattended, InProgress, Resolved }

class ChatMessagee {
  final String id;
  final String text;
  final bool fromUser;
  final DateTime timestamp;

  const ChatMessagee({
    required this.id,
    required this.text,
    required this.fromUser,
    required this.timestamp,
  });

  factory ChatMessagee.fromJson(Map<String, dynamic> json) => ChatMessagee(
    id: json['id'] as String,
    text: json['text'] as String,
    fromUser: json['fromUser'] as bool,
    timestamp: DateTime.parse(json['timestamp'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'fromUser': fromUser,
    'timestamp': timestamp.toIso8601String(),
  };
}

class Emergency {
  final int emergencyID;                 // Int
  final String userId;                   // FK
  final String? assignedBrigadistId;     // FK (nullable)
  final DateTime dateTime;               // date_time

  final int emerResquestTime;            // emerResquestTime / EmerResquestTime
  final int secondsResponse;             // secondsResponse / seconds_response

  final LocationEnum location;           // Enumeration (SD/ML/RGD)
  final EmergencyType emerType;          // Enumeration (Medical/...)
  final EmergencyStatus status;          // Unattended / In progress / Resolved

  final double? latitude;                // latitude
  final double? longitude;               // longitude
  final DateTime? createdAt;             // createdAt (epoch ms)
  final DateTime? updatedAt;             // updatedAt (epoch ms)

  final List<ChatMessagee>? chatMessages; // opcional

  const Emergency({
    required this.emergencyID,
    required this.userId,
    this.assignedBrigadistId,
    required this.dateTime,
    required this.emerResquestTime,
    required this.secondsResponse,
    required this.location,
    required this.emerType,
    required this.status,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
    this.chatMessages,
  });

  Emergency copyWith({
    int? emergencyID,
    String? userId,
    String? assignedBrigadistId,
    DateTime? dateTime,
    int? emerResquestTime,
    int? secondsResponse,
    LocationEnum? location,
    EmergencyType? emerType,
    EmergencyStatus? status,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessagee>? chatMessages,
  }) {
    return Emergency(
      emergencyID: emergencyID ?? this.emergencyID,
      userId: userId ?? this.userId,
      assignedBrigadistId: assignedBrigadistId ?? this.assignedBrigadistId,
      dateTime: dateTime ?? this.dateTime,
      emerResquestTime: emerResquestTime ?? this.emerResquestTime,
      secondsResponse: secondsResponse ?? this.secondsResponse,
      location: location ?? this.location,
      emerType: emerType ?? this.emerType,
      status: status ?? this.status,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      chatMessages: chatMessages ?? this.chatMessages,
    );
  }

  // ---- JSON ----
  factory Emergency.fromJson(Map<String, dynamic> json) => Emergency(
    emergencyID: (json['emergencyID'] as num).toInt(),
    userId: json['userId'] as String,
    assignedBrigadistId: json['assignedBrigadistId'] as String?,
    dateTime: DateTime.parse(json['date_time'] as String),

    // Soporta emerResquestTime y EmerResquestTime
    emerResquestTime: _intFromJson(
      json['emerResquestTime'] ?? json['EmerResquestTime'],
    ),

    // Soporta secondsResponse y seconds_response
    secondsResponse: _intFromJson(
      json['secondsResponse'] ?? json['seconds_response'],
    ),

    location: _locationFromWire(json['location'] as String),
    emerType: _emerTypeFromWire(json['emerType'] as String),
    status: _statusFromWire(json['status'] as String),

    latitude: _doubleFromJson(json['latitude']),
    longitude: _doubleFromJson(json['longitude']),

    createdAt: _dateTimeFromMillisOrIso(json['createdAt']),
    updatedAt: _dateTimeFromMillisOrIso(json['updatedAt']),

    chatMessages: (json['chatMessages'] as List?)
        ?.map((e) => ChatMessagee.fromJson(
      Map<String, dynamic>.from(e as Map),
    ))
        .toList(),
  );

  Map<String, dynamic> toJson() => {
    'emergencyID': emergencyID,
    'userId': userId,
    'assignedBrigadistId': assignedBrigadistId,
    'date_time': dateTime.toIso8601String(),

    // Usamos una convención "bonita" hacia afuera:
    'emerResquestTime': emerResquestTime,
    'secondsResponse': secondsResponse,

    'location': _locationToWire(location),    // SD/ML/RGD
    'emerType': _emerTypeToWire(emerType),    // Medical/Psycological/...
    'status': _statusToWire(status),          // Unattended / In progress / Resolved

    'latitude': latitude,
    'longitude': longitude,
    'createdAt': createdAt?.millisecondsSinceEpoch,
    'updatedAt': updatedAt?.millisecondsSinceEpoch,

    'chatMessages': chatMessages?.map((m) => m.toJson()).toList(),
  };

  // ---- helpers genéricos ----

  static int _intFromJson(dynamic v, [int defaultValue = 0]) {
    if (v == null) return defaultValue;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v) ?? defaultValue;
    return defaultValue;
  }

  static double? _doubleFromJson(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static DateTime? _dateTimeFromMillisOrIso(dynamic v) {
    if (v == null) return null;
    if (v is int) {
      return DateTime.fromMillisecondsSinceEpoch(v);
    }
    if (v is num) {
      return DateTime.fromMillisecondsSinceEpoch(v.toInt());
    }
    if (v is String) {
      return DateTime.tryParse(v);
    }
    return null;
  }

  // ---- Enum <-> wire helpers ----

  static LocationEnum _locationFromWire(String v) {
    switch (v) {
      case 'SD':
        return LocationEnum.SD;
      case 'ML':
        return LocationEnum.ML;
      case 'RGD':
        return LocationEnum.RGD;
      default:
      // fallback sensato
        return LocationEnum.SD;
    }
  }

  static String _locationToWire(LocationEnum e) => e.name; // SD/ML/RGD

  static EmergencyType _emerTypeFromWire(String v) {
    switch (v) {
      case 'Medical':
        return EmergencyType.Medical;
      case 'Psycological': // tal cual en el diagrama
        return EmergencyType.Psycological;
      case 'Hazard':
        return EmergencyType.Hazard;
      case 'Fire':
        return EmergencyType.Fire;
      case 'Earthquake':
        return EmergencyType.Earthquake;
      default:
        return EmergencyType.Medical;
    }
  }

  static String _emerTypeToWire(EmergencyType e) => e.name;

  static EmergencyStatus _statusFromWire(String v) {
    switch (v) {
      case 'Unattended':
        return EmergencyStatus.Unattended;
      case 'In progress': // OJO: con espacio
        return EmergencyStatus.InProgress;
      case 'Resolved':
        return EmergencyStatus.Resolved;
      default:
        return EmergencyStatus.Unattended;
    }
  }

  static String _statusToWire(EmergencyStatus s) {
    switch (s) {
      case EmergencyStatus.Unattended:
        return 'Unattended';
      case EmergencyStatus.InProgress:
        return 'In progress';
      case EmergencyStatus.Resolved:
        return 'Resolved';
    }
  }

  // utilidades si manejas JSON plano
  static Emergency fromJsonString(String s) =>
      Emergency.fromJson(json.decode(s) as Map<String, dynamic>);
  String toJsonString() => json.encode(toJson());
}

