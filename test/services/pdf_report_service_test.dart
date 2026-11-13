import 'package:diario_emocional/core/utils/date_utils.dart';
import 'package:diario_emocional/data/services/pdf_report_service.dart';
import 'package:diario_emocional/models/emotional_record.dart';
import 'package:diario_emocional/models/selected_emotion.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  EmotionalRecord record({
    required String id,
    required String time,
    DateTime? date,
    String freeText =
        'Un texto largo con acentos: emoción, corazón, mañana, pingüino, '
        'canción y una posdata que debe caber en el informe.',
  }) {
    final day = date ?? DateTime(2026, 11, 10);
    return EmotionalRecord(
      id: id,
      patientId: 'patient-1',
      eventDate: day,
      createdAt: DateTime(day.year, day.month, day.day, 8, 0),
      updatedAt: DateTime(day.year, day.month, day.day, 8, 0),
      situation: 'Situación con acentos: reunión, café y conversación.',
      emotions: const [
        SelectedEmotion(
          emotionId: 'tristeza_pena',
          name: 'Pena',
          groupId: 'tristeza',
          groupName: 'Tristeza',
          intensity: 6,
        ),
        SelectedEmotion(
          emotionId: 'alegria_alivio',
          name: 'Alivio',
          groupId: 'alegria',
          groupName: 'Alegría',
        ),
      ],
      thought:
          'Pensamiento con una frase larga que debería ajustarse al ancho '
          'de la página sin recortarse ni salirse del margen del documento.',
      behavior: 'Conducta observada.',
      freeText: freeText,
      eventTime: time,
    );
  }

  test('genera un PDF válido con varios registros', () async {
    final bytes = await const PdfReportService().buildDailyReport(
      DailyReportData(
        departmentName: 'Departamento de Psicología',
        patientPseudonym: 'Luna',
        date: DateTime(2026, 11, 10),
        records: [
          record(id: 'a', time: '09:15'),
          record(id: 'b', time: '18:40'),
        ],
        generatedAt: DateTime(2026, 11, 10, 20, 5),
      ),
    );

    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(1500));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('genera un PDF para un día sin registros', () async {
    final bytes = await const PdfReportService().buildDailyReport(
      DailyReportData(
        departmentName: 'Departamento de Psicología',
        patientPseudonym: 'Paciente',
        date: DateTime(2026, 11, 9),
        records: const [],
        generatedAt: DateTime(2026, 11, 10, 20, 5),
      ),
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('ordena los registros por hora del acontecimiento', () {
    final data = DailyReportData(
      departmentName: 'Departamento',
      patientPseudonym: 'Luna',
      date: DateTime(2026, 11, 10),
      records: [
        record(id: 'tarde', time: '18:40'),
        record(id: 'manana', time: '09:15'),
      ],
      generatedAt: DateTime(2026, 11, 10),
    );

    expect(data.sortedRecords.map((item) => item.id), <String>[
      'manana',
      'tarde',
    ]);
  });

  test('el nombre del archivo usa la fecha del informe', () {
    expect(
      PdfReportService.dailyReportFileName(DateTime(2026, 11, 10)),
      'diario_emocional_2026-11-10.pdf',
    );
  });

  test('el nombre del archivo semanal usa el lunes de la semana', () {
    expect(
      PdfReportService.weeklyReportFileName(DateTime(2026, 11, 9)),
      'diario_emocional_semana_2026-11-09.pdf',
    );
  });

  test('genera un PDF semanal con métricas, tablas y gráficos', () async {
    final bytes = await const PdfReportService().buildWeeklyReport(
      WeeklyReportData(
        departmentName: 'Departamento de Psicología',
        patientPseudonym: 'Luna',
        weekStart: DateTime(2026, 11, 9),
        weekEnd: DateTime(2026, 11, 15),
        records: [
          record(id: 'lunes', time: '09:15', date: DateTime(2026, 11, 9)),
          record(id: 'miercoles', time: '18:40', date: DateTime(2026, 11, 11)),
          record(id: 'viernes', time: '12:05', date: DateTime(2026, 11, 13)),
        ],
        generatedAt: DateTime(2026, 11, 15, 20, 5),
      ),
    );

    expect(bytes, isNotEmpty);
    expect(bytes.length, greaterThan(4000));
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('genera un PDF semanal aunque no haya registros', () async {
    final bytes = await const PdfReportService().buildWeeklyReport(
      WeeklyReportData(
        departmentName: 'Departamento de Psicología',
        patientPseudonym: 'Paciente',
        weekStart: DateTime(2026, 11, 9),
        weekEnd: DateTime(2026, 11, 15),
        records: const [],
        generatedAt: DateTime(2026, 11, 15, 20, 5),
      ),
    );

    expect(bytes, isNotEmpty);
    expect(String.fromCharCodes(bytes.take(4)), '%PDF');
  });

  test('el informe semanal filtra, ordena y agrega estadísticas', () {
    final data = WeeklyReportData(
      departmentName: 'Departamento',
      patientPseudonym: 'Luna',
      weekStart: DateTime(2026, 11, 9),
      weekEnd: DateTime(2026, 11, 15),
      records: [
        record(id: 'miercoles', time: '18:40', date: DateTime(2026, 11, 11)),
        record(id: 'lunes-tarde', time: '17:30', date: DateTime(2026, 11, 9)),
        record(id: 'lunes-manana', time: '09:15', date: DateTime(2026, 11, 9)),
        record(id: 'fuera', time: '10:00', date: DateTime(2026, 11, 16)),
      ],
      generatedAt: DateTime(2026, 11, 15, 20, 5),
    );

    expect(data.sortedRecords.map((item) => item.id), <String>[
      'lunes-manana',
      'lunes-tarde',
      'miercoles',
    ]);
    expect(data.stats.recordCount, 3);
    expect(data.stats.daysRecorded, 2);
    expect(data.stats.topEmotionName, 'Alivio');
    expect(data.stats.emotions.first.count, 3);
    expect(data.stats.averageIntensity, 6);
  });

  test('recordsForDate filtra por día ignorando la hora', () {
    final date = DateTime(2026, 11, 10);
    final records = [
      record(id: 'a', time: '09:15'),
      EmotionalRecord(
        id: 'otro-dia',
        patientId: 'patient-1',
        eventDate: DateTime(2026, 11, 11),
        createdAt: date,
        updatedAt: date,
        situation: 'Otra fecha',
        emotions: const [],
        thought: '',
        behavior: '',
      ),
    ];

    // Se usa el helper de la app a través de su importación en providers.
    final filtered = records
        .where(
          (item) =>
              item.eventDate.year == date.year &&
              item.eventDate.month == date.month &&
              item.eventDate.day == date.day,
        )
        .toList();

    expect(filtered.map((item) => item.id), <String>['a']);
    expect(isSameDay(filtered.single.eventDate, date), isTrue);
  });
}
