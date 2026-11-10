import 'selected_emotion.dart';

/// Registro del diario emocional.
///
/// Los campos `situation`, `thought` y `behavior` son obligatorios en la
/// interfaz; el modelo los acepta vacíos para poder migrar datos antiguos.
class EmotionalRecord {
  const EmotionalRecord({
    required this.id,
    required this.patientId,
    required this.eventDate,
    required this.createdAt,
    required this.updatedAt,
    required this.situation,
    required this.emotions,
    required this.thought,
    required this.behavior,
    this.freeText,
    this.eventTime,
    this.schemaVersion = 1,
  });

  final String id;
  final String patientId;

  /// Día del acontecimiento (sin hora).
  final DateTime eventDate;

  /// Momento en el que se creó el registro.
  final DateTime createdAt;

  /// Momento de la última modificación.
  final DateTime updatedAt;

  final String situation;
  final List<SelectedEmotion> emotions;
  final String thought;
  final String behavior;

  /// Texto libre: "¿cómo lo describirías con tus propias palabras?".
  final String? freeText;

  /// Hora del acontecimiento en formato `HH:mm`, si el paciente la indica.
  final String? eventTime;

  final int schemaVersion;

  List<String> get groupIds => emotions
      .map((emotion) => emotion.groupId)
      .toSet()
      .toList(growable: false);

  List<String> get groupNames => emotions
      .map((emotion) => emotion.groupName)
      .toSet()
      .toList(growable: false);

  List<String> get emotionIds => emotions
      .map((emotion) => emotion.emotionId)
      .toSet()
      .toList(growable: false);

  int? get maxIntensity {
    final values = emotions
        .map((emotion) => emotion.intensity)
        .whereType<int>()
        .toList(growable: false);
    if (values.isEmpty) return null;
    return values.reduce((a, b) => a > b ? a : b);
  }

  bool get hasIntensity => maxIntensity != null;

  EmotionalRecord copyWith({
    String? id,
    String? patientId,
    DateTime? eventDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? situation,
    List<SelectedEmotion>? emotions,
    String? thought,
    String? behavior,
    String? freeText,
    String? eventTime,
    bool clearEventTime = false,
    bool clearFreeText = false,
  }) {
    return EmotionalRecord(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      eventDate: eventDate ?? this.eventDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      situation: situation ?? this.situation,
      emotions: emotions ?? this.emotions,
      thought: thought ?? this.thought,
      behavior: behavior ?? this.behavior,
      freeText: clearFreeText ? null : (freeText ?? this.freeText),
      eventTime: clearEventTime ? null : (eventTime ?? this.eventTime),
      schemaVersion: schemaVersion,
    );
  }

  factory EmotionalRecord.fromJson(Map<String, dynamic> json) {
    final rawEmotions = (json['emotions'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(SelectedEmotion.fromJson)
        .toList(growable: false);

    return EmotionalRecord(
      id: json['id'] as String? ?? '',
      patientId: json['patientId'] as String? ?? '',
      eventDate: _parseDate(json['eventDate']) ?? DateTime.now(),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']) ?? DateTime.now(),
      situation: json['situation'] as String? ?? '',
      emotions: rawEmotions,
      thought: json['thought'] as String? ?? '',
      behavior: json['behavior'] as String? ?? '',
      freeText: json['freeText'] as String?,
      eventTime: json['eventTime'] as String?,
      schemaVersion: json['schemaVersion'] as int? ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'patientId': patientId,
    'eventDate': eventDate.toIso8601String(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'situation': situation,
    'emotions': emotions.map((emotion) => emotion.toJson()).toList(),
    'thought': thought,
    'behavior': behavior,
    if (freeText != null) 'freeText': freeText,
    if (eventTime != null) 'eventTime': eventTime,
    'schemaVersion': schemaVersion,
  };

  static DateTime? _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    // Compatibilidad con Timestamp de Firestore sin acoplar el modelo a
    // cloud_firestore (se normaliza en el repositorio).
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
