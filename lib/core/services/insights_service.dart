import '../../models/emotional_record.dart';
import '../../models/selected_emotion.dart';
import '../utils/date_utils.dart';

/// Cálculos de las pantallas de evolución.
///
/// Todo se calcula en el dispositivo a partir de los registros del paciente.
/// No se envían datos a ningún servidor ni se generan valoraciones clínicas.
class DateRange {
  const DateRange({required this.start, required this.end});

  /// Primer día incluido (sin hora).
  final DateTime start;

  /// Último día incluido (sin hora).
  final DateTime end;

  bool contains(DateTime date) {
    final day = dateOnly(date);
    return !day.isBefore(dateOnly(start)) && !day.isAfter(dateOnly(end));
  }

  /// Número de días naturales del intervalo.
  int get days => _calendarDaysBetween(start, end) + 1;
}

int _calendarDaysBetween(DateTime from, DateTime to) {
  final a = DateTime.utc(from.year, from.month, from.day);
  final b = DateTime.utc(to.year, to.month, to.day);
  return b.difference(a).inDays;
}

/// Lunes de la semana que contiene [date].
DateTime startOfWeek(DateTime date) {
  final day = dateOnly(date);
  return DateTime(day.year, day.month, day.day - (day.weekday - 1));
}

/// Semana completa (lunes a domingo) que contiene [date].
DateRange weekRange(DateTime date) {
  final start = startOfWeek(date);
  return DateRange(
    start: start,
    end: DateTime(start.year, start.month, start.day + 6),
  );
}

/// Mes completo que contiene [date].
DateRange monthRange(DateTime date) {
  return DateRange(
    start: DateTime(date.year, date.month, 1),
    end: DateTime(date.year, date.month + 1, 0),
  );
}

DateRange previousWeekRange(DateRange current) => weekRange(
  DateTime(current.start.year, current.start.month, current.start.day - 7),
);

DateRange previousMonthRange(DateRange current) =>
    monthRange(DateTime(current.start.year, current.start.month - 1, 1));

/// Registros cuyo día del acontecimiento cae dentro del intervalo.
List<EmotionalRecord> recordsInRange(
  List<EmotionalRecord> records,
  DateRange range,
) {
  return records
      .where((record) => range.contains(record.eventDate))
      .toList(growable: false);
}

/// Frecuencia de una emoción en el conjunto de registros analizado.
class EmotionFrequency {
  const EmotionFrequency({
    required this.emotionId,
    required this.name,
    required this.groupId,
    required this.groupName,
    required this.count,
  });

  final String emotionId;
  final String name;
  final String groupId;
  final String groupName;
  final int count;
}

class _EmotionCounter {
  _EmotionCounter(this.emotion) : count = 1;

  final SelectedEmotion emotion;
  int count;

  EmotionFrequency toFrequency() => EmotionFrequency(
    emotionId: emotion.emotionId,
    name: emotion.name,
    groupId: emotion.groupId,
    groupName: emotion.groupName,
    count: count,
  );
}

/// Emociones ordenadas de más a menos frecuentes.
List<EmotionFrequency> emotionFrequency(List<EmotionalRecord> records) {
  final counters = <String, _EmotionCounter>{};

  for (final record in records) {
    for (final emotion in record.emotions) {
      final key = emotion.emotionId.isNotEmpty
          ? emotion.emotionId
          : '${emotion.groupId}:${emotion.name}';
      final current = counters[key];
      if (current == null) {
        counters[key] = _EmotionCounter(emotion);
      } else {
        current.count += 1;
      }
    }
  }

  final result = counters.values
      .map((counter) => counter.toFrequency())
      .toList(growable: false);
  result.sort((a, b) {
    final byCount = b.count.compareTo(a.count);
    if (byCount != 0) return byCount;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  return result;
}

/// Media de todas las intensidades indicadas. `null` si no hay ninguna.
double? averageIntensity(List<EmotionalRecord> records) {
  var sum = 0;
  var count = 0;
  for (final record in records) {
    for (final emotion in record.emotions) {
      final intensity = emotion.intensity;
      if (intensity == null) continue;
      sum += intensity;
      count += 1;
    }
  }
  if (count == 0) return null;
  return sum / count;
}

/// Días distintos con al menos un registro.
int daysRecorded(List<EmotionalRecord> records) {
  return records.map((record) => dateOnly(record.eventDate)).toSet().length;
}

/// Intensidad media de una semana concreta.
class WeeklyIntensity {
  const WeeklyIntensity({
    required this.weekStart,
    required this.average,
    required this.recordCount,
  });

  final DateTime weekStart;

  /// `null` si esa semana no tiene intensidades indicadas.
  final double? average;

  final int recordCount;
}

/// Últimas [weeks] semanas, de la más antigua a la actual.
///
/// La semana actual se incluye completa; los registros de días futuros
/// simplemente no existirán.
List<WeeklyIntensity> weeklyIntensitySeries(
  List<EmotionalRecord> records, {
  DateTime? now,
  int weeks = 8,
}) {
  final currentWeek = startOfWeek(now ?? DateTime.now());
  final result = <WeeklyIntensity>[];

  for (var index = weeks - 1; index >= 0; index--) {
    final start = DateTime(
      currentWeek.year,
      currentWeek.month,
      currentWeek.day - (index * 7),
    );
    final range = DateRange(
      start: start,
      end: DateTime(start.year, start.month, start.day + 6),
    );
    final weekRecords = recordsInRange(records, range);
    result.add(
      WeeklyIntensity(
        weekStart: start,
        average: averageIntensity(weekRecords),
        recordCount: weekRecords.length,
      ),
    );
  }

  return result;
}

/// Número de registros por día, indexado por fecha sin hora.
Map<DateTime, int> dailyRecordCounts(List<EmotionalRecord> records) {
  final counts = <DateTime, int>{};
  for (final record in records) {
    final day = dateOnly(record.eventDate);
    counts[day] = (counts[day] ?? 0) + 1;
  }
  return counts;
}

/// Fechas que ocupan la cuadrícula de un mes, con `null` en los huecos
/// anteriores al día 1. La semana empieza en lunes.
List<DateTime?> monthGridDays(DateTime month) {
  final first = DateTime(month.year, month.month, 1);
  final leading = first.weekday - 1;
  final total = DateTime(month.year, month.month + 1, 0).day;
  final days = <DateTime?>[
    for (var i = 0; i < leading; i++) null,
    for (var day = 1; day <= total; day++)
      DateTime(month.year, month.month, day),
  ];
  return days;
}

/// Datos agregados de un periodo.
class PeriodStats {
  const PeriodStats({
    required this.range,
    required this.recordCount,
    required this.daysRecorded,
    required this.averageIntensity,
    required this.emotions,
  });

  final DateRange range;
  final int recordCount;
  final int daysRecorded;
  final double? averageIntensity;
  final List<EmotionFrequency> emotions;

  bool get hasRecords => recordCount > 0;

  String? get topEmotionName => emotions.isEmpty ? null : emotions.first.name;

  String? get topGroupName {
    if (emotions.isEmpty) return null;
    final counts = <String, int>{};
    final names = <String, String>{};
    for (final emotion in emotions) {
      counts[emotion.groupId] = (counts[emotion.groupId] ?? 0) + emotion.count;
      names[emotion.groupId] = emotion.groupName;
    }
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return names[entries.first.key];
  }
}

PeriodStats periodStats(List<EmotionalRecord> records, DateRange range) {
  final inRange = recordsInRange(records, range);
  return PeriodStats(
    range: range,
    recordCount: inRange.length,
    daysRecorded: daysRecorded(inRange),
    averageIntensity: averageIntensity(inRange),
    emotions: emotionFrequency(inRange),
  );
}

/// Comparación entre un periodo y el inmediatamente anterior.
class PeriodComparison {
  const PeriodComparison({required this.current, required this.previous});

  final PeriodStats current;
  final PeriodStats previous;

  int get recordDelta => current.recordCount - previous.recordCount;

  int get daysDelta => current.daysRecorded - previous.daysRecorded;

  double? get intensityDelta {
    final currentAverage = current.averageIntensity;
    final previousAverage = previous.averageIntensity;
    if (currentAverage == null || previousAverage == null) return null;
    return currentAverage - previousAverage;
  }
}

enum SummaryHighlightKind { records, days, intensity, emotion, group }

class SummaryHighlight {
  const SummaryHighlight(this.kind, this.text);

  final SummaryHighlightKind kind;
  final String text;
}

/// Textos neutros que describen cambios entre dos periodos.
///
/// Evita valoraciones como "mejor" o "peor": solo describe lo registrado.
List<SummaryHighlight> summaryHighlights(
  PeriodComparison comparison, {
  required bool isMonth,
  DateTime? today,
}) {
  final current = comparison.current;
  final previous = comparison.previous;
  final periodWord = isMonth ? 'mes' : 'semana';
  final previousLabel = isMonth ? 'mes anterior' : 'semana anterior';

  if (current.recordCount == 0) {
    return [
      SummaryHighlight(
        SummaryHighlightKind.records,
        'No hay registros en este $periodWord.',
      ),
    ];
  }

  final highlights = <SummaryHighlight>[];
  final recordsLabel = current.recordCount == 1
      ? '1 registro'
      : '${current.recordCount} registros';

  if (previous.recordCount == 0) {
    highlights.add(
      SummaryHighlight(
        SummaryHighlightKind.records,
        'Has escrito $recordsLabel. No había registros en la $previousLabel.',
      ),
    );
  } else if (comparison.recordDelta == 0) {
    highlights.add(
      SummaryHighlight(
        SummaryHighlightKind.records,
        'Has escrito $recordsLabel, igual que en la $previousLabel.',
      ),
    );
  } else if (comparison.recordDelta > 0) {
    highlights.add(
      SummaryHighlight(
        SummaryHighlightKind.records,
        'Has escrito $recordsLabel, ${comparison.recordDelta} más que en la $previousLabel.',
      ),
    );
  } else {
    highlights.add(
      SummaryHighlight(
        SummaryHighlightKind.records,
        'Has escrito $recordsLabel, ${-comparison.recordDelta} menos que en la $previousLabel.',
      ),
    );
  }

  final elapsedDays = _elapsedDays(current.range, today ?? DateTime.now());
  if (elapsedDays > 0) {
    highlights.add(
      SummaryHighlight(
        SummaryHighlightKind.days,
        'Has registrado en ${current.daysRecorded} de $elapsedDays días.',
      ),
    );
  }

  final average = current.averageIntensity;
  final previousAverage = previous.averageIntensity;
  if (average == null) {
    highlights.add(
      const SummaryHighlight(
        SummaryHighlightKind.intensity,
        'No indicaste intensidad en este periodo.',
      ),
    );
  } else if (previousAverage == null) {
    highlights.add(
      SummaryHighlight(
        SummaryHighlightKind.intensity,
        'La intensidad media ha sido ${formatIntensity(average)} sobre 10.',
      ),
    );
  } else {
    final delta = average - previousAverage;
    if (delta.abs() < 0.05) {
      highlights.add(
        SummaryHighlight(
          SummaryHighlightKind.intensity,
          'La intensidad media se mantiene en ${formatIntensity(average)} sobre 10.',
        ),
      );
    } else if (delta > 0) {
      highlights.add(
        SummaryHighlight(
          SummaryHighlightKind.intensity,
          'La intensidad media ha subido ${formatIntensity(delta)} puntos: '
          'de ${formatIntensity(previousAverage)} a ${formatIntensity(average)}.',
        ),
      );
    } else {
      highlights.add(
        SummaryHighlight(
          SummaryHighlightKind.intensity,
          'La intensidad media ha bajado ${formatIntensity(-delta)} puntos: '
          'de ${formatIntensity(previousAverage)} a ${formatIntensity(average)}.',
        ),
      );
    }
  }

  final topEmotion = current.topEmotionName;
  final previousTopEmotion = previous.topEmotionName;
  if (topEmotion != null) {
    if (previousTopEmotion != null && previousTopEmotion != topEmotion) {
      highlights.add(
        SummaryHighlight(
          SummaryHighlightKind.emotion,
          'La emoción más frecuente ha cambiado: antes era «$previousTopEmotion» '
          'y ahora es «$topEmotion».',
        ),
      );
    } else {
      final count = current.emotions.first.count;
      highlights.add(
        SummaryHighlight(
          SummaryHighlightKind.emotion,
          'La emoción más frecuente ha sido «$topEmotion» '
          '($count ${count == 1 ? 'vez' : 'veces'}).',
        ),
      );
    }
  }

  final topGroup = current.topGroupName;
  if (topGroup != null) {
    highlights.add(
      SummaryHighlight(
        SummaryHighlightKind.group,
        'El grupo más presente ha sido $topGroup.',
      ),
    );
  }

  return highlights;
}

int _elapsedDays(DateRange range, DateTime today) {
  final start = dateOnly(range.start);
  final end = dateOnly(range.end);
  final current = dateOnly(today);
  if (current.isBefore(start)) return 0;
  final last = current.isAfter(end) ? end : current;
  return _calendarDaysBetween(start, last) + 1;
}

/// Formato decimal con coma, como se usa en español.
String formatIntensity(double value) =>
    value.toStringAsFixed(1).replaceAll('.', ',');
