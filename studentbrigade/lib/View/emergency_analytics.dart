import 'package:flutter/material.dart';
import '../VM/Orchestrator.dart';
import '../VM/Adapter.dart';

class EmergencyAnalyticsPage extends StatefulWidget {
  final Orchestrator orchestrator;

  const EmergencyAnalyticsPage({super.key, required this.orchestrator});

  @override
  State<EmergencyAnalyticsPage> createState() => _EmergencyAnalyticsPageState();
}

class _EmergencyAnalyticsPageState extends State<EmergencyAnalyticsPage> {
  final Adapter _adapter = Adapter();

  Map<String, int> _locationStats = {};
  Map<String, int> _emergencyTypeStats = {};
  double _avgResponseTime = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      // Obtener datos de emergencias desde Firebase
      final emergencies = await _adapter.getEmergencyAnalytics();

      // Procesar estadísticas de ubicaciones
      Map<String, int> locationCount = {};
      Map<String, int> emergencyTypeCount = {};
      List<int> responseTimes = [];

      for (var emergency in emergencies) {
        // Contar ubicaciones
        String location = emergency['location'] ?? 'Unknown';
        locationCount[location] = (locationCount[location] ?? 0) + 1;

        // Contar tipos de emergencia
        String emerType = emergency['emerType'] ?? 'Unknown';
        emergencyTypeCount[emerType] = (emergencyTypeCount[emerType] ?? 0) + 1;

        // Recopilar tiempos de respuesta
        int responseTime = emergency['seconds_response'] ?? 0;
        if (responseTime > 0) {
          responseTimes.add(responseTime);
        }
      }

      // Calcular promedio de tiempo de respuesta
      double avgTime = 0.0;
      if (responseTimes.isNotEmpty) {
        avgTime = responseTimes.reduce((a, b) => a + b) / responseTimes.length;
      }

      setState(() {
        _locationStats = locationCount;
        _emergencyTypeStats = emergencyTypeCount;
        _avgResponseTime = avgTime;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading analytics: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Emergency Analytics',
          style: tt.titleLarge?.copyWith(color: cs.onPrimary),
        ),
        backgroundColor: cs.primary,
        iconTheme: IconThemeData(color: cs.onPrimary),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadAnalytics,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tiempo promedio de respuesta
                    _buildStatsCard(
                      title: 'Average Response Time',
                      icon: Icons.timer,
                      content: Text(
                        '${_avgResponseTime.toStringAsFixed(1)} seconds',
                        style: tt.headlineSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      theme: theme,
                    ),

                    const SizedBox(height: 12),

                    // Ubicaciones más usadas
                    _buildStatsCard(
                      title: 'Most Used Locations',
                      icon: Icons.location_on,
                      content: _buildLocationList(),
                      theme: theme,
                    ),

                    const SizedBox(height: 12),

                    // Tipos de emergencia más solicitados
                    _buildStatsCard(
                      title: 'Most Requested Emergency Types',
                      icon: Icons.emergency,
                      content: _buildEmergencyTypeList(),
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsCard({
    required String title,
    required IconData icon,
    required Widget content,
    required ThemeData theme,
  }) {
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: cs.primary, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildLocationList() {
    if (_locationStats.isEmpty) {
      return const Text('No location data available');
    }

    var sortedLocations = _locationStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedLocations.take(5).map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${entry.value}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmergencyTypeList() {
    if (_emergencyTypeStats.isEmpty) {
      return const Text('No emergency type data available');
    }

    var sortedTypes = _emergencyTypeStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedTypes.map((entry) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    _getEmergencyIcon(entry.key),
                    const SizedBox(width: 6),
                    Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${entry.value}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _getEmergencyIcon(String type) {
    IconData iconData;
    Color color = Theme.of(context).colorScheme.primary;

    switch (type.toLowerCase()) {
      case 'medical':
        iconData = Icons.medical_services;
        color = Colors.red;
        break;
      case 'fire':
        iconData = Icons.local_fire_department;
        color = Colors.orange;
        break;
      case 'security':
        iconData = Icons.security;
        color = Colors.blue;
        break;
      default:
        iconData = Icons.emergency;
    }

    return Icon(iconData, color: color, size: 16);
  }
}
