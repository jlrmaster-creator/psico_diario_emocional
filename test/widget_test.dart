import 'package:diario_emocional/app.dart';
import 'package:diario_emocional/core/services/firebase_bootstrap.dart';
import 'package:diario_emocional/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  AppSession localSession() => const AppSession(
    patientId: 'local_test_patient',
    firebaseStatus: FirebaseStatus.local(message: 'Prueba en modo local.'),
  );

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appSessionProvider.overrideWithValue(localSession())],
        child: const PsicoApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra el alta cuando no existe perfil', (tester) async {
    await pumpApp(tester);

    expect(find.text('Tu espacio de emociones'), findsOneWidget);
    expect(
      find.textContaining('Modo local'),
      findsOneWidget,
      reason: 'El modo local debe indicarse claramente',
    );
  });

  testWidgets('no permite continuar sin aceptar la privacidad', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Luna');
    await tester.scrollUntilVisible(
      find.text('Comenzar'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comenzar'));
    await tester.pumpAndSettle();

    expect(
      find.text('Debes aceptar la información de privacidad.'),
      findsOneWidget,
    );
  });
}
