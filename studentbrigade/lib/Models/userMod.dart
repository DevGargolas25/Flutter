import 'package:flutter/foundation.dart';

// ...existing code...
enum UserType { student, brigadist, analyst }

abstract class User {
  String fullName;
  String studentId;
  String email;
  String phone;

  String emergencyName1;
  String emergencyPhone1;
  String? emergencyName2;
  String? emergencyPhone2;

  String bloodType;
  String? doctorName;
  String? doctorPhone;
  String insuranceProvider;

  String? foodAllergies;
  String? environmentalAllergies;
  String? drugAllergies;
  String? severityNotes;

  String? dailyMedications;
  String? emergencyMedications;
  String? vitaminsSupplements;
  String? specialInstructions;
  String? userType;

  User({
    required this.fullName,
    required this.studentId,
    required this.email,
    required this.phone,
    required this.emergencyName1,
    required this.emergencyPhone1,
    this.emergencyName2,
    this.emergencyPhone2,
    required this.bloodType,
    this.doctorName,
    this.doctorPhone,
    required this.insuranceProvider,
    this.foodAllergies,
    this.environmentalAllergies,
    this.drugAllergies,
    this.severityNotes,
    this.dailyMedications,
    this.emergencyMedications,
    this.vitaminsSupplements,
    this.specialInstructions,
    this.userType,
  });

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'studentId': studentId,
      'email': email,
      'phone': phone,
      'emergencyName1': emergencyName1,
      'emergencyPhone1': emergencyPhone1,
      'emergencyName2': emergencyName2,
      'emergencyPhone2': emergencyPhone2,
      'bloodType': bloodType,
      'doctorName': doctorName,
      'doctorPhone': doctorPhone,
      'insuranceProvider': insuranceProvider,
      'foodAllergies': foodAllergies,
      'environmentalAllergies': environmentalAllergies,
      'drugAllergies': drugAllergies,
      'severityNotes': severityNotes,
      'dailyMedications': dailyMedications,
      'emergencyMedications': emergencyMedications,
      'vitaminsSupplements': vitaminsSupplements,
      'specialInstructions': specialInstructions,
      'userType': userType,
    };
  }

  static User? fromMap(Map<String, dynamic> m) {
    final typeStr = (m['userType'] ?? m['userType'] ?? 'student').toString().toLowerCase();
    // DEBUG: log incoming type/userType for troubleshooting
    try {
      debugPrint('[User.fromMap] incoming type=${m['type']} userType=${m['userType']} -> typeStr=$typeStr');
    } catch (_) {}
    final common = {
      'fullName': m['fullName'] ?? '',
      'studentId': m['studentId'] ?? '',
      'email': m['email'] ?? '',
      'phone': m['phone'] ?? '',
      'emergencyName1': m['emergencyName1'] ?? '',
      'emergencyPhone1': m['emergencyPhone1'] ?? '',
      'emergencyName2': m['emergencyName2'],
      'emergencyPhone2': m['emergencyPhone2'],
      'bloodType': m['bloodType'] ?? '',
      'doctorName': m['doctorName'],
      'doctorPhone': m['doctorPhone'],
      'insuranceProvider': m['insuranceProvider'] ?? '',
      'foodAllergies': m['foodAllergies'],
      'environmentalAllergies': m['environmentalAllergies'],
      'drugAllergies': m['drugAllergies'],
      'severityNotes': m['severityNotes'],
      'dailyMedications': m['dailyMedications'],
      'emergencyMedications': m['emergencyMedications'],
      'vitaminsSupplements': m['vitaminsSupplements'],
      'specialInstructions': m['specialInstructions'],
      'userType':m['userType'],
    };

    if (typeStr == 'brigadist') {
      final b = Brigadist(
        fullName: common['fullName'],
        studentId: common['studentId'],
        email: common['email'],
        phone: common['phone'],
        emergencyName1: common['emergencyName1'],
        emergencyPhone1: common['emergencyPhone1'],
        emergencyName2: common['emergencyName2'],
        emergencyPhone2: common['emergencyPhone2'],
        bloodType: common['bloodType'],
        doctorName: common['doctorName'],
        doctorPhone: common['doctorPhone'],
        insuranceProvider: common['insuranceProvider'],
        foodAllergies: common['foodAllergies'],
        environmentalAllergies: common['environmentalAllergies'],
        drugAllergies: common['drugAllergies'],
        severityNotes: common['severityNotes'],
        dailyMedications: common['dailyMedications'],
        emergencyMedications: common['emergencyMedications'],
        vitaminsSupplements: common['vitaminsSupplements'],
        specialInstructions: common['specialInstructions'],
        // fields specific to brigadist:
        latitude: (m['latitude'] is num) ? (m['latitude'] as num).toDouble() : null,
        longitude: (m['longitude'] is num) ? (m['longitude'] as num).toDouble() : null,
        status: (m['status'] ?? 'available').toString(),
        estimatedArrivalMinutes: (m['estimatedArrivalMinutes'] is num) ? (m['estimatedArrivalMinutes'] as num).toDouble() : null,
      );
      b.userType = typeStr;
      try { debugPrint('[User.fromMap] created Brigadist userType=${b.userType}'); } catch (_) {}
      return b;
    } else if (typeStr == 'analyst') {
      final a = Analyst(
        fullName: common['fullName'],
        studentId: common['studentId'],
        email: common['email'],
        phone: common['phone'],
        emergencyName1: common['emergencyName1'],
        emergencyPhone1: common['emergencyPhone1'],
        emergencyName2: common['emergencyName2'],
        emergencyPhone2: common['emergencyPhone2'],
        bloodType: common['bloodType'],
        doctorName: common['doctorName'],
        doctorPhone: common['doctorPhone'],
        insuranceProvider: common['insuranceProvider'],
        foodAllergies: common['foodAllergies'],
        environmentalAllergies: common['environmentalAllergies'],
        drugAllergies: common['drugAllergies'],
        severityNotes: common['severityNotes'],
        dailyMedications: common['dailyMedications'],
        emergencyMedications: common['emergencyMedications'],
        vitaminsSupplements: common['vitaminsSupplements'],
        specialInstructions: common['specialInstructions'],
      );
      a.userType = typeStr;
      try { debugPrint('[User.fromMap] created Analyst userType=${a.userType}'); } catch (_) {}
      return a;
    } else {
      // default: student
      final s = Student(
        fullName: common['fullName'],
        studentId: common['studentId'],
        email: common['email'],
        phone: common['phone'],
        emergencyName1: common['emergencyName1'],
        emergencyPhone1: common['emergencyPhone1'],
        emergencyName2: common['emergencyName2'],
        emergencyPhone2: common['emergencyPhone2'],
        bloodType: common['bloodType'],
        doctorName: common['doctorName'],
        doctorPhone: common['doctorPhone'],
        insuranceProvider: common['insuranceProvider'],
        foodAllergies: common['foodAllergies'],
        environmentalAllergies: common['environmentalAllergies'],
        drugAllergies: common['drugAllergies'],
        severityNotes: common['severityNotes'],
        dailyMedications: common['dailyMedications'],
        emergencyMedications: common['emergencyMedications'],
        vitaminsSupplements: common['vitaminsSupplements'],
        specialInstructions: common['specialInstructions'],
        userType: common['userType'],
      );
      s.userType = typeStr;
      try { debugPrint('[User.fromMap] created Student userType=${s.userType}'); } catch (_) {}
      return s;
    }
  }
}

// ========= CLASE STUDENT =========
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
    String? userType,
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
          userType: userType,
        );
}

// ========= CLASE BRIGADIST =========
class Brigadist extends User {
  double? latitude;
  double? longitude;
  String status;
  double? estimatedArrivalMinutes;

  Brigadist({
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
    this.latitude,
    this.longitude,
    this.status = 'available',
    this.estimatedArrivalMinutes,
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
}

// ========= CLASE ANALYST =========
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

