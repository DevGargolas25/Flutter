import 'dart:async';
import 'package:flutter/material.dart';
import '../../VM/Orchestrator.dart';

// map imports
import 'package:flutter_map/flutter_map.dart';  
import 'package:latlong2/latlong.dart';         


class EmergencyChatScreen extends StatefulWidget {
  final Orchestrator orchestrator;

  const EmergencyChatScreen({super.key, required this.orchestrator});

  @override
  State<EmergencyChatScreen> createState() => _EmergencyChatScreenState();
}

/* ======================= PALETA (match TSX) ======================= */
const _red = Color(0xFFE63946);
const _teal = Color(0xFF75C1C7);
const _green = Color(0xFF60B896);
const _aqua = Color(0xFF99D2D2);
const _peach = Color(0xFFF1AC89);
const _bg = Color(0xFFF7FBFC);
const _ink = Color(0xFF4A2951);

enum _TabKey { brigadist, medical, assistant, map }

class _Msg {
  final String text;
  final bool fromMe; // true => usuario; false => brigadista/bot
  final String time;
  _Msg({required this.text, required this.fromMe, this.time = 'Now'});
}

class _EmergencyChatScreenState extends State<EmergencyChatScreen> {
  _TabKey _activeTab = _TabKey.brigadist;

  // Map controller and simulated brigadist location
  late MapController _mapController = MapController();
  bool _isLoadingBrigadist = false;
  String _emergencyId = 'emergency_001'; // ID de emergencia simulado

  // Map controller operations
  @override
  void initState() {
    super.initState();
    // Listener para ubicación
    widget.orchestrator.mapVM.addListener(_onLocationUpdate);
    // Solicitar ubicación si no la tiene
    if (widget.orchestrator.currentUserLocation == null) {
      widget.orchestrator.getCurrentLocation();
      widget.orchestrator.startLocationTracking();
    }
    // Cargar datos del usuario si no están cargados
    if (widget.orchestrator.userVM.currentUser == null) {
      widget.orchestrator.userVM.fetchUserData('current_user_id');
    }

    // Cargar brigadista asignado
    _loadAssignedBrigadist();
  }

  // Method to upload Brigadist info
  Future<void> _loadAssignedBrigadist() async {
    setState(() => _isLoadingBrigadist = true);
    
    final brigadist = await widget.orchestrator.getAssignedBrigadist(_emergencyId);
    
    if (brigadist != null) {
      _calculateRouteWhenReady();
    }
    
    setState(() => _isLoadingBrigadist = false);
  }

  void _calculateRouteWhenReady() {
    final userLocation = widget.orchestrator.currentUserLocation;
    final assignedBrigadist = widget.orchestrator.assignedBrigadist;
    
    if (userLocation != null && assignedBrigadist != null) {
      widget.orchestrator.calculateRouteToBrigadist(
        assignedBrigadist.latitude, 
        assignedBrigadist.longitude
      );
    } else {
      Timer.periodic(const Duration(milliseconds: 500), (timer) {
        final location = widget.orchestrator.currentUserLocation;
        final brigadist = widget.orchestrator.assignedBrigadist;
        
        if (location != null && brigadist != null) {
          timer.cancel();
          widget.orchestrator.calculateRouteToBrigadist(
            brigadist.latitude, 
            brigadist.longitude
          );
        }
      });
    }
  }

  void _onLocationUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _brigadistInput.dispose();
    _botInput.dispose();
    widget.orchestrator.mapVM.removeListener(_onLocationUpdate);
    super.dispose();
  }



  // Brigadist chat
  final _brigadistInput = TextEditingController();
  final List<_Msg> _brigadistMsgs = [
    _Msg(text: "Emergency received! I'm Sarah from the Brigade Team. Are you injured?", fromMe: false),
    _Msg(text: "I'm currently 2 minutes away from your location. Stay calm.", fromMe: false),
  ];

  // Chatbot (assistant) chat
  final _botInput = TextEditingController();
  final List<_Msg> _botMsgs = [
    _Msg(
      text: 'Emergency protocol activated. I can help you with immediate safety instructions while help is on the way.',
      fromMe: false,
    ),
    _Msg(
      text: 'Based on your location, the nearest safe assembly point is the Main Campus front parking lot.',
      fromMe: false,
    ),
  ];

  // Medical info (mock)
  final _medicalInfo = const {
    'bloodType': 'O+',
    'allergies': [
      'Peanuts, Shellfish',
      'Pollen, Dust mites',
      'Penicillin',
    ],
    'medications': [
      'Inhaler (Albuterol) - As needed for asthma',
      'EpiPen - For severe allergic reactions',
      'Vitamin D3 - 1000 IU daily',
    ],
    'notes':
    'Carry EpiPen for severe reactions. Keep inhaler accessible at all times.',
  };

  /* ======================= CHATBOT REGLAS ======================= */
  String _aiResponse(String userMessage) {
    final m = userMessage.toLowerCase();
    if (m.contains('first aid') || m.contains('injured') || m.contains('hurt')) {
      return 'For immediate first aid: Check breathing and pulse. Apply pressure to bleeding wounds. Keep the person calm and still. Do not move them if you suspect spinal injury.';
    }
    if (m.contains('fire') || m.contains('smoke')) {
      return 'Fire emergency protocol: Stay low to avoid smoke. Feel doors before opening. Use stairs, never elevators. If trapped, signal for help from a window.';
    }
    if (m.contains('evacuation') || m.contains('exit')) {
      return 'Follow your nearest marked evacuation route. Proceed to the designated assembly point shown on the map. Wait for further instructions from brigadists.';
    }
    if (m.contains('panic') || m.contains('scared') || m.contains('afraid')) {
      return 'Take slow, deep breaths. Focus on your breathing pattern. Help is on the way. You are not alone - the brigade team is trained to handle this situation.';
    }
    if (m.contains('earthquake') || m.contains('shake')) {
      return 'During earthquake: Drop, Cover, Hold. After shaking stops, evacuate carefully watching for hazards. Stay away from damaged buildings and power lines.';
    }
    return "I'm here to help with emergency procedures. Ask me about first aid, evacuation routes, fire safety, or any other emergency situation you need assistance with.";
  }

  void _sendBrigadist() {
    final text = _brigadistInput.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _brigadistMsgs.add(_Msg(text: text, fromMe: true));
      _brigadistInput.clear();
    });
  }

  void _sendBot() {
    final text = _botInput.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _botMsgs.add(_Msg(text: text, fromMe: true));
      _botInput.clear();
    });

    // Respuesta "AI" simulada a los 800ms
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() {
        _botMsgs.add(_Msg(text: _aiResponse(text), fromMe: false));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _red,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Emergency Active',
                style: tt.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
            Text('Help is on the way',
                style: tt.bodySmall?.copyWith(color: Colors.white.withOpacity(.9))),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text('Connected',
                    style: tt.bodySmall?.copyWith(color: Colors.white, fontSize: 12)),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: Colors.white,
            child: Row(
              children: [
                _TabBtn(
                  label: 'Brigadist',
                  icon: Icons.chat_bubble_outline,
                  active: _activeTab == _TabKey.brigadist,
                  onTap: () => setState(() => _activeTab = _TabKey.brigadist),
                ),
                _TabBtn(
                  label: 'Medical',
                  icon: Icons.favorite_border,
                  active: _activeTab == _TabKey.medical,
                  onTap: () => setState(() => _activeTab = _TabKey.medical),
                ),
                _TabBtn(
                  label: 'Assistant',
                  icon: Icons.support_agent_outlined,
                  active: _activeTab == _TabKey.assistant,
                  onTap: () => setState(() => _activeTab = _TabKey.assistant),
                ),
                _TabBtn(
                  label: 'Location',
                  icon: Icons.location_on_outlined,
                  active: _activeTab == _TabKey.map,
                  onTap: () => setState(() => _activeTab = _TabKey.map),
                ),
              ],
            ),
          ),
        ),
      ),

      body: Container(
        color: _bg,
        child: IndexedStack(
          index: _activeTab.index,
          children: [
            _buildBrigadist(tt),
            _buildMedical(tt),
            _buildAssistant(tt),
            _buildMap(tt),
          ],
        ),
      ),
    );
  }

  /* ======================= BRIGADIST CHAT ======================= */
  Widget _buildBrigadist(TextTheme tt) {
    return Column(
      children: [
        // Header verde suave como en TSX
        Container(
          color: _green.withOpacity(.2),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: _green,
                child: Icon(Icons.person, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sarah Martinez',
                        style: tt.titleSmall?.copyWith(
                          color: _ink,
                          fontWeight: FontWeight.w600,
                        )),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('Available - 2 min away',
                            style: tt.bodySmall?.copyWith(color: _green)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  // TODO: llamada telefónica
                },
                icon: const Icon(Icons.call, color: _green),
                tooltip: 'Call',
              ),
            ],
          ),
        ),

        // Mensajes
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            itemCount: _brigadistMsgs.length,
            itemBuilder: (ctx, i) {
              final m = _brigadistMsgs[i];
              final isMe = m.fromMe;
              return _Bubble(
                text: m.text,
                time: m.time,
                fromMe: isMe,
                bg: isMe ? _green : _aqua,
                fg: isMe ? Colors.white : _ink,
                avatarColor: isMe ? Colors.grey.shade300 : _green.withOpacity(.2),
                avatarIconColor: isMe ? Colors.grey.shade700 : _green,
              );
            },
          ),
        ),

        // Input
        _InputBar(
          controller: _brigadistInput,
          hint: 'Type your response...',
          onSend: _sendBrigadist,
          buttonColor: _green,
        ),
      ],
    );
  }

  /* ======================= MEDICAL INFO ======================= */
  Widget _buildMedical(TextTheme tt) {
    final user = widget.orchestrator.userVM.currentUser;
    
    if (user == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _teal),
            SizedBox(height: 16),
            Text('Loading medical information...'),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _InfoCard(
                  title: 'Blood Type',
                  icon: Icons.favorite,
                  iconColor: const Color(0xFFE63946),
                  chipBg: _peach.withOpacity(.2),
                  borderColor: _aqua.withOpacity(.3),
                  titleColor: _ink,
                  child: Text(
                    user.bloodType,
                    style: tt.headlineSmall?.copyWith(
                      color: const Color(0xFFE63946),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'Critical Allergies',
                  icon: Icons.error_outline,
                  iconColor: _peach,
                  chipBg: _peach.withOpacity(.2),
                  borderColor: _aqua.withOpacity(.3),
                  titleColor: _ink,
                  child: Column(
                    children: _buildAllergyList(user, tt),
                  ),
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'Emergency Medications',
                  icon: Icons.medication_outlined,
                  iconColor: _teal,
                  chipBg: _teal.withOpacity(.2),
                  borderColor: _aqua.withOpacity(.3),
                  titleColor: _ink,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _teal.withOpacity(.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      user.emergencyMedications ?? 'No emergency medications specified',
                      style: tt.bodyMedium?.copyWith(color: _ink),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _InfoCard(
                  title: 'Emergency Contact',
                  icon: Icons.contact_phone,
                  iconColor: _green,
                  chipBg: _green.withOpacity(.2),
                  borderColor: _aqua.withOpacity(.3),
                  titleColor: _ink,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${user.emergencyName1}: ${user.emergencyPhone1}',
                          style: tt.bodyMedium?.copyWith(color: _ink, fontWeight: FontWeight.w600),
                        ),
                        if (user.emergencyName2 != null && user.emergencyPhone2 != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${user.emergencyName2}: ${user.emergencyPhone2}',
                            style: tt.bodyMedium?.copyWith(color: _ink),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (user.specialInstructions != null) ...[
                  const SizedBox(height: 12),
                  _InfoCard(
                    title: 'Special Instructions',
                    icon: Icons.report_gmailerrorred_outlined,
                    iconColor: _red,
                    chipBg: _red.withOpacity(.15),
                    borderColor: _aqua.withOpacity(.3),
                    titleColor: _ink,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _red.withOpacity(.12),
                        borderRadius: BorderRadius.circular(10),
                        border: Border(left: BorderSide(color: _red, width: 3)),
                      ),
                      child: Text(
                        user.specialInstructions!,
                        style: tt.bodyMedium?.copyWith(color: _ink, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildAllergyList(user, TextTheme tt) {
    List<Widget> allergyWidgets = [];
    
    if (user.foodAllergies != null) {
      allergyWidgets.add(_buildAllergyItem('Food: ${user.foodAllergies}', tt));
    }
    if (user.drugAllergies != null) {
      allergyWidgets.add(_buildAllergyItem('Drugs: ${user.drugAllergies}', tt));
    }
    if (user.environmentalAllergies != null) {
      allergyWidgets.add(_buildAllergyItem('Environmental: ${user.environmentalAllergies}', tt));
    }
    
    if (allergyWidgets.isEmpty) {
      allergyWidgets.add(_buildAllergyItem('No known allergies', tt));
    }
    
    return allergyWidgets;
  }

  Widget _buildAllergyItem(String text, TextTheme tt) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _peach.withOpacity(.2),
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: _peach, width: 3)),
      ),
      child: Text(text, style: tt.bodyMedium?.copyWith(color: _ink)),
    );
  }

  /* ======================= ASSISTANT (CHATBOT) ======================= */
  Widget _buildAssistant(TextTheme tt) {
    return Column(
      children: [
        Container(
          color: _teal.withOpacity(.2),
          padding: const EdgeInsets.all(12),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _teal,
                child: Icon(Icons.support_agent, color: Colors.white, size: 20),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Brigade Assistant AI',
                      style: TextStyle(color: _ink, fontWeight: FontWeight.w600)),
                  Text('Emergency support specialist',
                      style: TextStyle(color: _teal)),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            itemCount: _botMsgs.length,
            itemBuilder: (ctx, i) {
              final m = _botMsgs[i];
              final isMe = m.fromMe;
              return _Bubble(
                text: m.text,
                time: m.time,
                fromMe: isMe,
                bg: isMe ? _green : _aqua,
                fg: isMe ? Colors.white : _ink,
                avatarColor: isMe ? _green.withOpacity(.15) : _teal.withOpacity(.2),
                avatarIconColor: isMe ? _ink : _teal,
                iconData: isMe ? Icons.person : Icons.smart_toy_outlined,
              );
            },
          ),
        ),
        _InputBar(
          controller: _botInput,
          hint: 'Ask about emergency procedures...',
          onSend: _sendBot,
          buttonColor: _teal,
        ),
      ],
    );
  }

  /* ======================= MAP / LOCATION ======================= */
  Widget _buildMap(TextTheme tt) {
    final userLocation = widget.orchestrator.currentUserLocation;
    final assignedBrigadist = widget.orchestrator.assignedBrigadist;
    final brigadistRoute = widget.orchestrator.brigadistRoute;
    
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Header con info del brigadista real
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _green.withOpacity(.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _green.withOpacity(.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Brigadist Location',
                    style: tt.titleMedium?.copyWith(color: _ink, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                if (_isLoadingBrigadist) ...[
                  const Row(
                    children: [
                      SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: _green),
                      ),
                      SizedBox(width: 8),
                      Text('Finding nearest brigadist...'),
                    ],
                  ),
                ] else if (assignedBrigadist != null) ...[
                  Row(
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${assignedBrigadist.fullName} - ${assignedBrigadist.estimatedArrivalMinutes?.toInt() ?? 0} minutes away',
                          style: tt.bodyMedium?.copyWith(color: _ink, fontWeight: FontWeight.w600)
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Status: ${assignedBrigadist.status}',
                      style: tt.bodySmall?.copyWith(color: _green)),
                ] else ...[
                  const Text('No brigadist assigned', 
                      style: TextStyle(color: Colors.orange)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Mapa con ruta automática
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: userLocation != null 
                  ? FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: LatLng(userLocation.latitude, userLocation.longitude),
                        initialZoom: 16.0,
                        minZoom: 14.0,
                        maxZoom: 18.0,
                      ),
                      children: [
                        TileLayer(
                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                          userAgentPackageName: 'com.example.studentbrigade',
                          maxZoom: 18,
                        ),
                        // Agregar ruta
                        if (brigadistRoute != null)
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: brigadistRoute
                                    .map((point) => LatLng(point.latitude, point.longitude))
                                    .toList(),
                                color: _green, // Verde para ruta al brigadista
                                strokeWidth: 4.0,
                              ),
                            ],
                          ),
                        MarkerLayer(
                          markers: [
                            // Tu ubicación (azul)
                            Marker(
                              point: LatLng(userLocation.latitude, userLocation.longitude),
                              width: 50,
                              height: 50,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.person_pin_circle,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                            ),
                            // Ubicación del brigadista real
                            if (assignedBrigadist != null)
                              Marker(
                                point: LatLng(assignedBrigadist.latitude, assignedBrigadist.longitude),
                                width: 50,
                                height: 70,
                                child: Column(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: _green,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 3),
                                        boxShadow: [
                                          BoxShadow(
                                            color: _green.withOpacity(0.3),
                                            blurRadius: 8,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                      padding: const EdgeInsets.all(8),
                                      child: const Icon(
                                        Icons.medical_services,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                                    ),
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: _green,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        assignedBrigadist.fullName.split(' ').first, // Solo primer nombre
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                    )
                  : Container(
                      width: double.infinity,
                      color: _aqua.withOpacity(.2),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const CircularProgressIndicator(color: _teal),
                          const SizedBox(height: 16),
                          Text('Getting your location...',
                              style: tt.bodyMedium?.copyWith(color: _ink)),
                        ],
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 12),

          // Botones de acción del mapa
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: userLocation != null
                      ? () {
                          _mapController.move(
                            LatLng(userLocation.latitude, userLocation.longitude),
                            17.0,
                          );
                        }
                      : null,
                  icon: const Icon(Icons.my_location, size: 18),
                  label: const Text('My Location'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: assignedBrigadist != null
                      ? () {
                          _mapController.move(
                            LatLng(assignedBrigadist.latitude, assignedBrigadist.longitude), 
                            17.0
                          );
                        }
                      : null,
                  icon: const Icon(Icons.medical_services, size: 18),
                  label: const Text('Brigadist'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ETA info card con datos reales
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _peach.withOpacity(.2),
              border: Border.all(color: _peach.withOpacity(.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time, size: 18, color: _ink),
                const SizedBox(width: 8),
                Text(
                  assignedBrigadist != null 
                      ? 'Estimated arrival: ${assignedBrigadist.estimatedArrivalMinutes?.toInt() ?? 0} minutes'
                      : 'Calculating arrival time...',
                  style: tt.bodyMedium?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w600,
                  )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ======================= WIDGETS UI REUTILIZABLES ======================= */

class _TabBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _TabBtn({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final base = active
        ? BoxDecoration(
            color: _teal.withOpacity(.1),
            border: const Border(
              bottom: BorderSide(color: _teal, width: 2),
            ),
          )
        : const BoxDecoration();

    final labelStyle = TextStyle(
      color: active ? _teal : _ink.withOpacity(.6),
      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
      fontSize: 13,
    );

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: base,
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: labelStyle.color),
              const SizedBox(width: 6),
              Text(label, style: labelStyle),
            ],
          ),
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final String time;
  final bool fromMe;
  final Color bg;
  final Color fg;
  final Color avatarColor;
  final Color avatarIconColor;
  final IconData iconData;

  const _Bubble({
    super.key,
    required this.text,
    required this.time,
    required this.fromMe,
    required this.bg,
    required this.fg,
    required this.avatarColor,
    required this.avatarIconColor,
    this.iconData = Icons.person,
  });

  @override
  Widget build(BuildContext context) {
    final bubble = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .75),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(12),
          topRight: const Radius.circular(12),
          bottomLeft: Radius.circular(fromMe ? 12 : 4),
          bottomRight: Radius.circular(fromMe ? 4 : 12),
        ),
      ),
      child: Text(text, style: TextStyle(color: fg, height: 1.35, fontSize: 14)),
    );

    final stamp = Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        time,
        style: TextStyle(color: Colors.black54, fontSize: 11),
      ),
    );

    final avatar = CircleAvatar(
      radius: 14,
      backgroundColor: avatarColor,
      child: Icon(iconData, size: 16, color: avatarIconColor),
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: fromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: fromMe
            ? [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [bubble, stamp])),
          const SizedBox(width: 8),
          avatar,
        ]
            : [
          avatar,
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [bubble, stamp])),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final VoidCallback onSend;
  final Color buttonColor;

  const _InputBar({
    required this.controller,
    required this.hint,
    required this.onSend,
    required this.buttonColor,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade300)),
        ),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(color: _ink.withOpacity(.5), fontSize: 14),
                  filled: true,
                  fillColor: _bg,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _aqua.withOpacity(.3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _aqua.withOpacity(.3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _teal, width: 1),
                  ),
                ),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: buttonColor,
              borderRadius: BorderRadius.circular(10),
              child: InkWell(
                onTap: onSend,
                borderRadius: BorderRadius.circular(10),
                child: const Padding(
                  padding: EdgeInsets.all(10.0),
                  child: Icon(Icons.send_rounded, size: 20, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ======================= Cards genéricas ======================= */
class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color chipBg;
  final Color borderColor;
  final Color titleColor;
  final Color iconColor;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.child,
    required this.chipBg,
    required this.borderColor,
    required this.titleColor,
    this.iconColor = _teal,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.03),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: chipBg,
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w600,
                  )),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
