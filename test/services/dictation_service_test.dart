import 'package:diario_emocional/core/services/dictation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_recognition_error.dart';

void main() {
  group('appendText', () {
    test('añade lo dictado al texto que ya existía', () {
      expect(
        DictationService.appendText('Me sentí cansada.', 'y necesitaba parar'),
        'Me sentí cansada. y necesitaba parar',
      );
    });

    test('no duplica espacios al final del texto previo', () {
      expect(
        DictationService.appendText('Me sentí cansada. ', 'y necesitaba parar'),
        'Me sentí cansada. y necesitaba parar',
      );
    });

    test('usa solo lo dictado cuando el campo está vacío', () {
      expect(
        DictationService.appendText('   ', '  una tarde tranquila  '),
        'una tarde tranquila',
      );
    });

    test('mantiene el texto previo si no se reconoce nada', () {
      expect(
        DictationService.appendText('Texto escrito', '   '),
        'Texto escrito',
      );
    });
  });

  group('messageForError', () {
    test('explica el permiso denegado y recuerda el teclado', () {
      final message = DictationService.messageForError(
        SpeechRecognitionError('error_permission', true),
      );

      expect(message, contains('permiso'));
      expect(message, contains('escribir'));
    });

    test('explica un fallo de conexión sin presionar a repetir', () {
      final message = DictationService.messageForError(
        SpeechRecognitionError('error_network', false),
      );

      expect(message, contains('conexión'));
      expect(message, contains('escribir'));
    });

    test('traduce el silencio o audio no entendido', () {
      final message = DictationService.messageForError(
        SpeechRecognitionError('error_speech_timeout', false),
      );

      expect(message, contains('No se ha entendido'));
    });

    test('usa un mensaje tranquilo para errores desconocidos', () {
      final message = DictationService.messageForError(
        SpeechRecognitionError('error_desconocido', false),
      );

      expect(message, contains('escribir'));
    });

    test(
      'indica que el dictado no está disponible si el error es permanente',
      () {
        final message = DictationService.messageForError(
          SpeechRecognitionError('error_desconocido', true),
        );

        expect(message, contains('no está disponible'));
        expect(message, contains('teclado'));
      },
    );
  });
}
