# Pruebas y compilación

Este documento recoge **lo que se ha ejecutado realmente** en la máquina de
desarrollo, lo que queda pendiente de verificar y una lista de comprobación
manual antes de entregar la app a pacientes.

## 1. Entorno de desarrollo

| Elemento | Valor |
| --- | --- |
| Sistema operativo | Windows (win32) |
| Flutter | 3.47.9 (stable) |
| Dart | 3.13.7 |
| Java | OpenJDK 17.0.11 |
| Android SDK | **No instalado** en esta máquina |
| Xcode / macOS | No disponible |

La ruta de Flutter usada en las comprobaciones es `C:\tools\flutter\bin\flutter.bat`.
Sustitúyela por `flutter` si lo tienes en el `PATH`.

## 2. Comprobaciones automáticas

Ejecutadas desde la raíz del proyecto:

```bash
C:\tools\flutter\bin\flutter.bat pub get
C:\tools\flutter\bin\flutter.bat analyze
C:\tools\flutter\bin\flutter.bat test
```

### Resultado

| Comando | Resultado |
| --- | --- |
| `flutter pub get` | Dependencias resueltas correctamente |
| `flutter analyze` | `No issues found!` |
| `flutter test` | `All tests passed!` (25 pruebas) |

### Cobertura de las pruebas

| Archivo | Qué comprueba |
| --- | --- |
| `test/models/emotional_record_test.dart` | Serialización completa, intensidad máxima, `copyWith`, límite 0–10 y combinación de filtros por fecha, grupo y emoción |
| `test/data/emotion_catalog_test.dart` | Los seis grupos del catálogo, identificadores únicos, búsqueda sin tildes ni mayúsculas, emociones propias y catálogo vacío |
| `test/data/local_repositories_test.dart` | CRUD local de registros, orden descendente, aislamiento por paciente, filtros al leer, perfil y emociones propias, recuperación ante JSON corrupto |
| `test/services/pdf_report_service_test.dart` | Generación real de un PDF (`%PDF`), informe de un día sin registros, orden por hora, nombre del archivo y filtrado por día |
| `test/widget_test.dart` | El alta aparece sin perfil, el modo local se indica de forma visible y no se puede continuar sin aceptar la privacidad |

Las pruebas de PDF cargan la tipografía Noto Sans incluida en `assets/fonts/`,
por lo que los acentos y símbolos se renderizan sin advertencias de glifos
faltantes.

> Las pruebas no acceden a Firebase. Los repositorios de Firestore requieren un
> proyecto real y credenciales, que no forman parte del repositorio.

## 3. Estado de la compilación

### Android

**No se ha generado un APK en esta máquina** porque no hay Android SDK
instalado (`ANDROID_HOME` vacío y no existe
`%LOCALAPPDATA%\Android\Sdk`). No se debe interpretar el proyecto como
"compilado" hasta completar estos pasos:

1. Instala Android Studio o las *command-line tools*.
2. Instala `platform-tools`, un `platform` reciente y `build-tools`.
3. Acepta las licencias:

   ```bash
   sdkmanager --licenses
   ```

4. Verifica el entorno:

   ```bash
   flutter doctor -v
   flutter devices
   ```

5. Compila:

   ```bash
   flutter build apk --debug
   # o
   flutter build apk --release
   ```

El APK se genera en `build/app/outputs/flutter-apk/`.

Si `flutter build apk` falla por versión de Java o de Gradle, revisa
`android/gradle/wrapper/gradle-wrapper.properties` (Gradle 9.3.1) y usa Java 17.

### iOS

El proyecto iOS está generado, pero **no se ha compilado**: requiere macOS,
Xcode y CocoaPods. En un Mac:

```bash
cd ios && pod install
flutter build ios --release
```

## 4. Lista de comprobación manual

Ejecuta estos casos en un dispositivo o emulador Android antes de entregar la
app. Marca solo lo que hayas verificado.

### Primer uso y privacidad

- [ ] La app arranca en modo local y lo indica en el alta y en Inicio.
- [ ] No se puede continuar sin aceptar la información de privacidad.
- [ ] El texto de privacidad se puede leer completo y sin cortes.
- [ ] El seudónimo se guarda y aparece en Inicio y en los PDF.
- [ ] Cambiar el seudónimo en Configuración actualiza Inicio y los informes.

### Catálogo y emociones propias

- [ ] Se ven los seis grupos: asco, ira, tristeza, miedo, sorpresa y felicidad.
- [ ] La búsqueda encuentra emociones con y sin tildes y con mayúsculas.
- [ ] Se puede crear una emoción propia en cualquier grupo.
- [ ] La emoción propia aparece en el grupo correcto y se puede usar en un
      registro.
- [ ] Se puede eliminar una emoción propia y desaparece del selector.
- [ ] Eliminar una emoción propia no rompe los registros antiguos que la usaban.

### Registros

- [ ] Se puede crear un registro con situación, al menos una emoción,
      pensamiento y conducta.
- [ ] Se pueden seleccionar varias emociones y asignar intensidad 0–10 a cada
      una.
- [ ] La intensidad es opcional y se puede quitar.
- [ ] Se puede añadir hora del acontecimiento y texto libre.
- [ ] Se pueden crear **varios registros el mismo día**.
- [ ] Editar un registro conserva sus datos y actualiza la fecha de modificación.
- [ ] Eliminar un registro pide confirmación y desaparece del historial.
- [ ] Cerrar y reabrir la app conserva todos los registros (modo local).

### Historial y filtros

- [ ] El historial agrupa los registros por día, del más reciente al más antiguo.
- [ ] El filtro por día concreto funciona.
- [ ] El filtro por intervalo de fechas funciona, incluidos los extremos.
- [ ] El filtro por grupo emocional funciona.
- [ ] El filtro por emoción concreta funciona.
- [ ] Los filtros se combinan y cada uno se puede quitar por separado.
- [ ] Los atajos de rango (hoy, últimos 7 días, etc.) seleccionan el rango
      correcto y se resaltan.
- [ ] Sin resultados se muestra un estado vacío claro.

### Informe PDF

- [ ] El informe incluye cabecera con departamento, seudónimo y fecha.
- [ ] Aparecen **todos** los registros del día, no solo el primero.
- [ ] Los textos largos continúan en la página siguiente sin recortarse.
- [ ] Los acentos, la eñe y los signos de apertura se ven correctamente.
- [ ] Las páginas están numeradas y el pie indica la fecha de generación.
- [ ] La nota de privacidad aparece en el informe.
- [ ] Un día sin registros genera un PDF válido y comprensible.
- [ ] La vista previa se puede cerrar y volver al historial.
- [ ] Guardar muestra la ruta o confirmación y el archivo se puede abrir.
- [ ] Compartir abre el diálogo del sistema con el PDF adjunto.
- [ ] El nombre del archivo sigue el patrón
      `diario_emocional_AAAA-MM-DD.pdf`.

### Configuración y datos

- [ ] El modo de almacenamiento (local o Firebase) se muestra con su estado.
- [ ] Si Firebase no está configurado, se listan las variables que faltan y no
      se simula una conexión.
- [ ] "Borrar todos mis datos locales" pide confirmación y deja la app como
      recién instalada.
- [ ] La app funciona sin conexión en modo local.
- [ ] Con Firebase configurado, dos cuentas distintas no ven datos ajenos
      (requiere proyecto real; ver `docs/FIREBASE_SETUP.md`).

### Accesibilidad y diseño

- [ ] La interfaz se adapta a pantallas pequeñas y a tablets.
- [ ] El texto no se corta con el tamaño de fuente del sistema aumentado.
- [ ] Los botones tienen etiquetas semánticas y contraste suficiente.
- [ ] El modo oscuro se ve legible (si está disponible).
- [ ] No hay texto en inglés en las pantallas principales.

## 5. Firma de release

El proyecto usa **la firma de depuración** para `release` por defecto
(`android/app/build.gradle.kts`). Eso sirve para probar, pero no para
distribuir.

1. Genera un almacén de claves (guárdalo fuera del repositorio):

   ```bash
   keytool -genkey -v -keystore diario-emocional.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias diario
   ```

2. Crea `android/key.properties` (ignorado por Git):

   ```properties
   storePassword=...
   keyPassword=...
   keyAlias=diario
   storeFile=C:/ruta/segura/diario-emocional.jks
   ```

3. En `android/app/build.gradle.kts`, carga el archivo y crea la configuración
   de firma:

   ```kotlin
   import java.util.Properties
   import java.io.FileInputStream

   val keystoreProperties = Properties()
   val keystorePropertiesFile = rootProject.file("key.properties")
   if (keystorePropertiesFile.exists()) {
     keystoreProperties.load(FileInputStream(keystorePropertiesFile))
   }

   android {
     signingConfigs {
       create("release") {
         keyAlias = keystoreProperties["keyAlias"] as String
         keyPassword = keystoreProperties["keyPassword"] as String
         storeFile = file(keystoreProperties["storeFile"] as String)
         storePassword = keystoreProperties["storePassword"] as String
       }
     }
     buildTypes {
       release {
         signingConfig = signingConfigs.getByName("release")
       }
     }
   }
   ```

4. Compila y verifica la firma:

   ```bash
   flutter build apk --release
   apksigner verify --print-certs build/app/outputs/flutter-apk/app-release.apk
   ```

Nunca subas `key.properties`, `*.jks` ni `*.keystore` al repositorio: ya están
en `.gitignore`.

## 6. Qué falta por verificar

| Elemento | Motivo |
| --- | --- |
| APK de Android | Android SDK no instalado en esta máquina |
| App iOS | Requiere macOS/Xcode |
| Conexión real a Firebase | No se han aportado credenciales ni proyecto |
| Sincronización entre dispositivos | Depende de Firebase y de un proyecto real |
| Restauración de sesión anónima | Depende de Firebase; no hay recuperación de cuenta en esta versión |

Cuando completes alguna de estas verificaciones, actualiza este documento con
la fecha, el dispositivo y el resultado exacto.
