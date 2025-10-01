import 'package:flutter/foundation.dart';
import '../Models/userMod.dart';

class UserVM extends ChangeNotifier {
  User? _currentUser;
  String? _errorMessage;

  // Getters
  User? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;

  //Upload data from DB
  Future<User?> fetchUserData(String userId) async {
    _errorMessage = null;
    
    try {
      _currentUser = await UserData.fetchUserFromDatabase(userId);
      notifyListeners();
      return _currentUser;
    } catch (e) {
      _errorMessage = 'Error fetching user data: $e';
      notifyListeners();
      return null;
    }
  }

  // Obtener datos actuales 
  User? getUserData() {
    return _currentUser;
  }

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
      bool success = await UserData.saveUserToDatabase(_currentUser!);
      if (success) {
        notifyListeners();
      }
      return success;
    } catch (e) {
      _errorMessage = 'Error updating user data: $e';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}