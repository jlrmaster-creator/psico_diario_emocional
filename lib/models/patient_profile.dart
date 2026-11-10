/// Perfil del paciente.
///
/// Se usa un seudónimo (no el nombre real) para minimizar los datos personales
/// almacenados, tal y como se describe en la documentación de privacidad.
class PatientProfile {
  const PatientProfile({
    required this.patientId,
    required this.pseudonym,
    required this.departmentName,
    required this.createdAt,
    required this.updatedAt,
    this.privacyAcceptedAt,
  });

  /// Identificador técnico: UID de Firebase Auth o identificador local.
  final String patientId;

  /// Nombre o seudónimo visible en la app y en los informes PDF.
  final String pseudonym;

  final String departmentName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? privacyAcceptedAt;

  factory PatientProfile.create({
    required String patientId,
    required String pseudonym,
    required String departmentName,
    DateTime? now,
  }) {
    final timestamp = now ?? DateTime.now();
    return PatientProfile(
      patientId: patientId,
      pseudonym: pseudonym,
      departmentName: departmentName,
      createdAt: timestamp,
      updatedAt: timestamp,
      privacyAcceptedAt: timestamp,
    );
  }

  PatientProfile copyWith({
    String? pseudonym,
    String? departmentName,
    DateTime? updatedAt,
    DateTime? privacyAcceptedAt,
  }) {
    return PatientProfile(
      patientId: patientId,
      pseudonym: pseudonym ?? this.pseudonym,
      departmentName: departmentName ?? this.departmentName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      privacyAcceptedAt: privacyAcceptedAt ?? this.privacyAcceptedAt,
    );
  }

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      patientId: json['patientId'] as String? ?? '',
      pseudonym: json['pseudonym'] as String? ?? '',
      departmentName:
          json['departmentName'] as String? ?? 'Departamento de Psicología',
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
      privacyAcceptedAt: _parseDate(json['privacyAcceptedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'patientId': patientId,
    'pseudonym': pseudonym,
    'departmentName': departmentName,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    if (privacyAcceptedAt != null)
      'privacyAcceptedAt': privacyAcceptedAt!.toIso8601String(),
  };

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    try {
      final dynamic timestamp = value;
      final dynamic date = timestamp.toDate();
      if (date is DateTime) return date;
    } catch (_) {
      return null;
    }
    return null;
  }
}
