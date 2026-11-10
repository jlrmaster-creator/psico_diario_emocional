import '../../models/emotion.dart';

/// Almacenamiento de emociones personalizadas del paciente.
abstract interface class EmotionCatalogRepository {
  Future<List<Emotion>> loadCustomEmotions(String patientId);
  Future<void> addCustomEmotion(String patientId, Emotion emotion);
  Future<void> deleteCustomEmotion(String patientId, String emotionId);
}
