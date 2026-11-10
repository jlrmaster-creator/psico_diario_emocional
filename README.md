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
| Compilación Android | APK **debug** y **release** generados con Android SDK 36 (ver [docs/TESTING.md](docs/TESTING.md)) |
| Instalación en móvil | Pendiente de probar en un dispositivo físico |
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

## Tecnologías utilizadas

| Área | Elección | Motivo |
| --- | --- | --- |
| Framework | Flutter 3.47 / Dart 3.13 | App Android e iOS real, UI adaptable y código abierto |
| Estado | Riverpod 3.5 (sin codegen) | Providers testeables y bajo acoplamiento |
| Persistencia local | `shared_preferences` | Funcionar sin infraestructura y sin backend propio |
| Nube | Firebase Authentication + Cloud Firestore | Sesión anónima y datos por paciente con reglas propias |
| PDF | `pdf` + `printing` + `file_saver` | A4 real, vista previa, guardado y compartición |
| Tipografía | Noto Sans (OFL) | Acentos y Unicode garantizados en el PDF |

## Requisitos

- Flutter 3.47 o superior (probado con Flutter 3.47.9 / Dart 3.13.7).
- Android SDK para compilar el APK.
- Xcode en macOS para compilar iOS.
- Opcional: un proyecto de Firebase propio para el modo conectado.

## Instalación

```bash
# 1. Clona el repositorio (o abre esta carpeta)
git clone <url-de-tu-repositorio>
cd Psico_app

# 2. Comprueba el entorno
flutter doctor -v

# 3. Descarga las dependencias
flutter pub get

# 4. Ejecuta en un dispositivo o emulador
flutter run
```

Sin configuración adicional la app arranca en **modo local**. Los datos se
guardan con `shared_preferences` en el propio dispositivo y no se envían a
ningún servidor.

## Compilar el APK

```bash
flutter build apk --debug
# o, para distribución:
flutter build apk --release
```

El APK se genera en `build/app/outputs/flutter-apk/`.

Compilaciones verificadas en Windows 11 con Android SDK 36 el 2026-11-10:

| Variante | Archivo | Tamaño |
| --- | --- | --- |
| Debug | `app-debug.apk` | 181,8 MB |
| Release | `app-release.apk` | 63,8 MB |

La primera compilación descarga Gradle, el NDK y CMake, por lo que puede tardar
bastante. Las siguientes son mucho más rápidas.

> El APK release está firmado con la **clave de depuración** para poder
> instalarlo sin configurar nada. Es válido para pruebas y uso interno, pero
> **no para Google Play**. Para distribuir de forma profesional configura una
> firma propia (ver [docs/TESTING.md](docs/TESTING.md#5-firma-de-release)).

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

### Variables de configuración

Se pasan en tiempo de compilación con `--dart-define-from-file`. No se guardan
en el código ni en el repositorio.

| Variable | Obligatoria | Descripción |
| --- | --- | --- |
| `FIREBASE_API_KEY` | Sí | Clave pública de la app en Firebase |
| `FIREBASE_PROJECT_ID` | Sí | Identificador del proyecto |
| `FIREBASE_MESSAGING_SENDER_ID` | Sí | Número de remitente del proyecto |
| `FIREBASE_STORAGE_BUCKET` | Sí | Bucket de almacenamiento |
| `FIREBASE_ANDROID_APP_ID` | Sí en Android | ID de la app Android |
| `FIREBASE_IOS_APP_ID` | Sí en iOS | ID de la app iOS |
| `FIREBASE_AUTH_DOMAIN` | No | Dominio de autenticación (web/otros) |
| `FIREBASE_IOS_BUNDLE_ID` | No | Bundle ID de iOS (por defecto el del proyecto) |

El archivo `dart_defines.example.json` contiene todos los nombres con valores de
ejemplo. Copia, rellena y no lo subas: `dart_defines.json` está ignorado por Git.

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

## Futuras ampliaciones

La arquitectura está preparada para añadir módulos sin tocar el núcleo:

- **Nuevo módulo terapéutico**: crea `lib/features/<modulo>/`, añade su ruta en
  `lib/core/navigation/app_navigation.dart` y su acceso desde Inicio.
- **Nuevas emociones o grupos**: edita `assets/data/emotions_catalog.json`; no
  hace falta recompilar la lógica de la interfaz. Los grupos deben tener un
  `id`, `name`, `description` y una lista de `emotions`.
- **Nuevo backend**: implementa las interfaces de `lib/data/repositories/` y
  selecciona la implementación en `lib/state/providers.dart`.
- **Recordatorios**: añade notificaciones locales y un provider de
  configuración; no requiere cambiar el modelo de registros.
- **Panel para profesionales**: exigiría autenticación con roles, reglas de
  Firestore específicas y revisión legal; no forma parte de esta versión.
- **Exportación adicional**: el servicio de PDF es independiente de la UI, por
  lo que se puede reutilizar para informes semanales o mensuales.

Antes de ampliar el esquema de datos, actualiza `docs/FIRESTORE.md` y prueba la
migración con datos anonimizados.

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
