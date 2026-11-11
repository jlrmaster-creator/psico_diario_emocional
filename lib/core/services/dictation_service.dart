import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

/// Envoltorio delgado sobre `speech_to_text`.
///
/// La app solo necesita dictado en español, con resultados parciales para que
/// el texto aparezca mientras se habla. El servicio se inicializa la primera
/// vez que se pulsa el micrófono y nunca se usa para escuchar sin que la
/// persona lo pida.
///
/// La privacidad importa: el reconocimiento lo realiza el servicio de voz del
/// sistema operativo y puede procesar el audio en línea. Por eso el dictado es
/// siempre opcional y escribir con el teclado sigue disponible.
class DictationService {
  DictationService({SpeechToText? speech}) : _speech = speech ?? SpeechToText();

  final SpeechToText _speech;

  bool _initialized = false;
  bool _listening = false;
  String? _localeId;
  bool _localeResolved = false;

  void Function(SpeechRecognitionError error)? _onError;
  void Function(bool listening)? _onListeningChanged;

  /// Si el micrófono está escuchando en este momento.
  bool get isListening => _listening;

  /// Inicializa el reconocimiento una sola vez y registra los avisos.
  ///
  /// Devuelve `false` cuando el dispositivo no ofrece reconocimiento de voz o
  /// cuando la persona deniega el permiso del micrófono.
  Future<bool> initialize({
    required void Function(SpeechRecognitionError error) onError,
    required void Function(bool listening) onListeningChanged,
  }) async {
    _onError = onError;
    _onListeningChanged = onListeningChanged;

    if (_initialized) return true;

    try {
      _initialized = await _speech.initialize(
        onError: (error) {
          _setListening(false);
          _onError?.call(error);
        },
        onStatus: (status) {
          _setListening(status == 'listening');
        },
      );
    } catch (error) {
      debugPrint('No se pudo inicializar el dictado: $error');
      _initialized = false;
    }

    return _initialized;
  }

  /// Empieza a escuchar y entrega el texto reconocido.
  ///
  /// [onResult] recibe las palabras de la sesión actual y si el resultado es
  /// definitivo. Los resultados parciales se sustituyen entre sí, así que el
  /// campo debe combinar el texto previo con las palabras recibidas.
  Future<bool> start({
    required void Function(String words, bool isFinal) onResult,
  }) async {
    if (!_initialized) return false;

    try {
      if (_speech.isListening) {
        await _speech.stop();
      }
      await _resolveSpanishLocale();
      await _speech.listen(
        onResult: (SpeechRecognitionResult result) {
          _setListening(!result.finalResult);
          onResult(result.recognizedWords, result.finalResult);
        },
        listenOptions: SpeechListenOptions(
          localeId: _localeId,
          listenMode: ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
          autoPunctuation: true,
          pauseFor: const Duration(seconds: 5),
          listenFor: const Duration(minutes: 2),
        ),
      );
      _setListening(true);
      return true;
    } catch (error) {
      debugPrint('No se pudo iniciar el dictado: $error');
      _setListening(false);
      return false;
    }
  }

  /// Termina el dictado conservando lo reconocido hasta ahora.
  Future<void> stop() async {
    if (!_initialized) return;
    try {
      await _speech.stop();
    } catch (error) {
      debugPrint('No se pudo detener el dictado: $error');
    }
    _setListening(false);
  }

  /// Cancela el dictado sin esperar un resultado final.
  Future<void> cancel() async {
    if (!_initialized) return;
    try {
      await _speech.cancel();
    } catch (error) {
      debugPrint('No se pudo cancelar el dictado: $error');
    }
    _setListening(false);
  }

  void _setListening(bool value) {
    if (_listening == value) return;
    _listening = value;
    _onListeningChanged?.call(value);
  }

  Future<void> _resolveSpanishLocale() async {
    if (_localeResolved) return;
    _localeResolved = true;

    try {
      final locales = await _speech.locales();
      final spanish = locales
          .where((locale) => _languageCode(locale.localeId) == 'es')
          .toList(growable: false);
      if (spanish.isEmpty) return;

      for (final preferred in const [
        'es_es',
        'es_419',
        'es_us',
        'es_mx',
        'es_ar',
      ]) {
        for (final locale in spanish) {
          if (_normalize(locale.localeId) == preferred) {
            _localeId = locale.localeId;
            return;
          }
        }
      }

      _localeId = spanish.first.localeId;
    } catch (error) {
      debugPrint('No se pudieron consultar los idiomas de dictado: $error');
    }
  }

  static String _normalize(String localeId) =>
      localeId.replaceAll('-', '_').toLowerCase();

  static String _languageCode(String localeId) {
    final normalized = _normalize(localeId);
    final separator = normalized.indexOf('_');
    return separator == -1 ? normalized : normalized.substring(0, separator);
  }

  /// Combina el texto que ya había en el campo con lo dictado.
  ///
  /// Los resultados parciales llegan como la frase completa de la sesión, por
  /// eso se añaden al texto previo en lugar de acumularse entre sí.
  static String appendText(String base, String words) {
    final dictated = words.trim();
    if (dictated.isEmpty) return base;
    if (base.trim().isEmpty) return dictated;
    final separator = RegExp(r'\s$').hasMatch(base) ? '' : ' ';
    return '$base$separator$dictated';
  }

  /// Mensaje en español para cada error del servicio de voz.
  ///
  /// Siempre recuerda que se puede escribir con el teclado, sin presionar a la
  /// persona a repetir el dictado.
  static String messageForError(SpeechRecognitionError error) {
    switch (error.errorMsg) {
      case 'error_permission':
        return 'No hay permiso para usar el micrófono. Puedes activarlo en los ajustes del teléfono o escribir el texto.';
      case 'error_no_match':
      case 'error_speech_timeout':
        return 'No se ha entendido el audio. Puedes intentarlo otra vez o escribir el texto.';
      case 'error_network':
      case 'error_network_timeout':
        return 'El servicio de voz no tiene conexión en este momento. Puedes escribir el texto con el teclado.';
      case 'error_busy':
        return 'El micrófono está ocupado por otra aplicación. Inténtalo de nuevo en un momento o escribe el texto.';
      case 'error_audio_error':
        return 'No se ha podido acceder al micrófono. Puedes escribir el texto con el teclado.';
      case 'error_server':
      case 'error_server_disconnected':
        return 'El servicio de voz no está disponible ahora mismo. Puedes escribir el texto con el teclado.';
      default:
        return error.permanent
            ? 'El dictado no está disponible en este dispositivo. Puedes escribir el texto con el teclado.'
            : 'No se ha podido dictar. Puedes intentarlo otra vez o escribir el texto.';
    }
  }

  /// Mensaje cuando el dispositivo no ofrece dictado.
  static const String unavailableMessage =
      'Este dispositivo no ofrece dictado por voz. Puedes escribir el texto con el teclado.';

  /// Aviso breve que se muestra junto al micrófono.
  static const String privacyNote =
      'El dictado usa el servicio de voz del sistema y puede enviar el audio a sus servidores. Si lo prefieres, escribe con el teclado.';
}
