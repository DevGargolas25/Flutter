import 'package:flutter/material.dart';
import 'package:studentbrigade/VM/Orchestrator.dart';
import 'package:studentbrigade/Models/userMod.dart';

class EmergencyDetailPage extends StatefulWidget {
  final Orchestrator orchestrator;

  const EmergencyDetailPage({
    Key? key,
    required this.orchestrator,
  }) : super(key: key);

  @override
  State<EmergencyDetailPage> createState() => _EmergencyDetailPageState();
}

class _EmergencyDetailPageState extends State<EmergencyDetailPage> {
  Map<String, dynamic>? em; // selectedEmergency
  dynamic reporter; // User o Map o null
  bool _loadingReporter = false;

  @override
  void initState() {
    super.initState();
    em = widget.orchestrator.selectedEmergency;
    _loadReporterIfNeeded();
  }

  // ===================== Cargar usuario a partir de userId (email) =====================
  Future<void> _loadReporterIfNeeded() async {
    if (em == null) return;

    // En tu diseño, userId es el email del usuario que reporta
    final raw = em!['userId'];
    if (raw == null || raw.toString().trim().isEmpty) return;

    final email = raw.toString().trim();
    setState(() => _loadingReporter = true);

    try {
      dynamic fetched;

      // 1) Intentar obtener un Map directo desde RTDB
      final map = await widget.orchestrator.loadUserMapByEmail(email);
      if (map != null) {
        reporter = User.fromMap(Map<String, dynamic>.from(map));
        return;
      }

      // 2) Fallback: UserVM de alto nivel
      fetched = await widget.orchestrator.loadUserByEmail(email);

      if (fetched is User) {
        reporter = fetched;
      } else if (fetched is Map) {
        reporter = User.fromMap(Map<String, dynamic>.from(fetched));
      } else {
        reporter = null;
      }
    } catch (e) {
      debugPrint('Error loading reporter: $e');
      reporter = null;
    } finally {
      if (mounted) setState(() => _loadingReporter = false);
    }
  }

  // ===================== Helpers =====================

  String _safeString(dynamic v) {
    if (v == null) return 'Not specified';
    final s = v.toString().trim();
    return s.isEmpty ? 'Not specified' : s;
  }

  Future<void> _onResolve() async {
    if (em == null) return;

    // admite varias posibles claves de id
    final id = em!['id'] ?? em!['emergencyID'] ?? em!['emergencyId'];
    if (id == null) return;

    try {
      await widget.orchestrator.resolveEmergency(id.toString());
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Emergency resolved')),
      );

      setState(() => em = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error resolving emergency: $e')),
      );
    }
  }

  // ===================== Reporter display =====================

  String _reporterName() {
    if (reporter == null) return 'Reporter';

    try {
      if (reporter is User) {
        return (reporter as User).fullName;
      }
      if (reporter is Map) {
        final m = reporter as Map;
        return (m['fullName'] ??
                m['name'] ??
                m['displayName'] ??
                m['email'] ??
                'Reporter')
            .toString();
      }
      return reporter.toString();
    } catch (_) {
      return reporter.toString();
    }
  }

  String _reporterEmail() {
    if (reporter == null) return '';
    try {
      if (reporter is User) return (reporter as User).email;
      if (reporter is Map) return ((reporter as Map)['email'] ?? '').toString();
      return '';
    } catch (_) {
      return '';
    }
  }

  String _reporterPhone() {
    if (reporter == null) return '';
    try {
      if (reporter is User) {
        // uso emergencyPhone1 como principal
        return (reporter as User).emergencyPhone1;
      }
      if (reporter is Map) {
        final m = reporter as Map;
        return (m['emergencyPhone1'] ?? m['phone'] ?? '').toString();
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  // ===================== UI =====================

  @override
  Widget build(BuildContext context) {
    // Tipo de usuario loggeado (para mostrar Resolve Emergency solo al brigadista)
    final currentUserType =
        widget.orchestrator.getUserData()?.userType?.toString().toLowerCase();

    if (em == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Emergency')),
        body: const Center(child: Text('No emergency selected')),
      );
    }

    // Título y ubicación
    final title = _safeString(
      em!['type'] ?? em!['category'] ?? 'Emergency',
    );
    final location = _safeString(
      em!['location'] ?? em!['place'] ?? em!['address'],
    );

    // Si conseguimos un User, lo casteamos para usar sus campos
    final User? r = reporter is User ? reporter as User : null;

    // ===== Contactos de emergencia =====
    final primaryContactName = _safeString(
      r?.emergencyName1 ?? em!['emergencyName1'] ?? em!['primary_contact'],
    );
    final primaryContact = _safeString(
      r?.emergencyPhone1 ?? em!['emergencyPhone1'] ?? em!['primary_phone'],
    );
    final secondaryContact = _safeString(
      r?.emergencyPhone2 ?? em!['emergencyPhone2'] ?? em!['secondary_phone'],
    );

    // ===== Info médica básica =====
    final bloodType = _safeString(
      r?.bloodType ?? em!['bloodType'],
    );
    final doctor = _safeString(
      r?.doctorName ?? em!['doctorName'] ?? em!['primaryPhysician'],
    );

    // ===== Alergias =====
    final foodAllergies = _safeString(
      r?.foodAllergies ?? em!['foodAllergies'],
    );
    final environmentalAllergies = _safeString(
      r?.environmentalAllergies ?? em!['environmentalAllergies'],
    );
    final drugAllergies = _safeString(
      r?.drugAllergies ?? em!['drugAllergies'],
    );
    final severityNotes = _safeString(
      r?.severityNotes ?? em!['severityNotes'],
    );

    // ===== Medicamentos actuales =====
    final dailyMedications = _safeString(
      r?.dailyMedications ?? em!['dailyMedications'],
    );
    final emergencyMedications = _safeString(
      r?.emergencyMedications ?? em!['emergencyMedications'],
    );
    final vitaminsSupplements = _safeString(
      r?.vitaminsSupplements ?? em!['vitaminsSupplements'],
    );
    final specialInstructions = _safeString(
      r?.specialInstructions ?? em!['specialInstructions'],
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.redAccent,
        title: Text(
          title,
          style: const TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // aquí podrías lanzar llamada al primary phone
            },
            icon: const Icon(Icons.call, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ========== Cabecera: Location + Resolve ==========
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Location: $location',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    if (currentUserType == 'brigadist')
                      ElevatedButton(
                        onPressed: _onResolve,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 8.0,
                          ),
                          child: Text(
                            'Resolve Emergency',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ========== Emergency Contacts ==========
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.call, color: Colors.teal),
                        SizedBox(width: 8),
                        Text(
                          'Emergency Contacts',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Primary Contact',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _infoBox(primaryContactName),
                    const SizedBox(height: 12),
                    const Text(
                      'Primary Phone',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _infoBox(primaryContact),
                    const SizedBox(height: 12),
                    const Text(
                      'Secondary Contact',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _infoBox(secondaryContact),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ========== Medical Information ==========
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.favorite_border, color: Colors.purple),
                        SizedBox(width: 8),
                        Text(
                          'Medical Information',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Blood Type',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _infoBox(bloodType),
                    const SizedBox(height: 12),
                    const Text(
                      'Primary Physician',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _infoBox(doctor),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ========== Allergies ==========
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.warning_amber_rounded, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Allergies',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Food Allergies',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _infoBox(foodAllergies),
                    const SizedBox(height: 12),
                    const Text(
                      'Environmental Allergies',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _infoBox(environmentalAllergies),
                    const SizedBox(height: 12),
                    const Text(
                      'Drug Allergies',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _infoBox(drugAllergies),
                    const SizedBox(height: 12),
                    const Text(
                      'Severity / Notes',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _infoBox(severityNotes),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ========== Current Medications ==========
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.local_pharmacy, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Current Medications',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Daily Medications',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _infoBox(dailyMedications),
                    const SizedBox(height: 12),
                    const Text(
                      'Emergency Medications',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _infoBox(emergencyMedications),
                    const SizedBox(height: 12),
                    const Text(
                      'Vitamins / Supplements',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _infoBox(vitaminsSupplements),
                    const SizedBox(height: 12),
                    const Text(
                      'Special Instructions',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    _infoBox(specialInstructions),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ========== Reporter Info ==========
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Reported by',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (_loadingReporter)
                      const Center(child: CircularProgressIndicator())
                    else if (reporter != null) ...[
                      Text(_reporterName()),
                      const SizedBox(height: 6),
                      Text(_reporterEmail()),
                      const SizedBox(height: 6),
                      Text(_reporterPhone()),
                    ] else
                      const Text('No reporter details available'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Cajita de texto gris como en el diseño
  Widget _infoBox(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text),
    );
  }
}
