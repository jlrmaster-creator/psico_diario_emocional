import 'dart:convert';
import 'dart:io';

import 'package:diario_emocional/models/emotion.dart';
import 'package:diario_emocional/models/emotion_group.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late EmotionCatalog catalog;

  setUpAll(() {
    final raw = File('assets/data/emotions_catalog.json').readAsStringSync();
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    catalog = EmotionCatalog.fromJson(decoded);
  });

  test('el catálogo contiene los seis grupos esperados', () {
    expect(
      catalog.groups.map((group) => group.id),
      containsAll(<String>[
        'asco',
        'ira',
        'tristeza',
        'miedo',
        'sorpresa',
        'felicidad',
      ]),
    );
    expect(catalog.groups, hasLength(6));
  });

  test('cada grupo y emoción tiene identificadores y nombres únicos', () {
    final groupIds = catalog.groups.map((group) => group.id).toList();
    final emotionIds = catalog.allEmotions
        .map((emotion) => emotion.id)
        .toList();

    expect(groupIds.toSet(), hasLength(groupIds.length));
    expect(emotionIds.toSet(), hasLength(emotionIds.length));
    for (final group in catalog.groups) {
      expect(group.name, isNotEmpty);
      expect(group.description, isNotEmpty);
      expect(group.emotions, isNotEmpty);
      for (final emotion in group.emotions) {
        expect(emotion.name, isNotEmpty);
        expect(emotion.groupId, group.id);
      }
    }
  });

  test('la búsqueda ignora mayúsculas y tildes', () {
    final results = catalog.search('pena');
    expect(results, isNotEmpty);
    expect(results.map((emotion) => emotion.groupId), contains('tristeza'));
    expect(
      catalog.search('ALEGRIA').map((emotion) => emotion.groupId),
      contains('felicidad'),
    );
  });

  test('se pueden añadir emociones personalizadas a su grupo', () {
    const custom = Emotion(
      id: 'custom_1',
      name: 'Nostalgia',
      groupId: 'tristeza',
      isCustom: true,
    );

    final enriched = catalog.withCustomEmotions([custom]);
    final group = enriched.groupById('tristeza')!;

    expect(group.emotions.map((emotion) => emotion.id), contains('custom_1'));
    expect(enriched.totalEmotions, catalog.totalEmotions + 1);
  });

  test('las emociones con un grupo desconocido se ignoran', () {
    const orphan = Emotion(
      id: 'custom_orphan',
      name: 'Huérfana',
      groupId: 'grupo_inexistente',
      isCustom: true,
    );

    final enriched = catalog.withCustomEmotions([orphan]);
    expect(enriched.totalEmotions, catalog.totalEmotions);
  });

  test('fromJson tolera un catálogo vacío', () {
    final empty = EmotionCatalog.fromJson(const <String, dynamic>{});
    expect(empty.groups, isEmpty);
    expect(empty.totalEmotions, 0);
  });
}
