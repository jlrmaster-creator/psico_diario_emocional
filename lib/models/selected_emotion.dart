/// Emoción elegida dentro de un registro emocional.
///
/// Guarda una copia del nombre y del grupo en el momento del registro para que
/// el diario siga siendo comprensible aunque el catálogo cambie en el futuro.
class SelectedEmotion {
  const SelectedEmotion({
    required this.emotionId,
    required this.name,
    required this.groupId,
    required this.groupName,
    this.intensity,
  });

  final String emotionId;
  final String name;
  final String groupId;
  final String groupName;

  /// Intensidad percibida de 0 a 10. `null` si el paciente no la indicó.
  final int? intensity;

  bool get hasIntensity => intensity != null;

  SelectedEmotion copyWith({int? intensity, bool clearIntensity = false}) {
    return SelectedEmotion(
      emotionId: emotionId,
      name: name,
      groupId: groupId,
      groupName: groupName,
      intensity: clearIntensity ? null : (intensity ?? this.intensity),
    );
  }

  factory SelectedEmotion.fromJson(Map<String, dynamic> json) {
    final rawIntensity = json['intensity'];
    return SelectedEmotion(
      emotionId: json['emotionId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      groupId: json['groupId'] as String? ?? '',
      groupName: json['groupName'] as String? ?? '',
      intensity: rawIntensity is int
          ? rawIntensity.clamp(0, 10)
          : int.tryParse('$rawIntensity')?.clamp(0, 10),
    );
  }

  Map<String, dynamic> toJson() => {
    'emotionId': emotionId,
    'name': name,
    'groupId': groupId,
    'groupName': groupName,
    if (intensity != null) 'intensity': intensity,
  };
}
