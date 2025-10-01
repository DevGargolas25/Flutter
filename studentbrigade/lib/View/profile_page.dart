import 'package:flutter/material.dart';
import '../VM/Orchestrator.dart';

class ProfilePage extends StatefulWidget {
  final Orchestrator orchestrator;

  const ProfilePage({super.key, required this.orchestrator});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // MODES
  bool _isEditing = false;
  bool _isSaving = false;
  
  // Personal Information
  late String _fullName;
  late String _email;
  late String _studentId;
  late String _phone;

  // Emergency Contact
  late String _emergencyName1;
  late String _emergencyPhone1;
  late String _emergencyName2;
  late String _emergencyPhone2;

  // Medical Information
  late String _bloodType;
  late String _doctorName;
  late String _doctorPhone;
  late String _insuranceProvider;

  // Allergies
  late String _foodAllergies;
  late String _environmentalAllergies;
  late String _drugAllergies;
  late String _severityNotes;

  // Current Medications
  late String _dailyMedications;
  late String _emergencyMedications;
  late String _vitaminsSupplements;
  late String _specialInstructions;

  @override
  void initState() {
    super.initState();
    _loadUserData(); // Upload data
  }

  void _loadUserData() {
    final user = widget.orchestrator.getUserData();
    if (user != null) {
      // Personal Information
      _fullName = user.fullName;
      _email = user.email;
      _studentId = user.studentId;
      _phone = user.phone;

      // Emergency Contact
      _emergencyName1 = user.emergencyName1;
      _emergencyPhone1 = user.emergencyPhone1;
      _emergencyName2 = user.emergencyName2 ?? '';
      _emergencyPhone2 = user.emergencyPhone2 ?? '';

      // Medical Information
      _bloodType = user.bloodType;
      _doctorName = user.doctorName ?? '';
      _doctorPhone = user.doctorPhone ?? '';
      _insuranceProvider = user.insuranceProvider;

      // Allergies
      _foodAllergies = user.foodAllergies ?? '';
      _environmentalAllergies = user.environmentalAllergies ?? '';
      _drugAllergies = user.drugAllergies ?? '';
      _severityNotes = user.severityNotes ?? '';

      // Current Medications
      _dailyMedications = user.dailyMedications ?? '';
      _emergencyMedications = user.emergencyMedications ?? '';
      _vitaminsSupplements = user.vitaminsSupplements ?? '';
      _specialInstructions = user.specialInstructions ?? '';
    } 
  }

  // ✅ FUNCIÓN PARA GUARDAR CAMBIOS
  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      // ✅ USAR EL NUEVO MÉTODO - Solo campos editables
      bool success = await widget.orchestrator.updateUserData(
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
      
      if (success) {
        setState(() {
          _isEditing = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update profile. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  // FUNCIÓN PARA CANCELAR EDICIÓN
  void _cancelEditing() {
    setState(() {
      _isEditing = false;
    });
    _loadUserData(); // Recargar datos originales
  }


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: cs.primary,
        actions: [
          if (_isEditing) ...[
            // BOTONES PARA MODO EDICIÓN
            TextButton(
              onPressed: _isSaving ? null : _cancelEditing,
              child: const Text('Cancel', style: TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _isSaving ? null : _saveChanges,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: cs.primary,
              ),
              child: _isSaving 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Header
          _ProfileHeader(
            name: _fullName,
            subtitle: 'Student Brigade Member',
            isEditing: _isEditing,
            onEditPressed: () {
              setState(() {
                _isEditing = !_isEditing;
              });
            }
          ),
          
          const SizedBox(height: 24),

          // Personal Information
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

          // Emergency Contact
          _EditableSection(
            title: 'Emergency Contact',
            icon: Icons.contact_phone,
            isEditing: _isEditing,
            fields: [
              _EditableField(
                label: 'Contact Name 1',
                value: _emergencyName1,
                isEditing: _isEditing,
                onChanged: (value) => setState(() => _emergencyName1 = value),
              ),
              _EditableField(
                label: 'Contact Phone 1',
                value: _emergencyPhone1,
                isEditing: _isEditing,
                onChanged: (value) => setState(() => _emergencyPhone1 = value),
              ),
              _EditableField(
                label: 'Contact Name 2',
                value: _emergencyName2,
                isEditing: _isEditing,
                onChanged: (value) => setState(() => _emergencyName2 = value),
              ),
              _EditableField(
                label: 'Contact Phone 2',
                value: _emergencyPhone2,
                isEditing: _isEditing,
                onChanged: (value) => setState(() => _emergencyPhone2 = value),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Medical Information
          _EditableSection(
            title: 'Medical Information',
            icon: Icons.medical_services,
            isEditing: _isEditing,
            fields: [
              _EditableField(
                label: 'Blood Type',
                value: _bloodType,
                isEditing: _isEditing,
                onChanged: (value) => setState(() => _bloodType = value),
              ),
              _EditableField(
                label: 'Doctor Name',
                value: _doctorName,
                isEditing: _isEditing,
                onChanged: (value) => setState(() => _doctorName = value),
              ),
              _EditableField(
                label: 'Doctor Phone',
                value: _doctorPhone,
                isEditing: _isEditing,
                onChanged: (value) => setState(() => _doctorPhone = value),
              ),
              _EditableField(
                label: 'Insurance Provider',
                value: _insuranceProvider,
                isEditing: _isEditing,
                onChanged: (value) => setState(() => _insuranceProvider = value),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Allergies
          _EditableSection(
            title: 'Allergies',
            icon: Icons.warning,
            isEditing: _isEditing,
            fields: [
              _EditableField(
                label: 'Food Allergies',
                value: _foodAllergies,
                isEditing: _isEditing,
                onChanged: (value) => setState(() => _foodAllergies = value),
                maxLines: 2,
              ),
              _EditableField(
                label: 'Environmental Allergies',
                value: _environmentalAllergies,
                isEditing: _isEditing,
                onChanged: (value) => setState(() => _environmentalAllergies = value),
                maxLines: 2,
              ),
              _EditableField(
                label: 'Drug Allergies',
                value: _drugAllergies,
                isEditing: _isEditing,
                onChanged: (value) => setState(() => _drugAllergies = value),
                maxLines: 2,
              ),
              _EditableField(
                label: 'Severity/Notes',
                value: _severityNotes,
                isEditing: _isEditing,
                onChanged: (value) => setState(() => _severityNotes = value),
                maxLines: 3,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Current Medications
          _EditableSection(
            title: 'Current Medications',
            icon: Icons.local_pharmacy,
            isEditing: _isEditing,
            fields: [
              _EditableField(
                label: 'Daily Medications',
                value: _dailyMedications,
                isEditing: _isEditing,
                onChanged: (value) => setState(() => _dailyMedications = value),
                maxLines: 2,
              ),
              _EditableField(
                label: 'Emergency Medications',
                value: _emergencyMedications,
                isEditing: _isEditing,
                onChanged: (value) => setState(() => _emergencyMedications = value),
                maxLines: 2,
              ),
              _EditableField(
                label: 'Vitamins/Supplements',
                value: _vitaminsSupplements,
                isEditing: _isEditing,
                onChanged: (value) => setState(() => _vitaminsSupplements = value),
                maxLines: 2,
              ),
              _EditableField(
                label: 'Special Instructions',
                value: _specialInstructions,
                isEditing: _isEditing,
                onChanged: (value) => setState(() => _specialInstructions = value),
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
  final bool isEditing; // ✅ AGREGAR
  final VoidCallback onEditPressed; // ✅ AGREGAR

  const _ProfileHeader({
    required this.name,
    required this.subtitle,
    required this.isEditing, // ✅ AGREGAR
    required this.onEditPressed, // ✅ AGREGAR
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5F3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFF7DD3C0),
            child: Icon(
              Icons.person,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(isEditing ? Icons.close : Icons.edit), // ✅ CAMBIAR
            onPressed: onEditPressed, // ✅ CAMBIAR
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
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: TextFormField(
            initialValue: value,
            onChanged: onChanged,
            maxLines: maxLines,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
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
    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: cs.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Icon(Icons.lock, color: Colors.grey[400], size: 16),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value.isEmpty ? 'Not specified' : value,
                    style: TextStyle(
                      color: value.isEmpty ? Colors.grey[600] : Colors.black87,
                      fontStyle: value.isEmpty ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),
                Icon(Icons.lock, color: Colors.grey[400], size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}