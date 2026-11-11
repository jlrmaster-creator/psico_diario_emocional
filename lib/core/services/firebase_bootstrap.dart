import 'package:firebase_core/firebase_core.dart';

import '../config/app_config.dart';
import 'local_identity.dart';

/// Modo de funcionamiento de la aplicación.
enum FirebaseMode { local, firebase, error }

/// Resultado de la inicialización de Firebase.
class FirebaseRuntime {
  const FirebaseRuntime._({
    required this.mode,
    this.localPatientId,
    this.projectId,
    this.message,
  });

  const FirebaseRuntime.local({required String patientId})
    : this._(mode: FirebaseMode.local, localPatientId: patientId);

  const FirebaseRuntime.firebase({required String projectId})
    : this._(mode: FirebaseMode.firebase, projectId: projectId);

  const FirebaseRuntime.error(String message)
    : this._(mode: FirebaseMode.error, message: message);

  final FirebaseMode mode;

  /// Identificador aleatorio usado cuando no hay Firebase configurado.
  final String? localPatientId;

  final String? projectId;

  /// Motivo legible cuando la inicialización falla.
  final String? message;

  bool get isFirebase => mode == FirebaseMode.firebase;
}

/// Estado de la conexión con Firebase.
class FirebaseStatus {
  const FirebaseStatus._({
    required this.enabled,
    required this.isLocalFallback,
    this.projectId,
    this.message,
  });

  const FirebaseStatus.connected({required String projectId})
    : this._(enabled: true, isLocalFallback: false, projectId: projectId);

  const FirebaseStatus.local({String? message})
    : this._(enabled: false, isLocalFallback: true, message: message);

  /// `true` solo si Firebase está inicializado y hay sesión iniciada.
  final bool enabled;

  /// `true` si la app está usando almacenamiento local en este dispositivo.
  final bool isLocalFallback;

  final String? projectId;
  final String? message;

  String get shortLabel => enabled ? 'Firebase conectado' : 'Modo local';
}

/// Sesión de la aplicación: identifica al paciente y el modo de almacenamiento.
class AppSession {
  const AppSession({
    required this.patientId,
    required this.firebaseStatus,
    this.email,
  });

  final String patientId;
  final FirebaseStatus firebaseStatus;

  /// Correo de la cuenta autenticada. `null` en modo local.
  final String? email;

  bool get isFirebaseEnabled => firebaseStatus.enabled;
}

/// Inicializa Firebase si hay configuración válida.
///
/// No crea sesiones de forma automática: con Firebase configurado, la app
/// exige iniciar sesión con correo y contraseña. Si no hay configuración,
/// funciona en modo local y lo indica claramente en la interfaz.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static Future<FirebaseRuntime> initialize() async {
    if (!AppConfig.hasFirebaseConfig) {
      return FirebaseRuntime.local(patientId: await LocalIdentity.patientId());
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: AppConfig.firebaseOptions);
      }
      return FirebaseRuntime.firebase(projectId: AppConfig.projectId);
    } catch (error) {
      return FirebaseRuntime.error(_friendlyError(error));
    }
  }

  static String _friendlyError(Object error) {
    if (error is FirebaseException) {
      return '${error.plugin}: ${error.code}';
    }
    return 'No se pudo inicializar Firebase.';
  }
}
