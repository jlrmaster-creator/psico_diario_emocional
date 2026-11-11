import 'package:diario_emocional/core/services/auth_service.dart';
import 'package:diario_emocional/features/auth/auth_screen.dart';
import 'package:diario_emocional/state/providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthApi implements AuthApi {
  String? email;
  String? password;
  bool registered = false;
  bool resetRequested = false;
  Object? error;

  @override
  Future<void> signIn({required String email, required String password}) async {
    if (error != null) throw error!;
    this.email = email;
    this.password = password;
  }

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {
    if (error != null) throw error!;
    registered = true;
    this.email = email;
    this.password = password;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    if (error != null) throw error!;
    resetRequested = true;
    this.email = email;
  }

  @override
  Future<void> signOut() async {}
}

void main() {
  Future<_FakeAuthApi> pumpAuth(WidgetTester tester) async {
    final fake = _FakeAuthApi();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authServiceProvider.overrideWithValue(fake)],
        child: const MaterialApp(home: AuthScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return fake;
  }

  testWidgets('inicia sesión con correo y contraseña', (tester) async {
    final fake = await pumpAuth(tester);

    expect(find.text('Iniciar sesión'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'luna@ejemplo.com');
    await tester.enterText(fields.at(1), 'secreto123');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    expect(fake.email, 'luna@ejemplo.com');
    expect(fake.password, 'secreto123');
    expect(fake.registered, isFalse);
  });

  testWidgets('permite crear una cuenta', (tester) async {
    final fake = await pumpAuth(tester);

    await tester.tap(find.text('No tengo cuenta. Crear una'));
    await tester.pumpAndSettle();
    expect(find.text('Crear tu cuenta'), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'nueva@ejemplo.com');
    await tester.enterText(fields.at(1), 'secreto123');
    await tester.enterText(fields.at(2), 'secreto123');
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pump();

    expect(fake.registered, isTrue);
    expect(fake.email, 'nueva@ejemplo.com');
  });

  testWidgets('avisa si las contraseñas no coinciden', (tester) async {
    final fake = await pumpAuth(tester);

    await tester.tap(find.text('No tengo cuenta. Crear una'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'nueva@ejemplo.com');
    await tester.enterText(fields.at(1), 'secreto123');
    await tester.enterText(fields.at(2), 'otra-clave');
    await tester.tap(find.widgetWithText(FilledButton, 'Crear cuenta'));
    await tester.pump();

    expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
    expect(fake.registered, isFalse);
  });

  testWidgets('muestra un mensaje si el acceso falla', (tester) async {
    final fake = await pumpAuth(tester);
    fake.error = StateError('sin conexión');

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'luna@ejemplo.com');
    await tester.enterText(fields.at(1), 'secreto123');
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pump();

    expect(
      find.text('No se pudo completar la operación. Inténtalo de nuevo.'),
      findsOneWidget,
    );
  });

  testWidgets('envía el correo de recuperación', (tester) async {
    final fake = await pumpAuth(tester);

    await tester.enterText(
      find.byType(TextFormField).first,
      'luna@ejemplo.com',
    );
    await tester.tap(find.text('¿Olvidaste tu contraseña?'));
    await tester.pump();

    expect(fake.resetRequested, isTrue);
    expect(fake.email, 'luna@ejemplo.com');
  });
}
