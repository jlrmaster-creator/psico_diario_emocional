import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/errors/app_exception.dart';
import '../../models/emotion.dart';
import 'emotion_catalog_repository.dart';

/// Emociones personalizadas en `users/{uid}/customEmotions/{emotionId}`.
class FirestoreEmotionCatalogRepository implements EmotionCatalogRepository {
  FirestoreEmotionCatalogRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _collection(String patientId) =>
      _db.collection('users').doc(patientId).collection('customEmotions');

  @override
  Future<List<Emotion>> loadCustomEmotions(String patientId) async {
    try {
      final snapshot = await _collection(patientId).get();
      return snapshot.docs
          .map((doc) {
            final data = doc.data();
            return Emotion.fromJson(
              {...data, 'id': doc.id},
              groupId: data['groupId'] as String? ?? '',
              isCustom: true,
            );
          })
          .where((emotion) => emotion.groupId.isNotEmpty)
          .toList(growable: false);
    } catch (error) {
      throw StorageException(friendlyStorageError(error), cause: error);
    }
  }

  @override
  Future<void> addCustomEmotion(String patientId, Emotion emotion) async {
    try {
      await _collection(patientId).doc(emotion.id).set({
        ...emotion.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      throw StorageException(friendlyStorageError(error), cause: error);
    }
  }

  @override
  Future<void> deleteCustomEmotion(String patientId, String emotionId) async {
    try {
      await _collection(patientId).doc(emotionId).delete();
    } catch (error) {
      throw StorageException(friendlyStorageError(error), cause: error);
    }
  }
}
