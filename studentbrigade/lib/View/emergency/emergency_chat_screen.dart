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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: cs.error, // rojo “alerta”
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onError),
          onPressed: () => Navigator.pop(context),
          tooltip: 'Back',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Emergency Active',
                style: tt.titleMedium?.copyWith(color: cs.onError, fontWeight: FontWeight.w600)),
            Text('Help is on the way',
                style: tt.bodySmall?.copyWith(color: cs.onError.withOpacity(.9))),
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
                  decoration: BoxDecoration(color: cs.secondary, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text('Connected',
                    style: tt.bodySmall?.copyWith(color: cs.onError, fontSize: 12)),
              ],
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: theme.cardColor,
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
        color: theme.scaffoldBackgroundColor,
        child: IndexedStack(
          index: _activeTab.index,
          children: [
            _buildBrigadist(theme),
            _buildMedical(theme),
            _buildAssistant(theme),
            _buildMap(theme),
          ],
        ),
      ),
    );
  }

  /* ======================= BRIGADIST CHAT ======================= */
  Widget _buildBrigadist(ThemeData theme) {
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Column(
      children: [
        // Header suave con secondary (estado “en camino”)
        Container(
          color: cs.secondary.withOpacity(.15),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: cs.secondary,
                child: Icon(Icons.person, color: cs.onSecondary, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sarah Martinez',
                        style: tt.titleSmall?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.w600,
                        )),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: cs.secondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text('Available - 2 min away',
                            style: tt.bodySmall?.copyWith(color: cs.secondary)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {/* TODO: call */},
                icon: Icon(Icons.call, color: cs.secondary),
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
                // yo: secondary (verde/teal), bot: primaryContainer
                bg: isMe ? cs.secondary : cs.primaryContainer,
                fg: isMe ? cs.onSecondary : cs.onPrimaryContainer,
              );
            },
          ),
        ),

        // Input
        _InputBar(
          controller: _brigadistInput,
          hint: 'Type your response...',
          onSend: _sendBrigadist,
          buttonColor: cs.secondary,
        ),
      ],
    );
  }

  /* ======================= MEDICAL INFO ======================= */
<<<<<<< HEAD
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
=======
  Widget _buildMedical(ThemeData theme) {
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    Color chipBg(Color base) => Color.alphaBlend(base.withOpacity(.18), cs.surface);
    Color borderFaint = cs.outline.withOpacity(.25);
>>>>>>> fd94a0b679ee8aa361c2e0b43893871bde4d5311

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: ListView(
        children: [
<<<<<<< HEAD
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
=======
          _InfoCard(
            title: 'Blood Type',
            icon: Icons.favorite,
            iconBg: chipBg(cs.error),
            iconColor: cs.error,
            borderColor: borderFaint,
            child: Text(
              _medicalInfo['bloodType'] as String,
              style: tt.headlineSmall?.copyWith(
                color: cs.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Critical Allergies',
            icon: Icons.error_outline,
            iconBg: chipBg(cs.tertiary),
            iconColor: cs.tertiary,
            borderColor: borderFaint,
            child: Column(
              children: ( _medicalInfo['allergies'] as List )
                  .map((a) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: chipBg(cs.tertiary),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(left: BorderSide(color: cs.tertiary, width: 3)),
                ),
                child: Text(a, style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
              ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Emergency Medications',
            icon: Icons.medication_outlined,
            iconBg: chipBg(cs.primary),
            iconColor: cs.primary,
            borderColor: borderFaint,
            child: Column(
              children: ( _medicalInfo['medications'] as List )
                  .map((m) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: chipBg(cs.primary),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(m, style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
              ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          _InfoCard(
            title: 'Emergency Notes',
            icon: Icons.report_gmailerrorred_outlined,
            iconBg: chipBg(cs.error),
            iconColor: cs.error,
            borderColor: borderFaint,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: chipBg(cs.error),
                borderRadius: BorderRadius.circular(10),
                border: Border(left: BorderSide(color: cs.error, width: 3)),
              ),
              child: Text(
                _medicalInfo['notes'] as String,
                style: tt.bodyMedium?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600),
              ),
>>>>>>> fd94a0b679ee8aa361c2e0b43893871bde4d5311
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
  Widget _buildAssistant(ThemeData theme) {
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Column(
      children: [
        Container(
          color: cs.primary.withOpacity(.15),
          padding: const EdgeInsets.all(12),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: cs.primary,
                child: Icon(Icons.support_agent, color: cs.onPrimary, size: 20),
              ),
              SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Brigade Assistant AI',
<<<<<<< HEAD
                      style: TextStyle(color: _ink, fontWeight: FontWeight.w600)),
                  Text('Emergency support specialist',
                      style: TextStyle(color: _teal)),
=======
                      style: tt.titleSmall?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600)),
                  Text('Emergency support specialist',
                      style: tt.bodySmall?.copyWith(color: cs.primary)),
>>>>>>> fd94a0b679ee8aa361c2e0b43893871bde4d5311
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
                bg: isMe ? cs.secondary : cs.surfaceVariant,
                fg: isMe ? cs.onSecondary : cs.onSurfaceVariant,
                leadingIcon: isMe ? Icons.person : Icons.smart_toy_outlined,
                leadingColor: isMe ? cs.secondary : cs.primary,
              );
            },
          ),
        ),
        _InputBar(
          controller: _botInput,
          hint: 'Ask about emergency procedures...',
          onSend: _sendBot,
          buttonColor: cs.primary,
        ),
      ],
    );
  }

<<<<<<< HEAD
  /* ======================= MAP / LOCATION ======================= */
  Widget _buildMap(TextTheme tt) {
    final userLocation = widget.orchestrator.currentUserLocation;
    final assignedBrigadist = widget.orchestrator.assignedBrigadist;
    final brigadistRoute = widget.orchestrator.brigadistRoute;
    
=======
  /* ======================= MAP / LOCATION (placeholder) ======================= */
  Widget _buildMap(ThemeData theme) {
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

>>>>>>> fd94a0b679ee8aa361c2e0b43893871bde4d5311
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Header con info del brigadista real
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.secondary.withOpacity(.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.secondary.withOpacity(.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Brigadist Location',
                    style: tt.titleMedium?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
<<<<<<< HEAD
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
=======
                Row(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: cs.secondary, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text('Sarah Martinez - 2 minutes away',
                          style: tt.bodyMedium?.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Moving towards your location',
                    style: tt.bodySmall?.copyWith(color: cs.secondary)),
>>>>>>> fd94a0b679ee8aa361c2e0b43893871bde4d5311
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Mapa con ruta automática
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
<<<<<<< HEAD
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
=======
              child: Container(
                width: double.infinity,
                color: cs.primary.withOpacity(.08),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, size: 48, color: cs.primary),
                    const SizedBox(height: 8),
                    Text('Map goes here',
                        style: tt.bodyMedium?.copyWith(color: cs.onSurface)),
                  ],
                ),
              ),
>>>>>>> fd94a0b679ee8aa361c2e0b43893871bde4d5311
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
              color: cs.tertiaryContainer.withOpacity(.6),
              border: Border.all(color: cs.tertiary.withOpacity(.4)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.access_time, size: 18, color: cs.onTertiaryContainer),
                const SizedBox(width: 8),
<<<<<<< HEAD
                Text(
                  assignedBrigadist != null 
                      ? 'Estimated arrival: ${assignedBrigadist.estimatedArrivalMinutes?.toInt() ?? 0} minutes'
                      : 'Calculating arrival time...',
                  style: tt.bodyMedium?.copyWith(
                    color: _ink,
                    fontWeight: FontWeight.w600,
                  )),
=======
                Text('Estimated arrival: 2 minutes',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onTertiaryContainer,
                      fontWeight: FontWeight.w600,
                    )),
>>>>>>> fd94a0b679ee8aa361c2e0b43893871bde4d5311
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
<<<<<<< HEAD
    final base = active
        ? BoxDecoration(
            color: _teal.withOpacity(.1),
            border: const Border(
              bottom: BorderSide(color: _teal, width: 2),
            ),
          )
        : const BoxDecoration();
=======
    final cs = Theme.of(context).colorScheme;
    final activeStyle = BoxDecoration(
      color: cs.primary.withOpacity(.08),
      border: Border(bottom: BorderSide(color: cs.primary, width: 2)),
    );
>>>>>>> fd94a0b679ee8aa361c2e0b43893871bde4d5311

    final labelStyle = TextStyle(
      color: active ? cs.primary : cs.onSurface.withOpacity(.6),
      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
      fontSize: 13,
    );

    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: active ? activeStyle : const BoxDecoration(),
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
  final IconData leadingIcon;
  final Color? leadingColor;

  const _Bubble({
    super.key,
    required this.text,
    required this.time,
    required this.fromMe,
    required this.bg,
    required this.fg,
    this.leadingIcon = Icons.person,
    this.leadingColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
        border: Border.all(color: cs.outline.withOpacity(.15)),
      ),
      child: Text(text, style: TextStyle(color: fg, height: 1.35, fontSize: 14)),
    );

    final stamp = Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        time,
        style: TextStyle(color: cs.onSurface.withOpacity(.6), fontSize: 11),
      ),
    );

    final avatar = CircleAvatar(
      radius: 14,
      backgroundColor: (leadingColor ?? cs.primary).withOpacity(.15),
      child: Icon(leadingIcon, size: 16, color: leadingColor ?? cs.primary),
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: theme.cardColor,
          border: Border(top: BorderSide(color: theme.dividerColor)),
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
                  hintStyle: TextStyle(color: cs.onSurface.withOpacity(.6), fontSize: 14),
                  filled: true,
                  fillColor: cs.surface,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.outline.withOpacity(.25)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.outline.withOpacity(.25)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: cs.primary, width: 1.2),
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

/* ======================= Card genérica ======================= */
class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final Color iconBg;
  final Color iconColor;
  final Color borderColor;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.child,
    required this.iconBg,
    required this.iconColor,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(theme.brightness == Brightness.light ? .03 : .2),
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
                backgroundColor: iconBg,
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: cs.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

