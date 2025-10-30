import 'package:flutter/material.dart';
import '../VM/Orchestrator.dart';

class ProfilePage extends StatefulWidget {
  final Orchestrator orchestrator;

  const ProfilePage({super.key, required this.orchestrator});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with WidgetsBindingObserver {
  // MODES
  bool _userLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  // Personal Information (default to empty to avoid late initialization errors)
  String _fullName = '';
  String _email = '';
  String _studentId = '';
  String _phone = '';

  // Emergency Contact
  String _emergencyName1 = '';
  String _emergencyPhone1 = '';
  String _emergencyName2 = '';
  String _emergencyPhone2 = '';

  // Medical Information
  String _bloodType = '';
  String _doctorName = '';
  String _doctorPhone = '';
  String _insuranceProvider = '';

  // Allergies
  String _foodAllergies = '';
  String _environmentalAllergies = '';
  String _drugAllergies = '';
  String _severityNotes = '';

  // Current Medications
  String _dailyMedications = '';
  String _emergencyMedications = '';
  String _vitaminsSupplements = '';
  String _specialInstructions = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.orchestrator.addListener(_orchestratorListener);
    _loadUserData();
  }

  void _orchestratorListener() {
    if (!mounted) return;
    _loadUserData();
    setState(() {});
  }

  void _loadUserData() {
    final user = widget.orchestrator.userVM.currentUser;

    if (user != null) {
      _userLoading = false;
      _fullName = user.fullName;
      _email = user.email;
      _studentId = user.studentId;
      _phone = user.phone;

      _emergencyName1 = user.emergencyName1;
      _emergencyPhone1 = user.emergencyPhone1;
      _emergencyName2 = user.emergencyName2 ?? '';
      _emergencyPhone2 = user.emergencyPhone2 ?? '';

      _bloodType = user.bloodType;
      _doctorName = user.doctorName ?? '';
      _doctorPhone = user.doctorPhone ?? '';
      _insuranceProvider = user.insuranceProvider;

      _foodAllergies = user.foodAllergies ?? '';
      _environmentalAllergies = user.environmentalAllergies ?? '';
      _drugAllergies = user.drugAllergies ?? '';
      _severityNotes = user.severityNotes ?? '';

      _dailyMedications = user.dailyMedications ?? '';
      _emergencyMedications = user.emergencyMedications ?? '';
      _vitaminsSupplements = user.vitaminsSupplements ?? '';
      _specialInstructions = user.specialInstructions ?? '';
    } else {
      final err = widget.orchestrator.userVM.errorMessage;
      if (err != null && err.isNotEmpty) _userLoading = false;

      // keep defaults while loading or on error
    }
  }

  @override
  void dispose() {
    widget.orchestrator.removeListener(_orchestratorListener);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() => _isSaving = true);
    try {
      final success = await widget.orchestrator.userVM.updateUserData(
        emergencyName1: _emergencyName1,
        emergencyPhone1: _emergencyPhone1,
        emergencyName2: _emergencyName2,
        emergencyPhone2: _emergencyPhone2,
        bloodType: _bloodType,
        doctorName: _doctorName,
        doctorPhone: _doctorPhone,
        insuranceProvider: _insuranceProvider,
        foodAllergies: _foodAllergies,
        environmentalAllergies: _environmentalAllergies,
        drugAllergies: _drugAllergies,
        severityNotes: _severityNotes,
        dailyMedications: _dailyMedications,
        emergencyMedications: _emergencyMedications,
        vitaminsSupplements: _vitaminsSupplements,
        specialInstructions: _specialInstructions,
      );

      if (!mounted) return;

      if (success) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Perfil actualizado (offline-first)'),
            backgroundColor: Theme.of(context).snackBarTheme.backgroundColor ??
                Theme.of(context).colorScheme.inverseSurface,
          ),
        );
      } else {
        final err = widget.orchestrator.userVM.errorMessage;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err ?? 'No se pudo actualizar el perfil. Intenta de nuevo.'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _cancelEditing() {
    setState(() => _isEditing = false);
    _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final user = widget.orchestrator.userVM.currentUser;
    final userError = widget.orchestrator.userVM.errorMessage;

    if (user == null && _userLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (user == null && userError != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'No se encontraron datos de perfil para este usuario.\n\n${userError}',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        actions: [
          if (_isEditing) ...[
            TextButton(
              onPressed: _isSaving ? null : _cancelEditing,
              child: Text('Cancel', style: tt.labelLarge?.copyWith(color: cs.onPrimary)),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: FilledButton.styleFrom(
                backgroundColor: cs.onPrimary,
                foregroundColor: cs.primary,
              ),
              child: _isSaving
                  ? const SizedBox(
                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save'),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ProfileHeader(
            name: _fullName,
            subtitle: 'Student Brigade Member',
            isEditing: _isEditing,
            onEditPressed: () => setState(() => _isEditing = !_isEditing),
          ),
          const SizedBox(height: 24),

          // Personal Information (solo lectura)
          _ReadOnlySection(
            title: 'Personal Information',
            icon: Icons.person,
            fields: [
              _ReadOnlyField(label: 'Full Name', value: _fullName),
              _ReadOnlyField(label: 'Student ID', value: _studentId),
              _ReadOnlyField(label: 'Email', value: _email),
              _ReadOnlyField(label: 'Phone', value: _phone),
            ],
          ),

          const SizedBox(height: 16),

          // Emergency Contact (editable)
          _EditableSection(
            title: 'Emergency Contact',
            icon: Icons.contact_phone,
            isEditing: _isEditing,
            fields: [
              _EditableField(
                label: 'Contact Name 1',
                value: _emergencyName1,
                isEditing: _isEditing,
                onChanged: (v) => _emergencyName1 = v,
              ),
              _EditableField(
                label: 'Contact Phone 1',
                value: _emergencyPhone1,
                isEditing: _isEditing,
                onChanged: (v) => _emergencyPhone1 = v,
              ),
              _EditableField(
                label: 'Contact Name 2',
                value: _emergencyName2,
                isEditing: _isEditing,
                onChanged: (v) => _emergencyName2 = v,
              ),
              _EditableField(
                label: 'Contact Phone 2',
                value: _emergencyPhone2,
                isEditing: _isEditing,
                onChanged: (v) => _emergencyPhone2 = v,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Medical Information (editable)
          _EditableSection(
            title: 'Medical Information',
            icon: Icons.medical_services,
            isEditing: _isEditing,
            fields: [
              _EditableField(
                label: 'Blood Type',
                value: _bloodType,
                isEditing: _isEditing,
                onChanged: (v) => _bloodType = v,
              ),
              _EditableField(
                label: 'Doctor Name',
                value: _doctorName,
                isEditing: _isEditing,
                onChanged: (v) => _doctorName = v,
              ),
              _EditableField(
                label: 'Doctor Phone',
                value: _doctorPhone,
                isEditing: _isEditing,
                onChanged: (v) => _doctorPhone = v,
              ),
              _EditableField(
                label: 'Insurance Provider',
                value: _insuranceProvider,
                isEditing: _isEditing,
                onChanged: (v) => _insuranceProvider = v,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Allergies (editable)
          _EditableSection(
            title: 'Allergies',
            icon: Icons.warning,
            isEditing: _isEditing,
            fields: [
              _EditableField(
                label: 'Food Allergies',
                value: _foodAllergies,
                isEditing: _isEditing,
                onChanged: (v) => _foodAllergies = v,
                maxLines: 2,
              ),
              _EditableField(
                label: 'Environmental Allergies',
                value: _environmentalAllergies,
                isEditing: _isEditing,
                onChanged: (v) => _environmentalAllergies = v,
                maxLines: 2,
              ),
              _EditableField(
                label: 'Drug Allergies',
                value: _drugAllergies,
                isEditing: _isEditing,
                onChanged: (v) => _drugAllergies = v,
                maxLines: 2,
              ),
              _EditableField(
                label: 'Severity/Notes',
                value: _severityNotes,
                isEditing: _isEditing,
                onChanged: (v) => _severityNotes = v,
                maxLines: 3,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Current Medications (editable)
          _EditableSection(
            title: 'Current Medications',
            icon: Icons.local_pharmacy,
            isEditing: _isEditing,
            fields: [
              _EditableField(
                label: 'Daily Medications',
                value: _dailyMedications,
                isEditing: _isEditing,
                onChanged: (v) => _dailyMedications = v,
                maxLines: 2,
              ),
              _EditableField(
                label: 'Emergency Medications',
                value: _emergencyMedications,
                isEditing: _isEditing,
                onChanged: (v) => _emergencyMedications = v,
                maxLines: 2,
              ),
              _EditableField(
                label: 'Vitamins/Supplements',
                value: _vitaminsSupplements,
                isEditing: _isEditing,
                onChanged: (v) => _vitaminsSupplements = v,
                maxLines: 2,
              ),
              _EditableField(
                label: 'Special Instructions',
                value: _specialInstructions,
                isEditing: _isEditing,
                onChanged: (v) => _specialInstructions = v,
                maxLines: 3,
              ),
            ],
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool isEditing;
  final VoidCallback onEditPressed;

  const _ProfileHeader({
    required this.name,
    required this.subtitle,
    required this.isEditing,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(
              theme.brightness == Brightness.light ? .05 : .25,
            ),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: cs.primary,
            child: Icon(Icons.person, size: 32, color: cs.onPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)),
                const SizedBox(height: 4),
                Text(subtitle, style: tt.bodySmall?.copyWith(color: cs.onSurface.withOpacity(.7))),
              ],
            ),
          ),
          IconButton(
            icon: Icon(isEditing ? Icons.close : Icons.edit, color: cs.onSurface),
            onPressed: onEditPressed,
            tooltip: isEditing ? 'Close editing' : 'Edit',
          ),
        ],
      ),
    );
  }
}

class _EditableSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_EditableField> fields;
  final bool isEditing;

  const _EditableSection({
    required this.title,
    required this.icon,
    required this.fields,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Card(
      color: theme.cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)),
              ],
            ),
            const SizedBox(height: 16),
            ...fields.map((field) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: field,
            )),
          ],
        ),
      ),
    );
  }
}

class _EditableField extends StatelessWidget {
  final String label;
  final String value;
  final Function(String) onChanged;
  final int maxLines;
  final bool isEditing;

  const _EditableField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
        const SizedBox(height: 4),
        TextFormField(
          initialValue: value,
          onChanged: onChanged,
          maxLines: maxLines,
          enabled: isEditing,
          decoration: InputDecoration(
            isCollapsed: false,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
          style: tt.bodyMedium?.copyWith(color: cs.onSurface),
        ),
      ],
    );
  }
}

class _ReadOnlySection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_ReadOnlyField> fields;

  const _ReadOnlySection({
    required this.title,
    required this.icon,
    required this.fields,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    return Card(
      color: theme.cardColor,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(title, style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)),
                const Spacer(),
                Icon(Icons.lock, color: cs.onSurface.withOpacity(.4), size: 16),
              ],
            ),
            const SizedBox(height: 16),
            ...fields.map((field) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: field,
            )),
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  final String label;
  final String value;

  const _ReadOnlyField({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final tt = theme.textTheme;

    final isEmpty = value.isEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: theme.inputDecorationTheme.fillColor ?? cs.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isEmpty ? 'Not specified' : value,
                    style: tt.bodyMedium?.copyWith(
                      color: isEmpty ? cs.onSurface.withOpacity(.6) : cs.onSurface,
                      fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),
                Icon(Icons.lock, color: cs.onSurface.withOpacity(.4), size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}