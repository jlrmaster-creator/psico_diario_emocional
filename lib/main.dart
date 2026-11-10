import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'core/services/firebase_bootstrap.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fechas y calendarios en español.
  await initializeDateFormatting('es');

  // Inicializa Firebase solo si hay configuración válida. Si no la hay, la app
  // arranca en modo local y lo muestra claramente en la interfaz.
  final session = await FirebaseBootstrap.initialize();

  runApp(
    ProviderScope(
      overrides: [appSessionProvider.overrideWithValue(session)],
      child: const PsicoApp(),
    ),
  );
}
