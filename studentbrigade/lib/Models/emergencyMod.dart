enum EmerType {
  medical,
  psychological,
  hazard,
}

enum Location {
  SD,
  ML,
  RGD,
}

class Emergency {
  final int emergencyID;
  final int userId;                // FK hacia User
  final int? assignedBrigadistId;  // FK hacia Brigadist
  final DateTime dateTime;
  final int emerRequestTime;       // tiempo en ms o seg desde request
  final int secondsResponse;       // cuánto tardó en responder
  final Location location;
  final EmerType emerType;
  final List<String> chatMessages; // mensajes asociados

  Emergency({
    required this.emergencyID,
    required this.userId,
    this.assignedBrigadistId,
    required this.dateTime,
    required this.emerRequestTime,
    required this.secondsResponse,
    required this.location,
    required this.emerType,
    this.chatMessages = const [],
  });

}
