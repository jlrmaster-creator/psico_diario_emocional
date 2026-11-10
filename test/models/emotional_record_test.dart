import 'package:diario_emocional/models/emotional_record.dart';
import 'package:diario_emocional/models/record_filter.dart';
import 'package:diario_emocional/models/selected_emotion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final createdAt = DateTime(2026, 11, 10, 9, 30);

  EmotionalRecord buildSample() {
    return EmotionalRecord(
      id: 'record-1',
      patientId: 'patient-1',
      eventDate: DateTime(2026, 11, 10),
      createdAt: createdAt,
      updatedAt: createdAt,
      situation: 'Una conversación difícil',
      emotions: const [
        SelectedEmotion(
          emotionId: 'tristeza_pena',
          name: 'Pena',
          groupId: 'tristeza',
          groupName: 'Tristeza',
          intensity: 7,
        ),
        SelectedEmotion(
          emotionId: 'ira_enfado',
          name: 'Enfado',
          groupId: 'ira',
          groupName: 'Ira',
        ),
      ],
      thought: 'No me está escuchando.',
      behavior: 'Me callé y me fui.',
      freeText: 'Como si llevara una mochila pesada.',
      eventTime: '18:05',
    );
  }

  test('serializa y recupera todos los campos', () {
    final record = buildSample();
    final restored = EmotionalRecord.fromJson(record.toJson());

    expect(restored.id, record.id);
    expect(restored.patientId, record.patientId);
    expect(restored.eventDate, record.eventDate);
    expect(restored.createdAt, record.createdAt);
    expect(restored.updatedAt, record.updatedAt);
    expect(restored.situation, record.situation);
    expect(restored.thought, record.thought);
    expect(restored.behavior, record.behavior);
    expect(restored.freeText, record.freeText);
    expect(restored.eventTime, record.eventTime);
    expect(restored.emotions, hasLength(2));
    expect(restored.emotions.first.intensity, 7);
    expect(restored.emotions.last.intensity, isNull);
  });

  test('calcula intensidad máxima, grupos y emociones', () {
    final record = buildSample();

    expect(record.maxIntensity, 7);
    expect(record.hasIntensity, isTrue);
    expect(record.groupIds, containsAll(<String>['tristeza', 'ira']));
    expect(
      record.emotionIds,
      containsAll(<String>['tristeza_pena', 'ira_enfado']),
    );
  });

  test('copyWith permite limpiar la hora y el texto libre', () {
    final record = buildSample();
    final cleared = record.copyWith(
      clearEventTime: true,
      clearFreeText: true,
      situation: 'Otra situación',
    );

    expect(cleared.eventTime, isNull);
    expect(cleared.freeText, isNull);
    expect(cleared.situation, 'Otra situación');
    expect(cleared.id, record.id);
  });

  test('la intensidad se limita al rango 0-10 al deserializar', () {
    final emotion = SelectedEmotion.fromJson({
      'emotionId': 'x',
      'name': 'Prueba',
      'groupId': 'ira',
      'groupName': 'Ira',
      'intensity': 42,
    });

    expect(emotion.intensity, 10);
  });

  test('los filtros combinan fechas, grupo y emoción', () {
    final record = buildSample();

    expect(const RecordFilter().matches(record), isTrue);
    expect(
      RecordFilter(
        from: DateTime(2026, 11, 10),
        to: DateTime(2026, 11, 10),
      ).matches(record),
      isTrue,
    );
    expect(RecordFilter(from: DateTime(2026, 11, 11)).matches(record), isFalse);
    expect(const RecordFilter(groupId: 'ira').matches(record), isTrue);
    expect(const RecordFilter(groupId: 'asco').matches(record), isFalse);
    expect(
      const RecordFilter(emotionId: 'tristeza_pena').matches(record),
      isTrue,
    );
    expect(
      const RecordFilter(emotionId: 'asco_rechazo').matches(record),
      isFalse,
    );
  });

  test('copyWith de filtros limpia cada criterio', () {
    final filter = RecordFilter(
      from: DateTime(2026, 11, 1),
      to: DateTime(2026, 11, 10),
      groupId: 'ira',
      emotionId: 'ira_enfado',
    );

    final withoutEmotion = filter.copyWith(clearEmotion: true);
    expect(withoutEmotion.emotionId, isNull);
    expect(withoutEmotion.groupId, 'ira');

    final onlyEmotion = filter.copyWith(clearDates: true, clearGroup: true);
    expect(onlyEmotion.from, isNull);
    expect(onlyEmotion.to, isNull);
    expect(onlyEmotion.groupId, isNull);
    expect(onlyEmotion.emotionId, 'ira_enfado');
  });
}
