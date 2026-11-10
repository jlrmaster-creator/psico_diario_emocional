import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/app_exception.dart';
import '../../models/emotion.dart';
import 'emotion_catalog_repository.dart';

class LocalEmotionCatalogRepository implements EmotionCatalogRepository {
  LocalEmotionCatalogRepository({SharedPreferences? preferences})
    : _providedPreferences = preferences;

  final SharedPreferences? _providedPreferences;

  static String _key(String patientId) => 'psico.customEmotions.$patientId';

  Future<SharedPreferences> get _prefs async =>
      _providedPreferences ?? await SharedPreferences.getInstance();

  @override
  Future<List<Emotion>> loadCustomEmotions(String patientId) async {
    try {
      final prefs = await _prefs;
      final raw = prefs.getString(_key(patientId));
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];

      return decoded
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => Emotion.fromJson(
              item,
              groupId: item['groupId'] as String? ?? '',
              isCustom: true,
            ),
          )
          .where(
            (emotion) => emotion.id.isNotEmpty && emotion.groupId.isNotEmpty,
          )
          .toList(growable: false);
    } catch (error) {
      throw StorageException(
        'No se pudieron leer las emociones personalizadas.',
        cause: error,
      );
    }
  }

  @override
  Future<void> addCustomEmotion(String patientId, Emotion emotion) async {
    try {
      final prefs = await _prefs;
      final current = await loadCustomEmotions(patientId);
      final updated = [
        ...current.where((item) => item.id != emotion.id),
        emotion,
      ];
      final saved = await prefs.setString(
        _key(patientId),
        jsonEncode(updated.map((item) => item.toJson()).toList()),
      );
      if (!saved) {
        throw const StorageException('No se pudo guardar la emoción.');
      }
    } on StorageException {
      rethrow;
    } catch (error) {
      throw StorageException('No se pudo guardar la emoción.', cause: error);
    }
  }

  @override
  Future<void> deleteCustomEmotion(String patientId, String emotionId) async {
    try {
      final prefs = await _prefs;
      final current = await loadCustomEmotions(patientId);
      final updated = current.where((item) => item.id != emotionId).toList();
      await prefs.setString(
        _key(patientId),
        jsonEncode(updated.map((item) => item.toJson()).toList()),
      );
    } catch (error) {
      throw StorageException('No se pudo eliminar la emoción.', cause: error);
    }
  }
}
