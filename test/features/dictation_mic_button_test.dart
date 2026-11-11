import 'package:diario_emocional/features/diary/widgets/dictation_mic_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pump(
  WidgetTester tester, {
  required bool listening,
  VoidCallback? onPressed,
}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DictationMicButton(
          listening: listening,
          onPressed: onPressed ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('el botón invita a dictar cuando está parado', (tester) async {
    await _pump(tester, listening: false);

    expect(find.byTooltip('Dictar por voz'), findsOneWidget);
    expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
  });

  testWidgets('el botón permite detener mientras escucha', (tester) async {
    await _pump(tester, listening: true);

    expect(find.byTooltip('Detener dictado'), findsOneWidget);
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);
  });

  testWidgets('al pulsarlo avisa a la pantalla', (tester) async {
    var pressed = 0;
    await _pump(tester, listening: false, onPressed: () => pressed++);

    await tester.tap(find.byType(DictationMicButton));

    expect(pressed, 1);
  });
}
