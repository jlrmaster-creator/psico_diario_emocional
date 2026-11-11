import 'package:intl/intl.dart';

/// Utilidades de fecha compartidas por la app y los tests.
DateTime dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime startOfDay(DateTime value) => dateOnly(value);

DateTime endOfDay(DateTime value) =>
    DateTime(value.year, value.month, value.day, 23, 59, 59, 999);

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Ejemplo: `lunes, 10 de noviembre de 2026`.
String formatLongDate(DateTime date) =>
    DateFormat("EEEE, d 'de' MMMM 'de' y", 'es').format(date);

/// Ejemplo: `10 nov 2026`.
String formatShortDate(DateTime date) =>
    DateFormat('d MMM y', 'es').format(date);

/// Ejemplo: `10/11/2026`.
String formatNumericDate(DateTime date) =>
    DateFormat('dd/MM/yyyy', 'es').format(date);

/// Ejemplo: `10 de noviembre de 2026`.
String formatReportDate(DateTime date) =>
    DateFormat("d 'de' MMMM 'de' y", 'es').format(date);

/// Ejemplo: `noviembre de 2026`.
String formatMonthYear(DateTime date) =>
    DateFormat("MMMM 'de' y", 'es').format(date);

/// Ejemplo: `10 nov`.
String formatDayMonth(DateTime date) => DateFormat('d MMM', 'es').format(date);

/// Ejemplo: `3 – 9 nov 2026` o `27 oct – 2 nov 2026`.
String formatWeekRange(DateTime start, DateTime end) {
  if (start.year == end.year && start.month == end.month) {
    return '${start.day} – ${end.day} ${DateFormat('MMM y', 'es').format(end)}';
  }
  if (start.year == end.year) {
    return '${DateFormat('d MMM', 'es').format(start)} – '
        '${DateFormat('d MMM y', 'es').format(end)}';
  }
  return '${formatShortDate(start)} – ${formatShortDate(end)}';
}

/// Ejemplo: `14:35`.
String formatTime(DateTime date) => DateFormat('HH:mm').format(date);

/// Convierte una hora `HH:mm` en [DateTime] del día indicado.
DateTime? combineDateAndTime(DateTime date, String? time) {
  if (time == null || time.isEmpty) return null;
  final parts = time.split(':');
  if (parts.length != 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return DateTime(date.year, date.month, date.day, hour, minute);
}

/// Nombre del día de la semana en español, en minúsculas.
String weekdayName(DateTime date) => DateFormat('EEEE', 'es').format(date);

/// Etiqueta relativa amable: `Hoy`, `Ayer` o fecha corta.
String friendlyDateLabel(DateTime date, {DateTime? now}) {
  final today = dateOnly(now ?? DateTime.now());
  final target = dateOnly(date);
  final difference = today.difference(target).inDays;
  if (difference == 0) return 'Hoy';
  if (difference == 1) return 'Ayer';
  return formatShortDate(date);
}
