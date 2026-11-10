import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/app_exception.dart';
import '../../models/patient_profile.dart';
import 'profile_repository.dart';

class LocalProfileRepository implements ProfileRepository {
  LocalProfileRepository({SharedPreferences? preferences})
    : _providedPreferences = preferences;

  final SharedPreferences? _providedPreferences;

  static String _key(String patientId) => 'psico.profile.$patientId';

  Future<SharedPreferences> get _prefs async =>
      _providedPreferences ?? await SharedPreferences.getInstance();

  @override
  Future<PatientProfile?> load(String patientId) async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(_key(patientId));
      if (raw == null || raw.isEmpty) return null;
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return PatientProfile.fromJson(decoded);
    } catch (error) {
      throw StorageException(
        'No se pudo leer el perfil guardado en este dispositivo.',
        cause: error,
      );
    }
  }

  @override
  Future<void> save(PatientProfile profile) async {
    try {
      final prefs = await _prefs;
      final saved = await prefs.setString(
        _key(profile.patientId),
        jsonEncode(profile.toJson()),
      );
      if (!saved) {
        throw const StorageException(
          'No se pudo guardar el perfil en este dispositivo.',
        );
      }
    } on StorageException {
      rethrow;
    } catch (error) {
      throw StorageException(
        'No se pudo guardar el perfil en este dispositivo.',
        cause: error,
      );
    }
  }
}
