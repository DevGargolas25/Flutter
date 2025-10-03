import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:studentbrigade/View/video_detail_sheet.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;

// Import the VM clases
import 'ChatVM.dart';
import 'UserVM.dart';
import 'VideosVM.dart';
import 'AnalyticsVM.dart';
import 'MapVM.dart';

// Import the Model classes
import '../Models/mapMod.dart';
import '../Models/videoMod.dart';
import '../Models/userMod.dart';
import '../Models/chatModel.dart';

class Orchestrator extends ChangeNotifier {
  // Singleton pattern
  static final Orchestrator _instance = Orchestrator._internal();
  factory Orchestrator() => _instance;

  // Define the VM logic
  late final MapVM _mapVM;
  late final VideosVM _videoVM;
  late final UserVM _userVM;
  late final ChatVM _chatVM;
  // Historial que enviaremos al backend OpenAI (role/content)

  // Navigation state
  int _currentPageIndex = 0; // Home by default

  Orchestrator._internal() {
    _mapVM = MapVM();
    _videoVM = VideosVM(VideosInfo());
    _userVM = UserVM();
    _chatVM = ChatVM(baseUrl: 'http://127.0.0.1:8080'); // emulador Android
    _chatVM.addListener(notifyListeners);
    _loadInitialUser(); // TODO cambiar por quien inicie sesion
  }
  List<ChatMessage> get chatMessages => _chatVM.messages;
  bool get chatIsTyping => _chatVM.isTyping;
  Future<void> sendChatMessage(String text) => _chatVM.sendUserMessage(text);
  void setChatBackendBaseUrl(String url) {
    _chatVM.baseUrl = url; // usa el setter de ChatVM
  }

  void refreshChatBackendBaseUrl() {
    _chatVM.baseUrl = _resolveBaseUrl();
  }

  //Cargar datos iniciales
  Future<void> _loadInitialUser() async {
    await _userVM.fetchUserData('current-user-id');
  }

  // Getters
  int get currentPageIndex => _currentPageIndex;
  MapVM get mapVM => _mapVM;
  VideosVM get videoVM => _videoVM;
  UserVM get userVM => _userVM;
  ChatVM get chatVM => _chatVM;
  // urls para chat

  String _resolveBaseUrl() {
    // Si corres en Flutter Web:
    // - Si tu app web se sirve por http:// (flutter run -d chrome), puedes usar http://127.0.0.1:8080
    // - Si tu app web se sirve por https:// (hosting), DEBES usar backend https (ngrok, cloudflared).
    if (kIsWeb) {
      return const String.fromEnvironment(
        'BACKEND_URL',
        defaultValue: 'http://127.0.0.1:8080',
      );
    }

    // Plataformas nativas:
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Emulador Android
        return 'http://10.0.2.2:8080';
      case TargetPlatform.iOS:
        // Simulator iOS
        return 'http://localhost:8080';
      default:
        // Desktop (Windows/Mac/Linux)
        return 'http://127.0.0.1:8080';
    }
  }

  // Cambia dinámicamente cuando lo necesites:
  void useAndroidEmulatorBackend() {
    _chatVM.baseUrl = 'http://10.0.2.2:8080';
  }

  void useLanBackend(String pcLanIp) {
    // Para dispositivo físico: usa la IP local de tu PC, ej. 192.168.1.50
    _chatVM.baseUrl = 'http://$pcLanIp:8080';
  }

  // Navigation
  void navigateToPage(int index) {
    if (_currentPageIndex != index) {
      _currentPageIndex = index;
      notifyListeners();
    }
  }

  void navigateToMap() {
    navigateToPage(2);
  }

  void navigateToProfile() {
    navigateToPage(4);
  }

  void navigateToVideos() {
    navigateToPage(3);
  }

  void navigateToChat() {
    navigateToPage(1);
  }

  // MAP OPERATIONS
  Future<UserLocation?> getCurrentLocation() async {
    return await _mapVM.getCurrentLocation();
  }

  void startLocationTracking() {
    _mapVM.startLocationTracking();
  }

  void stopLocationTracking() {
    _mapVM.stopLocationTracking();
  }

  List<MapLocation> getMeetingPoints() {
    return _mapVM.getMeetingPoints();
  }

  MapLocation? getClosestMeetingPoint() {
    final userLocation = _mapVM.currentUserLocation;
    if (userLocation == null) return null;
    return _mapVM.getClosestMeetingPoint(userLocation);
  }

  Future<List<RoutePoint>?> calculateRouteToClosestPoint() async {
    return await _mapVM.calculateRouteToClosestPoint();
  }

  List<RoutePoint>? get currentRoute => _mapVM.currentRoute;

  void clearRoute() {
    _mapVM.clearRoute();
  }

  // Getters
  UserLocation? get currentUserLocation => _mapVM.currentUserLocation;
  bool get isLocationLoading => _mapVM.isLocationLoading;
  String? get locationError => _mapVM.locationError;

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
