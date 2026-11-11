import 'package:diario_emocional/core/services/insights_service.dart';
import 'package:diario_emocional/core/utils/date_utils.dart';
import 'package:diario_emocional/models/emotional_record.dart';
import 'package:diario_emocional/models/selected_emotion.dart';
import 'package:flutter_test/flutter_test.dart';

SelectedEmotion emotion(
  String id,
  String name,
  String groupId,
  String groupName, [
  int? intensity,
]) {
  return SelectedEmotion(
    emotionId: id,
    name: name,
    groupId: groupId,
    groupName: groupName,
    intensity: intensity,
  );
}

EmotionalRecord record({
  required String id,
  required DateTime date,
  List<SelectedEmotion> emotions = const [],
}) {
  return EmotionalRecord(
    id: id,
    patientId: 'paciente_1',
    eventDate: dateOnly(date),
    createdAt: date,
    updatedAt: date,
    situation: 'Situación $id',
    emotions: emotions,
    thought: 'Pensamiento $id',
    behavior: 'Conducta $id',
  );
}

void main() {
  group('emotionFrequency', () {
    test('cuenta y ordena las emociones de más a menos frecuentes', () {
      final records = [
        record(
          id: '1',
          date: DateTime(2026, 11, 9),
          emotions: [
            emotion('miedo_ansiedad', 'Ansiedad', 'miedo', 'Miedo', 6),
            emotion('tristeza_tristeza', 'Tristeza', 'tristeza', 'Tristeza', 4),
          ],
        ),
        record(
          id: '2',
          date: DateTime(2026, 11, 10),
          emotions: [
            emotion('miedo_ansiedad', 'Ansiedad', 'miedo', 'Miedo', 8),
            emotion(
              'felicidad_alegria',
              'Alegría',
              'felicidad',
              'Felicidad',
              7,
            ),
          ],
        ),
        record(
          id: '3',
          date: DateTime(2026, 11, 11),
          emotions: [
            emotion('miedo_ansiedad', 'Ansiedad', 'miedo', 'Miedo', 5),
          ],
        ),
      ];

      final result = emotionFrequency(records);

      expect(result, hasLength(3));
      expect(result.first.name, 'Ansiedad');
      expect(result.first.count, 3);
      expect(result[1].name, 'Alegría');
      expect(result[2].name, 'Tristeza');
    });

    test('devuelve una lista vacía sin registros', () {
      expect(emotionFrequency(const []), isEmpty);
    });
  });

  group('averageIntensity', () {
    test('ignora las intensidades no indicadas', () {
      final records = [
        record(
          id: '1',
          date: DateTime(2026, 11, 9),
          emotions: [
            emotion('a', 'A', 'miedo', 'Miedo', 5),
            emotion('b', 'B', 'miedo', 'Miedo', 8),
            emotion('c', 'C', 'miedo', 'Miedo'),
          ],
        ),
      ];

      expect(averageIntensity(records), 6.5);
    });

    test('devuelve null si no hay intensidades', () {
      expect(averageIntensity(const []), isNull);
      expect(
        averageIntensity([
          record(
            id: '1',
            date: DateTime(2026, 11, 9),
            emotions: [emotion('a', 'A', 'miedo', 'Miedo')],
          ),
        ]),
        isNull,
      );
    });
  });

  group('daysRecorded', () {
    test('cuenta días distintos aunque haya varios registros', () {
      final records = [
        record(id: '1', date: DateTime(2026, 11, 9)),
        record(id: '2', date: DateTime(2026, 11, 9)),
        record(id: '3', date: DateTime(2026, 11, 11)),
      ];

      expect(daysRecorded(records), 2);
    });
  });

  group('weeklyIntensitySeries', () {
    test('agrupa por semanas que empiezan en lunes', () {
      final now = DateTime(2026, 11, 11);
      final records = [
        record(
          id: '1',
          date: DateTime(2026, 11, 10),
          emotions: [
            emotion('a', 'A', 'miedo', 'Miedo', 4),
            emotion('b', 'B', 'miedo', 'Miedo', 8),
          ],
        ),
        record(
          id: '2',
          date: DateTime(2026, 11, 3),
          emotions: [emotion('a', 'A', 'miedo', 'Miedo', 10)],
        ),
        record(
          id: '3',
          date: DateTime(2026, 10, 20),
          emotions: [emotion('a', 'A', 'miedo', 'Miedo')],
        ),
      ];

      final result = weeklyIntensitySeries(records, now: now, weeks: 8);

      expect(result, hasLength(8));
      expect(result.first.weekStart, DateTime(2026, 9, 21));
      expect(result.last.weekStart, DateTime(2026, 11, 9));
      expect(result.last.average, 6);
      expect(result.last.recordCount, 1);
      expect(result[6].weekStart, DateTime(2026, 11, 2));
      expect(result[6].average, 10);
      expect(result[5].average, isNull);
      expect(result[5].recordCount, 0);
      expect(result[4].weekStart, DateTime(2026, 10, 19));
      expect(result[4].average, isNull);
      expect(result[4].recordCount, 1);
    });

    test('startOfWeek devuelve el lunes también para domingo', () {
      expect(startOfWeek(DateTime(2026, 11, 15)), DateTime(2026, 11, 9));
      expect(startOfWeek(DateTime(2026, 11, 9)), DateTime(2026, 11, 9));
    });
  });

  group('rangos', () {
    test('weekRange va de lunes a domingo', () {
      final range = weekRange(DateTime(2026, 11, 11));

      expect(range.start, DateTime(2026, 11, 9));
      expect(range.end, DateTime(2026, 11, 15));
      expect(range.days, 7);
      expect(range.contains(DateTime(2026, 11, 9, 23, 59)), isTrue);
      expect(range.contains(DateTime(2026, 11, 16)), isFalse);
    });

    test('monthRange y periodos anteriores', () {
      final november = monthRange(DateTime(2026, 11, 15));
      expect(november.start, DateTime(2026, 11, 1));
      expect(november.end, DateTime(2026, 11, 30));
      expect(november.days, 30);

      final october = previousMonthRange(november);
      expect(october.start, DateTime(2026, 10, 1));
      expect(october.end, DateTime(2026, 10, 31));

      final previousWeek = previousWeekRange(weekRange(DateTime(2026, 11, 11)));
      expect(previousWeek.start, DateTime(2026, 11, 2));
      expect(previousWeek.end, DateTime(2026, 11, 8));
    });

    test('monthGridDays deja huecos hasta el lunes del día 1', () {
      final november = monthGridDays(DateTime(2026, 11, 1));
      expect(november, hasLength(36));
      expect(november.take(6), everyElement(isNull));
      expect(november[6], DateTime(2026, 11, 1));
      expect(november.last, DateTime(2026, 11, 30));
    });
  });

  group('periodStats', () {
    test('agrega registros, días, intensidad y emociones del periodo', () {
      final records = [
        record(
          id: '1',
          date: DateTime(2026, 11, 10),
          emotions: [
            emotion('miedo_ansiedad', 'Ansiedad', 'miedo', 'Miedo', 6),
            emotion('tristeza_tristeza', 'Tristeza', 'tristeza', 'Tristeza', 4),
          ],
        ),
        record(
          id: '2',
          date: DateTime(2026, 11, 12),
          emotions: [
            emotion('miedo_ansiedad', 'Ansiedad', 'miedo', 'Miedo', 8),
          ],
        ),
        record(
          id: '3',
          date: DateTime(2026, 11, 3),
          emotions: [
            emotion('miedo_ansiedad', 'Ansiedad', 'miedo', 'Miedo', 10),
          ],
        ),
      ];

      final stats = periodStats(records, weekRange(DateTime(2026, 11, 11)));

      expect(stats.recordCount, 2);
      expect(stats.daysRecorded, 2);
      expect(stats.averageIntensity, 6);
      expect(stats.topEmotionName, 'Ansiedad');
      expect(stats.topGroupName, 'Miedo');
      expect(stats.emotions.first.count, 2);
    });

    test('devuelve ceros y null sin registros', () {
      final stats = periodStats(const [], weekRange(DateTime(2026, 11, 11)));

      expect(stats.hasRecords, isFalse);
      expect(stats.recordCount, 0);
      expect(stats.daysRecorded, 0);
      expect(stats.averageIntensity, isNull);
      expect(stats.topEmotionName, isNull);
    });
  });

  group('summaryHighlights', () {
    test('describe cambios sin valoraciones', () {
      final currentRecords = [
        record(
          id: '1',
          date: DateTime(2026, 11, 9),
          emotions: [
            emotion('miedo_ansiedad', 'Ansiedad', 'miedo', 'Miedo', 6),
          ],
        ),
        record(
          id: '2',
          date: DateTime(2026, 11, 10),
          emotions: [
            emotion('miedo_ansiedad', 'Ansiedad', 'miedo', 'Miedo', 6),
          ],
        ),
        record(
          id: '3',
          date: DateTime(2026, 11, 11),
          emotions: [
            emotion('tristeza_tristeza', 'Tristeza', 'tristeza', 'Tristeza', 7),
          ],
        ),
        record(
          id: '4',
          date: DateTime(2026, 11, 11),
          emotions: [
            emotion(
              'felicidad_alegria',
              'Alegría',
              'felicidad',
              'Felicidad',
              7,
            ),
          ],
        ),
      ];
      final previousRecords = [
        record(
          id: '5',
          date: DateTime(2026, 11, 3),
          emotions: [
            emotion('miedo_ansiedad', 'Ansiedad', 'miedo', 'Miedo', 5),
          ],
        ),
        record(
          id: '6',
          date: DateTime(2026, 11, 4),
          emotions: [
            emotion('miedo_ansiedad', 'Ansiedad', 'miedo', 'Miedo', 9),
          ],
        ),
      ];

      final range = weekRange(DateTime(2026, 11, 11));
      final comparison = PeriodComparison(
        current: periodStats(currentRecords, range),
        previous: periodStats(previousRecords, previousWeekRange(range)),
      );

      final highlights = summaryHighlights(
        comparison,
        isMonth: false,
        today: DateTime(2026, 11, 11),
      );

      expect(highlights.map((item) => item.text), [
        'Has escrito 4 registros, 2 más que en la semana anterior.',
        'Has registrado en 3 de 3 días.',
        'La intensidad media ha bajado 0,5 puntos: de 7,0 a 6,5.',
        'La emoción más frecuente ha sido «Ansiedad» (2 veces).',
        'El grupo más presente ha sido Miedo.',
      ]);
      expect(highlights.map((item) => item.kind), [
        SummaryHighlightKind.records,
        SummaryHighlightKind.days,
        SummaryHighlightKind.intensity,
        SummaryHighlightKind.emotion,
        SummaryHighlightKind.group,
      ]);
    });

    test('avisa cuando cambia la emoción más frecuente', () {
      final current = [
        record(
          id: '1',
          date: DateTime(2026, 11, 10),
          emotions: [
            emotion('tristeza_tristeza', 'Tristeza', 'tristeza', 'Tristeza', 4),
          ],
        ),
      ];
      final previous = [
        record(
          id: '2',
          date: DateTime(2026, 11, 3),
          emotions: [
            emotion('miedo_ansiedad', 'Ansiedad', 'miedo', 'Miedo', 7),
          ],
        ),
      ];

      final range = weekRange(DateTime(2026, 11, 11));
      final highlights = summaryHighlights(
        PeriodComparison(
          current: periodStats(current, range),
          previous: periodStats(previous, previousWeekRange(range)),
        ),
        isMonth: false,
        today: DateTime(2026, 11, 11),
      );

      expect(
        highlights.map((item) => item.text),
        contains(
          'La emoción más frecuente ha cambiado: antes era «Ansiedad» y ahora es «Tristeza».',
        ),
      );
    });

    test('indica cuando el periodo anterior estaba vacío', () {
      final current = [
        record(
          id: '1',
          date: DateTime(2026, 11, 10),
          emotions: [
            emotion('miedo_ansiedad', 'Ansiedad', 'miedo', 'Miedo', 5),
          ],
        ),
      ];
      final range = weekRange(DateTime(2026, 11, 11));
      final highlights = summaryHighlights(
        PeriodComparison(
          current: periodStats(current, range),
          previous: periodStats(const [], previousWeekRange(range)),
        ),
        isMonth: false,
        today: DateTime(2026, 11, 11),
      );

      expect(
        highlights.first.text,
        'Has escrito 1 registro. No había registros en la semana anterior.',
      );
    });

    test('devuelve un aviso claro si el periodo no tiene registros', () {
      final range = monthRange(DateTime(2026, 11, 11));
      final highlights = summaryHighlights(
        PeriodComparison(
          current: periodStats(const [], range),
          previous: periodStats(const [], previousMonthRange(range)),
        ),
        isMonth: true,
        today: DateTime(2026, 11, 11),
      );

      expect(highlights, hasLength(1));
      expect(highlights.first.text, 'No hay registros en este mes.');
    });

    test('en periodos pasados usa todos los días del intervalo', () {
      final range = weekRange(DateTime(2026, 11, 4));
      final records = [
        record(
          id: '1',
          date: DateTime(2026, 11, 3),
          emotions: [
            emotion('miedo_ansiedad', 'Ansiedad', 'miedo', 'Miedo', 5),
          ],
        ),
      ];

      final highlights = summaryHighlights(
        PeriodComparison(
          current: periodStats(records, range),
          previous: periodStats(const [], previousWeekRange(range)),
        ),
        isMonth: false,
        today: DateTime(2026, 11, 11),
      );

      expect(
        highlights.map((item) => item.text),
        contains('Has registrado en 1 de 7 días.'),
      );
    });
  });

  test('formatIntensity usa coma decimal', () {
    expect(formatIntensity(6.5), '6,5');
    expect(formatIntensity(7), '7,0');
  });
}
