import 'package:firebase_auth/firebase_auth.dart';

/// Operaciones de autenticación que utiliza la interfaz.
///
/// Se define como interfaz para poder sustituirla en las pruebas sin
/// depender de una instancia real de Firebase.
abstract class AuthApi {
  Future<void> signIn({required String email, required String password});

  Future<void> register({required String email, required String password});

  Future<void> sendPasswordReset(String email);

  Future<void> signOut();
}

/// Implementación real sobre Firebase Authentication.
///
/// El acceso es con correo y contraseña. El correo se guarda en Firebase
/// Authentication únicamente para identificar la cuenta; no se copia a
/// Firestore ni a los registros emocionales.
class FirebaseAuthService implements AuthApi {
  FirebaseAuthService(this._auth);

  final FirebaseAuth _auth;

  @override
  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> register({
    required String email,
    required String password,
  }) async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> sendPasswordReset(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
  }

  @override
  Future<void> signOut() => _auth.signOut();
}

/// Traduce los errores de Firebase Authentication a mensajes en español.
String authErrorMessage(Object error) {
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return 'El correo electrónico no tiene un formato válido.';
      case 'user-disabled':
        return 'Esta cuenta está desactivada. Contacta con tu psicólogo/a.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Ya existe una cuenta con ese correo electrónico.';
      case 'weak-password':
        return 'La contraseña es demasiado débil. Usa al menos 8 caracteres.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera unos minutos y vuelve a probar.';
      case 'network-request-failed':
        return 'No hay conexión a internet. Comprueba tu red.';
      case 'operation-not-allowed':
        return 'El acceso con correo y contraseña no está habilitado en Firebase.';
      case 'requires-recent-login':
        return 'Por seguridad, vuelve a iniciar sesión.';
      default:
        return 'No se pudo completar la operación (${error.code}).';
    }
  }
  return 'No se pudo completar la operación. Inténtalo de nuevo.';
}
