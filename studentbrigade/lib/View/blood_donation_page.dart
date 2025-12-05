import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../VM/Orchestrator.dart';
import '../services/blood_donation_storage.dart';

class BloodDonationPage extends StatefulWidget {
  final Orchestrator orchestrator;

  const BloodDonationPage({
    super.key,
    required this.orchestrator,
  });

  @override
  State<BloodDonationPage> createState() => _BloodDonationPageState();
}

class _BloodDonationPageState extends State<BloodDonationPage> {
  final MapController _mapController = MapController();
  late LatLng _initialLocation;
  late String _donationUrl;
  final _fmtcProvider = FMTCTileProvider(
    stores: const {'mapStore': BrowseStoreStrategy.readUpdateCreate},
  );
  
  // Track donated centers to disable buttons
  final Set<String> _donatedCenters = {};
  bool _isProcessingDonation = false;

  @override
  void initState() {
    super.initState();
    print('🩸 [BloodDonationPage] initState - Iniciando carga de datos...');
    
    final centers = widget.orchestrator.mapVM.getBloodDonationCenters();
    if (centers.isNotEmpty) {
      final firstPoint = centers.first;
      _initialLocation = LatLng(firstPoint.latitude, firstPoint.longitude);
    } else {
      _initialLocation = const LatLng(4.6014, -74.0660);
    }

    _requestLocation();
    _loadDonationUrl();
    
    // 🔍 DIAGNÓSTICO TEMPORAL
    widget.orchestrator.mapVM.adapter.debugDonationCentersRaw();
    
    _loadDonationCentersFromFirebase(); // ← NUEVO: Cargar datos de Firebase
    widget.orchestrator.mapVM.addListener(_onMapVmUpdated);
  }

  Future<void> _loadDonationCentersFromFirebase() async {
    try {
      print('🩸 [BloodDonationPage] Cargando centros de donación desde Firebase...');
      await widget.orchestrator.loadDonationCenters();
      print('🩸 [BloodDonationPage] ✅ Centros cargados correctamente');
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('🩸 [BloodDonationPage] ❌ Error cargando centros: $e');
    }
  }

  Future<void> _loadDonationUrl() async {
    print('🩸 [BloodDonationPage] Cargando URL de donación...');
    _donationUrl = await BloodDonationStorage.getDonationUrl();
    print('🩸 [BloodDonationPage] ✅ URL cargada: $_donationUrl');
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    widget.orchestrator.mapVM.removeListener(_onMapVmUpdated);
    super.dispose();
  }

  void _onMapVmUpdated() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _requestLocation() async {
    await widget.orchestrator.getCurrentLocation();
    widget.orchestrator.startLocationTracking();
  }

  Future<void> _openDonationUrl() async {
    try {
      if (await canLaunchUrl(Uri.parse(_donationUrl))) {
        await launchUrl(
          Uri.parse(_donationUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se pudo abrir el enlace')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  List<Marker> _buildBloodDonationMarkers(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final markers = <Marker>[];

    final centers = widget.orchestrator.mapVM.getBloodDonationCenters();

    for (var center in centers) {
      markers.add(
        Marker(
          point: LatLng(center.latitude, center.longitude),
          width: 90,
          height: 70,
          child: Column(
            children: [
              // Icono de donación de sangre (gota con corazón)
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: cs.error,
                  shape: BoxShape.circle,
                  border: Border.all(color: cs.onError, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: cs.error.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.favorite,
                  color: cs.onError,
                  size: 20,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: cs.error,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  center.name,
                  style: TextStyle(
                    color: cs.onError,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Agregar marcador de ubicación del usuario
    final userLocation = widget.orchestrator.currentUserLocation;
    if (userLocation != null) {
      markers.add(
        Marker(
          point: LatLng(userLocation.latitude, userLocation.longitude),
          width: 50,
          height: 50,
          child: Container(
            decoration: BoxDecoration(
              color: cs.primary,
              shape: BoxShape.circle,
              border: Border.all(color: cs.surface, width: 3),
              boxShadow: [
                BoxShadow(
                  color: cs.primary.withOpacity(0.28),
                  blurRadius: 10,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Icon(
              Icons.person_pin_circle,
              color: cs.onPrimary,
              size: 25,
            ),
          ),
        ),
      );
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Blood Donation Information'),
        elevation: 0,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ===== IMAGEN HEADER =====
            Container(
              width: double.infinity,
              height: 200,
              color: cs.primary,
              child: Image.asset(
                'lib/LocalStorage/gotita_donar.png',
                fit: BoxFit.cover,
              ),
            ),
            
            // ===== SECCIÓN DE DESCRIPCIÓN CON IMAGEN =====
            Container(
              padding: const EdgeInsets.all(16),
              color: theme.cardColor,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Text(
                    'Help Save Lives',
                    style: tt.headlineSmall?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Contenedor con descripción completa
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.dividerColor),
                      boxShadow: [
                        BoxShadow(
                          color: cs.shadow.withOpacity(
                            theme.brightness == Brightness.light ? .08 : .24,
                          ),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Imagen de encabezado
                        Container(
                          width: double.infinity,
                          height: 180,
                          decoration: const BoxDecoration(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(12),
                            ),
                            child: Image.asset(
                              'assets/images/gotita_donar.png',
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: cs.primaryContainer,
                                  child: Icon(
                                    Icons.bloodtype,
                                    size: 80,
                                    color: cs.primary,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Título
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cs.primaryContainer,
                          ),
                          child: Text(
                            'Blood Donation Centers Near You',
                            style: tt.titleLarge?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        // Descripción
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Multiple donation centers are near the university. If you would like to learn more, please continue to the following page:',
                            style: tt.bodyMedium?.copyWith(
                              color: cs.onSurface,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Botón para abrir URL
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: _openDonationUrl,
                      style: FilledButton.styleFrom(
                        backgroundColor: cs.error,
                        foregroundColor: cs.onError,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.open_in_new, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Learn More About Donation',
                            style: tt.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ===== SECCIÓN DEL MAPA =====
            Container(
              height: 400,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withOpacity(
                      theme.brightness == Brightness.light ? .12 : .32,
                    ),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _initialLocation,
                    initialZoom: 15.0,
                    minZoom: 5.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.studentbrigade',
                      tileProvider: _fmtcProvider,
                      maxZoom: 18,
                    ),
                    MarkerLayer(
                      markers: _buildBloodDonationMarkers(context),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ===== SECCIÓN DE INFORMACIÓN =====
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Donation Centers',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Builder(
                    builder: (context) {
                      final centers = widget.orchestrator.getDonationCenters();
                      print('🩸 [BloodDonationPage UI] Rendering ${centers.length} centros');
                      
                      if (centers.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Text(
                              'No donation centers available',
                              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                            ),
                          ),
                        );
                      }

                      return Column(
                        children: centers.map((center) {
                          print('🩸 [BloodDonationPage] Rendering center: ${center.name}');
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: theme.cardColor,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: theme.dividerColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Nombre en negrilla con icono
                                  Row(
                                    children: [
                                      Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: cs.error,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.favorite,
                                          color: cs.onError,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          center.name,
                                          style: tt.headlineSmall?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: cs.onSurface,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),

                                  // Información en filas
                                  Text(
                                    'Open: ${center.openTime}',
                                    style: tt.bodyMedium?.copyWith(
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Close: ${center.closeTime}',
                                    style: tt.bodyMedium?.copyWith(
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Donations: ${center.donations}',
                                    style: tt.bodyMedium?.copyWith(
                                      color: cs.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 12),

                                  // Botón de donación
                                  SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: (_donatedCenters.isNotEmpty && !_donatedCenters.contains(center.id)) || _isProcessingDonation
                                          ? null  // Disable if already donated in another center or processing
                                          : () async {
                                              if (_isProcessingDonation) return;
                                              
                                              print('🩸 [BloodDonationPage] Usuario intenta donar en ${center.name} (ID: ${center.id})');
                                              setState(() => _isProcessingDonation = true);
                                              
                                              try {
                                                // Increment donation count
                                                await widget.orchestrator.incrementDonationCount(center.id);
                                                print('🩸 [BloodDonationPage] ✅ Donación registrada en ${center.name}');
                                                
                                                // Mark center as donated
                                                setState(() {
                                                  _donatedCenters.add(center.id);
                                                  _isProcessingDonation = false;
                                                });
                                                
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('¡Gracias por donar en ${center.name}!'),
                                                      backgroundColor: cs.error,
                                                      duration: const Duration(seconds: 2),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                print('❌ Error en donación: $e');
                                                setState(() => _isProcessingDonation = false);
                                                
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: Text('Error al registrar donación: $e'),
                                                      backgroundColor: cs.errorContainer,
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                      style: FilledButton.styleFrom(
                                        backgroundColor: _donatedCenters.contains(center.id)
                                            ? cs.tertiaryContainer  // Light gray for donated
                                            : (_donatedCenters.isNotEmpty && !_donatedCenters.contains(center.id))
                                                ? cs.surfaceVariant  // Disabled gray
                                                : cs.error,  // Red for active
                                        foregroundColor: _donatedCenters.contains(center.id)
                                            ? cs.onTertiary
                                            : (_donatedCenters.isNotEmpty && !_donatedCenters.contains(center.id))
                                                ? cs.onSurfaceVariant
                                                : cs.onError,
                                      ),
                                      child: Text(
                                        _donatedCenters.contains(center.id)
                                            ? 'Thanks for your donation! ❤️'
                                            : (_donatedCenters.isNotEmpty && !_donatedCenters.contains(center.id))
                                                ? 'Already donated at another center'
                                                : 'Donate Here',
                                        style: tt.labelLarge,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),

      // FABs para mapa
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "bd_location",
            onPressed: widget.orchestrator.currentUserLocation != null
                ? () {
                    _mapController.move(
                      LatLng(
                        widget.orchestrator.currentUserLocation!.latitude,
                        widget.orchestrator.currentUserLocation!.longitude,
                      ),
                      16.0,
                    );
                  }
                : null,
            backgroundColor: widget.orchestrator.currentUserLocation != null
                ? cs.primary
                : cs.surfaceVariant,
            foregroundColor: widget.orchestrator.currentUserLocation != null
                ? cs.onPrimary
                : cs.onSurfaceVariant,
            tooltip: 'My Location',
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "bd_refresh",
            onPressed: _requestLocation,
            backgroundColor: cs.primaryContainer,
            foregroundColor: cs.onPrimaryContainer,
            tooltip: 'Refresh Location',
            child: const Icon(Icons.refresh),
          ),
        ],
      ),
    );
  }
}
