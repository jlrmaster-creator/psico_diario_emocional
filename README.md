# Diario Emocional

Aplicación móvil en Flutter para que un departamento de psicología ofrezca a sus
pacientes un espacio privado donde registrar emociones entre sesiones y generar
un informe PDF diario que puedan compartir voluntariamente.

La app funciona **sin Firebase** en modo local y está preparada para conectarse a
Firebase Authentication + Cloud Firestore cuando el equipo aporte su propia
configuración. **Este repositorio no incluye credenciales ni proyectos de
Firebase desplegados.**

## Estado verificado

| Comprobación | Resultado |
| --- | --- |
| `flutter analyze` | Sin errores ni advertencias |
| `flutter test` | 25 pruebas superadas |
| Compilación Android | Ver [docs/TESTING.md](docs/TESTING.md) para el estado exacto de la máquina de desarrollo |
| Firebase | Integración preparada; sin credenciales, la app arranca en modo local |
| iOS | Proyecto generado; requiere macOS/Xcode para compilar |

> La app no diagnostica, no interpreta automáticamente las emociones y no
> sustituye la atención psicológica profesional.

## Funcionalidades

- **Catálogo emocional** con seis grupos (asco, ira, tristeza, miedo, sorpresa y
  felicidad), descripciones y búsqueda sin distinción de mayúsculas ni tildes.
- **Emociones propias**: el paciente puede crear y eliminar palabras que no
  encuentre en el catálogo.
- **Diario emocional**: situación, varias emociones por registro, intensidad
  opcional de 0 a 10 para cada emoción, pensamiento, conducta y texto libre.
- **Varios registros por día**, con fecha y hora opcional del acontecimiento.
- **CRUD completo** de registros: crear, consultar, editar y eliminar.
- **Historial** agrupado por día y filtros combinables por fecha, intervalo,
  grupo emocional y emoción concreta.
- **Informe PDF diario** en A4 con cabecera, todos los registros del día, texto
  largo, acentos, numeración de páginas, nota de privacidad y pie con la fecha
  de generación. Vista previa, guardado en el dispositivo y compartición.
- **Modo local visible**: si Firebase no está configurado o falla, la app lo
  indica en la pantalla de inicio y en Configuración, y guarda los datos
  únicamente en el dispositivo.
- **Privacidad por diseño**: seudónimo en lugar de nombre real, aislamiento por
  paciente, sin credenciales en el repositorio y consentimiento informado en el
  alta.

## Requisitos

- Flutter 3.47 o superior (probado con Flutter 3.47.9 / Dart 3.13.7).
- Android SDK para compilar el APK.
- Xcode en macOS para compilar iOS.
- Opcional: un proyecto de Firebase propio para el modo conectado.

## Puesta en marcha rápida (modo local)

```bash
flutter pub get
flutter run
```

Sin argumentos adicionales la app arranca en **modo local**. Los datos se
guardan con `shared_preferences` en el propio dispositivo y no se envían a
ningún servidor.

## Compilar el APK

```bash
flutter build apk --debug
# o, para distribución:
flutter build apk --release
```

El APK se genera en `build/app/outputs/flutter-apk/`. Para publicar en tiendas o
distribuir fuera del equipo conviene configurar una firma de release propia
(ver [docs/TESTING.md](docs/TESTING.md#5-firma-de-release)).

## Conectar Firebase

1. Crea un proyecto de Firebase y habilita **Authentication > Anónimo** y
   **Cloud Firestore**.
2. Registra las apps Android/iOS con estos identificadores:
   - Android: `com.psicologia.diario_emocional`
   - iOS: `com.psicologia.diarioEmocional`
3. Copia `dart_defines.example.json` a `dart_defines.json` y rellena los valores
   de tu proyecto. Ese archivo está ignorado por Git.
4. Despliega `firestore.rules` y `firestore.indexes.json` con Firebase CLI.
5. Ejecuta:

```bash
flutter run --dart-define-from-file=dart_defines.json
flutter build apk --release --dart-define-from-file=dart_defines.json
```

Los pasos detallados están en [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md).
Si falta cualquier variable o la autenticación falla, la app **no simula** una
conexión: continúa en modo local y muestra el motivo.

## Estructura del proyecto

```text
lib/
  core/          configuración, tema, navegación, utilidades y servicios
  data/          repositorios locales/Firestore y servicio de PDF
  features/      pantallas por funcionalidad
  models/        modelos de dominio serializables
  state/         providers de Riverpod
  widgets/       componentes visuales reutilizables
assets/
  data/          catálogo emocional editable en JSON
  fonts/         Noto Sans (OFL) para los PDF
test/            pruebas unitarias, de repositorios, PDF y widget
docs/            arquitectura, Firebase, privacidad, pruebas y licencias
```

Más detalle en [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Datos y privacidad

- No se solicita nombre real, teléfono, correo ni localización.
- El perfil usa un seudónimo y un identificador técnico (UID anónimo de Firebase
  o UUID local).
- En Firestore cada paciente solo puede leer y escribir
  `users/{su UID}/...` gracias a las reglas incluidas.
- Los PDF se generan en el dispositivo y solo salen de él cuando el paciente usa
  Compartir o Guardar.
- La información completa para el paciente está en
  `lib/core/constants/privacy_text.dart` y la guía para el responsable del
  tratamiento en [docs/PRIVACY.md](docs/PRIVACY.md).

## Pruebas

```bash
flutter analyze
flutter test
```

Las pruebas cubren serialización, filtros, catálogo, CRUD local, aislamiento por
paciente, generación real de PDF y el flujo inicial de consentimiento. Ver
[docs/TESTING.md](docs/TESTING.md).

## Licencias

El código de la aplicación se distribuye bajo licencia MIT (ver [LICENSE](LICENSE)).
Las dependencias y la tipografía Noto Sans tienen sus propias licencias, todas
compatibles con uso open source; el detalle está en
[docs/LICENSES.md](docs/LICENSES.md).

## Limitaciones conocidas

- No hay backend propio ni panel para psicólogos: el paciente es quien comparte
  el PDF.
- El modo local no sincroniza entre dispositivos. Si se configura Firebase
  después, los datos locales no se migran automáticamente.
- La autenticación es anónima: si el paciente borra los datos de la app o cambia
  de dispositivo, pierde el acceso a la sesión anterior salvo que se implante un
  mecanismo de recuperación (fuera del alcance de esta versión).
- La compilación iOS requiere macOS y no se ha verificado en Windows.
