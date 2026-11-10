import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../config/app_config.dart';
import 'local_identity.dart';

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

  /// `true` solo si Firebase está inicializado y hay sesión de autenticación.
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
    this.isAnonymous = true,
  });

  final String patientId;
  final FirebaseStatus firebaseStatus;
  final bool isAnonymous;

  bool get isFirebaseEnabled => firebaseStatus.enabled;
}

/// Inicializa Firebase si hay configuración y crea una sesión.
///
/// Reglas de seguridad del proyecto:
/// - Nunca se simula una conexión: si falla la inicialización o la
///   autenticación, la app pasa a modo local y lo indica claramente.
/// - Se usa autenticación anónima para no solicitar datos personales.
class FirebaseBootstrap {
  FirebaseBootstrap._();

  static Future<AppSession> initialize() async {
    if (!AppConfig.hasFirebaseConfig) {
      final id = await LocalIdentity.patientId();
      return AppSession(
        patientId: id,
        firebaseStatus: const FirebaseStatus.local(
          message:
              'Firebase no está configurado en esta compilación. '
              'Los datos se guardan únicamente en este dispositivo.',
        ),
      );
    }

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: AppConfig.firebaseOptions);
      }

      final auth = FirebaseAuth.instance;
      var user = auth.currentUser;
      user ??= (await auth.signInAnonymously()).user;

      if (user == null) {
        throw StateError('No se pudo crear la sesión anónima.');
      }

      return AppSession(
        patientId: user.uid,
        firebaseStatus: FirebaseStatus.connected(
          projectId: AppConfig.projectId,
        ),
      );
    } catch (error) {
      final id = await LocalIdentity.patientId();
      return AppSession(
        patientId: id,
        firebaseStatus: FirebaseStatus.local(
          message:
              'No se pudo conectar con Firebase (${_friendlyError(error)}). '
              'Se está usando el almacenamiento local de este dispositivo.',
        ),
      );
    }
  }

  static String _friendlyError(Object error) {
    if (error is FirebaseAuthException) {
      return 'autenticación: ${error.code}';
    }
    if (error is FirebaseException) {
      return '${error.plugin}: ${error.code}';
    }
    return 'error de conexión';
  }
}
