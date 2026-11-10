import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/app_exception.dart';
import '../../models/emotional_record.dart';
import '../../models/record_filter.dart';
import 'emotional_record_repository.dart';

/// Repositorio local basado en `SharedPreferences`.
///
/// Se usa cuando Firebase no está configurado o no se pudo conectar. Permite
/// que la aplicación sea funcional desde el primer momento y que los datos
/// sobrevivan al cierre de la app.
class LocalEmotionalRecordRepository implements EmotionalRecordRepository {
  LocalEmotionalRecordRepository({SharedPreferences? preferences})
    : _providedPreferences = preferences;

  final SharedPreferences? _providedPreferences;

  static String _key(String patientId) => 'psico.records.$patientId';

  Future<SharedPreferences> get _prefs async =>
      _providedPreferences ?? await SharedPreferences.getInstance();

  @override
  Future<List<EmotionalRecord>> fetchRecords({
    required String patientId,
    RecordFilter filter = const RecordFilter(),
  }) async {
    try {
      final prefs = await _prefs;
      final records = (await _readAll(
        prefs,
        patientId,
      )).where(filter.matches).toList();

      records.sort(_compareRecords);
      return records;
    } catch (error) {
      throw StorageException(
        'No se pudo leer el diario guardado en este dispositivo.',
        cause: error,
      );
    }
  }

  @override
  Future<void> upsertRecord(EmotionalRecord record) async {
    try {
      final prefs = await _prefs;
      final records = await _readAll(prefs, record.patientId);

      final index = records.indexWhere((item) => item.id == record.id);
      if (index >= 0) {
        records[index] = record;
      } else {
        records.add(record);
      }

      records.sort(_compareRecords);
      final encoded = jsonEncode(
        records.map((item) => item.toJson()).toList(growable: false),
      );
      final saved = await prefs.setString(_key(record.patientId), encoded);
      if (!saved) {
        throw const StorageException(
          'No se pudo guardar el registro en este dispositivo.',
        );
      }
    } on StorageException {
      rethrow;
    } catch (error) {
      throw StorageException(
        'No se pudo guardar el registro en este dispositivo.',
        cause: error,
      );
    }
  }

  @override
  Future<void> deleteRecord({
    required String patientId,
    required String recordId,
  }) async {
    try {
      final prefs = await _prefs;
      final records = await _readAll(prefs, patientId);
      records.removeWhere((record) => record.id == recordId);
      final encoded = jsonEncode(
        records.map((item) => item.toJson()).toList(growable: false),
      );
      final saved = await prefs.setString(_key(patientId), encoded);
      if (!saved) {
        throw const StorageException(
          'No se pudo eliminar el registro de este dispositivo.',
        );
      }
    } on StorageException {
      rethrow;
    } catch (error) {
      throw StorageException(
        'No se pudo eliminar el registro de este dispositivo.',
        cause: error,
      );
    }
  }

  /// Elimina todos los registros locales del paciente.
  Future<void> deleteAll(String patientId) async {
    final prefs = await _prefs;
    await prefs.remove(_key(patientId));
  }

  Future<List<EmotionalRecord>> _readAll(
    SharedPreferences prefs,
    String patientId,
  ) async {
    final raw = prefs.getString(_key(patientId));
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(EmotionalRecord.fromJson)
          .where((record) => record.patientId == patientId)
          .toList();
    } catch (_) {
      // Un dato corrupto no debe impedir seguir usando el diario. Se conserva
      // una copia de seguridad en una clave aparte antes de continuar.
      await prefs.setString('${_key(patientId)}.corrupt', raw);
      return [];
    }
  }

  static int _compareRecords(EmotionalRecord a, EmotionalRecord b) {
    final byDate = b.eventDate.compareTo(a.eventDate);
    if (byDate != 0) return byDate;
    return b.createdAt.compareTo(a.createdAt);
  }
}
