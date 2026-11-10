import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Identidad local usada cuando Firebase no está configurado.
///
/// El identificador es aleatorio y no contiene datos personales. Se conserva
/// en el dispositivo para que los registros sigan asociados al mismo paciente.
class LocalIdentity {
  LocalIdentity._();

  static const String _key = 'psico.localPatientId';

  static Future<String> patientId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_key);
    if (existing != null && existing.isNotEmpty) return existing;

    final generated = 'local_${const Uuid().v4()}';
    await prefs.setString(_key, generated);
    return generated;
  }
}
