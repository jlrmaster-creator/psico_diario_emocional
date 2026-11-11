# Arquitectura

## Visión general

La app sigue una separación por capas sencilla, sin generación de código y con
Riverpod como único gestor de estado.

```text
UI (features/ + widgets/)
        │  watch/read
        ▼
Estado (state/providers.dart)
        │  interfaces
        ▼
Repositorios (data/repositories/)
        │
        ├── Local*        shared_preferences
        └── Firestore*    Cloud Firestore
        ▼
Modelos (models/)
```

La capa de UI no conoce si los datos vienen de Firestore o de
`shared_preferences`: los providers deciden el repositorio a partir de
`AppSession`.

## Arranque

1. `main.dart` inicializa los datos de locale español (`initializeDateFormatting`).
2. `firebaseRuntimeProvider` ejecuta `FirebaseBootstrap.initialize()`, que
   comprueba si existen las variables `--dart-define` necesarias.
   - Si no existen: crea/recupera un identificador local y devuelve una sesión en
     **modo local**.
   - Si existen: inicializa Firebase y devuelve el modo **firebase**.
   - Si Firebase falla: devuelve un error y la app muestra una pantalla de
     reintento. Nunca se presenta como conectado ni se cae a modo local.
3. En modo Firebase, `AppRoot` observa `authStateProvider`. Sin usuario muestra
   `AuthScreen` (acceso, registro y recuperación de contraseña); con usuario
   carga el perfil.
4. `AppRoot` observa `profileProvider`: si no hay perfil muestra el alta; si lo
   hay, muestra la pantalla principal.
5. `appSessionProvider` combina el modo de almacenamiento con la cuenta activa:
   usa el UID de Firebase como `patientId` o el UUID local en modo local.

## Estado

| Provider | Tipo | Responsabilidad |
| --- | --- | --- |
| `firebaseRuntimeProvider` | `FutureProvider` | Inicialización de Firebase y modo de almacenamiento |
| `authStateProvider` | `StreamProvider` | Usuario autenticado o `null` |
| `authServiceProvider` | `Provider` | Acceso, registro, recuperación y cierre de sesión |
| `appSessionProvider` | `Provider` | Sesión y modo de almacenamiento derivados de Firebase o de la identidad local |
| `recordRepositoryProvider` | `Provider` | Elige repositorio local o Firestore |
| `profileRepositoryProvider` | `Provider` | Perfil local o Firestore |
| `catalogRepositoryProvider` | `Provider` | Emociones personalizadas |
| `profileProvider` | `AsyncNotifierProvider` | Alta, edición y recarga del perfil |
| `catalogProvider` | `AsyncNotifierProvider` | Catálogo base + emociones propias |
| `recordsProvider` | `AsyncNotifierProvider` | Lista completa de registros |
| `recentRecordsProvider` | `Provider` | Últimos tres registros para el inicio |
| `recordFilterProvider` | `NotifierProvider` | Filtro activo del historial |
| `filteredRecordsProvider` | `Provider` | Registros que cumplen el filtro |
| `pdfReportServiceProvider` | `Provider` | Servicio de generación de PDF |

Se usa `AsyncNotifier` sin `riverpod_generator` para mantener el proyecto
legible sin pasos de build adicionales.

## Modelos

- `Emotion` y `EmotionGroup` / `EmotionCatalog`: catálogo cargado desde
  `assets/data/emotions_catalog.json` y enriquecido con emociones propias.
- `SelectedEmotion`: copia del nombre y grupo en el momento del registro, más la
  intensidad opcional. Así un registro histórico sigue siendo legible aunque el
  catálogo cambie.
- `EmotionalRecord`: situación, emociones, pensamiento, conducta, texto libre,
  fecha del acontecimiento, hora opcional y marcas de creación/edición.
- `RecordFilter`: combina rango de fechas, grupo y emoción.
- `PatientProfile`: seudónimo, departamento, fechas técnicas y aceptación de
  privacidad.

Todos los modelos tienen `toJson`/`fromJson` y toleran campos ausentes para
facilitar migraciones.

## Persistencia

### Modo local

`shared_preferences` guarda un JSON por clave y paciente:

- `psico.records.{patientId}`
- `psico.profile.{patientId}`
- `psico.customEmotions.{patientId}`
- `psico.localPatientId` (identificador aleatorio)

Si un JSON local está corrupto, se copia a `*.corrupt` y se devuelve una lista
vacía para no bloquear la app.

### Firestore

- `users/{uid}` — perfil.
- `users/{uid}/records/{recordId}` — registros.
- `users/{uid}/customEmotions/{emotionId}` — emociones propias.

Las fechas se guardan como `Timestamp` en Firestore y se normalizan a
`DateTime` en el repositorio. Los filtros se aplican en el cliente para evitar
índices compuestos y mantener el historial disponible sin conexión.

## PDF

`PdfReportService` usa `pdf` y `printing`. Genera un A4 con `MultiPage`:

- cabecera con departamento, paciente, fecha y número de registros;
- todos los registros del día ordenados por hora;
- emociones con intensidad y textos largos;
- pie con nota de privacidad y `Página X de Y`;
- tipografía **Noto Sans** incluida en `assets/fonts` para acentos y símbolos.

La vista previa usa `PdfPreview`; guardar usa `file_saver`; compartir usa
`Printing.sharePdf`.

## Navegación

`AppNavigation` centraliza las rutas con `MaterialPageRoute`. No se usa
`go_router` para mantener el árbol de dependencias pequeño; la app no necesita
deep links en esta versión.

## Decisiones y compromisos

- **Sin codegen**: menos herramientas y builds más simples; a cambio, los
  providers se escriben a mano.
- **Filtros en cliente**: menor complejidad y ningún índice compuesto; suficiente
  para el volumen esperado de un diario personal.
- **Autenticación con correo y contraseña**: permite recuperar la cuenta y
  mantener la continuidad entre dispositivos. Como contrapartida, se trata un
  dato personal adicional (el correo) que se limita a la autenticación.
- **Modo local primero**: la app es útil sin infraestructura y el modo se indica
  de forma explícita para no dar una falsa sensación de sincronización.
- **Sin panel clínico**: el paciente decide qué PDF comparte. Un portal para
  profesionales requeriría autenticación adicional, roles y revisión legal.
