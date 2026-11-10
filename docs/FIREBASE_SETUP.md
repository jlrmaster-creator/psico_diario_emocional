# Configuración de Firebase

La app **no incluye** un proyecto de Firebase, credenciales ni archivos
`google-services.json` / `GoogleService-Info.plist`. Todo lo necesario se aporta
en tiempo de compilación mediante `--dart-define-from-file`.

## 1. Crear el proyecto

1. Entra en <https://console.firebase.google.com/> y crea un proyecto.
2. En **Authentication > Sign-in method**, habilita el proveedor **Anónimo**.
3. En **Firestore Database**, crea una base de datos en modo producción.
4. Elige una ubicación cercana a los usuarios (por ejemplo, `europe-west1` o
   `europe-southwest1`) y revisa las implicaciones de residencia de datos con el
   responsable del tratamiento.

## 2. Registrar las aplicaciones

### Android

- Nombre del paquete: `com.psicologia.diario_emocional`
- Puedes obtener la huella SHA-1 con:

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey \
  -storepass android -keypass android
```

No es imprescindible para Firestore, pero sí para otros servicios de Firebase.

### iOS

- Bundle ID: `com.psicologia.diarioEmocional`

## 3. Rellenar las variables

Copia el archivo de ejemplo y edítalo:

```bash
cp dart_defines.example.json dart_defines.json
```

```json
{
  "FIREBASE_API_KEY": "AIza...",
  "FIREBASE_PROJECT_ID": "mi-proyecto",
  "FIREBASE_MESSAGING_SENDER_ID": "123456789012",
  "FIREBASE_STORAGE_BUCKET": "mi-proyecto.firebasestorage.app",
  "FIREBASE_AUTH_DOMAIN": "mi-proyecto.firebaseapp.com",
  "FIREBASE_ANDROID_APP_ID": "1:123456789012:android:abcdef123456",
  "FIREBASE_IOS_APP_ID": "1:123456789012:ios:abcdef123456",
  "FIREBASE_IOS_BUNDLE_ID": "com.psicologia.diarioEmocional"
}
```

Puedes obtener estos valores en **Configuración del proyecto > Tus apps** o
ejecutando `flutterfire configure` (opcional; la app no depende de
`firebase_options.dart`).

> `dart_defines.json` está en `.gitignore`. No lo subas al repositorio ni lo
> adjuntes en incidencias.

## 4. Desplegar reglas e índices

Con Firebase CLI instalado y autenticado:

```bash
firebase login
firebase use --add            # selecciona tu proyecto
firebase deploy --only firestore:rules,firestore:indexes
```

Los archivos están en la raíz del repositorio:

- `firestore.rules`
- `firestore.indexes.json`

## 5. Ejecutar y compilar

```bash
flutter run --dart-define-from-file=dart_defines.json
flutter build apk --release --dart-define-from-file=dart_defines.json
```

## Comportamiento si algo falla

`AppConfig.hasFirebaseConfig` exige `API_KEY`, `PROJECT_ID`,
`MESSAGING_SENDER_ID`, `STORAGE_BUCKET` y el APP_ID de la plataforma. Si falta
algo, la app arranca en **modo local** y lo muestra.

Si la inicialización o el inicio de sesión anónimo fallan, `FirebaseBootstrap`
captura el error, usa un identificador local y muestra el motivo en
Configuración. La app nunca marca Firebase como conectado sin una sesión real.

## Checklist antes de producción

- [ ] Authentication anónimo habilitado.
- [ ] Firestore en modo producción con las reglas de este repositorio.
- [ ] Índices desplegados (el archivo actual no requiere índices compuestos).
- [ ] Variables de Firebase revisadas para Android e iOS.
- [ ] Firma de release configurada (no usar la firma debug).
- [ ] Política de privacidad revisada por el responsable del tratamiento.
- [ ] Copias de seguridad y plazo de conservación definidos.
- [ ] Prueba real con dos cuentas para verificar el aislamiento de datos.
- [ ] Revisión de costes y cuotas de Firestore.
