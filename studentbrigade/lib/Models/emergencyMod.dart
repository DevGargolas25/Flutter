// models/emergency.dart
import 'dart:convert';

/// <<emerType>> según el diagrama: Medical, Psycological, Hazard
enum EmergencyType { Medical, Psycological, Hazard, Fire, Earthquake }

/// <<location>> según el diagrama: SD, ML, RGD
enum LocationEnum { SD, ML, RGD }

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
  final int emerResquestTime;            // EmerResquestTime (según diagrama)
  final int secondsResponse;             // seconds_response
  final LocationEnum location;           // Enumeration (SD/ML/RGD)
  final EmergencyType emerType;          // Enumeration (Medical/...)
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
      chatMessages: chatMessages ?? this.chatMessages,
    );
  }

  // ---- JSON ----
  factory Emergency.fromJson(Map<String, dynamic> json) => Emergency(
    emergencyID: (json['emergencyID'] as num).toInt(),
    userId: json['userId'] as String,
    assignedBrigadistId: json['assignedBrigadistId'] as String?,
    dateTime: DateTime.parse(json['date_time'] as String),
    emerResquestTime: (json['EmerResquestTime'] as num).toInt(),
    secondsResponse: (json['seconds_response'] as num).toInt(),
    location: _locationFromWire(json['location'] as String),
    emerType: _emerTypeFromWire(json['emerType'] as String),
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
    'EmerResquestTime': emerResquestTime,
    'seconds_response': secondsResponse,
    'location': _locationToWire(location),   // SD/ML/RGD
    'emerType': _emerTypeToWire(emerType),   // Medical/Psycological/Hazard
    'chatMessages': chatMessages?.map((m) => m.toJson()).toList(),
  };

  // ---- Enum <-> wire helpers (respetan EXACTAMENTE el texto del diagrama) ----
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
      default:
        return EmergencyType.Medical;
    }
  }

  static String _emerTypeToWire(EmergencyType e) => e.name;

  // utilidades si manejas JSON plano
  static Emergency fromJsonString(String s) =>
      Emergency.fromJson(json.decode(s) as Map<String, dynamic>);
  String toJsonString() => json.encode(toJson());
}

