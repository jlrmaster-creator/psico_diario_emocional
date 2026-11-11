import 'selected_emotion.dart';

/// Registro del diario emocional.
///
/// Los campos `situation`, `thought` y `behavior` son obligatorios en la
/// interfaz; el modelo los acepta vacíos para poder migrar datos antiguos.
/// `title` se añadió después: los registros anteriores lo leen vacío y generan
/// un título automático a partir de su contenido.
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
    this.title = '',
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

  /// Título breve que resume el registro.
  final String title;

  final String situation;
  final List<SelectedEmotion> emotions;
  final String thought;
  final String behavior;

  /// Título visible en listados y detalles.
  ///
  /// Si el registro es anterior a la incorporación del título, se genera uno
  /// breve a partir de la situación, el pensamiento o las emociones para que
  /// las tarjetas antiguas no queden vacías.
  String get displayTitle {
    final own = title.trim();
    if (own.isNotEmpty) return own;

    for (final source in [situation, thought, behavior, freeText ?? '']) {
      final text = source.trim();
      if (text.isEmpty) continue;
      final firstSentence = text
          .split(RegExp(r'[.\n!?]'))
          .map((part) => part.trim())
          .firstWhere((part) => part.isNotEmpty, orElse: () => text);
      return _shortTitle(firstSentence);
    }

    if (emotions.isNotEmpty) {
      final names = emotions.map((emotion) => emotion.name).take(2).join(' y ');
      return names;
    }

    return 'Registro sin título';
  }

  static String _shortTitle(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 60) return normalized;
    final cut = normalized.substring(0, 60);
    final lastSpace = cut.lastIndexOf(' ');
    final base = lastSpace > 20 ? cut.substring(0, lastSpace) : cut;
    return '${base.trimRight()}…';
  }

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
    String? title,
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
      title: title ?? this.title,
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
      title: json['title'] as String? ?? '',
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
    'title': title,
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
