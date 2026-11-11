import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Configuración de la aplicación.
///
/// Las credenciales de Firebase NO se guardan en el repositorio. Se pasan en
/// tiempo de compilación mediante `--dart-define-from-file` (ver
/// `dart_defines.example.json` y `docs/FIREBASE_SETUP.md`).
class AppConfig {
  AppConfig._();

  static const String appName = 'Diario Emocional';
  static const String defaultDepartmentName = 'Departamento de Psicología';
  static const String appVersion = '1.0.0';
  static const String privacyVersion = '2026-11.1';

  static const String _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const String _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const String _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const String _authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
  );
  static const String _androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
  );
  static const String _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');

  static String get projectId => _projectId;

  static bool get hasFirebaseConfig {
    if (_apiKey.isEmpty ||
        _projectId.isEmpty ||
        _messagingSenderId.isEmpty ||
        _storageBucket.isEmpty) {
      return false;
    }
    return firebaseOptions != null;
  }

  /// Opciones de Firebase para la plataforma actual.
  ///
  /// Android e iOS usan identificadores de aplicación distintos, por eso se
  /// solicitan por separado. En el resto de plataformas la app funciona en
  /// modo local.
  static FirebaseOptions? get firebaseOptions {
    if (kIsWeb) return null;

    if (defaultTargetPlatform == TargetPlatform.android) {
      if (_androidAppId.isEmpty) return null;
      return FirebaseOptions(
        apiKey: _apiKey,
        appId: _androidAppId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
        authDomain: _authDomain.isEmpty ? null : _authDomain,
      );
    }

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      if (_iosAppId.isEmpty) return null;
      return FirebaseOptions(
        apiKey: _apiKey,
        appId: _iosAppId,
        messagingSenderId: _messagingSenderId,
        projectId: _projectId,
        storageBucket: _storageBucket,
        authDomain: _authDomain.isEmpty ? null : _authDomain,
        iosBundleId: String.fromEnvironment(
          'FIREBASE_IOS_BUNDLE_ID',
          defaultValue: 'com.psicologia.diarioEmocional',
        ),
      );
    }

    return null;
  }

  /// Lista de variables que faltan, útil para la pantalla de configuración.
  static List<String> get missingFirebaseVariables {
    final missing = <String>[];
    if (_apiKey.isEmpty) missing.add('FIREBASE_API_KEY');
    if (_projectId.isEmpty) missing.add('FIREBASE_PROJECT_ID');
    if (_messagingSenderId.isEmpty) missing.add('FIREBASE_MESSAGING_SENDER_ID');
    if (_storageBucket.isEmpty) missing.add('FIREBASE_STORAGE_BUCKET');
    if (defaultTargetPlatform == TargetPlatform.android &&
        _androidAppId.isEmpty) {
      missing.add('FIREBASE_ANDROID_APP_ID');
    }
    if (defaultTargetPlatform == TargetPlatform.iOS && _iosAppId.isEmpty) {
      missing.add('FIREBASE_IOS_APP_ID');
    }
    return missing;
  }
}
