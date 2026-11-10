/// Modelo de una emoción individual del catálogo.
///
/// Es intencionadamente independiente de la interfaz para que el catálogo
/// pueda ampliarse desde datos (JSON, Firestore o emociones personalizadas).
class Emotion {
  const Emotion({
    required this.id,
    required this.name,
    required this.groupId,
    this.description,
    this.isCustom = false,
  });

  final String id;
  final String name;
  final String groupId;
  final String? description;

  /// `true` cuando la emoción ha sido creada por el propio paciente.
  final bool isCustom;

  factory Emotion.fromJson(
    Map<String, dynamic> json, {
    required String groupId,
    bool isCustom = false,
  }) {
    return Emotion(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      groupId: groupId,
      description: json['description'] as String?,
      isCustom: isCustom || (json['isCustom'] as bool? ?? false),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'groupId': groupId,
    if (description != null) 'description': description,
    'isCustom': isCustom,
  };

  @override
  bool operator ==(Object other) => other is Emotion && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
