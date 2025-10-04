import 'package:flutter/foundation.dart';
import '../Models/userMod.dart';
import 'Adapter.dart';

class UserVM extends ChangeNotifier {
  final Adapter _adapter = Adapter();
  User? _currentUser;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  // Obtener datos actuales
  User? getUserData() => _currentUser;
  String? getErrorMessage() => _errorMessage;

  // Actualizar datos del usuario
  Future<bool> updateUserData({
    String? emergencyName1, String? emergencyPhone1,
    String? emergencyName2, String? emergencyPhone2,
    String? bloodType, String? doctorName, String? doctorPhone,
    String? insuranceProvider, String? foodAllergies,
    String? environmentalAllergies, String? drugAllergies,
    String? severityNotes, String? dailyMedications,
    String? emergencyMedications, String? vitaminsSupplements,
    String? specialInstructions,
  }) async {
    if (_currentUser == null) return false;

    _errorMessage = null;

    try {
      // Usar setters para actualizar campos específicos
      if (emergencyName1 != null) _currentUser!.emergencyName1 = emergencyName1;
      if (emergencyPhone1 != null) _currentUser!.emergencyPhone1 = emergencyPhone1;
      if (emergencyName2 != null) _currentUser!.emergencyName2 = emergencyName2.isEmpty ? null : emergencyName2;
      if (emergencyPhone2 != null) _currentUser!.emergencyPhone2 = emergencyPhone2.isEmpty ? null : emergencyPhone2;
      if (bloodType != null) _currentUser!.bloodType = bloodType;
      if (doctorName != null) _currentUser!.doctorName = doctorName.isEmpty ? null : doctorName;
      if (doctorPhone != null) _currentUser!.doctorPhone = doctorPhone.isEmpty ? null : doctorPhone;
      if (insuranceProvider != null) _currentUser!.insuranceProvider = insuranceProvider;
      if (foodAllergies != null) _currentUser!.foodAllergies = foodAllergies.isEmpty ? null : foodAllergies;
      if (environmentalAllergies != null) _currentUser!.environmentalAllergies = environmentalAllergies.isEmpty ? null : environmentalAllergies;
      if (drugAllergies != null) _currentUser!.drugAllergies = drugAllergies.isEmpty ? null : drugAllergies;
      if (severityNotes != null) _currentUser!.severityNotes = severityNotes.isEmpty ? null : severityNotes;
      if (dailyMedications != null) _currentUser!.dailyMedications = dailyMedications.isEmpty ? null : dailyMedications;
      if (emergencyMedications != null) _currentUser!.emergencyMedications = emergencyMedications.isEmpty ? null : emergencyMedications;
      if (vitaminsSupplements != null) _currentUser!.vitaminsSupplements = vitaminsSupplements.isEmpty ? null : vitaminsSupplements;
      if (specialInstructions != null) _currentUser!.specialInstructions = specialInstructions.isEmpty ? null : specialInstructions;

      // Guardar en BD simulada
      final key = _currentUser!.studentId.isNotEmpty ? _currentUser!.studentId : _currentUser!.email;
      await _adapter.updateUser(key, _currentUser!.toMap());

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    }
  }

  // Methods for the map in emergency
  Brigadist? _assignedBrigadist;
  Brigadist? get assignedBrigadist => _assignedBrigadist;

  // Usuario por email para cargar desde el login 
  Future<User?> fetchUserByEmail(String email) async {
    _errorMessage = null;
    try {
      final u = await _adapter.getUserByEmail(email);
      if (u == null) {
        _errorMessage = 'Usuario no encontrado para el email: $email';
        notifyListeners();
        return null;
      }
      _currentUser = u;
      notifyListeners();
      return _currentUser;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }


  // Obtener brigadista más cercano
  Future<Brigadist?> getClosestBrigadist(double userLat, double userLon) async {
    try {
      // Simular llamada a API
      await Future.delayed(const Duration(milliseconds: 500));

      _assignedBrigadist = BrigadistData.getClosestAvailableBrigadist(userLat, userLon);
      notifyListeners();
      return _assignedBrigadist;
    } catch (e) {
      print('Error getting brigadist: $e');
      return null;
    }
  }

  // Obtener brigadista asignado a emergencia activa
  Future<Brigadist?> getAssignedBrigadist(String emergencyId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 300));

      _assignedBrigadist = BrigadistData.getAssignedBrigadist(emergencyId);
      notifyListeners();
      return _assignedBrigadist;
    } catch (e) {
      print('Error getting assigned brigadist: $e');
      return null;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}