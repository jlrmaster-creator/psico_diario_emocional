import 'package:diario_emocional/features/diary/widgets/record_card.dart';
import 'package:diario_emocional/models/emotional_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

EmotionalRecord _record({String title = ''}) {
  final date = DateTime(2026, 11, 10, 18, 5);
  return EmotionalRecord(
    id: 'record-1',
    patientId: 'patient-1',
    eventDate: DateTime(2026, 11, 10),
    createdAt: date,
    updatedAt: date,
    title: title,
    situation: 'Una conversación difícil con mi amiga',
    emotions: const [],
    thought: 'No me está escuchando.',
    behavior: 'Me callé y me fui.',
    eventTime: '18:05',
  );
}

Future<void> _pump(WidgetTester tester, EmotionalRecord record) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: RecordCard(record: record, catalog: null, onTap: () {}),
      ),
    ),
  );
}

void main() {
  testWidgets('el historial muestra el título y no el detalle', (tester) async {
    await _pump(tester, _record(title: 'Conversación con mi amiga'));

    expect(find.text('Conversación con mi amiga'), findsOneWidget);
    expect(find.textContaining('Una conversación difícil'), findsNothing);
    expect(find.textContaining('No me está escuchando'), findsNothing);
    expect(find.textContaining('Me callé y me fui'), findsNothing);
  });

  testWidgets('los registros sin título muestran uno automático', (
    tester,
  ) async {
    await _pump(tester, _record());

    expect(find.text('Una conversación difícil con mi amiga'), findsOneWidget);
  });
}
