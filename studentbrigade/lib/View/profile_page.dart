import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Personal Information
  String _fullName = 'John Smith';
  String _studentId = 'SB2024001';
  String _email = 'john.smith@university.edu';
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
  String _FoodAllergies = '';
  String _EnvironmentalAllergies = '';
  String _DrugAllergies = '';
  String _SeverityNotes = '';

  // Current Medications
  String _DailyMedications = '';
  String EmergencyMedications = '';
  String VitaminsSupplements = '';
  String SpecialInstructions = '';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: cs.primary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Header
          _ProfileHeader(
            name: _fullName,
            subtitle: 'Student Brigade Member',
          ),
          
          const SizedBox(height: 24),

          // Personal Information
          _EditableSection(
            title: 'Personal Information',
            icon: Icons.person,
            fields: [
              _EditableField(
                label: 'Full Name',
                value: _fullName,
                onChanged: (value) => setState(() => _fullName = value),
              ),
              _EditableField(
                label: 'Student ID',
                value: _studentId,
                onChanged: (value) => setState(() => _studentId = value),
              ),
              _EditableField(
                label: 'Email',
                value: _email,
                onChanged: (value) => setState(() => _email = value),
              ),
              _EditableField(
                label: 'Phone',
                value: _phone,
                onChanged: (value) => setState(() => _phone = value),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Emergency Contact
          _EditableSection(
            title: 'Emergency Contact',
            icon: Icons.contact_phone,
            fields: [
              _EditableField(
                label: 'Contact Name 1',
                value: _emergencyName1,
                onChanged: (value) => setState(() => _emergencyName1 = value),
              ),
              _EditableField(
                label: 'Contact Phone 1',
                value: _emergencyPhone1,
                onChanged: (value) => setState(() => _emergencyPhone1 = value),
              ),
              _EditableField(
                label: 'Contact Name 2',
                value: _emergencyName2,
                onChanged: (value) => setState(() => _emergencyName2 = value),
              ),
              _EditableField(
                label: 'Contact Phone 2',
                value: _emergencyPhone2,
                onChanged: (value) => setState(() => _emergencyPhone2 = value),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Medical Information
          _EditableSection(
            title: 'Medical Information',
            icon: Icons.medical_services,
            fields: [
              _EditableField(
                label: 'Blood Type',
                value: _bloodType,
                onChanged: (value) => setState(() => _bloodType = value),
              ),
              _EditableField(
                label: 'Doctor Name',
                value: _doctorName,
                onChanged: (value) => setState(() => _doctorName = value),
              ),
              _EditableField(
                label: 'Doctor Phone',
                value: _doctorPhone,
                onChanged: (value) => setState(() => _doctorPhone = value),
              ),
              _EditableField(
                label: 'Insurance Provider',
                value: _insuranceProvider,
                onChanged: (value) => setState(() => _insuranceProvider = value),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Allergies
          _EditableSection(
            title: 'Allergies',
            icon: Icons.warning,
            fields: [
              _EditableField(
                label: 'Food Allergies',
                value: _FoodAllergies,
                onChanged: (value) => setState(() => _FoodAllergies = value),
                maxLines: 2,
              ),
              _EditableField(
                label: 'Environmental Allergies',
                value: _EnvironmentalAllergies,
                onChanged: (value) => setState(() => _EnvironmentalAllergies = value),
                maxLines: 2,
              ),
              _EditableField(
                label: 'Drug Allergies',
                value: _DrugAllergies,
                onChanged: (value) => setState(() => _DrugAllergies = value),
                maxLines: 2,
              ),
              _EditableField(
                label: 'Severity/Notes',
                value: _SeverityNotes,
                onChanged: (value) => setState(() => _SeverityNotes = value),
                maxLines: 3,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Current Medications
          _EditableSection(
            title: 'Current Medications',
            icon: Icons.local_pharmacy,
            fields: [
              _EditableField(
                label: 'Daily Medications',
                value: _DailyMedications,
                onChanged: (value) => setState(() => _DailyMedications = value),
                maxLines: 2,
              ),
              _EditableField(
                label: 'Emergency Medications',
                value: EmergencyMedications,
                onChanged: (value) => setState(() => EmergencyMedications = value),
                maxLines: 2,
              ),
              _EditableField(
                label: 'Vitamins/Supplements',
                value: VitaminsSupplements,
                onChanged: (value) => setState(() => VitaminsSupplements = value),
                maxLines: 2,
              ),
              _EditableField(
                label: 'Special Instructions',
                value: SpecialInstructions,
                onChanged: (value) => setState(() => SpecialInstructions = value),
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

  const _ProfileHeader({
    required this.name,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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
            icon: const Icon(Icons.edit),
            onPressed: () {
              // Acción de editar perfil general
            },
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

  const _EditableSection({
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

  const _EditableField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.maxLines = 1,
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