import 'package:flutter/foundation.dart';

// Import the VM clases
import 'ChatVM.dart';
import 'UserVM.dart';
import 'VideosVM.dart';
import 'AnalyticsVM.dart';
import 'MapVM.dart';

// Import the Model classes
import '../Models/mapMod.dart';



class Orchestrator extends ChangeNotifier {
  
  // Singleton pattern
  static final Orchestrator _instance = Orchestrator._internal();
  factory Orchestrator() => _instance;
  
  // Define the VM logic
  late final MapVM _mapVM;
  
  // Navigation state
  int _currentPageIndex = 0; // Home by default

  Orchestrator._internal() {
    _mapVM = MapVM();
  }

  // Getters
  int get currentPageIndex => _currentPageIndex;
  MapVM get mapVM => _mapVM;

  // Navigation
  void navigateToPage(int index) {
    if (_currentPageIndex != index) {
      _currentPageIndex = index;
      notifyListeners();
    }
  }

  void navigateToProfile() {
    navigateToPage(4);
  }

  // Map operations - delegar a MapVM
  MapLocation getUniandesLocation() {
    return _mapVM.getUniandesLocation();
  }
}