import 'package:diario_emocional/features/emotions/emotion_picker_sheet.dart';
import 'package:diario_emocional/models/emotion.dart';
import 'package:diario_emocional/models/emotion_group.dart';
import 'package:diario_emocional/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCatalogNotifier extends EmotionCatalogNotifier {
  _FakeCatalogNotifier(this.catalog);

  final EmotionCatalog catalog;

  @override
  Future<EmotionCatalog> build() async => catalog;
}

const _felicidad = EmotionGroup(
  id: 'felicidad',
  name: 'Felicidad',
  colorHex: '#E0A458',
  icon: 'sentiment_satisfied',
  description: 'Bienestar y disfrute.',
  emotions: [
    Emotion(id: 'felicidad_alegria', name: 'Alegría', groupId: 'felicidad'),
    Emotion(id: 'felicidad_orgullo', name: 'Orgullo', groupId: 'felicidad'),
  ],
);

const _catalog = EmotionCatalog(
  version: 1,
  notice: 'Catálogo de prueba.',
  groups: [_felicidad],
);

class _Launcher extends StatelessWidget {
  const _Launcher({required this.onResult});

  final ValueChanged<List<Emotion>?> onResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final result = await showEmotionPicker(context, selected: const []);
            onResult(result);
          },
          child: const Text('Abrir selector'),
        ),
      ),
    );
  }
}

void main() {
  testWidgets('permite elegir varias emociones del mismo grupo', (
    tester,
  ) async {
    List<Emotion>? result;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogProvider.overrideWith(() => _FakeCatalogNotifier(_catalog)),
        ],
        child: MaterialApp(
          home: _Launcher(onResult: (value) => result = value),
        ),
      ),
    );

    await tester.tap(find.text('Abrir selector'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('incluso del mismo grupo'),
      findsOneWidget,
      reason: 'El selector debe explicar que se pueden combinar emociones',
    );

    await tester.tap(find.text('Alegría'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Orgullo'));
    await tester.pumpAndSettle();

    expect(find.text('Añadir (2)'), findsOneWidget);
    expect(find.text('2 elegidas'), findsOneWidget);
    expect(
      find.textContaining('Puedes combinar varias del mismo grupo'),
      findsOneWidget,
    );

    await tester.tap(find.text('Añadir (2)'));
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result, hasLength(2));
    expect(
      result!.map((emotion) => emotion.name),
      containsAll(<String>['Alegría', 'Orgullo']),
    );
    expect(result!.every((emotion) => emotion.groupId == 'felicidad'), isTrue);
  });
}
