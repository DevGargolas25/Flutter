import 'package:flutter/foundation.dart';

// Import the VM clases
import 'ChatVM.dart';
import 'UserVM.dart';
import 'VideosVM.dart';
import 'AnalyticsVM.dart';
import 'MapVM.dart';

// Import the Model classes
import '../Models/mapMod.dart';
import '../Models/userMod.dart';



class Orchestrator extends ChangeNotifier {
  
  // Singleton pattern
  static final Orchestrator _instance = Orchestrator._internal();
  factory Orchestrator() => _instance;
  
  // Define the VM logic
  late final MapVM _mapVM;
  late final UserVM _userVM;
  
  // Navigation state
  int _currentPageIndex = 0; // Home by default

  Orchestrator._internal() {
    _mapVM = MapVM();
    _userVM = UserVM();
    _loadInitialUser(); // TODO cambiar por quien inicie sesion
  }

  //Cargar datos iniciales
  Future<void> _loadInitialUser() async {
    await _userVM.fetchUserData('current-user-id');
  }

  // Getters
  int get currentPageIndex => _currentPageIndex;
  MapVM get mapVM => _mapVM;
  UserVM get userVM => _userVM;

  // Navigation
  void navigateToPage(int index) {
    if (_currentPageIndex != index) {
      _currentPageIndex = index;
      notifyListeners();
    }
  }

  void navigateToMap(){
    navigateToPage(2);
  }

  void navigateToProfile() {
    navigateToPage(4);
  }



  // MAP OPERATIONS
  MapLocation getUniandesLocation() {
    return _mapVM.getUniandesLocation();
  }


  // USER OPERATIONS
  User? getUserData() {
    return _userVM.getUserData();
  }

  Future<bool> updateUserData({
    String? emergencyName1,
    String? emergencyPhone1,
    String? emergencyName2,
    String? emergencyPhone2,
    String? bloodType,
    String? doctorName,
    String? doctorPhone,
    String? insuranceProvider,
    String? foodAllergies,
    String? environmentalAllergies,
    String? drugAllergies,
    String? severityNotes,
    String? dailyMedications,
    String? emergencyMedications,
    String? vitaminsSupplements,
    String? specialInstructions,
  }) async {
    return await _userVM.updateUserData(
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
}