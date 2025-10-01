class User {
  // Personal Information
  String _fullName;
  String _studentId;
  String _email;
  String _phone;

  // Emergency Contact
  String _emergencyName1;
  String _emergencyPhone1;
  String? _emergencyName2;
  String? _emergencyPhone2;

  // Medical Information
  String _bloodType;
  String? _doctorName;
  String? _doctorPhone;
  String _insuranceProvider;

  // Allergies
  String? _foodAllergies;
  String? _environmentalAllergies;
  String? _drugAllergies;
  String? _severityNotes;

  // Current Medications
  String? _dailyMedications;
  String? _emergencyMedications;
  String? _vitaminsSupplements;
  String? _specialInstructions;

  User({
    required String fullName,
    required String studentId,
    required String email,
    required String phone,
    required String emergencyName1,
    required String emergencyPhone1,
    String? emergencyName2,
    String? emergencyPhone2,
    required String bloodType,
    String? doctorName,
    String? doctorPhone,
    required String insuranceProvider,
    String? foodAllergies,
    String? environmentalAllergies,
    String? drugAllergies,
    String? severityNotes,
    String? dailyMedications,
    String? emergencyMedications,
    String? vitaminsSupplements,
    String? specialInstructions,
  }) : _fullName = fullName,
       _studentId = studentId,
       _email = email,
       _phone = phone,
       _emergencyName1 = emergencyName1,
       _emergencyPhone1 = emergencyPhone1,
       _emergencyName2 = emergencyName2,
       _emergencyPhone2 = emergencyPhone2,
       _bloodType = bloodType,
       _doctorName = doctorName,
       _doctorPhone = doctorPhone,
       _insuranceProvider = insuranceProvider,
       _foodAllergies = foodAllergies,
       _environmentalAllergies = environmentalAllergies,
       _drugAllergies = drugAllergies,
       _severityNotes = severityNotes,
       _dailyMedications = dailyMedications,
       _emergencyMedications = emergencyMedications,
       _vitaminsSupplements = vitaminsSupplements,
       _specialInstructions = specialInstructions;

  // Getters
  String get fullName => _fullName;
  String get studentId => _studentId;
  String get email => _email;
  String get phone => _phone;
  String get emergencyName1 => _emergencyName1;
  String get emergencyPhone1 => _emergencyPhone1;
  String? get emergencyName2 => _emergencyName2;
  String? get emergencyPhone2 => _emergencyPhone2;
  String get bloodType => _bloodType;
  String? get doctorName => _doctorName;
  String? get doctorPhone => _doctorPhone;
  String get insuranceProvider => _insuranceProvider;
  String? get foodAllergies => _foodAllergies;
  String? get environmentalAllergies => _environmentalAllergies;
  String? get drugAllergies => _drugAllergies;
  String? get severityNotes => _severityNotes;
  String? get dailyMedications => _dailyMedications;
  String? get emergencyMedications => _emergencyMedications;
  String? get vitaminsSupplements => _vitaminsSupplements;
  String? get specialInstructions => _specialInstructions;

  // Setters
  set fullName(String value) => _fullName = value;
  set studentId(String value) => _studentId = value;
  set email(String value) => _email = value;
  set phone(String value) => _phone = value;
  set emergencyName1(String value) => _emergencyName1 = value;
  set emergencyPhone1(String value) => _emergencyPhone1 = value;
  set emergencyName2(String? value) => _emergencyName2 = value;
  set emergencyPhone2(String? value) => _emergencyPhone2 = value;
  set bloodType(String value) => _bloodType = value;
  set doctorName(String? value) => _doctorName = value;
  set doctorPhone(String? value) => _doctorPhone = value;
  set insuranceProvider(String value) => _insuranceProvider = value;
  set foodAllergies(String? value) => _foodAllergies = value;
  set environmentalAllergies(String? value) => _environmentalAllergies = value;
  set drugAllergies(String? value) => _drugAllergies = value;
  set severityNotes(String? value) => _severityNotes = value;
  set dailyMedications(String? value) => _dailyMedications = value;
  set emergencyMedications(String? value) => _emergencyMedications = value;
  set vitaminsSupplements(String? value) => _vitaminsSupplements = value;
  set specialInstructions(String? value) => _specialInstructions = value;
}

// Simulación de BD - obtener datos
class UserData {
  // Simular obtener datos de BD
  static Future<User> fetchUserFromDatabase(String userId) async {
    // Simular petición a BD
    await Future.delayed(const Duration(milliseconds: 100));
    
    return User(
      fullName: 'John Smith',
      studentId: 'SB2024001',
      email: 'john.smith@uniandes.edu.co',
      phone: '+57 300 123 4567',
      emergencyName1: 'Maria Smith',
      emergencyPhone1: '+57 300 987 6543',
      emergencyName2: 'Carlos Smith',
      emergencyPhone2: '+57 300 567 8901',
      bloodType: 'O+',
      doctorName: 'Dr. Ana Perez',
      doctorPhone: '+57 300 111 2222',
      insuranceProvider: 'Seguros ABC',
      foodAllergies: 'Peanuts, Shellfish',
      environmentalAllergies: 'Dust',
      drugAllergies: 'Ibuprofen',
      severityNotes: 'Mild',
      dailyMedications: 'None',
      emergencyMedications: 'Epinephrine Auto-Injector',
      vitaminsSupplements: 'Vitamin C, Omega-3',
      specialInstructions: 'Avoid strenuous exercise',
    );
  }
  
  // Simular guardar datos en BD
  static Future<bool> saveUserToDatabase(User user) async {
    // Simular petición a BD
    await Future.delayed(const Duration(milliseconds: 200));
    return true; // Simulamos éxito
  }
}