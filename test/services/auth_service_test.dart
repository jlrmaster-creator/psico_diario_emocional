import 'package:diario_emocional/core/services/auth_service.dart';
import 'package:diario_emocional/core/utils/validators.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestAuthException extends FirebaseAuthException {
  _TestAuthException(String code) : super(code: code);
}

void main() {
  group('authErrorMessage', () {
    test('traduce credenciales incorrectas', () {
      expect(
        authErrorMessage(_TestAuthException('wrong-password')),
        'Correo o contraseña incorrectos.',
      );
      expect(
        authErrorMessage(_TestAuthException('invalid-credential')),
        'Correo o contraseña incorrectos.',
      );
    });

    test('traduce correo ya registrado', () {
      expect(
        authErrorMessage(_TestAuthException('email-already-in-use')),
        'Ya existe una cuenta con ese correo electrónico.',
      );
    });

    test('traduce falta de red', () {
      expect(
        authErrorMessage(_TestAuthException('network-request-failed')),
        'No hay conexión a internet. Comprueba tu red.',
      );
    });

    test('traduce proveedor deshabilitado', () {
      expect(
        authErrorMessage(_TestAuthException('operation-not-allowed')),
        'El acceso con correo y contraseña no está habilitado en Firebase.',
      );
    });

    test('incluye el código en errores desconocidos', () {
      expect(
        authErrorMessage(_TestAuthException('algo-raro')),
        contains('algo-raro'),
      );
    });

    test('devuelve un mensaje genérico para errores que no son de Auth', () {
      expect(
        authErrorMessage(StateError('fallo')),
        'No se pudo completar la operación. Inténtalo de nuevo.',
      );
    });
  });

  group('Validators.email', () {
    test('acepta correos válidos', () {
      expect(Validators.email('luna@ejemplo.com'), isNull);
      expect(Validators.email('a.b+c@sub.dominio.es'), isNull);
    });

    test('rechaza correos inválidos', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('sin-arroba'), isNotNull);
      expect(Validators.email('sin@dominio'), isNotNull);
      expect(Validators.email('con espacio@ejemplo.com'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('exige al menos 8 caracteres', () {
      expect(Validators.password('1234567'), isNotNull);
      expect(Validators.password('12345678'), isNull);
    });

    test('rechaza contraseñas vacías o demasiado largas', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('a' * 129), isNotNull);
    });
  });
}
