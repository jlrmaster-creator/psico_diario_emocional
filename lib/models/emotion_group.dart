import 'emotion.dart';

/// Grupo emocional principal del catálogo (asco, ira, tristeza...).
class EmotionGroup {
  const EmotionGroup({
    required this.id,
    required this.name,
    required this.colorHex,
    required this.icon,
    required this.description,
    required this.emotions,
  });

  final String id;
  final String name;
  final String colorHex;
  final String icon;
  final String description;
  final List<Emotion> emotions;

  factory EmotionGroup.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final emotions = (json['emotions'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map((item) => Emotion.fromJson(item, groupId: id))
        .toList(growable: false);

    return EmotionGroup(
      id: id,
      name: json['name'] as String? ?? '',
      colorHex: json['color'] as String? ?? '#7A8B99',
      icon: json['icon'] as String? ?? 'mood',
      description: json['description'] as String? ?? '',
      emotions: emotions,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'color': colorHex,
    'icon': icon,
    'description': description,
    'emotions': emotions.map((emotion) => emotion.toJson()).toList(),
  };

  EmotionGroup copyWith({List<Emotion>? emotions}) => EmotionGroup(
    id: id,
    name: name,
    colorHex: colorHex,
    icon: icon,
    description: description,
    emotions: emotions ?? this.emotions,
  );
}

/// Catálogo completo de emociones.
///
/// Se carga desde `assets/data/emotions_catalog.json` y se enriquece con las
/// emociones personalizadas del paciente.
class EmotionCatalog {
  const EmotionCatalog({
    required this.version,
    required this.notice,
    required this.groups,
  });

  final int version;
  final String notice;
  final List<EmotionGroup> groups;

  factory EmotionCatalog.fromJson(Map<String, dynamic> json) {
    final groups = (json['groups'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(EmotionGroup.fromJson)
        .toList(growable: false);

    return EmotionCatalog(
      version: json['version'] as int? ?? 1,
      notice:
          json['notice'] as String? ??
          'Vocabulario orientativo. No es una clasificación clínica cerrada.',
      groups: groups,
    );
  }

  factory EmotionCatalog.empty() =>
      const EmotionCatalog(version: 1, notice: '', groups: <EmotionGroup>[]);

  Map<String, dynamic> toJson() => {
    'version': version,
    'notice': notice,
    'groups': groups.map((group) => group.toJson()).toList(),
  };

  List<Emotion> get allEmotions =>
      groups.expand((group) => group.emotions).toList(growable: false);

  int get totalEmotions =>
      groups.fold(0, (sum, group) => sum + group.emotions.length);

  EmotionGroup? groupById(String? id) {
    if (id == null) return null;
    for (final group in groups) {
      if (group.id == id) return group;
    }
    return null;
  }

  Emotion? emotionById(String? id) {
    if (id == null) return null;
    for (final emotion in allEmotions) {
      if (emotion.id == id) return emotion;
    }
    return null;
  }

  String groupNameFor(String groupId) =>
      groupById(groupId)?.name ?? 'Sin grupo';

  /// Búsqueda sin distinción de mayúsculas, tildes ni espacios sobrantes.
  List<Emotion> search(String query) {
    final normalized = _normalize(query);
    if (normalized.isEmpty) return allEmotions;
    return allEmotions
        .where((emotion) => _normalize(emotion.name).contains(normalized))
        .toList(growable: false);
  }

  /// Devuelve una copia del catálogo con las emociones personalizadas añadidas
  /// a su grupo correspondiente.
  EmotionCatalog withCustomEmotions(List<Emotion> customEmotions) {
    if (customEmotions.isEmpty) return this;

    final byGroup = <String, List<Emotion>>{};
    for (final emotion in customEmotions) {
      byGroup.putIfAbsent(emotion.groupId, () => []).add(emotion);
    }

    return EmotionCatalog(
      version: version,
      notice: notice,
      groups: groups
          .map(
            (group) => byGroup.containsKey(group.id)
                ? group.copyWith(
                    emotions: [...group.emotions, ...byGroup[group.id]!],
                  )
                : group,
          )
          .toList(growable: false),
    );
  }

  static String _normalize(String value) {
    const replacements = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    var result = value.trim().toLowerCase();
    replacements.forEach((key, replacement) {
      result = result.replaceAll(key, replacement);
    });
    return result;
  }
}
