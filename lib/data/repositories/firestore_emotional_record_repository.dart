import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/date_utils.dart';
import '../../models/emotional_record.dart';
import '../../models/record_filter.dart';
import 'emotional_record_repository.dart';

/// Repositorio de registros emocionales en Cloud Firestore.
///
/// Estructura:
/// `users/{uid}/records/{recordId}`
///
/// El UID procede de Firebase Authentication. Las reglas de seguridad impiden
/// que un paciente lea o escriba datos de otro.
class FirestoreEmotionalRecordRepository implements EmotionalRecordRepository {
  FirestoreEmotionalRecordRepository({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _records(String patientId) =>
      _db.collection('users').doc(patientId).collection('records');

  @override
  Future<List<EmotionalRecord>> fetchRecords({
    required String patientId,
    RecordFilter filter = const RecordFilter(),
  }) async {
    try {
      final snapshot = await _records(patientId)
          .orderBy('eventDate', descending: true)
          .get();

      final records = snapshot.docs
          .map((doc) => _fromFirestore(doc.id, doc.data()))
          .where((record) => record.patientId == patientId)
          .where(filter.matches)
          .toList();

      records.sort((a, b) {
        final byDate = b.eventDate.compareTo(a.eventDate);
        if (byDate != 0) return byDate;
        return b.createdAt.compareTo(a.createdAt);
      });

      return records;
    } catch (error) {
      throw StorageException(friendlyStorageError(error), cause: error);
    }
  }

  @override
  Future<void> upsertRecord(EmotionalRecord record) async {
    try {
      await _records(record.patientId)
          .doc(record.id)
          .set(_toFirestore(record), SetOptions(merge: true));
    } catch (error) {
      throw StorageException(friendlyStorageError(error), cause: error);
    }
  }

  @override
  Future<void> deleteRecord({
    required String patientId,
    required String recordId,
  }) async {
    try {
      await _records(patientId).doc(recordId).delete();
    } catch (error) {
      throw StorageException(friendlyStorageError(error), cause: error);
    }
  }

  Map<String, dynamic> _toFirestore(EmotionalRecord record) {
    final data = record.toJson();
    data['eventDate'] = Timestamp.fromDate(dateOnly(record.eventDate));
    data['createdAt'] = Timestamp.fromDate(record.createdAt);
    data['updatedAt'] = Timestamp.fromDate(record.updatedAt);
    data['patientId'] = record.patientId;
    return data;
  }

  EmotionalRecord _fromFirestore(String id, Map<String, dynamic> data) {
    final normalized = Map<String, dynamic>.from(data);
    for (final field in ['eventDate', 'createdAt', 'updatedAt']) {
      final value = normalized[field];
      if (value is Timestamp) {
        normalized[field] = value.toDate().toIso8601String();
      }
    }
    normalized['id'] = id;
    return EmotionalRecord.fromJson(normalized);
  }
}
