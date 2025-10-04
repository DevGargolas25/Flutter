// Enum para tipos de usuario
enum UserType {
  student,
  brigadist,
  analyst
}

// Clase base User (abstracta) - Solo atributos comunes
abstract class User {
  // Información personal base (TODOS los usuarios)
  String _fullName;
  String _studentId;
  String _email;
  String _phone;

  // Contacto de emergencia (TODOS los usuarios)
  String _emergencyName1;
  String _emergencyPhone1;
  String? _emergencyName2;
  String? _emergencyPhone2;

  // Información médica (TODOS los usuarios)
  String _bloodType;
  String? _doctorName;
  String? _doctorPhone;
  String _insuranceProvider;

  // Alergias (TODOS los usuarios)
  String? _foodAllergies;
  String? _environmentalAllergies;
  String? _drugAllergies;
  String? _severityNotes;

  // Medicamentos (TODOS los usuarios)
  String? _dailyMedications;
  String? _emergencyMedications;
  String? _vitaminsSupplements;
  String? _specialInstructions;

  // Constructor base para todas las clases hijas
  User({
    required String fullName,
    required String studentId,
    required String email,
    required String phone,
    required String emergencyName1,
    required String emergencyPhone1,
    String? emergencyName2,
    String? emergencyPhone2,
    required String bloodType,
    String? doctorName,
    String? doctorPhone,
    required String insuranceProvider,
    String? foodAllergies,
    String? environmentalAllergies,
    String? drugAllergies,
    String? severityNotes,
    String? dailyMedications,
    String? emergencyMedications,
    String? vitaminsSupplements,
    String? specialInstructions,
  }) : _fullName = fullName,
       _studentId = studentId,
       _email = email,
       _phone = phone,
       _emergencyName1 = emergencyName1,
       _emergencyPhone1 = emergencyPhone1,
       _emergencyName2 = emergencyName2,
       _emergencyPhone2 = emergencyPhone2,
       _bloodType = bloodType,
       _doctorName = doctorName,
       _doctorPhone = doctorPhone,
       _insuranceProvider = insuranceProvider,
       _foodAllergies = foodAllergies,
       _environmentalAllergies = environmentalAllergies,
       _drugAllergies = drugAllergies,
       _severityNotes = severityNotes,
       _dailyMedications = dailyMedications,
       _emergencyMedications = emergencyMedications,
       _vitaminsSupplements = vitaminsSupplements,
       _specialInstructions = specialInstructions;

  // Getters base (TODOS los usuarios)
  String get fullName => _fullName;
  String get studentId => _studentId;
  String get email => _email;
  String get phone => _phone;
  String get emergencyName1 => _emergencyName1;
  String get emergencyPhone1 => _emergencyPhone1;
  String? get emergencyName2 => _emergencyName2;
  String? get emergencyPhone2 => _emergencyPhone2;
  String get bloodType => _bloodType;
  String? get doctorName => _doctorName;
  String? get doctorPhone => _doctorPhone;
  String get insuranceProvider => _insuranceProvider;
  String? get foodAllergies => _foodAllergies;
  String? get environmentalAllergies => _environmentalAllergies;
  String? get drugAllergies => _drugAllergies;
  String? get severityNotes => _severityNotes;
  String? get dailyMedications => _dailyMedications;
  String? get emergencyMedications => _emergencyMedications;
  String? get vitaminsSupplements => _vitaminsSupplements;
  String? get specialInstructions => _specialInstructions;

  // Getter abstracto para tipo (cada clase hija lo implementa)
  UserType get userType;

  // Métodos de conveniencia para verificar tipo
  bool get isStudent => userType == UserType.student;
  bool get isBrigadist => userType == UserType.brigadist;
  bool get isAnalyst => userType == UserType.analyst;

  // Setters base
  set fullName(String value) => _fullName = value;
  set studentId(String value) => _studentId = value;
  set email(String value) => _email = value;
  set phone(String value) => _phone = value;
  set emergencyName1(String value) => _emergencyName1 = value;
  set emergencyPhone1(String value) => _emergencyPhone1 = value;
  set emergencyName2(String? value) => _emergencyName2 = value;
  set emergencyPhone2(String? value) => _emergencyPhone2 = value;
  set bloodType(String value) => _bloodType = value;
  set doctorName(String? value) => _doctorName = value;
  set doctorPhone(String? value) => _doctorPhone = value;
  set insuranceProvider(String value) => _insuranceProvider = value;
  set foodAllergies(String? value) => _foodAllergies = value;
  set environmentalAllergies(String? value) => _environmentalAllergies = value;
  set drugAllergies(String? value) => _drugAllergies = value;
  set severityNotes(String? value) => _severityNotes = value;
  set dailyMedications(String? value) => _dailyMedications = value;
  set emergencyMedications(String? value) => _emergencyMedications = value;
  set vitaminsSupplements(String? value) => _vitaminsSupplements = value;
  set specialInstructions(String? value) => _specialInstructions = value;
}

// ========= CLASE STUDENT - Solo atributos básicos =========
class Student extends User {
  Student({
    required String fullName,
    required String studentId,
    required String email,
    required String phone,
    required String emergencyName1,
    required String emergencyPhone1,
    String? emergencyName2,
    String? emergencyPhone2,
    required String bloodType,
    String? doctorName,
    String? doctorPhone,
    required String insuranceProvider,
    String? foodAllergies,
    String? environmentalAllergies,
    String? drugAllergies,
    String? severityNotes,
    String? dailyMedications,
    String? emergencyMedications,
    String? vitaminsSupplements,
    String? specialInstructions,
  }) : super(
         fullName: fullName,
         studentId: studentId,
         email: email,
         phone: phone,
         emergencyName1: emergencyName1,
         emergencyPhone1: emergencyPhone1,
         emergencyName2: emergencyName2,
         emergencyPhone2: emergencyPhone2,
         bloodType: bloodType,
         doctorName: doctorName,
         doctorPhone: doctorPhone,
         insuranceProvider: insuranceProvider,
         foodAllergies: foodAllergies,
         environmentalAllergies: environmentalAllergies,
         drugAllergies: drugAllergies,
         severityNotes: severityNotes,
         dailyMedications: dailyMedications,
         emergencyMedications: emergencyMedications,
         vitaminsSupplements: vitaminsSupplements,
         specialInstructions: specialInstructions,
       );

  @override
  UserType get userType => UserType.student;
}

// ========= CLASE BRIGADIST - Hereda de User + atributos específicos =========
class Brigadist extends User {
  // ATRIBUTOS EXCLUSIVOS de brigadista
  double _latitude;
  double _longitude;
  String _status; // "available", "busy", "en_route"
  double? _estimatedArrivalMinutes;

  Brigadist({
    // Atributos base heredados
    required String fullName,
    required String studentId,
    required String email,
    required String phone,
    required String emergencyName1,
    required String emergencyPhone1,
    String? emergencyName2,
    String? emergencyPhone2,
    required String bloodType,
    String? doctorName,
    String? doctorPhone,
    required String insuranceProvider,
    String? foodAllergies,
    String? environmentalAllergies,
    String? drugAllergies,
    String? severityNotes,
    String? dailyMedications,
    String? emergencyMedications,
    String? vitaminsSupplements,
    String? specialInstructions,
    // ATRIBUTOS EXCLUSIVOS de brigadista
    required double latitude,
    required double longitude,
    required String status,
    double? estimatedArrivalMinutes,
  }) : _latitude = latitude,
       _longitude = longitude,
       _status = status,
       _estimatedArrivalMinutes = estimatedArrivalMinutes,
       super(
         fullName: fullName,
         studentId: studentId,
         email: email,
         phone: phone,
         emergencyName1: emergencyName1,
         emergencyPhone1: emergencyPhone1,
         emergencyName2: emergencyName2,
         emergencyPhone2: emergencyPhone2,
         bloodType: bloodType,
         doctorName: doctorName,
         doctorPhone: doctorPhone,
         insuranceProvider: insuranceProvider,
         foodAllergies: foodAllergies,
         environmentalAllergies: environmentalAllergies,
         drugAllergies: drugAllergies,
         severityNotes: severityNotes,
         dailyMedications: dailyMedications,
         emergencyMedications: emergencyMedications,
         vitaminsSupplements: vitaminsSupplements,
         specialInstructions: specialInstructions,
       );

  @override
  UserType get userType => UserType.brigadist;

  // Getters específicos de brigadista
  double get latitude => _latitude;
  double get longitude => _longitude;
  String get status => _status;
  double? get estimatedArrivalMinutes => _estimatedArrivalMinutes;

  // Setters específicos de brigadista
  set latitude(double value) => _latitude = value;
  set longitude(double value) => _longitude = value;
  set status(String value) => _status = value;
  set estimatedArrivalMinutes(double? value) => _estimatedArrivalMinutes = value;
}

// ========= CLASE ANALYST - Solo atributos básicos =========
class Analyst extends User {
  Analyst({
    required String fullName,
    required String studentId,
    required String email,
    required String phone,
    required String emergencyName1,
    required String emergencyPhone1,
    String? emergencyName2,
    String? emergencyPhone2,
    required String bloodType,
    String? doctorName,
    String? doctorPhone,
    required String insuranceProvider,
    String? foodAllergies,
    String? environmentalAllergies,
    String? drugAllergies,
    String? severityNotes,
    String? dailyMedications,
    String? emergencyMedications,
    String? vitaminsSupplements,
    String? specialInstructions,
  }) : super(
         fullName: fullName,
         studentId: studentId,
         email: email,
         phone: phone,
         emergencyName1: emergencyName1,
         emergencyPhone1: emergencyPhone1,
         emergencyName2: emergencyName2,
         emergencyPhone2: emergencyPhone2,
         bloodType: bloodType,
         doctorName: doctorName,
         doctorPhone: doctorPhone,
         insuranceProvider: insuranceProvider,
         foodAllergies: foodAllergies,
         environmentalAllergies: environmentalAllergies,
         drugAllergies: drugAllergies,
         severityNotes: severityNotes,
         dailyMedications: dailyMedications,
         emergencyMedications: emergencyMedications,
         vitaminsSupplements: vitaminsSupplements,
         specialInstructions: specialInstructions,
       );

  @override
  UserType get userType => UserType.analyst;
}

// ========= DATOS SIMULADOS =========
class BrigadistData {
  static final List<Brigadist> _mockBrigadists = [
    Brigadist(
      fullName: 'Sarah Martinez',
      studentId: 'BR2024001',
      email: 'sarah.martinez@uniandes.edu.co',
      phone: '+57 300 123 4567',
      emergencyName1: 'Carlos Martinez',
      emergencyPhone1: '+57 300 111 1111',
      bloodType: 'A+',
      insuranceProvider: 'Seguros Universitarios',
      latitude: 4.6018,
      longitude: -74.0658,
      status: 'en_route',
      estimatedArrivalMinutes: 2.0,
    ),
    Brigadist(
      fullName: 'Carlos Rodriguez',
      studentId: 'BR2024002',
      email: 'carlos.rodriguez@uniandes.edu.co',
      phone: '+57 301 987 6543',
      emergencyName1: 'Ana Rodriguez',
      emergencyPhone1: '+57 301 222 2222',
      bloodType: 'O+',
      insuranceProvider: 'Seguros Universitarios',
      latitude: 4.6025,
      longitude: -74.0670,
      status: 'available',
      estimatedArrivalMinutes: 5.0,
    ),
  ];

  // Obtener brigadista más cercano disponible
  static Brigadist? getClosestAvailableBrigadist(double userLat, double userLon) {
    final available = _mockBrigadists.where((b) => b.status != 'busy');
    return available.isNotEmpty ? available.first : null;
  }

  // Obtener brigadista asignado a emergencia
  static Brigadist? getAssignedBrigadist(String emergencyId) {
    return _mockBrigadists.first;
  }

  // Obtener todos los brigadistas
  static List<Brigadist> getAllBrigadists() {
    return List.unmodifiable(_mockBrigadists);
  }
}

