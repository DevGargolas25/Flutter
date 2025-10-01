import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:studentbrigade/View/video_detail_sheet.dart';

// Import the VM clases
import 'ChatVM.dart';
import 'UserVM.dart';
import 'VideosVM.dart';
import 'AnalyticsVM.dart';
import 'MapVM.dart';

// Import the Model classes
import '../Models/mapMod.dart';
import '../Models/videoMod.dart';

class Orchestrator extends ChangeNotifier {
  // Singleton pattern
  static final Orchestrator _instance = Orchestrator._internal();
  factory Orchestrator() => _instance;

  // Define the VM logic
  late final MapVM _mapVM;
  late final VideosVM _videoVM;

  // Navigation state
  int _currentPageIndex = 0; // Home by default

  Orchestrator._internal() {
    _mapVM = MapVM();
    _videoVM = VideosVM(VideosInfo());
  }

  // Getters
  int get currentPageIndex => _currentPageIndex;
  MapVM get mapVM => _mapVM;
  VideosVM get videoVM => _videoVM;

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

  void navigateToVideos() {
    navigateToPage(3);
  }

  // Map operations - delegar a MapVM
  MapLocation getUniandesLocation() {
    return _mapVM.getUniandesLocation();
  }

  void openVideoDetails(BuildContext context, VideoMod v) {
    _videoVM.play(v);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VideoDetailsSheet(video: v),
    );
  }
}
