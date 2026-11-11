import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Fechas y calendarios en español.
  await initializeDateFormatting('es');

  // Firebase se inicializa dentro de la app (firebaseRuntimeProvider). Si no
  // hay configuración, la app arranca en modo local y lo indica claramente.
  runApp(const ProviderScope(child: PsicoApp()));
}
